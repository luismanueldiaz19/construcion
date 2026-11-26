<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ImageOptimizer
{
    /**
     * Extensiones y MIME types admitidos para optimización y compresión.
     */
    protected const SUPPORTED_MIMES = [
        'image/jpeg' => 'jpg',
        'image/jpg'  => 'jpg',
        'image/png'  => 'png',
        'image/webp' => 'webp',
    ];

    /**
     * Optimiza y almacena un archivo subido.
     * Si es una imagen (JPG, PNG, WEBP), la redimensiona a un máximo proporcional
     * (por defecto 1600px) y la recomprime con calidad 75-80%, reduciendo fotos de 10MB-20MB
     * a aproximadamente 150KB - 350KB sin perder legibilidad en planos, firmas o documentos.
     * Si no es imagen (ej. PDF) o si ocurre algún error, se almacena directamente sin alteración.
     *
     * @param UploadedFile $file
     * @param string $directory Directorio de destino en storage (ej. 'proyectos/2026/1' o 'compras_documentos')
     * @param string $disk Disco de almacenamiento (por defecto 'public')
     * @param int $maxDimension Dimensión máxima en píxeles (ancho o alto, por defecto 1600)
     * @param int $quality Calidad de compresión (1-100, por defecto 75)
     * @return string Ruta relativa resultante en el disco de storage
     */
    public static function optimizeAndStore(
        UploadedFile $file,
        string $directory,
        string $disk = 'public',
        int $maxDimension = 1600,
        int $quality = 75
    ): string {
        // Elevar temporalmente el límite de memoria para permitir descomprimir fotos pesadas (ej: 6000x4000)
        @ini_set('memory_limit', '512M');

        $realPath = $file->getRealPath();
        if (!$realPath || !file_exists($realPath)) {
            return $file->store($directory, $disk);
        }

        // Si la extensión GD no está disponible, almacenar directamente
        if (!extension_loaded('gd')) {
            Log::warning('[ImageOptimizer] Extensión GD no disponible. Almacenando archivo sin compresión.');
            return $file->store($directory, $disk);
        }

        $mime = $file->getMimeType() ?: @mime_content_type($realPath);
        $ext = strtolower($file->getClientOriginalExtension());

        // Verificar si es un tipo de imagen soportado
        $targetExt = self::SUPPORTED_MIMES[$mime] ?? null;
        if (!$targetExt && in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) {
            $targetExt = ($ext === 'jpeg') ? 'jpg' : $ext;
        }

        // Si es PDF u otro archivo no soportado, almacenar tal cual
        if (!$targetExt) {
            return $file->store($directory, $disk);
        }

        try {
            $imageInfo = @getimagesize($realPath);
            if (!$imageInfo) {
                return $file->store($directory, $disk);
            }

            [$origW, $origH] = $imageInfo;
            if ($origW <= 0 || $origH <= 0) {
                return $file->store($directory, $disk);
            }

            // Crear recurso GD según el formato original
            $srcImage = match ($imageInfo[2]) {
                IMAGETYPE_JPEG => @imagecreatefromjpeg($realPath),
                IMAGETYPE_PNG  => @imagecreatefrompng($realPath),
                IMAGETYPE_WEBP => function_exists('imagecreatefromwebp') ? @imagecreatefromwebp($realPath) : null,
                default        => null,
            };

            if (!$srcImage) {
                return $file->store($directory, $disk);
            }

            // Corregir orientación EXIF si está disponible (fotos tomadas con móviles)
            if (function_exists('exif_read_data')) {
                try {
                    $exif = @exif_read_data($realPath);
                    if (!empty($exif['Orientation'])) {
                        $srcImage = match ($exif['Orientation']) {
                            3 => imagerotate($srcImage, 180, 0),
                            6 => imagerotate($srcImage, -90, 0),
                            8 => imagerotate($srcImage, 90, 0),
                            default => $srcImage,
                        };
                        $origW = imagesx($srcImage);
                        $origH = imagesy($srcImage);
                    }
                } catch (\Throwable) {
                    // Ignorar errores de lectura EXIF
                }
            }

            // Calcular escala proporcional respetando el límite máximo
            $scale = min($maxDimension / $origW, $maxDimension / $origH, 1.0);
            $newW = (int) max(1, round($origW * $scale));
            $newH = (int) max(1, round($origH * $scale));

            $dstImage = imagecreatetruecolor($newW, $newH);

            if ($targetExt === 'png' || $targetExt === 'webp') {
                imagealphablending($dstImage, false);
                imagesavealpha($dstImage, true);
                $transparent = imagecolorallocatealpha($dstImage, 255, 255, 255, 127);
                imagefilledrectangle($dstImage, 0, 0, $newW, $newH, $transparent);
            }

            imagecopyresampled($dstImage, $srcImage, 0, 0, 0, 0, $newW, $newH, $origW, $origH);

            // Generar archivo temporal comprimido
            $tempPath = tempnam(sys_get_temp_dir(), 'opt_');
            if ($targetExt === 'png') {
                imagepng($dstImage, $tempPath, 7);
            } elseif ($targetExt === 'webp' && function_exists('imagewebp')) {
                imagewebp($dstImage, $tempPath, $quality);
            } else {
                $targetExt = 'jpg';
                imagejpeg($dstImage, $tempPath, $quality);
            }

            imagedestroy($srcImage);
            imagedestroy($dstImage);

            // Guardar en el disco de storage
            $filename = Str::random(40) . '.' . $targetExt;
            $destinationPath = trim($directory, '/') . '/' . $filename;

            Storage::disk($disk)->put($destinationPath, file_get_contents($tempPath));
            @unlink($tempPath);

            return $destinationPath;
        } catch (\Throwable $e) {
            Log::error('[ImageOptimizer] Error al optimizar imagen: ' . $e->getMessage() . '. Fallback a almacenamiento original.');
            return $file->store($directory, $disk);
        }
    }

    /**
     * Optimiza y recomprime un archivo ya existente en el disco de storage.
     * Reemplaza el archivo si la versión optimizada reduce el tamaño.
     */
    public static function optimizeExistingFile(
        string $relativePath,
        string $disk = 'public',
        int $maxDimension = 1600,
        int $quality = 75
    ): bool {
        @ini_set('memory_limit', '512M');

        if (!extension_loaded('gd') || !Storage::disk($disk)->exists($relativePath)) {
            return false;
        }

        $fullPath = Storage::disk($disk)->path($relativePath);
        if (!file_exists($fullPath)) {
            return false;
        }

        $info = @getimagesize($fullPath);
        if (!$info) {
            return false;
        }

        [$w, $h] = $info;
        if ($w <= 0 || $h <= 0) {
            return false;
        }

        try {
            $srcImage = match ($info[2]) {
                IMAGETYPE_JPEG => @imagecreatefromjpeg($fullPath),
                IMAGETYPE_PNG  => @imagecreatefrompng($fullPath),
                IMAGETYPE_WEBP => function_exists('imagecreatefromwebp') ? @imagecreatefromwebp($fullPath) : null,
                default        => null,
            };

            if (!$srcImage) {
                return false;
            }

            $scale = min($maxDimension / $w, $maxDimension / $h, 1.0);
            $newW = (int) max(1, round($w * $scale));
            $newH = (int) max(1, round($h * $scale));

            $dstImage = imagecreatetruecolor($newW, $newH);

            if ($info[2] === IMAGETYPE_PNG || $info[2] === IMAGETYPE_WEBP) {
                imagealphablending($dstImage, false);
                imagesavealpha($dstImage, true);
                $transparent = imagecolorallocatealpha($dstImage, 255, 255, 255, 127);
                imagefilledrectangle($dstImage, 0, 0, $newW, $newH, $transparent);
            }

            imagecopyresampled($dstImage, $srcImage, 0, 0, 0, 0, $newW, $newH, $w, $h);

            $tempPath = tempnam(sys_get_temp_dir(), 'opt_exist_');
            if ($info[2] === IMAGETYPE_PNG) {
                imagepng($dstImage, $tempPath, 7);
            } elseif ($info[2] === IMAGETYPE_WEBP && function_exists('imagewebp')) {
                imagewebp($dstImage, $tempPath, $quality);
            } else {
                imagejpeg($dstImage, $tempPath, $quality);
            }

            imagedestroy($srcImage);
            imagedestroy($dstImage);

            $origSize = filesize($fullPath);
            $newSize = filesize($tempPath);

            // Solo reemplazar si realmente redujo de tamaño
            if ($newSize < $origSize) {
                copy($tempPath, $fullPath);
            }
            @unlink($tempPath);

            return true;
        } catch (\Throwable $e) {
            Log::warning('[ImageOptimizer] Error optimizando archivo existente ' . $relativePath . ': ' . $e->getMessage());
            return false;
        }
    }
}

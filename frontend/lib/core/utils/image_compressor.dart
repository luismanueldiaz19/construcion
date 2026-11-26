import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Utilidad centralizada para selección y compresión de imágenes en el cliente.
/// 
/// Evita subir archivos pesados (10MB - 20MB) al servidor redimensionando y
/// comprimiendo en el dispositivo antes de la transmisión HTTP.
class ImageCompressor {
  static final ImagePicker _picker = ImagePicker();

  /// Abre un modal intuitivo para que el usuario elija entre Cámara o Galería,
  /// y retorna la imagen ya comprimida y optimizada.
  static Future<XFile?> pickAndCompressWithModal(
    BuildContext context, {
    int imageQuality = 80,
    double maxWidth = 1600,
    double maxHeight = 1600,
  }) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Seleccionar Imagen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFE31E24),
                  ),
                ),
                title: const Text(
                  'Tomar foto con la cámara',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: const Text(
                  'Compresión automática en alta calidad',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text(
                  'Elegir de la galería',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: const Text(
                  'Optimiza fotos pesadas antes de subirlas',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    return pickAndCompressImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  /// Selecciona una imagen de la fuente indicada y la comprime directamente.
  static Future<XFile?> pickAndCompressImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
    double maxWidth = 1600,
    double maxHeight = 1600,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return image;
    } catch (_) {
      return null;
    }
  }
}

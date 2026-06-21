Write-Host "Iniciando compilación de Flutter Web..." -ForegroundColor Cyan

# 1. Navegar y compilar Flutter Web
Push-Location "$PSScriptRoot\frontend"
flutter build web --release --web-renderer canvaskit
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en la compilación de Flutter Web." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host "Compilación completada. Copiando archivos a Laravel..." -ForegroundColor Cyan

# Rutas
$buildWebDir = "$PSScriptRoot\frontend\build\web"
$publicDir = "$PSScriptRoot\backend\public"
$bladeViewPath = "$PSScriptRoot\backend\resources\views\app.blade.php"

# 2. Asegurar que las carpetas existen
if (-not (Test-Path $publicDir)) {
    New-Item -ItemType Directory -Path $publicDir -Force | Out-Null
}

# 3. Limpiar carpetas de compilaciones previas para evitar acumulación
$foldersToClean = @("assets", "canvaskit", "icons", "images")
foreach ($folder in $foldersToClean) {
    $targetFolder = Join-Path $publicDir $folder
    if (Test-Path $targetFolder) {
        Remove-Item -Recurse -Force $targetFolder
    }
}

# 4. Copiar todos los archivos de build/web a backend/public
Copy-Item -Path "$buildWebDir\*" -Destination $publicDir -Recurse -Force

# 5. Copiar index.html a app.blade.php para que Laravel lo sirva como vista
if (Test-Path "$buildWebDir\index.html") {
    Copy-Item -Path "$buildWebDir\index.html" -Destination $bladeViewPath -Force
    Write-Host "Se actualizó app.blade.php con el nuevo index.html." -ForegroundColor Green
}

# 6. Borrar index.html del public de Laravel para evitar conflictos con las rutas amigables de Laravel
$publicIndexHtml = Join-Path $publicDir "index.html"
if (Test-Path $publicIndexHtml) {
    Remove-Item -Path $publicIndexHtml -Force
}

Write-Host "¡Proceso terminado con éxito! Listo para hacer git add, commit y push en producción." -ForegroundColor Green

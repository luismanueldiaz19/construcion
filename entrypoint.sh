#!/bin/bash
set -e

# Optimizar caché de configuración, rutas y vistas para producción
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link || true

exec "$@"

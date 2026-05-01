#!/bin/bash
set -e

php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear || true
php artisan storage:link || true
# php artisan migrate || true
# Migraciones solo si quieres automatizar (opcional)
# php artisan migrate --force || true

exec "$@"

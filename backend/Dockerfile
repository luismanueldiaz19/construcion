FROM php:8.2-apache

# Instalación de dependencias del sistema
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_pgsql gd zip

# Configuración de PHP (Aumentar límites para documentos pesados)
RUN echo "upload_max_filesize = 25M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 25M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini

# Habilitar mod_rewrite de Apache para las rutas de Laravel
RUN a2enmod rewrite

# Directorio de trabajo
WORKDIR /var/www/html

# Copiar el código del proyecto
COPY . /var/www/html

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar dependencias de PHP sin entorno de desarrollo
RUN composer install --no-dev --optimize-autoloader

# Configurar permisos para Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Apuntar Apache a la carpeta /public de Laravel
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

# Puerto expuesto
EXPOSE 80

# Script de inicio para Render: limpia caché, linkea storage y corre migraciones
CMD php artisan config:clear && \
    php artisan cache:clear && \
    php artisan route:clear && \
    php artisan view:clear && \
    php artisan storage:link && \
    php artisan migrate --seed --force && \
    exec apache2-foreground

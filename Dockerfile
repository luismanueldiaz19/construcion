# Etapa 1: Build con Composer
FROM composer:2 AS build

WORKDIR /app

# Copiar composer.json y composer.lock primero (para cache de dependencias)
COPY backend/composer.json backend/composer.lock ./

# Instalar dependencias sin dev
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copiar el resto del proyecto
COPY backend/ .

# Etapa 2: Runtime con PHP + Apache
FROM php:8.2-apache

# Dependencias del sistema
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
    && docker-php-ext-install pdo pdo_pgsql gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configuración PHP
RUN echo "upload_max_filesize = 25M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 25M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini

# Apache
RUN a2enmod rewrite

WORKDIR /var/www/html

# Copiar proyecto desde la etapa build (incluye vendor ya instalado)
COPY --from=build /app /var/www/html

# Permisos Laravel
RUN mkdir -p storage bootstrap/cache && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Apache apunta a public
RUN sed -i 's!/var/www/html!/var/www/html/public!g' \
    /etc/apache2/sites-available/000-default.conf

EXPOSE 80

# Entrypoint script para limpiar caches y preparar entorno
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

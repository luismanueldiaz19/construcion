# Etapa 1: Construcción (Build)
FROM debian:latest AS build-env

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Descargar Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Ejecutar doctor y habilitar web
RUN flutter doctor -v
RUN flutter config --enable-web

# Copiar el código del proyecto
WORKDIR /app
COPY . .

# Obtener dependencias y compilar para web
RUN flutter pub get
RUN flutter build web --release

# Etapa 2: Servidor (Nginx)
FROM nginx:alpine

# Copiar los archivos compilados desde la etapa anterior
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Exponer el puerto 80 (puerto por defecto de Render)
EXPOSE 80

# Iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]

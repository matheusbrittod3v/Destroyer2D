# Escolha uma imagem oficial com PHP e extensões necessárias
FROM php:8.2-cli

# Instale dependências do sistema e extensões PHP necessárias para o Laravel
RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql zip

# Instale o Composer globalmente
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Crie diretório do app
WORKDIR /var/www

# Copie os arquivos da aplicação Laravel para o contêiner
COPY . .

# Instale as dependências do PHP
RUN composer install --no-dev --optimize-autoloader

# Ajusta permissões (dependendo do seu SO host pode ser necessário usar `www-data`)
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Porta exposta (a padrão do artisan serve)
EXPOSE 8000

# Comando padrão ao iniciar o container
CMD php artisan serve --host=0.0.0.0 --port=8000

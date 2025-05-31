# Base com Apache e PHP 8.2
FROM php:8.2-apache

# Instale dependências e extensões PHP necessárias para Laravel + Node.js + npm
RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev libpng-dev libonig-dev libxml2-dev \
    gnupg ca-certificates lsb-release wget build-essential \
    && docker-php-ext-install pdo pdo_mysql zip

# Instalar Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Instale o Composer globalmente
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Define o diretório da aplicação
WORKDIR /var/www/html

# Copie os arquivos da aplicação para o container
COPY . .

# Copie o arquivo de configuração personalizado do Apache
COPY apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Instala dependências PHP do Laravel
RUN composer install --no-dev --optimize-autoloader

# Instala dependências do frontend
RUN npm install && npm run build

# Permissões corretas
RUN chown -R www-data:www-data storage bootstrap/cache

# Habilita mod_rewrite
RUN a2enmod rewrite

# Exponha a porta do Apache
EXPOSE 80

# Inicia o Apache
CMD ["apache2-foreground"]

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

# Instale dependências PHP
RUN composer install --no-dev --optimize-autoloader

# Instale dependências do frontend
RUN npm install && npm run build

# Permissões
RUN chown -R www-data:www-data storage bootstrap/cache

# Configura o Apache para apontar para public/
RUN echo '<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/public
    <Directory /var/www/html/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Habilita mod_rewrite (importante para rotas do Laravel)
RUN a2enmod rewrite

# Exponha a porta padrão do Apache
EXPOSE 80

# Inicia o Apache no modo foreground
CMD ["apache2-foreground"]

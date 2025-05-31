FROM php:8.2-apache

# Instala dependências do sistema e extensões PHP necessárias para Laravel
RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev libpng-dev libonig-dev libxml2-dev \
    gnupg ca-certificates lsb-release wget build-essential \
    && docker-php-ext-install pdo pdo_mysql zip mbstring xml

# Instala Node.js 20.x e npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Copia o Composer do container oficial para cá
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Define diretório de trabalho
WORKDIR /var/www/html

# Copia arquivos do projeto
COPY . .

# Habilita rewrite do Apache (obrigatório para Laravel)
RUN a2enmod rewrite

# Configura virtual host do Apache com permissão para .htaccess
RUN printf '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>\n' > /etc/apache2/sites-available/000-default.conf

# Instala dependências PHP via composer sem dev e com otimização
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Instala dependências frontend e compila (ajuste se usa Vite ou Mix)
RUN npm install && npm run build

# Ajusta permissões (muito importante para evitar erro 500)
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Expõe porta padrão do Apache
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]


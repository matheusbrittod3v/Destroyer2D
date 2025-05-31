# Etapa base com Apache e PHP 8.2
FROM php:8.2-apache

# Instala dependências de sistema e extensões PHP
RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev libpng-dev libonig-dev libxml2-dev \
    gnupg ca-certificates lsb-release wget build-essential \
    && docker-php-ext-install pdo pdo_mysql zip

# Instala Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Copia o Composer da imagem oficial
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Define o diretório de trabalho da aplicação
WORKDIR /var/www/html

# Copia os arquivos do projeto
COPY . .

# Ativa o módulo rewrite do Apache
RUN a2enmod rewrite

# Gera dinamicamente o arquivo de configuração do Apache com quebras de linha válidas
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

# Instala dependências do Laravel
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Instala dependências e compila frontend
RUN npm install && npm run build

# Ajusta permissões de diretórios necessários
RUN chown -R www-data:www-data storage bootstrap/cache

# Expõe a porta padrão do Apache
EXPOSE 80

# Comando de entrada do container
CMD ["apache2-foreground"]

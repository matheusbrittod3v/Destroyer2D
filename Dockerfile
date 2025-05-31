# Escolha uma imagem oficial com PHP e extensões necessárias
FROM php:8.2-cli

# Instale dependências do sistema, Node.js, npm e extensões PHP necessárias para o Laravel
RUN apt-get update && apt-get install -y \
    zip unzip git curl libzip-dev libpng-dev libonig-dev libxml2-dev \
    gnupg ca-certificates lsb-release wget build-essential \
    && docker-php-ext-install pdo pdo_mysql zip

# Instalar Node.js 20 LTS e npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Instale o Composer globalmente
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Crie diretório do app
WORKDIR /var/www

# Copie os arquivos da aplicação Laravel para o contêiner
COPY . .

# Instale as dependências do PHP (Laravel)
RUN composer install --no-dev --optimize-autoloader

# Instale dependências do frontend com npm
RUN npm install

# Compile os assets com Vite ou Mix (ajuste conforme seu setup)
RUN npm run build

# Ajusta permissões (dependendo do seu SO host pode ser necessário usar `www-data`)
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expor a porta padrão do Laravel artisan serve
EXPOSE 80

# Comando padrão ao iniciar o container
CMD php artisan serve --host=0.0.0.0 --port=80

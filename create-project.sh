#!/bin/bash

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les logs
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier les prérequis
check_requirements() {
    log_info "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl n'est pas installé"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq n'est pas installé. Installez-le avec: sudo apt install jq"
        exit 1
    fi
    
    log_success "Tous les prérequis sont satisfaits"
}

# Récupérer la dernière version de Laravel
get_latest_laravel_version() {
    log_info "Récupération de la dernière version de Laravel..."
    
    local version=$(curl -s https://api.github.com/repos/laravel/laravel/releases/latest | jq -r .tag_name)
    
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        log_warning "Impossible de récupérer la version via GitHub, utilisation de 'latest'"
        echo "latest"
    else
        echo "$version"
    fi
}

# Récupérer la version PHP requise pour Laravel
get_required_php_version() {
    local laravel_version=$1
    log_info "Détermination de la version PHP requise..."
    
    # Créer un conteneur temporaire pour récupérer les infos de composer.json
    local temp_dir=$(mktemp -d)
    
    # Télécharger Laravel dans un conteneur temporaire
    docker run --rm -v "$temp_dir:/app" composer:latest create-project --prefer-dist laravel/laravel /app --no-interaction --quiet 2>/dev/null || true
    
    # Lire les requirements PHP depuis composer.json
    if [ -f "$temp_dir/composer.json" ]; then
        local php_req=$(jq -r '.require.php // empty' "$temp_dir/composer.json")
        
        # Extraire la version minimale (ex: "^8.2" -> "8.2")
        if [ ! -z "$php_req" ]; then
            local php_version=$(echo "$php_req" | grep -oP '\d+\.\d+' | head -1)
            rm -rf "$temp_dir"
            echo "$php_version"
            return
        fi
    fi
    
    rm -rf "$temp_dir"
    
    # Versions par défaut selon la version de Laravel
    log_warning "Impossible de déterminer automatiquement, utilisation de la version par défaut"
    echo "8.3"
}

# Créer le Dockerfile
create_dockerfile() {
    local php_version=$1
    local project_path=$2
    
    log_info "Création du Dockerfile avec PHP $php_version..."
    
    mkdir -p "$project_path/.docker"
    
    cat > "$project_path/.docker/Dockerfile" <<EOF
FROM php:${php_version}-fpm

# Installation des dépendances système
RUN apt-get update && apt-get install -y \\
    git \\
    curl \\
    libpng-dev \\
    libonig-dev \\
    libxml2-dev \\
    zip \\
    unzip \\
    libzip-dev \\
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définir le répertoire de travail
WORKDIR /var/www

# Copier les fichiers de l'application
COPY . /var/www

# Définir les permissions
RUN chown -R www-data:www-data /var/www

# Exposer le port 9000 pour PHP-FPM
EXPOSE 9000

CMD ["php-fpm"]
EOF
    
    log_success "Dockerfile créé"
}

# Créer le docker-compose.yml
create_docker_compose() {
    local project_name=$1
    local project_path=$2
    local php_version=$3
    
    log_info "Création du docker-compose.yml..."
    
    cat > "$project_path/docker-compose.yml" <<EOF
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: .docker/Dockerfile
    container_name: ${project_name}_app
    restart: unless-stopped
    working_dir: /var/www
    volumes:
      - ./:/var/www
    networks:
      - ${project_name}_network
    environment:
      - PHP_VERSION=${php_version}

  nginx:
    image: nginx:alpine
    container_name: ${project_name}_nginx
    restart: unless-stopped
    ports:
      - "8000:80"
    volumes:
      - ./:/var/www
      - ./.docker/nginx:/etc/nginx/conf.d
    networks:
      - ${project_name}_network

  db:
    image: mysql:8.0
    container_name: ${project_name}_db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${project_name}
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_PASSWORD: secret
      MYSQL_USER: laravel
    volumes:
      - dbdata:/var/lib/mysql
    ports:
      - "3306:3306"
    networks:
      - ${project_name}_network

networks:
  ${project_name}_network:
    driver: bridge

volumes:
  dbdata:
    driver: local
EOF
    
    # Créer la config nginx
    mkdir -p "$project_path/.docker/nginx"
    cat > "$project_path/.docker/nginx/default.conf" <<EOF
server {
    listen 80;
    index index.php index.html;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/public;

    location ~ \\.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\\.php)(/.+)$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }
}
EOF
    
    log_success "docker-compose.yml créé"
}

# Créer le projet Laravel
create_laravel_project() {
    local project_name=$1
    local project_path=$2
    local laravel_version=$3
    
    log_info "Création du projet Laravel '$project_name'..."
    
    # Créer le projet avec Composer via Docker
    docker run --rm -v "$project_path:/app" composer:latest create-project --prefer-dist laravel/laravel /app
    
    log_success "Projet Laravel créé"
}

# Afficher le résumé des versions
show_version_summary() {
    local project_name=$1
    local project_path=$2
    local php_version=$3
    local laravel_version=$4
    
    log_info "Génération du résumé des versions..."
    
    # Lire la version de Laravel depuis composer.json
    local actual_laravel_version=$(jq -r '.require."laravel/framework" // "N/A"' "$project_path/composer.json")
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           RÉSUMÉ DE L'INSTALLATION - $project_name"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║ Version PHP:           $php_version"
    echo "║ Version Laravel:       $actual_laravel_version"
    echo "║ Chemin du projet:      $project_path"
    echo "║ "
    echo "║ Services disponibles:"
    echo "║   - Application:       http://localhost:8000"
    echo "║   - Base de données:   localhost:3306"
    echo "║     * User:            laravel"
    echo "║     * Password:        secret"
    echo "║     * Database:        $project_name"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║ Pour démarrer le projet:"
    echo "║   cd $project_path"
    echo "║   docker-compose up -d"
    echo "║   docker-compose exec app php artisan key:generate"
    echo "║   docker-compose exec app php artisan migrate"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Fonction principale
main() {
    # Vérifier les arguments
    if [ $# -eq 0 ]; then
        log_error "Usage: $0 <nom_du_projet>"
        exit 1
    fi
    
    local project_name=$1
    
    # Vérifier les prérequis
    check_requirements
    
    # Déterminer le chemin du projet
    local project_path
    if [ ! -z "$PJ" ]; then
        project_path="$PJ/$project_name"
        log_info "Utilisation du répertoire défini dans \$PJ: $project_path"
    else
        project_path="$(pwd)/$project_name"
        log_info "Installation dans le répertoire courant: $project_path"
    fi
    
    # Vérifier si le répertoire existe déjà
    if [ -d "$project_path" ]; then
        log_error "Le répertoire $project_path existe déjà"
        exit 1
    fi
    
    # Créer le répertoire du projet
    mkdir -p "$project_path"
    
    # Récupérer la dernière version de Laravel
    local laravel_version=$(get_latest_laravel_version)
    log_success "Version Laravel: $laravel_version"
    
    # Récupérer la version PHP requise
    local php_version=$(get_required_php_version "$laravel_version")
    log_success "Version PHP déterminée: $php_version"
    
    # Créer le projet Laravel
    create_laravel_project "$project_name" "$project_path" "$laravel_version"
    
    # Créer les fichiers Docker
    create_dockerfile "$php_version" "$project_path"
    create_docker_compose "$project_name" "$project_path" "$php_version"
    
    # Afficher le résumé
    show_version_summary "$project_name" "$project_path" "$php_version" "$laravel_version"
    
    log_success "Installation terminée avec succès !"
}

# Exécuter le script
main "$@"

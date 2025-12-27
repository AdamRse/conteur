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
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

# Fonction pour afficher un spinner pendant une opération longue
show_spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    
    echo -n "$message " >&2
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r$message ${spin:$i:1}" >&2
        sleep 0.1
    done
    printf "\r$message ✓\n" >&2
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

# Récupérer les informations de la dernière version de Laravel
get_latest_laravel_info() {
    log_info "Récupération des informations sur la dernière version de Laravel..."
    
    # Récupérer les infos depuis l'API GitHub
    local api_response=$(curl -s https://api.github.com/repos/laravel/framework/releases/latest)
    local version=$(echo "$api_response" | jq -r .tag_name)
    
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        log_warning "Impossible de récupérer la version via GitHub API"
        echo ""
        return 1
    fi
    
    # Nettoyer la version (enlever le 'v' si présent)
    version=$(echo "$version" | sed 's/^v//')
    
    echo "$version"
    return 0
}

# Récupérer la version PHP requise depuis un projet Laravel existant
get_actual_php_requirement() {
    local project_path=$1
    
    log_info "Vérification des exigences PHP réelles du projet..."
    
    if [ ! -f "$project_path/composer.json" ]; then
        log_warning "composer.json introuvable, utilisation de PHP 8.4 par défaut"
        echo "8.4"
        return
    fi
    
    # Lire le requirement PHP depuis composer.json
    local php_req=$(jq -r '.require.php // empty' "$project_path/composer.json")
    
    if [ -z "$php_req" ]; then
        log_warning "Requirement PHP non spécifié, utilisation de PHP 8.4 par défaut"
        echo "8.4"
        return
    fi
    
    log_info "Requirement PHP détecté: $php_req"
    
    # Extraire la version minimale (ex: "^8.4" -> "8.4", ">=8.4.0" -> "8.4")
    local php_version=$(echo "$php_req" | grep -oP '\d+\.\d+' | head -1)
    
    if [ -z "$php_version" ]; then
        log_warning "Impossible de parser le requirement PHP '$php_req', utilisation de PHP 8.4 par défaut"
        echo "8.4"
        return
    fi
    
    log_success "Version PHP extraite: $php_version"
    echo "$php_version"
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
    
    log_info "Création du projet Laravel '$project_name'..."
    
    # Créer le projet avec Composer via Docker (en arrière-plan pour le spinner)
    (docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$project_path:/app" \
        composer:latest \
        create-project --prefer-dist laravel/laravel /app --no-install > /dev/null 2>&1) &
    local docker_pid=$!
    
    show_spinner $docker_pid "Téléchargement du template Laravel"
    
    wait $docker_pid
    
    log_success "Template Laravel téléchargé"
}

# Récupérer les versions installées du projet
get_installed_versions() {
    local project_path=$1
    
    if [ ! -f "$project_path/composer.json" ]; then
        echo "N/A|N/A"
        return
    fi
    
    local laravel_version=$(jq -r '.require."laravel/framework" // "N/A"' "$project_path/composer.json")
    local php_version=$(jq -r '.require.php // "N/A"' "$project_path/composer.json")
    
    echo "$laravel_version|$php_version"
}

# Afficher le résumé des versions
show_version_summary() {
    local project_name=$1
    local project_path=$2
    local php_version=$3
    
    log_info "Génération du résumé des versions..."
    
    # Récupérer les versions réellement installées
    local versions=$(get_installed_versions "$project_path")
    local laravel_version=$(echo "$versions" | cut -d'|' -f1)
    local php_requirement=$(echo "$versions" | cut -d'|' -f2)
    
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║           RÉSUMÉ DE L'INSTALLATION - $project_name"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║ Version PHP (Docker):  $php_version"
    echo "║ Requirement PHP:       $php_requirement"
    echo "║ Version Laravel:       $laravel_version"
    echo "║ Chemin du projet:      $project_path"
    echo "║ "
    echo "║ Services disponibles:"
    echo "║   - Application:       http://localhost:8000"
    echo "║   - Base de données:   localhost:3306"
    echo "║     * User:            laravel"
    echo "║     * Password:        secret"
    echo "║     * Database:        $project_name"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║ Pour démarrer le projet:"
    echo "║   cd $project_path"
    echo "║   docker-compose up -d"
    echo "║   docker-compose exec app php artisan key:generate"
    echo "║   docker-compose exec app php artisan migrate"
    echo "╚═══════════════════════════════════════════════════════════╝"
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
    
    # Récupérer les infos sur la dernière version (optionnel, pour information)
    local latest_framework_version=$(get_latest_laravel_info)
    if [ ! -z "$latest_framework_version" ]; then
        log_success "Dernière version du framework Laravel: $latest_framework_version"
    fi
    
    # Créer le projet Laravel d'abord
    create_laravel_project "$project_name" "$project_path"
    
    # Récupérer la version PHP RÉELLE après création du projet
    local php_version=$(get_actual_php_requirement "$project_path")
    
    # Vérifier que la version n'est pas vide
    if [ -z "$php_version" ]; then
        log_error "La version PHP n'a pas pu être déterminée"
        php_version="8.4"
        log_warning "Utilisation de PHP 8.4 par défaut"
    fi
    
    log_success "Version PHP requise: $php_version"
    
    # Créer les fichiers Docker APRÈS avoir déterminé la version PHP
    create_dockerfile "$php_version" "$project_path"
    create_docker_compose "$project_name" "$project_path" "$php_version"
    
    # Installer les dépendances avec la bonne version de PHP via Docker
    log_info "Installation des dépendances Composer avec PHP $php_version..."
    
    # Build l'image Docker
    (cd "$project_path" && docker compose build --no-cache > /dev/null 2>&1) &
    local build_pid=$!
    show_spinner $build_pid "Build de l'image Docker"
    wait $build_pid
    
    # Installer les dépendances dans le conteneur
    log_info "Installation des dépendances Laravel..."
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$project_path:/var/www" \
        -w /var/www \
        "php:${php_version}-fpm" \
        sh -c "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && composer install --no-interaction" > /dev/null 2>&1
    
    log_success "Dépendances installées avec PHP $php_version"
    
    # Afficher le résumé
    show_version_summary "$project_name" "$project_path" "$php_version"
    
    log_success "Installation terminée avec succès !"
}

# Exécuter le script
main "$@"

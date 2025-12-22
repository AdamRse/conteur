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

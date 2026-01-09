# -- LARAVEL VARS --

laravel_script_name=$(basename $0)

# templates
dockerfile_template_path="${script_dir}/templates/laravel/Dockerfile.template"
docker_compose_template_path="${script_dir}/templates/laravel/docker-compose.yml.template"
nginx_template_path="${script_dir}/templates/laravel/nginx.template"

# fichiers du projet
project_docker_dir="${project_path}/.docker/development"
project_dockerfile_path="${project_docker_dir}/Dockerfile"

# versions
php_version=""
laravel_version=""

# -- FUNCTIONS --

# Prépare les variables et vérifie les fichiers de configuration
# return null
laravel_check_requirments() {
    [ -d "${script_dir}" ] || eout "La variable 'script_dir' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -n "${project_path}" ] || eout "La variable 'project_path' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -f "${dockerfile_template_path}" ] || eout "Template dockerfile non trouvé dans ${dockerfile_template_path}"
    [ -f "${nginx_template_path}" ] || eout "Template de configuration nginx non trouvé dans ${nginx_template_path}"
    [ -f "${docker_compose_template_path}" ] || eout "Template docker-compose non trouvé dans ${docker_compose_template_path}"
    [ -n "${php_version}" ] || eout "La variable 'php_version' doit être initialisée"
    [ -n "${laravel_version}" ] || eout "La variable 'laravel_version' doit être initialisée"
}

# En cas de réussite il est certain qu'on retourne une version laravel et php
# return array+true|false
laravel_get_json_latest_info() {
    local packagist_link="https://repo.packagist.org/p2/laravel/laravel.json"
    
    # Récupérer et traduire la réponse JSON
    local json_response=$(curl -s --max-time 10 "${packagist_link}" | jq -r '
        .packages."laravel/laravel"[0] as $p |
        {
            "laravel_version": $p.version_normalized,
            "php_version": ($p.require.php // "" | sub("^\\^"; ""))
        }
    ')

    local version_regex='^[0-9]+(\.[0-9]+)*$'
    if [[ "$(jq -r ".laravel_version" <<< "$json_response")" =~ $version_regex ]] && [[ "$(jq -r ".php_version" <<< "$json_response")" =~ $version_regex ]]; then
        echo $json_response
        return 0
    else
        fout "Échec de récupération des infos sur la dernière version de laravel"
        return 1
    fi
}

laravel_create_dockerfile() {
    local project_dockerfile_path="/home/adam/dev/projets/conteur/Dockerfile" && debug_ "Chemin du dockerfile modifié pour $project_dockerfile_path"
    
    # Copier le template et remplacer les variables
    sed -e "s/\${PHP_VERSION}/$php_version/g" \
        -e "s/\${PROJECT_NAME}/$project_name/g" \
        "$dockerfile_template_path" > "${project_dockerfile_path}"
    
    sout "✓ Dockerfile créé dans $dockerfile_path"
}

laravel_create_docker_compose() {
    local template_file="templates/laravel/docker-compose.yml.template"
    local dockerfile_path="$project_path/docker-compose.yml"
    
    # Vérifier que le template existe
    if [[ ! -f "$template_file" ]]; then
        echo "Erreur: Le template $template_file n'existe pas"
        return 1
    fi
    
    # Copier le template et remplacer les variables
    sed -e "s/\${PHP_VERSION}/$php_version/g" \
        -e "s/\${PROJECT_NAME}/$project_name/g" \
        -e "s/\${LARAVEL_VERSION}/$laravel_version/g" \
        "${dockerfile_template_path}" > "$dockerfile_path"
    
    echo "✓ docker-compose.yml créé dans $dockerfile_path"
}

laravel_create_nginx_config() {
    local template_file="templates/laravel/nginx.template"
    local output_file="$project_path/.docker/nginx.conf"
    
    # Créer le répertoire .docker s'il n'existe pas
    mkdir -p "$project_path/.docker"
    
    # Vérifier que le template existe
    if [[ ! -f "$template_file" ]]; then
        echo "Avertissement: Le template $template_file n'existe pas, nginx.conf non créé"
        return 0
    fi
    
    # Copier le template et remplacer les variables
    sed -e "s/\${PROJECT_NAME}/$project_name/g" \
        "$template_file" > "$output_file"
    
    echo "✓ nginx.conf créé dans $output_file"
}

laravel_create_project() {
    echo "Création des fichiers Docker pour le projet Laravel..."

    # ICI CREER LE PROJET AVEC DOCKER
    
    laravel_create_dockerfile
    laravel_create_docker_compose
    laravel_create_nginx_config
    
    echo "✓ Tous les fichiers Docker ont été créés avec succès"
    echo ""
    echo "Pour démarrer le projet :"
    echo "  cd $project_path"
    echo "  docker compose up -d"
}

# -- MAIN --

# Récupération des infos de laravel/latest
lout "Récupération des infos sur la dernière version de laravel via packagist.org"
if ! laravel_latest_requirements=$(laravel_get_json_latest_info); then
    eout "La récupération des exigeances laravel a échouée. Abandon..."
fi
php_version=$(jq -r '.php_version' <<< $laravel_latest_requirements)
laravel_version=$(jq -r '.laravel_version' <<< $laravel_latest_requirements)
sout "Version trouvées, laravel ${laravel_version} et PHP ${php_version}"

laravel_check_requirments
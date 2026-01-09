# -- CHECKS --

# test
[ -d "${script_dir}" ] || eout "fct/laravel.fct.sh : La variable 'script_dir' doit être initialisée avant l'appel de laravel.fct.sh"
[ -n "${project_path}" ] || eout "fct/laravel.fct.sh : La variable 'project_path' doit être initialisée avant l'appel de laravel.fct.sh"

# -- LARAVEL VARS --

dockerfile_template_path="${script_dir}/templates/laravel/Dockerfile.template"
docker-compose_template_path="${script_dir}/templates/laravel/docker-compose.yml.template"
nginx_template_path="${script_dir}/templates/laravel/nginx.template"
laravel_docker_dir="${project_path}/.docker"

# -- FUNCTIONS --

# Prépare les variables et vérifie les fichiers de configuration
# return null
laravel_check_requirments() {
    [ -f "${dockerfile_template_path}" ] || eout "Template Dockerfile non trouvé. Fichier attendu : ${dockerfile_template_path}"
    [ -f "${compose_template_path}" ] || eout "Template docker-compose non trouvé. Fichier attendu : ${compose_template_path}"
    [ -f "${nginx_template_path}" ] || eout "Template nginx laravel non trouvé. Fichier attendu : ${nginx_template_path}"
    debug_ "Templates trouvés"
}

# En cas de réussite il est certain qu'on retourne une version laravel et php
# return string|bool
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
    local template_file="templates/laravel/Dockerfile.template"
    local output_file="$project_path/.docker/Dockerfile"
    
    # Copier le template et remplacer les variables
    sed -e "s/\${PHP_VERSION}/$php_version/g" \
        -e "s/\${PROJECT_NAME}/$project_name/g" \
        "$template_file" > "$output_file"
    
    echo "✓ Dockerfile créé dans $output_file"
}

laravel_create_docker_compose() {
    local template_file="templates/laravel/docker-compose.yml.template"
    local output_file="$project_path/docker-compose.yml"
    
    # Vérifier que le template existe
    if [[ ! -f "$template_file" ]]; then
        echo "Erreur: Le template $template_file n'existe pas"
        return 1
    fi
    
    # Copier le template et remplacer les variables
    sed -e "s/\${PHP_VERSION}/$php_version/g" \
        -e "s/\${PROJECT_NAME}/$project_name/g" \
        -e "s/\${LARAVEL_VERSION}/$laravel_version/g" \
        "$template_file" > "$output_file"
    
    echo "✓ docker-compose.yml créé dans $output_file"
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
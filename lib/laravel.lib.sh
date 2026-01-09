# -- LARAVEL VARS --

laravel_script_name=$(basename $0)

# templates
dockerfile_template_path="${script_dir}/templates/laravel/Dockerfile.template"
docker_compose_template_path="${script_dir}/templates/laravel/docker-compose.yml.template"
nginx_template_path="${script_dir}/templates/laravel/nginx.template"

# fichiers du projet
project_docker_dir="${project_path}/.docker/development"
project_dockerfile_path="${project_docker_dir}/Dockerfile"
project_docker_compose_path="${project_path}/docker-compose.yml"
project_nginx_path="${project_docker_dir}/nginx.conf"

# variables export pour template
export PHP_VERSION=""
export LARAVEL_VERSION=""
export PROJECT_NAME=${project_name}

# -- FUNCTIONS --

# Prépare les variables et vérifie les fichiers de configuration
# return null
laravel_check_requirments() {
    [ -d "${script_dir}" ] || eout "La variable 'script_dir' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -n "${project_path}" ] || eout "La variable 'project_path' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -n "${project_name}" ] || eout "La variable 'project_name' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -f "${dockerfile_template_path}" ] || eout "Template dockerfile non trouvé dans ${dockerfile_template_path}"
    [ -f "${nginx_template_path}" ] || eout "Template de configuration nginx non trouvé dans ${nginx_template_path}"
    [ -f "${docker_compose_template_path}" ] || eout "Template docker-compose non trouvé dans ${docker_compose_template_path}"
    [ -n "${PHP_VERSION}" ] || eout "La variable 'PHP_VERSION' doit être initialisée"
    [ -n "${LARAVEL_VERSION}" ] || eout "La variable 'LARAVEL_VERSION' doit être initialisée"
}

# En cas de réussite il est certain qu'on retourne une version laravel et php
# return array+true|false
laravel_get_json_latest_info() {
    local packagist_link="https://repo.packagist.org/p2/laravel/laravel.json"
    
    # Récupérer et traduire la réponse JSON
    local json_response=$(curl -s --max-time 10 "${packagist_link}" | jq -r '
        .packages."laravel/laravel"[0] as $p |
        {
            "LARAVEL_VERSION": $p.version_normalized,
            "PHP_VERSION": ($p.require.php // "" | sub("^\\^"; ""))
        }
    ')

    local version_regex='^[0-9]+(\.[0-9]+)*$'
    if [[ "$(jq -r ".LARAVEL_VERSION" <<< "$json_response")" =~ $version_regex ]] && [[ "$(jq -r ".PHP_VERSION" <<< "$json_response")" =~ $version_regex ]]; then
        echo $json_response
        return 0
    else
        fout "Échec de récupération des infos sur la dernière version de laravel"
        return 1
    fi
}

# return bool
laravel_create_dockerfile() {
    # Test, à supprimer en prod, pour créer le fichier dans l'environement de test --------------------
    if $DEBUG_MODE; then
        local project_dockerfile_path="/home/adam/dev/projets/conteur/Dockerfile" && debug_ "ATTENTION DEBUG MODE : Chemin du dockerfile modifié pour $project_dockerfile_path\
        Le dockerfile ne sera pas créé dans le projet, retirer cette contition une fois le debug fini"
    fi
    # -------------------------------------------------------------------------------------------------

    lout "Création du dockerfile (${project_dockerfile_path})"
    if [ -f "${project_dockerfile_path}" ]; then
        wout "Dockerfile détecté dans '${project_dockerfile_path}'"
        ask_yn "Faut-il écraser le Dockerfile existant ?"
    fi

    if envsubst '$PHP_VERSION' < "$dockerfile_template_path" > "$project_dockerfile_path"; then # Ajouter les variables à remplacer, sinon envsubst remplace les variables inconues
        sout "Dockerfile créé dans $project_dockerfile_path"
        return 0
    else
        fout "${laravel_script_name} laravel_create_dockerfile() : envsubst n'a pas pu créer le Dockerfile à partir du template ${dockerfile_template_path}"
        return 1
    fi
    
}

laravel_create_docker_compose() {
    # Test, à supprimer en prod, pour créer le fichier dans l'environement de test --------------------
    if $DEBUG_MODE; then
        local project_docker_compose_path="/home/adam/dev/projets/conteur/docker-compose.yml" && debug_ "ATTENTION DEBUG MODE : Chemin du docker-compose modifié pour $project_docker_compose_path\
        Le docker-compose ne sera pas créé dans le projet, retirer cette contition une fois le debug fini"
    fi
    # -------------------------------------------------------------------------------------------------

    lout "Création du dockerfile (${project_docker_compose_path})"
    if [ -f "${project_docker_compose_path}" ]; then
        wout "docker-compose.yml détecté dans '${project_docker_compose_path}'"
        ask_yn "Faut-il écraser le docker-compose.yml existant ?"
    fi

    if envsubst '$PHP_VERSION $PROJECT_NAME $LARAVEL_VERSION' < "$docker_compose_template_path" > "$project_docker_compose_path"; then # Ajouter les variables à remplacer, sinon envsubst remplace les variables inconues
        sout "docker-compose.yml créé dans $project_docker_compose_path"
        return 0
    else
        fout "${laravel_script_name} laravel_create_docker_compose() : envsubst n'a pas pu créer le docker-compose.yml à partir du template ${docker_compose_template_path}"
        return 1
    fi
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
    
    echo "nginx.conf créé dans $output_file"
}

laravel_create_project() {
    lout "Création des fichiers Docker pour le projet Laravel..."

    # ICI CREER LE PROJET AVEC DOCKER
    
    #laravel_create_dockerfile
    # laravel_create_docker_compose
    # laravel_create_nginx_config
    
    sout "Tous les fichiers Docker ont été créés avec succès"
}

# -- MAIN --

# Récupération des infos de laravel/latest
lout "Récupération des infos sur la dernière version de laravel via packagist.org"
if ! laravel_latest_requirements=$(laravel_get_json_latest_info); then
    eout "La récupération des exigeances laravel a échouée. Abandon..."
fi
PHP_VERSION=$(jq -r '.PHP_VERSION' <<< $laravel_latest_requirements)
LARAVEL_VERSION=$(jq -r '.LARAVEL_VERSION' <<< $laravel_latest_requirements)
sout "Version trouvées, laravel ${LARAVEL_VERSION} et PHP ${PHP_VERSION}"

lout "Vérification du contenu des variables"
laravel_check_requirments


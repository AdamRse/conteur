# -- LARAVEL VARS --

laravel_script_name=$(basename $0)

# templates
dockerfile_template_path="${script_dir}/templates/laravel/default/Dockerfile.template"
docker_compose_template_path="${script_dir}/templates/laravel/default/docker-compose.yml.template"
nginx_template_path="${script_dir}/templates/laravel/default/nginx.conf.template"

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
        local project_dockerfile_path="/home/adam/dev/projets/conteur/Dockerfile" && wout "ATTENTION DEBUG MODE : Chemin du dockerfile modifié pour $project_dockerfile_path\
        \n\tLe dockerfile ne sera pas créé dans le projet, retirer cette contition une fois le debug fini"
    fi
    # -------------------------------------------------------------------------------------------------
    local project_dockerfile_file="Dockerfile"
    local project_dockerfile_path="$(dirname ${project_dockerfile_path})"
    local project_dockerfile_vars="PHP_VERSION"

    debug_ "Appel de copy_file_from_template() :\n\t\t${project_dockerfile_file}\n\t\t${project_dockerfile_path}\n\t\t${project_dockerfile_vars}"
    lout "Création du ${project_dockerfile_file} (${project_dockerfile_path})"

    if copy_file_from_template $project_dockerfile_file $project_dockerfile_path $project_dockerfile_vars; then
        sout "${project_dockerfile_file} créé dans $project_dockerfile_path"
        return 0
    else
        fout "${laravel_script_name}/laravel_create_dockerfile() : Impossible de créer le fichier ${project_dockerfile_file} à partir de son template"
        return 1
    fi
}

laravel_create_docker_compose() {
    # Test, à supprimer en prod, pour créer le fichier dans l'environement de test --------------------
    if $DEBUG_MODE; then
        local project_docker_compose_path="/home/adam/dev/projets/conteur/docker-compose.yml" && wout "ATTENTION DEBUG MODE : Chemin du docker-compose modifié pour $project_docker_compose_path\
        \n\tLe docker-compose ne sera pas créé dans le projet, retirer cette contition une fois le debug fini"
    fi
    # -------------------------------------------------------------------------------------------------
    local project_docker_compose_file="docker-compose.yml"
    local project_docker_compose_path="$(dirname ${project_docker_compose_path})"
    local project_docker_compose_vars="PROJECT_NAME"

    debug_ "Appel de copy_file_from_template() :\n\t\t${project_docker_compose_file}\n\t\t${project_docker_compose_path}\n\t\t${project_docker_compose_vars}"
    lout "Création du ${project_docker_compose_file} (${project_docker_compose_path})"

    if copy_file_from_template $project_docker_compose_file $project_docker_compose_path $project_docker_compose_vars; then
        sout "${project_docker_compose_file} créé dans $project_docker_compose_path"
        return 0
    else
        fout "${laravel_script_name}/laravel_create_docker_compose() : Impossible de créer le fichier ${project_docker_compose_file} à partir de son template"
        return 1
    fi
}

laravel_create_nginx_config() {
    # Test, à supprimer en prod, pour créer le fichier dans l'environement de test --------------------
    if $DEBUG_MODE; then
        local project_nginx_path="/home/adam/dev/projets/conteur/nginx.conf" && wout "ATTENTION DEBUG MODE : Chemin du fichier de configuration nginx modifié pour $project_docker_compose_path\
        \n\tLe fichier de configuration nginx ne sera pas créé dans le projet, retirer cette contition une fois le debug fini"
    fi
    # -------------------------------------------------------------------------------------------------
    local project_nginx_file="nginx.conf"
    local project_nginx_path="$(dirname ${project_nginx_path})"
    local project_nginx_vars="PROJECT_NAME"

    debug_ "Appel de copy_file_from_template() :\n\t\t${project_nginx_file}\n\t\t${project_nginx_path}\n\t\t${project_nginx_vars}"
    lout "Création du fichier de config nginx (${project_nginx_path})"

    if copy_file_from_template $project_nginx_file $project_nginx_path $project_nginx_vars; then
        sout "Fichier de configuration nginx créé dans $project_nginx_path"
        return 0
    else
        fout "${laravel_script_name}/laravel_create_docker_compose() : Impossible de créer le fichier ${project_nginx_path} à partir de son template"
        return 1
    fi
}

# FONCTION create_project() OBLIGATOIRE DANS TOUTES LES LIBS (POLYMORPHISME), LE SCRIPT PRINCIPAL APPELLE CETTE FONCTION
# SANS RETOURNER DE TRUE/FALSE
create_project() {
    lout "Création des fichiers Docker pour le projet Laravel..."

    # ICI CREER LE PROJET AVEC DOCKER !!!
    
    laravel_create_dockerfile
    laravel_create_docker_compose
    laravel_create_nginx_config
    
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


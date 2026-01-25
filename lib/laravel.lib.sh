# -- GLOBALS AVAILABLES --
# Variables globales utilisables dans le json de configuration config/custom.json et config/default.json
# ${LARAVEL_VERSION} : Dernière version stable de Laravel
# ${PHP_VERSION} : Version de PHP associée à la dernière version stable de laravel

# -- LARAVEL VARS --

laravel_script_name=$(basename $0)
docker_cmd_path="${MAIN_SCRIPT_DIR}/templates/laravel/cmd.docker.sh"

# variables export pour template
export PHP_VERSION=""
export LARAVEL_VERSION=""
export PROJECT_NAME

# -- FUNCTIONS --

# Prépare les variables et vérifie les fichiers de configuration
# return null
laravel_check_requirments() {
    [ -d "${MAIN_SCRIPT_DIR}" ] || eout "La variable 'MAIN_SCRIPT_DIR' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -n "${PROJECT_PATH}" ] || eout "La variable 'PROJECT_PATH' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -n "${PROJECT_NAME}" ] || eout "La variable 'PROJECT_NAME' doit être initialisée avant l'appel de ${laravel_script_name}"
    [ -n "${PHP_VERSION}" ] || eout "La variable 'PHP_VERSION' doit être initialisée."
    [ -n "${LARAVEL_VERSION}" ] || eout "La variable 'LARAVEL_VERSION' doit être initialisée."
    [ -n "${LARAVEL_VERSION}" ] || eout "La variable 'LARAVEL_VERSION' doit être initialisée."
    [ -n "${JSON_CONFIG}" ] || eout "La variable 'JSON_CONFIG' doit être initialisée (Usiliser la function export_json_config)."
    check_json_config_integrity || eout "La variable 'JSON_CONFIG' n'est pas conforme."
}

# return empty|exit
check_project_path(){
    if [ -d "${PROJECT_PATH}" ]; then
        eout "Le répertoire ${PROJECT_PATH} existe déjà. Supprimez-le, ou changez le nom du projet avant de relancer le script."
    fi
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

use_sail(){
    echo "$(parse_jq_bool ".projects.laravel.settings.sail.useSail" <<< "${JSON_CONFIG}")"
}

laravel_create_sail_project(){
    local devcontainer="$(parse_jq_bool ".projects.laravel.settings.sail.devcontainer" <<< "${JSON_CONFIG}")"
    local services_array="$(laravel_sail_get_services_in_array)"
    local url_sail_bash_execute="https://laravel.build/${PROJECT_NAME}"
    local services_url=""
    local services_text=""
    debug_ "laravel_create_sail_project() : calcul des variables :
        \$devcontainer=$devcontainer
        \$services_array=$services_array
        \$url_sail_bash_execute=$url_sail_bash_execute"

    if [ -z "${services_array}" ]; then
        if ! ask_yn "Attention ! Aucun service n'a été sélectionné pour le projet laravel, mais Laravel Sail fournit des services par défaut si aucun n'est sélectionné. Ajouter un moin 1 service dans 'config/custom.json' pour ne pas avoir les services par défaut de Laravel Sail. Continuer avec les service par défaut de Laravel Sail ?"; then
            lout "Arrêt demmandé par l'utilisateur."
            exit 0
        fi
    fi

    for service in $services_array; do
        if [ -n "${service}" ]; then
            if [ -z "${services_url}" ]; then
                services_url="?with=${service}"
                services_text="${service}"
            else
                services_url="${services_url},${service}"
                services_text="${services_text}, ${service}"
            fi
        fi
    done

    [ -n "${services_url}" ] && url_sail_bash_execute="${url_sail_bash_execute}${services_url}"

    if [ $devcontainer = true ]; then
        debug_ "ajouter l'option dev container"
        if [ -n "${services_url}" ]; then
            url_sail_bash_execute="${url_sail_bash_execute}&devcontainer"
        else
            url_sail_bash_execute="${url_sail_bash_execute}?devcontainer"
        fi
    elif [ $devcontainer = false ]; then
        debug_ "Option devcontainer non ajoutée"
    else
        wout "Option devcontainer ambigue, JSON de configuration : '.projects.laravel.settings.sail.devcontainer' doit être un booléen."
    fi

    cd "${PROJECTS_DIR}" || eout "Impossible d'atteindre '${PROJECTS_DIR}', vérifiez les privilèges."

    lout "Execution de la requête : ${url_sail_bash_execute}\n\tRépertoire des projets : '${PROJECT_PATH}'"
    curl -s "${url_sail_bash_execute}" | bash
    if [ $? -eq 0 ]; then
        sout "Le projet ${PROJECT_NAME} a bien été créé avec laravel sail !\n\tServices installés :\n\t${services_text:-"Aucun"}"
    else
        eout "L'execution du script bash de laravel sail renvoie une erreur."
    fi
}

laravel_sail_get_services_in_array() {
    local service_name service_val is_enabled
    local enabled_services=""

    while read -r service_name service_val; do
        is_enabled=$(return_unified_json_bool <<< "$service_val")

        if [ "${is_enabled}" = true ]; then
            enabled_services="$enabled_services $service_name"
        fi
    done < <(jq -r '.projects.laravel.settings.sail.services | to_entries | .[] | "\(.key) \(.value)"' <<< "$JSON_CONFIG")

    echo $enabled_services
}

# FONCTION create_project() OBLIGATOIRE DANS TOUTES LES LIBS (POLYMORPHISME), LE SCRIPT PRINCIPAL APPELLE CETTE FONCTION
# return empty|exit
create_project() {
    debug_ "create_project() Création du projet Laravel :\n\tLaravel : ${LARAVEL_VERSION}\n\tPHP : ${PHP_VERSION}\n\tRépertoire : ${PROJECTS_DIR}\n\tNom du projet : ${PROJECT_NAME}"
    [ -z "${LARAVEL_VERSION}" ] && eout "create_project() : La variable 'LARAVEL_VERSION' doit être initialisée."
    [ -z "${PHP_VERSION}" ] && eout "create_project() : La variable 'PHP_VERSION' doit être initialisée."
    [ -z "${PROJECTS_DIR}" ] && eout "create_project() : La variable 'PROJECTS_DIR' doit être initialisée."
    [ -z "${PROJECT_NAME}" ] && eout "create_project() : La variable 'PROJECT_NAME' doit être initialisée."
    [ -z "${PROJECT_PATH}" ] && eout "create_project() : La variable 'PROJECT_PATH' doit être initialisée."

    local use_sail=$(use_sail)
    lout "Création des fichiers Docker pour le projet Laravel..."

    check_project_path
    if [ $use_sail = true ]; then
        lout "Nouveau projet Laravel : Utilisation de laravel Sail"
        laravel_create_sail_project
    elif [ $use_sail = false ]; then
        lout "Nouveau projet Laravel : Utilisation des templates personnalisés"
        [ -f "${docker_cmd_path}" ] || eout "Commande docker non trouvée dans '${docker_cmd_path}'"
        # Piège de l'erreur dans le script utilisateur 'docker_cmd_path'
        local user_script_fail=0
        set -E
        set -e
        trap 'user_script_fail=1' ERR.
        source "${docker_cmd_path}" || user_script_fail=1
        trap - ERR
        set +e
        set +E
        if [ "$user_script_fail" -eq 0 ]; then
            sout "Projet Laravel avec la commande docker créé avec succès."
        else
            eout "La commande docker dans le fichier '${docker_cmd_path}' a échoué."
        fi
        # --
        copy_files_from_template
        sout "Tous les fichiers Docker ont été créés avec succès"
    else
        eout "Variable ambigue useSail dans le JSON de configuration. Doit être un booléen"
    fi
}
    

# -- MAIN --

# Récupération des infos de laravel/latest
lout "Récupération des infos sur la dernière version de laravel via packagist.org"

if [ "${DEBUG_MODE}" = true ]; then
    wout "DEBUG MODE ACTIVÉ, PHP_VERSION ET LARAVEL_VERSION ONT DES VALEURS FACTICES DANS laravel.lib.sh"
    sleep 1
    PHP_VERSION="8.4"
    LARAVEL_VERSION="12.1.1.0"
else
    if ! laravel_latest_requirements=$(laravel_get_json_latest_info); then
        eout "La récupération des exigeances laravel a échouée. Abandon..."
    fi
    PHP_VERSION="$(jq -r '.PHP_VERSION' <<< "${laravel_latest_requirements}")"
    LARAVEL_VERSION="$(jq -r '.LARAVEL_VERSION' <<< "${laravel_latest_requirements}")"
fi
sout "Version trouvées, laravel ${LARAVEL_VERSION} et PHP ${PHP_VERSION}"

lout "Laravel : Vérification du contenu des variables"
laravel_check_requirments


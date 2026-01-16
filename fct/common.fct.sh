# return null|string
check_packages_requirements() {
    if ! command -v docker &> /dev/null; then
        eout "Docker n'est pas installé"
    fi
    if ! command -v curl &> /dev/null; then
        eout "curl n'est pas installé"
    fi
    if ! command -v jq &> /dev/null; then
        eout "jq n'est pas installé. Installez-le avec: sudo apt install jq"
    fi
    if ! command -v envsubst >/dev/null 2>&1; then
        eout "envsubst n'est pas disponible. Installez-le avec : sudo apt install gettext-base"
    fi
}

# return null
set_directory() {
    if [ -n "$PJ" ]; then
        debug_ "Dev architecture détectée"
        if [ ! -d "${PJ}" ]; then
            wout "Le répertoire ${PJ} n'existe pas"
        fi
        project_dir="$PJ"
    fi
}

# return bool
check_project_type() {
    [ -z "$1" ] && eout "check_project_type() : Aucun nom de projet passé."

    local $project_name_check = $1

    [ -d "${script_dir}/templates/${project_name_check}" ] || eout "Type de projet ${project_name_check} inconnu. Aucun template associé pour ce type de projet."
    [ -f "${script_dir}/lib/${project_name_check}.lib.sh" ] || eout "Type de projet ${project_name_check} inconnu. Aucune bibliothèque associé pour ce type de projet."
}

# return bool
is_json_var(){
    local json_test="${1}"
    [ -z "${json_test}" ] && eout "is_json_var() : Aucun paramètre passé"

    if ! jq -e . <<< "$json_test" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Utilisable avec un pipe
# return "bool"|empty
parse_jq_bool() {
    local filter="$1"
    local data="${2:-$(cat)}"

    echo "$data" | jq -r "$filter | 
        if . == true or . == \"true\" or . == 1 or . == \"1\" then true
        elif . == false or . == \"false\" or . == 0 or . == \"0\" then false
        else empty
        end"
}

# $1 : json_test : Chaîne de config JSON à tester
# return true|exit
check_json_config_integrity(){
    local json_test="${1:-$JSON_CONFIG}"
    lout "Check de l'intégrité du fichier de configuration JSON"
    [ -z "${json_test}" ] && eout "check_json_config_integrity() : Aucun paramètre passé"


    debug_ "Vérification du type de variable JSON"
    is_json_var "${json_test}" || eout "check_json_config_integrity() : La variable passée n'est pas un JSON valide."

    debug_ "Vérification du contenu logique"
    local has_project=$(jq ".project_type.${project_type}" <<< "$json_test")
    if [ "$has_project" == "null" ]; then
        eout "check_json_config_integrity() : Le type de projet '${project_type}' est absent du JSON."
    fi

    debug_ "Vérification de laravel Sail"
    local is_sail=$(parse_jq_bool ".project_type.${project_type}.settings.sail.useSail" <<< "$json_test")
    if [ "${is_sail}" = false ]; then
        debug_ "Vérification des templates"
        local selected_count=$(jq "[.project_type.${project_type}.templates[] | select(.selected | tostring | . == \"true\" or . == \"1\")] | length" <<< "$json_test")
        if [ "$selected_count" -eq 0 ]; then
            eout "check_json_config_integrity() : Aucun template n'est sélectionné (selected: true) pour ${project_type}. Séléctionner au moins un template si Laravel Sail n'est pas utilisé"
        fi
    fi
    debug_ "Fichier de configuration JSON conforme."
    return 0
}

# return JSON|exit
merge_config_json(){
    local default_path="${script_dir}/config/default.json"
    local custom_path="${script_dir}/config/custom.json"

    [ -d "${script_dir}" ] || eout "merge_config_json() : la variable \$script_dir n'est pas initialisée"
    [ -f "${default_path}" ] || eout "merge_config_json() : Fichier de configuration json requis dans ${default_path}"

    local default_json=$(cat "${default_path}")

    if [ -f "${custom_path}" ]; then
        local custom_json=$(cat "${custom_path}")

        if [ -n "${custom_json}" ] && is_json_var "${custom_json}"; then
            local merged_json="$(jq -s 'reduce .[] as $item ({}; . * $item)' "${default_path}" "${custom_path}")"
            echo "${merged_json}"
            return 0
        fi
    fi
    echo "${default_json}"
    return 0
}

# return void|exit
export_json_config(){
    JSON_CONFIG=$(merge_config_json)
    debug_ "Vérification de l'intégrité du JSON obetnu par merge_config_json()"
    check_json_config_integrity "${JSON_CONFIG}"
    export JSON_CONFIG
}

# $1 : mode     : relative|absolute
# $2 : path     : 
# return string : path nettoyé
clean_path_variable(){
    local mode="${1}"
    local path="${2}"
    if [ -n "${path}" ]; then
        local relative="relative"
        local absolute="absolute"
        path=$(echo "$path" | tr -s '/')
        if [ "${mode}" = "${relative}" ]; then
            path="${path#/}"
            path="${path%/}"
        elif [ "${mode}" = "${absolute}" ]; then
            path="/${path#/}"
            path="${path%/}"
        else
            eout "clean_path_variable() : Erreur, mode non conforme passé en 1er paramètre. Attendu : '${relative}' ou '${absolute}'"
        fi
    fi
    echo "$path"
}

# $1(Optionnel) : json_config  : json de configuration, apr défaut prend une variable exportée
copy_files_from_template() {
    local json_config=${1:-$JSON_CONFIG}
    [ -z "${json_config}" ] && eout "copy_files_from_template() : Le JSON de configuration n'a pas été trouvé."
    [ -z "${project_dir}" ] && eout "copy_files_from_template() : La variable '\$project_dir' doit être initialisée avant."
    [ -d "${project_dir}" ] || eout "copy_files_from_template() : Le projet n'a pas été créé, créer le projet avant de faire appel à cette fonction."
    check_json_config_integrity "${json_config}"
    debug_ "Projet dans ${project_dir}"

    local project_docker_dir_relative=$(jq -r ".project_type.${project_type}.settings.project_docker_files_dir" <<< "$json_config")
    local project_docker_dir="$(clean_path_variable "absolute" "${project_dir}/${project_docker_dir_relative}")"

    echo "project docker dir : $project_docker_dir"
}
copy_file() {
    echo "a venir"
}
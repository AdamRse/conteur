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

# $1 : json_test : Chaîne JSON à tester
# return true|exit
check_json_config_integrity(){
    local json_test="${1}"
    [ -z "${json_test}" ] && eout "check_json_config_integrity() : Aucun paramètre passé"

    is_json_var "${json_test}" || eout "check_json_config_integrity() : La variable passée n'est pas un JSON valide."

    local has_project=$(jq ".${project_type}" <<< "$json_test")
    if [ "$has_project" == "null" ]; then
        eout "check_json_config_integrity() : Le type de projet '${project_type}' est absent du JSON."
    fi

    local local selected_count=$(jq "[.${project_type}.templates[] | select(.selected | tostring | . == \"true\" or . == \"1\")] | length" <<< "$json_test")

    if [ "$selected_count" -eq 0 ]; then
        eout "check_json_config_integrity() : Aucun template n'est sélectionné (selected: true) pour ${project_type}."
    fi

    return 0
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

# return JSON|exit
merge_config_json(){
    local default_path="${script_dir}/config/default.json"
    local custom_path="${script_dir}/config/custom.json"

    [ -d "${script_dir}" ] || eout "merge_config_json() : la variable \$script_dir n'est pas initialisée"
    [ -f "${default_path}" ] || eout "merge_config_json() : Fichier de configuration json requis dans ${default_path}"

    local default_json=$(cat "${default_path}")
    check_json_config_integrity "${default_json}"

    if [ -f "${custom_path}" ]; then
        local custom_json=$(cat "${custom_path}")

        if [ -n "${custom_json}" ] && is_json_var "${custom_json}"; then
            local merged_json="$(jq -s 'reduce .[] as $item ({}; . * $item)' "${default_path}" "${custom_path}")"

            if check_json_config_integrity "${merged_json}"; then
                echo "${merged_json}"
                return 0
            fi
        fi
    fi
    echo "${default_json}"
    return 0
}

get_templates_from_config(){
    echo "A venir"
}

# Note : Ne vérifie pas si les variables passées sont bien dans le template
# $1 : <name>             : obligatoire : Nom exact du fichier à copier. La fonction ira chercher dans ./templates/$project_type/$nom.template
# $2 : <output directory> : obligatoire : Répertoire absolu dans lequel copier le fichier (le nom est déduit de $1)
# $3 : [variables name]   : optionnel   : Tableau (séparateur Espace) avec le nom des variables exclusives (sans le $) à remplacer dans le template. Sinon les variables trouvées sont remplacées par une chaîne vide dans le template.
# return bool
copy_file_from_template() {
    echo "A venir"
}
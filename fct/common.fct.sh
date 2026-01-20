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

parse_arguments() {
    # On définit les options courtes (lP:) et longues (laravel,path:)
    # Le ":" après une lettre signifie qu'un argument est attendu.
    local PARSED_OPTIONS
    PARSED_OPTIONS=$(getopt -o lP: --long laravel,path: -n "$0" -- "$@")
    
    # On vérifie si getopt a rencontré une erreur
    if [ $? -ne 0 ]; then
        eout "L'interpreteur de commande n'a pas fonctionné"
    fi

    # Réorganisation des arguments pour le parsing
    eval set -- "$PARSED_OPTIONS"

    while true; do
        case "$1" in
            -l|--laravel)
                PROJECT_TYPE="laravel"
                shift
                ;;
            -P|--path)
                PROJECTS_DIR="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Erreur interne de parsing"
                exit 1
                ;;
        esac
    done

    # Gestion de l'argument obligatoire (PROJECT_NAME) qui reste après les options
    if [ -n "$1" ]; then
        PROJECT_NAME="$1"
    fi

    # --- Validation des paramètres obligatoires ---
    if [ -z "$PROJECT_TYPE" ]; then
        eout "Erreur : L'option -l ou --laravel est obligatoire."
    fi

    if [ -z "$PROJECT_NAME" ]; then
        fout "Erreur : Le nom du projet est obligatoire."
        eout "Usage: $0 --laravel [options] 'nom_du_projet'"
    fi

    PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"
}

# Utilisable avec pipe
# $1 : dir  : chemin absolu du répertoire
# return bool
is_empty_dir(){
    local dir="${1-$(cat)}"
    [ -z "${dir}" ] && eout "is_empty_dir() : Aucun paramètre donné. Passer le chemin absolu d'un répertoire à tester en paramètre."
    [ -d "${dir}" ] || return 0

    if [ -z "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        return 0
    else
        return 1
    fi
}

# return empty|exit
check_globals(){
    debug_ "check_globals() :
        PROJECTS_DIR=$PROJECTS_DIR
        PROJECT_NAME=$PROJECT_NAME
        PROJECT_PATH=$PROJECT_PATH
        PROJECT_TYPE=$PROJECT_TYPE"

    [ -z "${PROJECT_NAME}" ] && eout "Aucun nom de projet donné. Spécifiez un nom de projet à l'appel du programme."
    [ -z "${PROJECT_TYPE}" ] && eout "Aucun type de projet donné. Spécifiez un type de projet à l'appel du programme (pax ex -l ou --laravel)."
    # PROJECT_NAME
    local name_pattern='^[a-zA-Z0-9._-]{2,}$'
    if [[ ! "$PROJECT_NAME" =~ $pattern ]]; then
        eout "Le nom de projet n'est pas valide. Il doit faire au moins 2 caractères et ne contenir que des lettres, chiffres, '.', '_' ou '-'."
    fi

    # PROJECTS_DIR
    if [ -z "${PROJECTS_DIR}" ]; then
        local projects_dir_from_json="$(jq -r ".settings.default_projects_dir" <<< "${JSON_CONFIG}")"
        if [ -z "${projects_dir_from_json}" ]; then
            PROJECTS_DIR="${PWD}"
        elif [ "${projects_dir_from_json}" = "/" ] || [ "${projects_dir_from_json}" = "./" ]; then
            wout "Le chemin '${projects_dir_from_json}' défini dans je JSON de configuration à : '.settings.default_projects_dir' est invalide."
            if ask_yn "Créer le projet dans ce répertoire (${PWD}) à la place ?"; then
                PROJECTS_DIR="${PWD}"
            else
                lout "Abandon par l'utilisateur, configurez le répertoire des projets avec l'un de ces choix :\n\t- L'option du programme -P <répertoire>\n\t- La variable '.settings.default_projects_dir' dans 'config/custom.json'\n\t- En executant ce programme dans le répertoire ciblé."
                exit 1
            fi
        else
            PROJECTS_DIR="$(clean_path_variable "absolute" "${projects_dir_from_json}")"
        fi
    else
        if [[ ! "$PROJECTS_DIR" == /* ]]; then
            PROJECTS_DIR="$(clean_path_variable "absolute" "${PWD}/${PROJECTS_DIR}")"
        fi
    fi # PROJECTS_DIR est maintenant forcément un chemin absolu
    if [ ! -d "${PROJECTS_DIR}" ]; then
        wout "Répertoire '${PROJECTS_DIR}' introuvable, ou permission refusée."
        if ask_yn "ATTENTION : Le répertoire donné dans lequel créer le projet '${PROJECT_NAME}' n'existe pas, il s'agit peut être d'une erreur de frappe. Faut-il malgré tout créer le répertoire de projet '${PROJECTS_DIR}' ?"; then
            mkdir -p "${PROJECTS_DIR}" || eout "Impossible de créer le répertoire des projets, permission refusée."
        fi
    fi

    PROJECT_PATH="$(clean_path_variable "absolute" "${PROJECTS_DIR}/${PROJECT_NAME}")"
    if [ ! -d "$(dirname "${PROJECT_PATH}")" ]; then
        eout "Le répertoire parent de ${PROJECT_PATH} n'existe pas, PROJECT_PATH est donc mal construit à cause de clean_path_variable(). L'erreur n'est corrigeable que dans le code du programme."
    fi

    # PROJECT_TYPE
    [ -d "${MAIN_SCRIPT_DIR}/templates/${PROJECT_TYPE}" ] || eout "Type de projet ${PROJECT_TYPE} inconnu. Aucun template associé pour ce type de projet. Les templates prévu ont été supprimés, ou le code du programme a été modifié."
    [ -f "${MAIN_SCRIPT_DIR}/lib/${PROJECT_TYPE}.lib.sh" ] || eout "Type de projet ${PROJECT_TYPE} inconnu. Aucune bibliothèque associé pour ce type de projet. La bibliothèque associée a été supprimée, ou le code du programme a été modifié."
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
# $1 : filter   : pattern jq pour cibler le booléen à tester
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

# Donne un "true" ou "false" en checkant les multiples syntaxes possibles. A utiliser pour unifier la valeur d'un booléen dans un json
# Utilisable avec un pipe
# return "bool"|empty
return_unified_json_bool(){
    local boolean="$(cat)"
    if [ "$boolean" = "true" ] || [ "$boolean" = "1" ] || [ "$boolean" = "\"true\"" ] || [ "$boolean" = "\"1\"" ]; then
        echo "true"
    elif [ "$boolean" = "false" ] || [ "$boolean" = "0" ] || [ "$boolean" = "\"false\"" ] || [ "$boolean" = "\"0\"" ]; then
        echo "false"
    else
        echo ""
    fi
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
    local has_project=$(jq ".PROJECT_TYPE.${PROJECT_TYPE}" <<< "$json_test")
    if [ "$has_project" == "null" ]; then
        eout "check_json_config_integrity() : Le type de projet '${PROJECT_TYPE}' est absent du JSON."
    fi

    debug_ "Vérification de laravel Sail"
    local is_sail=$(parse_jq_bool ".PROJECT_TYPE.${PROJECT_TYPE}.settings.sail.useSail" <<< "$json_test")
    if [ "${is_sail}" = false ]; then
        debug_ "Vérification des templates"
        local selected_count=$(jq "[.PROJECT_TYPE.${PROJECT_TYPE}.templates[] | select(.selected | tostring | . == \"true\" or . == \"1\")] | length" <<< "$json_test")
        if [ "$selected_count" -eq 0 ]; then
            eout "check_json_config_integrity() : Aucun template n'est sélectionné (selected: true) pour ${PROJECT_TYPE}. Séléctionner au moins un template si Laravel Sail n'est pas utilisé"
        fi
    fi
    debug_ "Fichier de configuration JSON conforme."
    return 0
}

# return JSON|exit
merge_config_json(){
    local default_path="${MAIN_SCRIPT_DIR}/config/default.json"
    local custom_path="${MAIN_SCRIPT_DIR}/config/custom.json"

    [ -d "${MAIN_SCRIPT_DIR}" ] || eout "merge_config_json() : la variable \$MAIN_SCRIPT_DIR n'est pas initialisée"
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
    [ -z "${json_config}" ] && eout "copy_files_from_template() : Le JSON de configuration n'a pas été trouvé. Utiliser export_json_config() pour rendre la config globale ou passez là en paramètre."
    [ -z "${PROJECTS_DIR}" ] && eout "copy_files_from_template() : La variable '\$PROJECTS_DIR' doit être initialisée avant."
    [ -d "${PROJECTS_DIR}" ] || eout "copy_files_from_template() : Le projet n'a pas été créé, créer le projet avant de faire appel à cette fonction."
    check_json_config_integrity "${json_config}"
    debug_ "Projet dans ${PROJECTS_DIR}"

    local project_docker_dir_relative=$(jq -r ".PROJECT_TYPE.${PROJECT_TYPE}.settings.project_docker_files_dir" <<< "$json_config")
    local project_docker_dir="$(clean_path_variable "absolute" "${PROJECTS_DIR}/${project_docker_dir_relative}")"
    debug_ "copy_files_from_template() : Vérification des calculs de variables.
        \$project_docker_dir_relative=${project_docker_dir_relative}
        \$project_docker_dir=${project_docker_dir}"

    if [ ! -d "${project_docker_dir}" ]; then
        mkdir -p "${project_docker_dir}" || eout "copy_files_from_template() : droits insufisants pour créer le répertoire de templates '${project_docker_dir}'"
    fi

    jq -r --arg type "${PROJECT_TYPE}" '.PROJECT_TYPE[$type].templates | to_entries[] | "\(.key) \(.value | @json)"' <<< "${json_config}" | while read -r name configuration; do
        debug_ "Boucle de copie, appel de copy_file()"
        copy_file "${name}" "${configuration}" "${project_docker_dir}"
    done
}

# $1                : name                      : Nom du fichier à copier
# $2                : config                    : JSON config attaché au template. Par exemple : .PROJECT_TYPE.laravel.templates.<fichier>[]
# $3 (optionnel)    : project_docker_files_dir  : Répertoire dans le projet où ranger les fichiers par défaut. Indiqué dans JSON de config : PROJECT_TYPE.laravel.settings.project_docker_files_dir
# return message+true|message+false
copy_file() {
    local name="${1}"
    local config="${2}"
    local project_docker_files_dir="${3}"

    [ -z "${name}" ] && fout "copy_file() : Aucun nom de template passé." && return 1
    [ -z "${config}" ] && fout "copy_file() : Aucune configuration passée pour la copie du template ${name}." && return 1
    [ ! -d "${PROJECT_PATH}" ] && fout "copy_file() : Le répertoire de projet n'existe pas encore dans '${PROJECT_PATH}'." && return 1
    ! is_json_var "${config}" && fout "copy_file() : Le json de configuration n'est pas conforme :\n${config}" && return 1

    
    debug "copy_file() Résumée des paramètres reçu :
        \$name=${name}
        \$config=${config}
        \$project_docker_files_dir=${project_docker_files_dir}"

    # On peut ensuite extraire des données spécifiques de la configuration du template
    local selected=$(jq -r '.selected' <<< "${config}")
    if [ "${selected}" = true ]; then
        debug_ "Lancement de la copie"
        local custom_path="$(jq -r ".PROJECTS_DIR" <<< "${config}")"
        local template_path
        if ! template_path="$(find_template_from_name "${name}")"; then
            fout "copy_file() : Template de ${name} non trouvé."
            return 1
        fi
        local variables_list_json="$(jq ".variables" <<< "${config}")"
        local project_file_path="$(get_project_file_path "${name}" "${project_docker_files_dir}" "${custom_path}")"
        export_vars_list "${variables_list_json}" # Rend EXPORTED_VARS accessible, l'export ne fonctionne pas dans un sous-shell avec $() pour récupérer les variables exportées
        debug_ "Résumée du calcul de variables pour la copie :
            \$custom_path=${custom_path}
            \$template_path=${template_path}
            \$project_file_path=${project_file_path}
            \$EXPORTED_VARS=${EXPORTED_VARS}"

        if [ ${#EXPORTED_VARS[@]} -eq 0 ]; then
            if cp "${template_path}" "${project_file_path}"; then
                sout "copie sans variables de ${template_path} -> ${project_file_path} effectuée"
                return 0
            fi
            fout "La copie sans variables de\n\t\t'${template_path}'\n\t\tvers\n\t\t'${project_file_path}'\n\t\ta échouée. Vérifier les droits d'accès."
            return 1
        else
            if envsubst "${EXPORTED_VARS}" < "${template_path}" > "${project_file_path}"; then
                sout "copie sans variables de ${template_path} -> ${project_file_path} effectuée"
                return 0
            fi
            fout "La copie en mode dynamique (variables '${exported_vars_list}') de\n\t\t'${template_path}'\n\t\tvers\n\t\t'${project_file_path}'\n\t\ta échouée."
            return 1
        fi
    else
        lout "Le template ${name} est ignoré (json config : selected:false)"
        return 0
    fi
}

# $1 : json_var_list    : Tableau json contenant les variables à exporter dans config/default.json : PROJECT_TYPE.<PROJECT_TYPE>.templates.<fichier>.variables[]
# return string+true|error+false
export_vars_list(){
    local json_var_list="${1}"
    local exported_vars_array=()
    export EXPORTED_VARS

    debug_ "export_vars_list() appelé, avec les paramètres :\n\
        \$json_var_list=${json_var_list}"

    [ -z "${json_var_list}" ] && eout "export_vars_list() : Aucune variable envoyée en premier paramètre" && return 1
    ! is_json_var "${json_var_list}" && eout "export_vars_list() : La variable envoyé en premier paramètre n'est pas un JSON" && return 1

    debug_ "lecture du JSON"
    while IFS="=" read -r key value; do
        local interpreted_value
        interpreted_value=$(eval "echo \"$value\"")
        debug_ "Valeur trouvée : ${interpreted_value}"

        if [[ -n "$interpreted_value" ]]; then
            debug_ "Export de ${key}:${interpreted_value}"
            export "$key"="$interpreted_value"
            exported_vars_array+=("\$${key}")
        fi
    done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' <<< "$json_var_list")
    EXPORTED_VARS="${exported_vars_array[*]}"
    debug_ "Variables exportées : ${EXPORTED_VARS}"
}

# $1 : file_name                            : Le nom du fichier à copier
# $2 : project_docker_files_dir             : Répertoire par défaut des fichiers docker dans le projet (variable config/default.json du même nom)
# $3 : project_file_custom_dir (optionnel)  : Le répertoire personnalisé du fichier dans le répertoire de projet  (variable "PROJECTS_DIR" config/default.json)
# return result+true|false
get_project_file_path(){
    local file_name="${1}"
    local project_docker_files_dir="${2}"
    local project_file_custom_dir="${3}"
    local l_projects_dir="${PROJECTS_DIR}"
    [ -z "${file_name}" ] && eout "get_project_file_path() : Aucun nom passé en premier paramètre"
    [ -z "${l_projects_dir}" ] && eout "get_project_file_path() : La variable globale '\$PROJECTS_DIR' doit être initialisée"
    [ -d "${l_projects_dir}" ] || eout "get_project_file_path() : Le répertoire du projet doit être créé"

    local file_location=""
    if [ -n "${project_file_custom_dir}" ]; then
        if [ "${project_file_custom_dir}" = "." ] || [ "${project_file_custom_dir}" = "./" ] || [ "${project_file_custom_dir}" = "/" ]; then
            file_location="${l_projects_dir}/${file_name}"
        else
            file_location="${l_projects_dir}/${project_file_custom_dir}/${file_name}"
        fi
    else
        file_location="${l_projects_dir}/${project_docker_files_dir}/${file_name}"
    fi

    echo "$(clean_path_variable "absolute" "${file_location}")"
}

# $1 : name     : Le nom du fichier pour lequel trouver le template associé
# return result+true|wout+false
find_template_from_name() {
    local name="${1}"
    local default_templates_dir="${MAIN_SCRIPT_DIR}/templates/${PROJECT_TYPE}/default"
    local custom_templates_dir="${MAIN_SCRIPT_DIR}/templates/${PROJECT_TYPE}/custom"
    [ -z "${name}" ] && eout "find_template_from_name() : Aucun nom passé en premier paramètre"
    [ -z "${MAIN_SCRIPT_DIR}" ] && eout "find_template_from_name() : La variable globale '\$MAIN_SCRIPT_DIR' doit être initialisé"
    [ -z "${PROJECT_TYPE}" ] && eout "find_template_from_name() : La variable globale '\$PROJECT_TYPE' doit être initialisé"
    [ -d "${default_templates_dir}" ] || eout "find_template_from_name() : Le répertoire de templates par défaut est introuvable dans : '${default_templates_dir}'"
    
    local template_path_possibility_by_priorities=(
        "${custom_templates_dir}/${name}.template"
        "${custom_templates_dir}/${name}"
        "${default_templates_dir}/${name}.template"
    )

    local template_path_found=""
    for template_path in "${template_path_possibility_by_priorities[@]}"; do
        if [ -f "${template_path}" ]; then
            template_path_found="${template_path}"
            break
        fi
    done

    if [ -n "${template_path_found}" ]; then
        echo "${template_path_found}"
        return 0
    else
        wout "find_template_from_name() : Aucun template trouvé pour '${name}'"
        return 1
    fi
}

show_summary() {
    local BOLD='\033[1m'
    local COLOR_2='\033[0;32m'
    local COLOR_3='\033[1;33m'
    local NC='\033[0m'
    
    # --- PARAMÈTRES DE TAILLE ---
    local width=70
    local label_width=25
    # ----------------------------
    
    print_table_row() {
        local label=$1
        local value=$2
        
        # Construction de la partie gauche fixe
        local left_part=$(printf "  %-*s : " "$label_width" "$label")
        
        # Calcul du remplissage dynamique pour la bordure droite
        local used_space=$((${#left_part} + ${#value}))
        local padding=$((width - used_space))
        
        # Sécurité si la valeur est trop longue
        [[ $padding -lt 0 ]] && padding=0

        printf "${COLOR_2}│${NC}%s${COLOR_2}%s%*s│${NC}\n" "$left_part" "$value" "$padding" ""
    }

    # Bordure haute
    echo -e "${COLOR_2}┌$(printf '─%.0s' $(seq 1 $width))┐${NC}"
    
    # Titre centré dynamiquement
    local title="RÉSUMÉ DE LA CONFIGURATION"
    local title_len=${#title}
    local title_space=$(( (width - title_len) / 2 ))
    local title_res=$(( (width - title_len) % 2 )) # Pour gérer les nombres impairs
    printf "${COLOR_2}│${NC}%*s${BOLD}${COLOR_3}%s${NC}%*s${COLOR_2}│${NC}\n" "$title_space" "" "$title" "$((title_space + title_res))" ""
    
    echo -e "${COLOR_2}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"
    
    # Lignes du tableau
    print_table_row "Nom du projet" "$PROJECT_NAME"
    print_table_row "Type d'application" "$PROJECT_TYPE"
    print_table_row "Répertoire racine" "$PROJECTS_DIR"

    echo -e "${COLOR_2}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"
    
    # Chemin complet
    echo -e "${COLOR_2}│${NC}  ${BOLD}Chemin complet :${NC}$(printf '%*s' $((width - 18)) "")${COLOR_2}│${NC}"
    
    local path_display="${PROJECT_PATH}"
    if [ ${#path_display} -gt $((width - 4)) ]; then
        path_display="...${path_display: -$((width - 7))}"
    fi
    local path_pad=$((width - ${#path_display} - 2))
    echo -e "${COLOR_2}│${NC}  ${path_display}$(printf '%*s' $path_pad "")${COLOR_2}│${NC}"
    
    # Bordure basse
    echo -e "${COLOR_2}└$(printf '─%.0s' $(seq 1 $width))┘${NC}"
}

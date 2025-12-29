# Couleurs pour les logs
C_ERROR='\e[38;5;9m'      # Rouge vif
C_SUCCESS='\e[38;5;118m'     # Vert vif
C_WARNING='\e[38;5;220m'    # Jaune vif
C_INFO='\e[38;5;75m'        # Bleu fixe
C_PARAM='\e[38;5;219m'       # Cyan clair
C_END='\033[0m' # Balise de fin de couleur

# Log standard
lout(){
    local message=$1
    [ -z "$message" ] && echo "lout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_INFO}[INFO]${C_END} $message"
}
# Success
sout(){
    local message=$1
    [ -z "$message" ] && echo "sout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_SUCCESS}[SUCCESS]${C_END} $message ${C_SUCCESS}✓${C_END}"
}
# Warning, le script continue
wout(){
    local message=$1
    [ -z "$message" ] && echo "wout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_WARNING}[WARNING]${C_END} $message" >&2
}
# Fail, erreur mais le script continue
fout(){
    local message=$1
    [ -z "$message" ] && echo "fout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_ERROR}[FAIL]${C_END} $message" >&2
}
# Erreur, arrête le script
eout(){
    local message=$1
    [ -z "$message" ] && echo "eout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_ERROR}[ERROR]${C_END} $message" >&2
    exit 1
}
# Uniquement affiché en mode debug
debug_(){
    if $debug_mode; then
        local message=$1
        [ -z "$message" ] && echo "debug_() : Aucun paramètre passé pour message" >&2
        echo -e "[DEBUG] $message"
    fi
}
# Question fermée attend une réponse
ask_yn () {
    if [ -z "$1" ]; then
        echo -e "fonction ask_yn() : Aucun paramètre passé" >&2
        exit 1
    fi

    while true; do
        echo -ne "${C_PARAM}[PARAM]${C_END} $1 (o/n)"
        read -n 1 -p "" response
        echo ""
        # Vérification de la réponse
        if [[ $response == "o" || $response == "O" ]]; then
            return 0
        elif [[ $response == "n" || $response == "N" ]]; then
            return 1
        else
            wout "'$response' : Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non)."
        fi
    done
}


############################# create-project

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
}

get_json_latest_laravel_info() {
    local packagist_link="https://repo.packagist.org/p2/laravel/laravel.json"
    
    # Récupérer et traduire la réponse JSON
    local json_response=$(curl -s --max-time 10 "${packagist_link}" | jq -r '
        .packages."laravel/laravel"[0] as $p |
        {
            "laravel_version": $p.version_normalized,
            "php_version": ($p.require.php // "" | sub("^\\^"; ""))
        }
    ')

    if [ $(jq -r ".laravel_version" <<< $json_response) = "" ] ||
    [ $(jq -r ".php_version" <<< $json_response) = "" ]; then
        fout "Échec de récupération des infos sur la dernière version de laravel"
        return 1
    else
        echo $json_response
        return 0
    fi
}
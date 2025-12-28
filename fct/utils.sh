# Couleurs pour les logs
C_ERROR='\033[0;31m'
C_SUCCESS='\033[0;32m'
C_WARNING='\033[1;33m'
C_INFO='\033[0;34m'
C_END='\033[0m' # Balise de fin de couleur

lout(){
    local message=$1
    [ -z "$message" ] && echo "lout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_INFO}[INFO]${C_END} $message"
}
sout(){
    local message=$1
    [ -z "$message" ] && echo "sout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_SUCCESS}[SUCCESS]${C_END} $message ${C_SUCCESS}✓${C_END}"
}
wout(){
    local message=$1
    [ -z "$message" ] && echo "wout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_WARNING}[WARNING]${C_END} $message" >&2
}
fout(){
    local message=$1
    [ -z "$message" ] && echo "fout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_ERROR}[FAIL]${C_END} $message" >&2
}
eout(){
    local message=$1
    [ -z "$message" ] && echo "eout() : Aucun paramètre passé pour message" >&2
    echo -e "${C_ERROR}[ERROR]${C_END} $message" >&2
    exit 1
}
debug_(){
    if $debug_mode; then
        local message=$1
        [ -z "$message" ] && echo "debug_() : Aucun paramètre passé pour message" >&2
        echo -e "[DEBUG] $message"
    fi
}

#############################

check_packages_requirements() {
    lout "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        eout "Docker n'est pas installé"
    fi
    
    if ! command -v curl &> /dev/null; then
        eout "curl n'est pas installé"
    fi
    
    if ! command -v jq &> /dev/null; then
        eout "jq n'est pas installé. Installez-le avec: sudo apt install jq"
    fi
    
    sout "Tous les prérequis sont satisfaits"
}
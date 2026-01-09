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
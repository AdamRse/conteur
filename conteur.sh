#!/bin/bash
MAIN_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$MAIN_SCRIPT_PATH")"

COMMAND_NAME=""
MAIN_PID=$$
VERSION=""
DEBUG_MODE=false
CONFIRM_OPTIONS=true
CONFIG_DIR="${HOME}/.config/conteur"
PROJECT_PATH=""
PROJECTS_DIR=""
PROJECT_NAME=""
PROJECT_TYPE=""
DEFAULT_TEMPLATE_DIR=""
CUSTOM_TEMPLATE_DIR=""
JSON_CONFIG=""
DOCKER_CMD_PATH=""

source "${ROOT_DIR}/fct/terminal-tools.fct.sh" || exit 1
if [ -f "${ROOT_DIR}/.env" ]; then
    source "${ROOT_DIR}/.env"
else
    wout "Aucun fichier d'environement trouvé dans '${ROOT_DIR}', certaines valeurs seront appliquées par défaut"
    sleep 1
fi
source "${ROOT_DIR}/src/vars.sh" || exit 1
source "${ROOT_DIR}/src/parse_arguments.sh" || exit 1
source "${ROOT_DIR}/fct/common.fct.sh" || exit 1

# -- CHECKS --
lout "Vérification des dépendances"
check_packages_requirements

lout "Export des configurations"
export_json_config

lout "Vérification des variables globales"
set_check_globals

show_summary
if [ "${CONFIRM_OPTIONS}" = true ]; then
    if ! ask_yn "Créer le projet avec ces paramètres ?"; then
        lout "Abandon de l'utilisateur..."
        exit 0
    fi
fi

# -- MAIN --
library_path="${ROOT_DIR}/lib/${PROJECT_TYPE}/main.lib.sh"

lout "Chargement de la bibliothèque '${PROJECT_TYPE}'"
[ ! -f "${library_path}" ] && eout "Bibliothèque introuvable ou incomplète : main.lib.sh manquant"
source "${library_path}"
create_project # Polymorphisme de la bibliothèque importée au dessus
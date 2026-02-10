#!/bin/bash

DEBUG_MODE=false

MAIN_SCRIPT_PATH="$(readlink -f "$0")"
MAIN_SCRIPT_DIR="$(dirname "$MAIN_SCRIPT_PATH")"
COMMAND_NAME="$(basename "$0")"

MAIN_PID=$$
CONFIRM_OPTIONS=true
CONFIG_DIR="${HOME}/.config/conteur"
PROJECT_PATH=""
PROJECTS_DIR=""
PROJECT_NAME=""
PROJECT_TYPE=""
DEFAULT_TEMPLATE_DIR=""
CUSTOM_TEMPLATE_DIR=""
JSON_CONFIG=""

source "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh"
source "${MAIN_SCRIPT_DIR}/src/parse_arguments.sh"
source "${MAIN_SCRIPT_DIR}/fct/common.fct.sh"
if [ -f "${MAIN_SCRIPT_DIR}/.env" ]; then
    source "${MAIN_SCRIPT_DIR}/.env"
else
    wout "Aucun fichier d'environement trouvé dans '${MAIN_SCRIPT_DIR}', certaines valeurs seront appliquées par défaut"
    sleep 1
fi

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
library="${PROJECT_TYPE}.lib.sh"
source "${MAIN_SCRIPT_DIR}/lib/${library}"
create_project # Polymorphisme de la bibliothèque importée au dessus
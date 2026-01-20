#!/bin/bash

DEBUG_MODE=false

MAIN_SCRIPT_PATH=$(readlink -f "$0")
MAIN_SCRIPT_DIR="$(dirname "$MAIN_SCRIPT_PATH")"
PROGRAM_COMMAND_NAME="conteur"

MAIN_PID=$$
CONFIRM_OPTIONS=true
PROJECT_PATH=""
PROJECTS_DIR=""
PROJECT_NAME=""
PROJECT_TYPE=""

source "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh"
source "${MAIN_SCRIPT_DIR}/src/parse_arguments.sh"
source "${MAIN_SCRIPT_DIR}/fct/common.fct.sh"

# -- CHECKS --
lout "Vérification des dépendances"
check_packages_requirements

lout "Export des configurations"
export_json_config

lout "Vérification des variables globales"
check_globals

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
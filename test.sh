#!/bin/bash

MAIN_SCRIPT_PATH=$(readlink -f "$0")
MAIN_SCRIPT_DIR=$(dirname "$MAIN_SCRIPT_PATH")

DEBUG_MODE=false

# PROJECTS_DIR="$PJ"
# MAIN_PID=$$
# PROJECT_NAME="test-conteur"
# PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"
# PROJECT_TYPE="laravel"
CONFIRM_OPTIONS=true
PROJECT_PATH=""
PROJECTS_DIR=""
PROJECT_NAME=""
PROJECT_TYPE=""
PROGRAM_COMMAND_NAME="conteur"

MAIN_PID=$$

source "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh"
source "${MAIN_SCRIPT_DIR}/src/parse_arguments.sh"
source "${MAIN_SCRIPT_DIR}/fct/common.fct.sh"

# Tests de fonctions
debug_ "DEBUG MODE ON"

export_json_config
check_globals

show_summary
if [ "${CONFIRM_OPTIONS}" = true ]; then
    if ! ask_yn "Créer le projet avec ces paramètres ?"; then
        lout "Abandon de l'utilisateur..."
        exit 0
    fi
fi
sout "Projet créé !"


# if declare -p Zala 2>/dev/null | grep -q '^declare -x'; then
#     echo "La variable Zala est exportée : $Zala"
# else
#     echo "La variable Zala n'est pas exportée"
# fi

# lout "lout"
# sout "sout"
# wout "wout"
# fout "fout"
#!/bin/bash

MAIN_SCRIPT_PATH=$(readlink -f "$0")
MAIN_SCRIPT_DIR=$(dirname "$MAIN_SCRIPT_PATH")

DEBUG_MODE=true

# PROJECTS_DIR="$PJ"
# MAIN_PID=$$
# PROJECT_NAME="test-conteur"
# PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"
# PROJECT_TYPE="laravel"

MAIN_PID=$$

source "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh"
source "${MAIN_SCRIPT_DIR}/src/parse_arguments.sh"
source "${MAIN_SCRIPT_DIR}/fct/common.fct.sh"
source "${MAIN_SCRIPT_DIR}/lib/laravel.lib.sh"

# Tests de fonctions
debug_ "DEBUG MODE ON"

debug_ "RÉSUMÉ DES VARIABLES :
\tPROJECTS_DIR=$PROJECTS_DIR
\tPROJECT_NAME=$PROJECT_NAME
\tPROJECT_PATH=$PROJECT_PATH
\tPROJECT_TYPE=$PROJECT_TYPE"


# if declare -p Zala 2>/dev/null | grep -q '^declare -x'; then
#     echo "La variable Zala est exportée : $Zala"
# else
#     echo "La variable Zala n'est pas exportée"
# fi

# lout "lout"
# sout "sout"
# wout "wout"
# fout "fout"
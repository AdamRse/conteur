#!/bin/bash

DEBUG_MODE=true
PROJECT_TYPE="laravel"  # DEBUG, à remplacer par une option
                        # DOIT CORRESPONDRE À UN RÉPERTOIRE DANS ./templates/$PROJECT_TYPE/ ET DANS lib/$PROJECT_TYPE.lib.sh

MAIN_SCRIPT_PATH=$(readlink -f "$0")
MAIN_SCRIPT_DIR=$(dirname "$MAIN_SCRIPT_PATH")
MAIN_PID=$$
PROJECT_PATH=""
PROJECTS_DIR="${PWD}"
PROJECT_NAME=""

source "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh"
source "${MAIN_SCRIPT_DIR}/src/parse_arguments.sh"
source "${MAIN_SCRIPT_DIR}/fct/common.fct.sh"

# -- CHECKS --

# Check set project name
[ -z "${1}" ] && eout "Veillez nommer le projet"
PROJECT_NAME="$1"
debug_ "Nom du projet : ${1}"

# Check packages
lout "Vérification des dépendances..."
check_packages_requirements
sout "Toutes les dépendances sont satisfaites"

# Check set project directory
set_directory
debug_ "Répertoire du projet dans ${PROJECTS_DIR}"
PROJECT_PATH="${PROJECTS_DIR}/${PROJECT_NAME}"
debug_ "Répertoire du projet dans ${PROJECT_PATH}"

check_PROJECT_TYPE
debug_ "Type de projet '${PROJECT_TYPE}' validé"

# -- MAIN --

library="${PROJECT_TYPE}.lib.sh"
source "${MAIN_SCRIPT_DIR}/lib/${library}"
create_project # Polymorphisme de la bibliothèque importée au dessus
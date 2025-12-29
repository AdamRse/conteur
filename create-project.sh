#!/bin/bash

DEBUG_MODE=true
project_type="Laravel"

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
project_dir="$PWD"
project_name=false

source "$script_dir/fct/utils.sh"

# -- CHECKS --
# Check set project name
[ -z "$1" ] && eout "Veillez nommer le projet"
project_name="$1"
debug_ "Nom du projet : ${1}"

# Check packages
lout "Vérification des dépendances..."
check_packages_requirements
sout "Toutes les dépendances sont satisfaites"

# Check set project directory
if [ -n "$PJ" ]; then
    debug_ "Dev architecture détectée"
    if [ ! -d "${PJ}" ]; then
        wout "Le répertoire ${PJ} n'existe pas"
    fi
    project_dir="$PJ"
fi
debug_ "Répertoire du projet dans ${project_dir}"

debug_ "Nouveau projet ${project_type}"

# -- MAIN
lout "Récupération des infos sur la dernière version de laravel via packagist.org"

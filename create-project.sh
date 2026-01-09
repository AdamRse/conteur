#!/bin/bash

DEBUG_MODE=true
project_type="Laravel" # DEBUG, à remplacer par une ption

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
project_dir="$PWD"
project_name=false
project_path=false

source "${script_dir}/fct/terminal-tools.fct.sh"
source "${script_dir}/fct/common.fct.sh"

# -- CHECKS --

# Check set project name
[ -z "${1}" ] && eout "Veillez nommer le projet"
project_name="$1"
debug_ "Nom du projet : ${1}"

# Check packages
lout "Vérification des dépendances..."
check_packages_requirements
sout "Toutes les dépendances sont satisfaites"

# Check set project directory
set_directory
debug_ "Répertoire du projet dans ${project_dir}"
project_path="${project_dir}/${project_name}"
debug_ "Projet dans ${project_path}"

debug_ "Nouveau projet ${project_type}"

# -- MAIN --
if [ $project_type = "Laravel" ]; then
    source "${script_dir}/lib/laravel.lib.sh"
    laravel_create_project
else
    eout "Type de projet non supporté (${project_type})"
fi
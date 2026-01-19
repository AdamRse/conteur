#!/bin/bash

DEBUG_MODE=true
project_type="laravel"  # DEBUG, à remplacer par une option
                        # DOIT CORRESPONDRE À UN RÉPERTOIRE DANS ./templates/$project_type/ ET DANS lib/$project_type.lib.sh

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
project_path=false
project_dir="$PWD"
project_name=false

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
debug_ "Répertoire du projet dans ${project_path}"

check_project_type
debug_ "Type de projet '${project_type}' validé"

# -- MAIN --

library="${project_type}.lib.sh"
source "${script_dir}/lib/${library}"
if ! create_project; then # Polymorphisme de la bibliothèque importée au dessus
    eout "La fonction create_project() de la bibliothèque interne '${library}' n'existe pas."
fi

sout "Projet ${project_type} créé dans '${project_dir}' !"
lout "Pour lancer le projet : utilsier la commande : 'docker compose up' à la racine du projet."
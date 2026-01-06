#!/bin/bash

DEBUG_MODE=true
project_type="Laravel"

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
project_dir="$PWD"
project_name=false

source "${script_dir}/fct/terminal-tools.fct.sh"
source "${script_dir}/fct/common.fct.sh"
source "${script_dir}/fct/laravel.fct.sh"

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

lout "Vérification des fichiers de configuration laravel"
laravel_set_requirments

debug_ "Nouveau projet ${project_type}"


# -- MAIN --
lout "Récupération des infos sur la dernière version de laravel via packagist.org"

if ! laravel_latest_requirements=$(laravel_get_json_latest_info); then
    eout "La récupération des exigeances laravel a échouée. Abandon..."
fi
php_version=$(jq -r '.php_version' <<< $laravel_latest_requirements)
laravel_version=$(jq -r '.laravel_version' <<< $laravel_latest_requirements)

sout "Version trouvées, laravel ${laravel_version} et PHP ${php_version}"

lout "Création du projet avec docker"


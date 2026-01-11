#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

DEBUG_MODE=true

project_dir="$PWD"
project_name="conteur"
project_path="$PJ"

source "${script_dir}/fct/terminal-tools.fct.sh"
source "${script_dir}/fct/common.fct.sh"
# source "${script_dir}/lib/laravel.lib.sh"

ex() {
    export $1=$1
}
# Tests de fonctions
debug_ "DEBUG MODE ON"

conf_reader

# zal="ok zal"
# var_name="zala"
# if [ -n "${!var_name}" ]; then
#     export $var_name
#     echo "Variable \$$var_name expotée"
# else
#     wout "La variable '$var_name' passée en 3ème paramètre de 'copy_file_from_template()' ne pointe sur aucune valeur, elle est ignoré et ne modifiera pas le template. Vérifiez le nom de la variable passée à 'copy_file_from_template()', elle doit comporter une erreur de nom."
# fi

# if declare -p zal 2>/dev/null | grep -q "^declare -x"; then
#     echo "$var_name est exportée, contenu : $zal"
# else
#     echo "$var_name n'est pas exportée ou n'existe pas"
# fi

# lout "lout"
# sout "sout"
# wout "wout"
# fout "fout"
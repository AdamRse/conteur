#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

DEBUG_MODE=true

project_dir="$PWD"
project_name="conteur"
project_path="$PJ"
project_type="laravel"

source "${script_dir}/fct/terminal-tools.fct.sh"
source "${script_dir}/fct/common.fct.sh"
#source "${script_dir}/lib/laravel.lib.sh"

# Tests de fonctions
debug_ "DEBUG MODE ON"
#copy_files_from_template

jsn=$(merge_config_json)
#echo "$jsn"
if check_json_config_integrity "$jsn"; then
    echo "VALIDE"
else
    echo "ERREUR"
fi
copy_files_from_template "$jsn"

# zala="zal"
# name="zala"
# export $name

# if declare -p zala 2>/dev/null | grep -q '^declare -x'; then
#     echo "La variable zala est exportée"
# else
#     echo "La variable zala n'est pas exportée"
# fi

# lout "lout"
# sout "sout"
# wout "wout"
# fout "fout"
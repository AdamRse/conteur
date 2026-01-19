#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

DEBUG_MODE=true

project_dir="$PJ"
project_name="mon_projet"
project_path="$PWD"
project_type="laravel"

source "${script_dir}/fct/terminal-tools.fct.sh"
source "${script_dir}/fct/common.fct.sh"
source "${script_dir}/lib/laravel.lib.sh"

# Tests de fonctions
debug_ "DEBUG MODE ON"
create_project

# if declare -p Zala 2>/dev/null | grep -q '^declare -x'; then
#     echo "La variable Zala est exportée : $Zala"
# else
#     echo "La variable Zala n'est pas exportée"
# fi

# lout "lout"
# sout "sout"
# wout "wout"
# fout "fout"
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
source "${script_dir}/lib/laravel.lib.sh"

# Tests de fonctions
debug_ "DEBUG MODE ON"
echo "SERVICES : $(laravel_sail_get_services_in_array)"

# if declare -p Zala 2>/dev/null | grep -q '^declare -x'; then
#     echo "La variable Zala est exportée : $Zala"
# else
#     echo "La variable Zala n'est pas exportée"
# fi

# lout "lout"
# sout "sout"
# wout "wout"
# fout "fout"
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

test_conf="$PJ/conteur/templates/laravel/conf/test.conf"
#Appel de la fonction
new_vars=$(conf_reader "$test_conf")


echo "$new_vars"


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
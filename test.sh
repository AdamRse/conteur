#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

DEBUG_MODE=true

project_dir="$PWD"
project_name="conteur"
project_path="$PJ"

source "${script_dir}/fct/terminal-tools.fct.sh"
source "${script_dir}/fct/common.fct.sh"
source "${script_dir}/fct/laravel.fct.sh"


# Tests de fonctions
debug_ "DEBUG MODE ON"

# laravel_check_requirments

# laravel_create_dockerfile

echo $0

# lout "lout"
# sout "sout"
# wout "wout"
# fout "fout"
#!/bin/bash

debug_mode=true

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
project_dir="$PWD"

source "$script_dir/fct/utils.sh"

# -- CHECKS --
# Check packages
check_packages_requirements

# Check project directory
if [ -n "$PJ" ]; then
    project_dir="$PJ"
fi
debug_ "Répertoire du projet dans ${project_dir}"

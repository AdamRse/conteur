#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source "$script_dir/fct/utils.sh"

# Tests de fonctions
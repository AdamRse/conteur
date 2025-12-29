#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

DEBUG_MODE=true

source "$script_dir/fct/utils.sh"


# Tests de fonctions
debug_ "DEBUG MODE ON"
rt=$(get_json_latest_laravel_info)
echo "---------------"
echo $rt
echo "---------------"
php=$(jq -r '.php_version' <<< $rt)
laravel=$(jq -r '.laravel_version' <<< $rt)
echo "Version laravel : ${laravel}"
echo "Version PHP : ${php}"
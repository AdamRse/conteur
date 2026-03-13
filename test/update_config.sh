#!/bin/bash

MAIN_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"

COMMAND_NAME=""
VERSION=""
CONFIG_DIR=""
INSTALL_DIR=""
BIN_LINK=""
DEBUG_MODE=true
USER_NAME=""
USER_MAIN_GROUP=""
USER_HOME=""
source "${ROOT_DIR}/src/vars.sh" || exit 1

source "${ROOT_DIR}/fct/terminal-tools.fct.sh" || exit 1
source "${ROOT_DIR}/fct/core.fct.sh" || exit 1
source "${ROOT_DIR}/fct/common.fct.sh" || exit 1

lout "check des requirements"
check_packages_requirements

lout "Export du json de configuration"
export_json_config

lout "Lancement de update_config_dir, ATTENTION :"
update_config_dir
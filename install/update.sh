#!/bin/bash

source "${ROOT_DIR}/src/vars.sh" || exit 1

INSTALL_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$(dirname "$INSTALL_SCRIPT_PATH")")"
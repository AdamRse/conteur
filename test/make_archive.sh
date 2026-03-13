#!/bin/bash

MAIN_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"

cd "${ROOT_DIR}"
git archive --format=tar.gz -o "${ROOT_DIR}/install/conteur.tar.gz" HEAD
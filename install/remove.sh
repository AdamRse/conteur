#!/bin/bash

INSTALL_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$(dirname "$INSTALL_SCRIPT_PATH")")"

COMMAND_NAME=""
VERSION=""
CONFIG_DIR=""
INSTALL_DIR=""
BIN_LINK=""
source "${ROOT_DIR}/src/vars.sh" || exit 1

source "${ROOT_DIR}/fct/terminal-tools.fct.sh" || exit 1
source "${ROOT_DIR}/fct/common.fct.sh" || exit 1

remove_config_dir(){
    USER_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
    [ ! -d "${USER_HOME}" ] && USER_HOME="/home/${SUDO_USER}"
    [ ! -d "${USER_HOME}" ] && USER_HOME="${HOME}"
    [ ! -d "${USER_HOME}" ] && {
        fout "Impossible de déterminer le répertoire HOME de l'utilisateur."
        return 1
    }

    CONFIG_DIR="${USER_HOME}/.config/${COMMAND_NAME}"

    [ ! -d "${CONFIG_DIR}" ] && {
        fout "Impossible de déterminer le répertoire CONFIG_DIR de l'utilisateur ."
        return 1
    }

    if ask_yn "Confirmer la supression de '${CONFIG_DIR}' ?"; then
        rm -rf "${CONFIG_DIR}" && lout "Suppression de '${CONFIG_DIR}' réussie" && return 0
        fout "Impossible de supprimer '${CONFIG_DIR}'" && return 1
    fi

    lout "L'utilisateur a choisit de garder le répertoire de configuration de ${COMMAND_NAME} dans '${CONFIG_DIR}'"
    return 0
}

[[ $EUID -ne 0 ]] && eout "Ce script doit être exécuté en tant que root (utilisez sudo)."
[[ ! "${COMMAND_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]] && eout "La commande '${COMMAND_NAME}' (./src/vars.sh) contient des caractères interdits"

lout "Désinstallation de ${COMMAND_NAME}"

if [[ -d "${INSTALL_DIR}" ]]; then
    [[ ! "${INSTALL_DIR}" =~ ${COMMAND_NAME}/?$ ]] && eout "Attention, par sécurité le programme a été arrêté pour ne pas supprimer un mauvais répertoire. Le répertoire d'installation '${INSTALL_DIR}' devrait terminer par ${COMMAND_NAME}" && exit 1

    lout "Suppression de '${INSTALL_DIR}'"
    rm -rf "${INSTALL_DIR}"
fi

lout "Supression du lien symbolique"
sudo rm "${BIN_LINK}" || fout "Impossible de supprimer le lien symbolique dans '${BIN_LINK}'"

if ask_yn "Supprimer le répertoire de configuration avec les paramètres de l'utilisateur ?"; then
    remove_config_dir
fi

sout "Désinstallation de ${COMMAND_NAME} réussie !"
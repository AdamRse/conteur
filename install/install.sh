#!/bin/bash

# -- VARIABLES GLOBALES
INSTALL_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$(dirname "$INSTALL_SCRIPT_PATH")")"

COMMAND_NAME=""
VERSION=""
CONFIG_DIR=""

source "${ROOT_DIR}/src/vars.sh" || exit 1
INSTALL_DIR="/usr/local/share/${COMMAND_NAME}"
BIN_LINK="/usr/local/bin/${COMMAND_NAME}"

source "${ROOT_DIR}/fct/terminal-tools.fct.sh" || exit 1
source "${ROOT_DIR}/fct/common.fct.sh" || exit 1

# -- CONDITIONS
[[ $EUID -ne 0 ]] && eout "Ce script doit être exécuté en tant que root (utilisez sudo)."
[[ ! "${COMMAND_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]] && eout "La commande '${COMMAND_NAME}' (./src/vars.sh) contient des caractères interdits"

if command -v "${COMMAND_NAME}" >/dev/null 2>&1; then
    [ ! -f "${ROOT_DIR}/install/update.sh" ] && eout "${COMMAND_NAME} est déjà installé, impossible de trouver le script de mise à jour"
    ${COMMAND_NAME} -U
    exit 0
fi

check_packages_requirements

USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
[ ! -d "${USER_HOME}" ] && USER_HOME="/home/$SUDO_USER"
[ ! -d "${USER_HOME}" ] && USER_HOME="$HOME"
[ ! -d "${USER_HOME}" ] && eout "Impossible de déterminer le répertoire HOME de l'utilisateur pour initialiser les fichiers de configuration."
CONFIG_DIR="${USER_HOME}/.config/${COMMAND_NAME}"

# -- INSTALLATION
lout "Début de l'installation de '${COMMAND_NAME}'..."

lout "Export du json de configuration"
export_json_config

if [[ -d "${INSTALL_DIR}" ]]; then
    [[ ! "${INSTALL_DIR}" =~ ${COMMAND_NAME}/?$ ]] && eout "Attention, par sécurité le programme a été arrêté pour ne pas supprimer un mauvais répertoire. Le répertoire d'installation '${INSTALL_DIR}' devrait terminer par ${COMMAND_NAME}" && exit 1
    ! ask_yn "Le répertoire d'installation '${INSTALL_DIR}' existe déjà. Faut-il l'écraser pour poursuivre l'installation ?" && {
        lout "Abandon de l'installation par l'utilisateur."
        exit 0
    }

    [[ -f "${INSTALL_DIR}/.env" ]] && env_tmp_path="/tmp/${COMMAND_NAME}.env_$(cat /proc/sys/kernel/random/uuid)" && cp "${INSTALL_DIR}/.env" "${env_tmp_path}"
    rm -rf "${INSTALL_DIR}"
fi
mkdir -p "${INSTALL_DIR}" || fout "Impossible de créer ${INSTALL_DIR}"
[[ -f "${env_tmp_path}" ]] && mv "${env_tmp_path}" "${INSTALL_DIR}/.env"

lout "Synchronisation des fichiers..."
rsync -r --exclude={'.git', '.gitignore', 'install/install.sh'} "${ROOT_DIR}/." "${INSTALL_DIR}/"
sout "Fichiers copiés avec succès."

lout "Configuration des permissions..."
find "${INSTALL_DIR}" -type d -exec chmod 751 {} +
find "${INSTALL_DIR}" -type f -exec chmod 644 {} +
chmod +x "${INSTALL_DIR}/${COMMAND_NAME}.sh" "${INSTALL_DIR}/install/update.sh"

lout "Création du lien symbolique dans /usr/local/bin..."
if [[ -L "${BIN_LINK}" ]]; then
    rm "${BIN_LINK}"
fi
ln -s "${INSTALL_DIR}/${COMMAND_NAME}.sh" "${BIN_LINK}" || fout "Échec de création du lien symbolique."


# -- SUCCESS

if command -v "${COMMAND_NAME}" >/dev/null 2>&1; then
    lout "Vous pouvez maintenant utiliser la commande : ${COMMAND_NAME}"
else
    wout "Le lien symbolique semble ne pas répondre immédiatement. Vérifiez que votre PATH contient '${BIN_LINK}'."
fi

if ask_yn "Créer les fichiers de configuration de l'utilisateur dans '${CONFIG_DIR}' ?"; then
    lout "Création des fichiers de configuration dans '${CONFIG_DIR}'"
    create_config_dir
else
    wout "Les fichiers de configuration ne sont pas installés."
fi
sout "Installation terminée !"
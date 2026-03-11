#!/bin/bash

# Le script doit être appelé sans contexte

# -- VARIABLES GLOBALES
INSTALL_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$(dirname "$INSTALL_SCRIPT_PATH")")"

COMMAND_NAME=""
VERSION=""
CONFIG_DIR=""
INSTALL_DIR=""
BIN_LINK=""
DEBUG_MODE=false
USER_NAME=""
USER_MAIN_GROUP=""
USER_HOME=""
source "${ROOT_DIR}/src/vars.sh" || exit 1

source "${ROOT_DIR}/fct/terminal-tools.fct.sh" || exit 1
source "${ROOT_DIR}/fct/core.fct.sh" || exit 1
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
sudo rsync -r --exclude="{
    '.git',
    '.gitignore',
    'install/install.sh',
    'install/dev.install.sh'
    }" "${ROOT_DIR}/." "${INSTALL_DIR}/"
sout "Fichiers copiés avec succès."

lout "Configuration des permissions..."
if ! set_permissions; then
    fout "Impossible de paramétrer les permission de base, attention ${COMMAND_NAME} ne sera pas executable !!!"
    # fout "---------"
    # fout "Veillez paramétrer manuellement les permissions :"
    # fout "- répertoires ${INSTALL_DIR} : execution"
    # fout "- fichiers ${INSTALL_DIR} : lecture"
    # fout "- répertoires ${INSTALL_DIR}/lib/*/templates : lecture+execution"
    # fout "- répertoires ${INSTALL_DIR}/lib/*/templates/deprecated : lecture+execution"
    # fout "- ${INSTALL_DIR}/${COMMAND_NAME}.sh : lecture+execution"
    # fout "---------"
    sleep 2
fi

lout "Création du lien symbolique dans /usr/local/bin..."
if [[ -L "${BIN_LINK}" ]]; then
    rm "${BIN_LINK}"
fi
sudo ln -s "${INSTALL_DIR}/${COMMAND_NAME}.sh" "${BIN_LINK}" || fout "Échec de création du lien symbolique."


# -- SUCCESS

if command -v "${COMMAND_NAME}" >/dev/null 2>&1; then
    lout "Vous pouvez maintenant utiliser la commande : ${COMMAND_NAME}"
else
    wout "Le lien symbolique semble ne pas répondre immédiatement. Vérifiez que votre PATH contient '${BIN_LINK}'."
fi

if ask_yn "Créer les fichiers de configuration de l'utilisateur dans '${CONFIG_DIR}' ?"; then
    lout "Création des fichiers de configuration dans '${CONFIG_DIR}'"
    update_config_dir
    if [ -n "${USER_NAME}" ] && [ -n "${USER_MAIN_GROUP}" ]; then
        sudo chown -R "${USER_NAME}:${USER_MAIN_GROUP}" "${CONFIG_DIR}"
    else
        wout "Impossible de trouver le nom d'utilisateur ou son groupe principal, pour paramétrer les droits d'accès aux fichiers de config."
        wout "Veuillez donner les bon droits au fichier de configurations utilisateur dans '${CONFIG_DIR}'"
    fi
else
    wout "Les fichiers de configuration ne sont pas installés."
fi
sout "Installation terminée !"
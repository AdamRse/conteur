#!/bin/bash

# -- VARIABLES D'ENV
COMMAND_NAME="conteur"

INSTALL_SCRIPT_PATH="$(readlink -f "$0")"
MAIN_SCRIPT_DIR="$(dirname "$(dirname "$INSTALL_SCRIPT_PATH")")"
INSTALL_DIR="/usr/local/lib/${COMMAND_NAME}"
BIN_LINK="/usr/local/bin/${COMMAND_NAME}"

# -- CONDITIONS
if [[ -f "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh" ]] && [[ -f "${MAIN_SCRIPT_DIR}/fct/common.fct.sh" ]]; then
    source "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh"
    source "${MAIN_SCRIPT_DIR}/fct/common.fct.sh"
else
    echo "Erreur critique : Outils de terminal introuvables."
    exit 1
fi

if command -v "${COMMAND_NAME}" >/dev/null 2>&1; then
    [ ! -f "${MAIN_SCRIPT_DIR}/install/update.sh" ] && eout "${COMMAND_NAME} est déjà installé, impossible de trouver le script de mise à jour"
    source "${MAIN_SCRIPT_DIR}/install/update.sh"
    exit 0
fi

check_packages_requirements

# -- INSTALLATION
lout "Début de l'installation de '${COMMAND_NAME}'..."

[[ $EUID -ne 0 ]] && eout "Ce script doit être exécuté en tant que root (utilisez sudo)."

if [[ ! -d "${INSTALL_DIR}" ]]; then
    lout "Création du répertoire d'installation : ${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}" || fout "Impossible de créer ${INSTALL_DIR}"
fi

lout "Synchronisation des fichiers..."
rsync -r "${MAIN_SCRIPT_DIR}/." "${INSTALL_DIR}/"
sout "Fichiers copiés avec succès."

lout "Configuration des permissions..."
chmod +x "${INSTALL_DIR}/${COMMAND_NAME}.sh"
find "${INSTALL_DIR}" -type d -exec chmod 751 {} +
find "${INSTALL_DIR}" -type f -exec chmod 644 {} +
chmod +x "${INSTALL_DIR}/install/update.sh ${INSTALL_DIR}/install/install.sh"

lout "Création du lien symbolique dans /usr/local/bin..."
if [[ -L "${BIN_LINK}" ]]; then
    rm "${BIN_LINK}"
fi
ln -s "${INSTALL_DIR}/${COMMAND_NAME}.sh" "${BIN_LINK}" || fout "Échec de création du lien symbolique."

# -- SUCCESS

if command -v "${COMMAND_NAME}" >/dev/null 2>&1; then
    lout "Vous pouvez maintenant utiliser la commande : ${COMMAND_NAME}"
    sout "Installation terminée !"
else
    wout "Le lien symbolique semble ne pas répondre immédiatement. Vérifiez votre PATH."
fi

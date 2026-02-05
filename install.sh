#!/bin/bash

# --- Initialisation ---
MAIN_SCRIPT_PATH=$(readlink -f "$0")
MAIN_SCRIPT_DIR="$(dirname "$MAIN_SCRIPT_PATH")"
BIN_DIR="/usr/local/bin"
INSTALL_DIR="/opt/${COMMAND_NAME}"
COMMAND_NAME="conteur"

source "${MAIN_SCRIPT_DIR}/fct/terminal-tools.fct.sh"

lout "-- Installation de ${COMMAND_NAME} --"
lout "Vous avez la possibilité de choisir entre l'installation dans ce répertoire (aucune copie de fichiers ne sera faite), ou plus globallement (${INSTALL_DIR})"
wout "ATTENTION : Pour personnaliser le répertoire d'installation, placez le repo à l'endroit souhaité."
if ask_yn "Installer ${COMMAND_NAME} de manière globale ?\n\tOui\t: ${INSTALL_DIR}\n\tNon\t: ${MAIN_SCRIPT_DIR}\n\tControl+C pour annuler\n\t"; then
    lout "Installation globale"
    INSTALL_DIR="/opt/${COMMAND_NAME}"
else
    lout "Installation locale"
    INSTALL_DIR="${MAIN_SCRIPT_DIR}"
fi

BIN_LINK="${BIN_DIR}/${COMMAND_NAME}"

# -- EXEC --

if ! [ "${INSTALL_DIR}" = "${MAIN_SCRIPT_DIR}" ]; then
    lout "Création du répertoire ${INSTALL_DIR}"
    sudo mkdir -p "${INSTALL_DIR}"
    lout "Copie des fichiers"
    sudo cp -r "${MAIN_SCRIPT_DIR}/." "${INSTALL_DIR}/"
fi
lout "Privilège d'execution globale"
sudo chmod +x "${INSTALL_DIR}/conteur.sh"
lout "Ajout de programme à l'index"
sudo ln -sf "${INSTALL_DIR}/conteur.sh" "${BIN_LINK}"

echo -e "\t----------------------------------------------------------"

hash -r
if ! command -v "${COMMAND_NAME}" &> /dev/null; then
    eout "L'installation a échouée, la commande ne peut pas être executée. Vérifier que ${BIN_DIR} est bien dans le PATH"
fi
sout "Installation réussie !"
lout "Commande utilisable : ${COMMAND_NAME}"

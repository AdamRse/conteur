#!/bin/bash

# -- CONFIGURATION GITHUB (À adapter)
GITHUB_USER="AdamRse"
GITHUB_REPO="conteur"

# -- CHARGEMENT DE L'ENVIRONNEMENT LOCAL
# On détermine le dossier racine à partir de l'emplacement du script d'update
UPDATE_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$(dirname "$UPDATE_SCRIPT_PATH")")"

source "${ROOT_DIR}/src/vars.sh" || exit 1
# VERSION est maintenant chargée depuis vars.sh
# COMMAND_NAME est chargé aussi

source "${ROOT_DIR}/fct/terminal-tools.fct.sh" || exit 1
source "${ROOT_DIR}/fct/common.fct.sh" || exit 1

INSTALL_DIR="/usr/local/share/${COMMAND_NAME}"

# -- VÉRIFICATION DES DROITS
[[ $EUID -ne 0 ]] && eout "La mise à jour nécessite les droits root (sudo)."

lout "Vérification des mises à jour pour ${COMMAND_NAME}..."

# -- RÉCUPÉRATION DE LA DERNIÈRE VERSION SUR GITHUB
# Utilisation de l'API GitHub (nécessite 'curl' et 'grep/sed' ou 'jq')
LATEST_RELEASE_JSON=$(curl -s "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/releases/latest")
LATEST_VERSION=$(echo "$LATEST_RELEASE_JSON" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [[ -z "$LATEST_VERSION" ]]; then
    fout "Impossible de récupérer la dernière version sur GitHub."
fi

# -- COMPARAISON
if [[ "$VERSION" == "$LATEST_VERSION" ]]; then
    sout "${COMMAND_NAME} est déjà à jour (Version $VERSION)."
    exit 0
fi

lout "Une nouvelle version est disponible : ${LATEST_VERSION} (Actuelle : ${VERSION})"
if ! ask_yn "Souhaitez-vous installer la mise à jour ?"; then
    lout "Mise à jour annulée."
    exit 0
fi

# -- TÉLÉCHARGEMENT ET INSTALLATION
TMP_DIR=$(mktemp -d)
TARBALL_URL=$(echo "$LATEST_RELEASE_JSON" | grep '"tarball_url":' | sed -E 's/.*"([^"]+)".*/\1/')

lout "Téléchargement de la mise à jour..."
curl -L "$TARBALL_URL" -o "${TMP_DIR}/update.tar.gz" || fout "Échec du téléchargement."

lout "Extraction..."
mkdir -p "${TMP_DIR}/source"
tar -xzf "${TMP_DIR}/update.tar.gz" -C "${TMP_DIR}/source" --strip-components=1

# -- MISE À JOUR DES FICHIERS
lout "Application de la mise à jour dans ${INSTALL_DIR}..."

# Sauvegarde temporaire du .env si nécessaire
[[ -f "${INSTALL_DIR}/.env" ]] && cp "${INSTALL_DIR}/.env" "${TMP_DIR}/.env_backup"

# On utilise rsync pour mettre à jour les fichiers proprement
# --delete permet de supprimer les fichiers qui n'existent plus dans la nouvelle version
rsync -rtv --exclude={'.git', '.gitignore', '.env'} "${TMP_DIR}/source/" "${INSTALL_DIR}/"

# Restauration du .env
[[ -f "${TMP_DIR}/.env_backup" ]] && mv "${TMP_DIR}/.env_backup" "${INSTALL_DIR}/.env"

# -- PERMISSIONS ET NETTOYAGE
lout "Finalisation..."
chmod +x "${INSTALL_DIR}/${COMMAND_NAME}.sh" "${INSTALL_DIR}/install/update.sh"
rm -rf "${TMP_DIR}"

sout "Mise à jour vers la version ${LATEST_VERSION} terminée avec succès !"
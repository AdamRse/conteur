#!/bin/bash

# /!\ Le script ne peut pas être appelé sans contexte, il faut que les variables globales soient préalablement chargées

UPDATE_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$(dirname "$UPDATE_SCRIPT_PATH")")"

VERSION=""
COMMAND_NAME=""
USER_NAME=""
USER_MAIN_GROUP=""
USER_HOME=""
INSTALL_DIR=""
BIN_LINK=""
CONFIG_DIR=""
OLD_VERSION=""

source "${ROOT_DIR}/src/vars.sh" || {
    echo "Erreur, architecture non reconnue : '${ROOT_DIR}/src/vars.sh' non trouvé"
    exit 1
}
source "${ROOT_DIR}/fct/terminal-tools.fct.sh" || {
    echo "Erreur, architecture non reconnue : '${ROOT_DIR}/fct/terminal-tools.fct.sh' non trouvé"
    exit 1
}
source "${ROOT_DIR}/fct/core.fct.sh" || eout "Erreur, architecture non reconnue : '${ROOT_DIR}/fct/core.fct.sh' non trouvé"

# ---
recover_last_version(){
    lout "Récupération du backup :S"
    [[ -n "${INSTALL_DIR}" ]] && [[ "${INSTALL_DIR}" =~ \/conteur.*$ ]] && sudo rm -rf "${INSTALL_DIR}"
    sudo mv "${BACKUP_DIR}" "${INSTALL_DIR}" || {
        sudo rm "${BIN_LINK}"
        eout "Impossible de récupérer le backup dans '${BACKUP_DIR}', il faut réinstaller ${COMMAND_NAME}."
    }
}
# ---

if [ -f "${CONFIG_DIR}/.env" ]; then
    source "${CONFIG_DIR}/.env"
    lout "Variables d'environement chargées"
else
    wout "Aucun fichier d'environement trouvé dans '${CONFIG_DIR}', certaines valeurs seront appliquées par défaut"
    sleep 1
fi

lout "Récupération de la version à jour"

REPO_URL="https://github.com/AdamRse/conteur/releases/latest"
GITHUB_HEADER=$(curl -sI "${REPO_URL}")
LATEST_VERSION_TAG=$(grep -i "location:" <<< "${GITHUB_HEADER}" | awk -F'/' '{print $NF}'| tr -d '\r')
LATEST_VERSION=$(tr -cd '0-9.' <<< "$LATEST_VERSION_TAG")

[ -z "${LATEST_VERSION}" ] && eout "Impossible de récupérer la dernière version sur github.\n\turl : ${REPO_URL}\n\t--------------------------\nHEADER REÇU\n--------------------------\n${GITHUB_HEADER}"
[[ ! "${LATEST_VERSION}" =~ ^[0-9]+(\.[0-9]+)*$ ]] && eout "La version récupérée ($LATEST_VERSION}) n'est pas un numéro de version valide. La realease n'a peut-être pas le bon label."

lout "Latest : v${LATEST_VERSION}\n\tLocale : v${VERSION}"
[[ "${LATEST_VERSION}" = "${VERSION}" ]] && { lout "La version locale est à jour."; exit 0; }

DOWNLOAD_URL="https://github.com/AdamRse/conteur/releases/download/${LATEST_VERSION_TAG}/conteur.tar.gz"
UUID=$(cat /proc/sys/kernel/random/uuid)

TEMP_DIR="/tmp/conteur-${UUID}"
TEMP_DIR_ARCHIVE="${TEMP_DIR}.tar.gz"
BACKUP_DIR="/tmp/conteur-backup-${UUID}"


[[ ! "${INSTALL_DIR}" =~ ${COMMAND_NAME}/?$ ]] && eout "Attention, par sécurité le programme a été arrêté pour ne pas supprimer un mauvais répertoire. Le répertoire d'installation '${INSTALL_DIR}' devrait terminer par ${COMMAND_NAME}" && exit 1

lout "Lancement de la mise à jour vers ${LATEST_VERSION_TAG}"

lout "Téléchargement de l'archive"
curl -L "${DOWNLOAD_URL}" -o "${TEMP_DIR_ARCHIVE}" || eout "Le téléchargement de l'archive a échoué"

lout "Backup de l'ancienne version"
sudo mv "${INSTALL_DIR}" "${BACKUP_DIR}"
sudo mkdir -p "${INSTALL_DIR}"

lout "décompression de l'archive"
sudo tar -xzf "${TEMP_DIR_ARCHIVE}" -C "${INSTALL_DIR}" --strip-components=1 || {
    fout "Impossible de décompresser l'archive, elle n'est peut être pas au format .tar.gz, ou peut-être corrompue."
    recover_last_version
    eout "La mise a jour a échoué."
}
sudo find "${INSTALL_DIR}" -type d -exec chmod 751 {} +
sudo find "${INSTALL_DIR}" -type f -exec chmod 644 {} +
sudo chmod 755 "${INSTALL_DIR}/conteur.sh"

# Mise a jour de l'architecture effectuée, recgargement des nouveaux fichiers et mise à jour des fichiers de config (en cas de nouvelle lib)
OLD_VERSION="${VERSION}"
source "${ROOT_DIR}/src/vars.sh" || {
    fout "Erreur, architecture non reconnue : '${ROOT_DIR}/src/vars.sh' non trouvé.\nLa mise a jour semble avoir échouée, Impossible de mettre à jour le répertoire de config..."
    fout "Récupération de l'ancienne version par sécurité"
    recover_last_version
    eout "La mise a jour a échoué."
}
source "${ROOT_DIR}/src/common.sh" || {
    fout "Erreur, architecture non reconnue : '${ROOT_DIR}/src/common.sh' non trouvé.\nLa mise a jour semble avoir échouée, Impossible de mettre à jour le répertoire de config..."
    fout "Récupération de l'ancienne version par sécurité"
    recover_last_version
    eout "La mise a jour a échoué."
}
lout "Export des configurations"
export_json_config

lout "Mise à jour des fichiers de configuration de l'utilisateur"
update_config_dir

lout "Supression du backup"
[[ -n "${BACKUP_DIR}" ]] && [[ "${BACKUP_DIR}" =~ \/conteur.*$ ]] && sudo rm -rf "${BACKUP_DIR}"
[[ -n "${TEMP_DIR}" ]] && [[ "${TEMP_DIR}" =~ \/conteur.*$ ]] && sudo rm -rf "${TEMP_DIR}"
[[ -n "${TEMP_DIR_ARCHIVE}" ]] && [[ "${TEMP_DIR_ARCHIVE}" =~ \/conteur.*$ ]] && sudo rm -rf "${TEMP_DIR_ARCHIVE}"

sout "Mise a jour v${OLD_VERSION} > v${LATEST_VERSION} terminée avec succès !"
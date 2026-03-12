#!/bin/bash

# /!\ Le script ne peut pas être appelé sans contexte, il faut que les variables globales soient préalablement chargées

UPDATE_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "$(dirname "$UPDATE_SCRIPT_PATH")")"

NOM_ARCHIVE_UPDATE="conteur.tar.gz"

VERSION=""
COMMAND_NAME=""
DEBUG_MODE=true
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

REPO_URL="local latest"
GITHUB_HEADER="header v 2.0"
LATEST_VERSION_TAG="v2.0"
LATEST_VERSION="2.0"

[ -z "${LATEST_VERSION}" ] && eout "Impossible de récupérer la dernière version sur github.\n\turl : ${REPO_URL}\n\t--------------------------\nHEADER REÇU\n--------------------------\n${GITHUB_HEADER}"
[[ ! "${LATEST_VERSION}" =~ ^[0-9]+(\.[0-9]+)*$ ]] && eout "La version récupérée ($LATEST_VERSION}) n'est pas un numéro de version valide. La realease n'a peut-être pas le bon label."

lout "Latest : v${LATEST_VERSION}\n\tLocale : v${VERSION}"
[[ "${LATEST_VERSION}" = "${VERSION}" ]] && { lout "La version locale est à jour."; exit 0; }

UUID=$(cat /proc/sys/kernel/random/uuid)

TEMP_DIR="/tmp/conteur-${UUID}"
TEMP_DIR_ARCHIVE="${TEMP_DIR}.tar.gz"
BACKUP_DIR="/tmp/conteur-backup-${UUID}"
debug_ "-- Résumée --\n\tTEMP_DIR : ${TEMP_DIR}\n\tTEMP_DIR_ARCHIVE : ${TEMP_DIR_ARCHIVE}\n\tBACKUP_DIR : ${BACKUP_DIR}"


[[ ! "${INSTALL_DIR}" =~ ${COMMAND_NAME}/?$ ]] && eout "Attention, par sécurité le programme a été arrêté pour ne pas supprimer un mauvais répertoire. Le répertoire d'installation '${INSTALL_DIR}' devrait terminer par ${COMMAND_NAME}" && exit 1

lout "Lancement de la mise à jour vers ${LATEST_VERSION_TAG}"

lout "Copie de l'archive"
#curl -L "${DOWNLOAD_URL}" -o "${TEMP_DIR_ARCHIVE}" || eout "Le téléchargement de l'archive a échoué"
sudo cp "$ROOT_DIR/install/$NOM_ARCHIVE_UPDATE" "${TEMP_DIR_ARCHIVE}"

lout "Backup de l'ancienne version"
sudo mv "${INSTALL_DIR}" "${BACKUP_DIR}"
sudo mkdir -p "${INSTALL_DIR}"

lout "décompression de l'archive"
sudo tar -xzf "${TEMP_DIR_ARCHIVE}" -C "${INSTALL_DIR}" --strip-components=1 || {
    fout "Impossible de décompresser l'archive, elle n'est peut être pas au format .tar.gz, ou peut-être corrompue."
    recover_last_version
    eout "La mise a jour a échoué."
}
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
update_conteur(){
    local update_script_path="${ROOT_DIR}/install/update.sh"
    [ -z "${ROOT_DIR}" ] && eout "update_conteur() : La variable globale ROOT_DIR doit être initialiser avant l'apel de la fonction."
    [ ! -f "${update_script_path}" ] && eout "update_conteur() : Le script de mise à jour est introuvable."
    
    wout "Attention, la fonction est encore expérimentale !"
    sleep 2
    source "${update_script_path}"
    exit 0
}

set_permissions(){
    [[ -z $COMMAND_NAME ]] && fout "set_permissions() : La variable globale COMMAND_NAME doit être initialisée" && return 1
    [[ ! -d $INSTALL_DIR ]] && fout "set_permissions() : Impossible d'appliquer les permissions, la variable globale INSTALL_DIR ne pointe sur aucun fichier" && return 1
    [[ ! $INSTALL_DIR =~ \/conteur.*$ ]] && fout "set_permissions() : La variable globale INSTALL_DIR ne semble pas correspondre à une valeur attendue : ${INSTALL_DIR}" && return 1

    sudo find "${INSTALL_DIR}" -type d -exec chmod 751 {} +
    sudo find "${INSTALL_DIR}" -type f -exec chmod 644 {} +
    sudo find "${INSTALL_DIR}" -type d \( -name "templates" -o -name "deprecated" -o -name "lib" \) -exec chmod 755 {} +
    sudo chmod 755 "${INSTALL_DIR}/${COMMAND_NAME}.sh" "${INSTALL_DIR}/install/update.sh"
}
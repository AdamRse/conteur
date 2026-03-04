update_conteur(){
    local update_script_path="${ROOT_DIR}/install/update.sh"
    [ -z "${ROOT_DIR}" ] && eout "update_conteur() : La variable globale ROOT_DIR doit être initialiser avant l'apel de la fonction."
    [ ! -f "${update_script_path}" ] && eout "update_conteur() : Le script de mise à jour est introuvable."
    
    wout "Feature à venir prochainement, une V1.0 doit être en mode release pour tester cette fonctionnalité"
    # source "${update_script_path}"
    exit 0
}
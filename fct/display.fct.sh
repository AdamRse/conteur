usage(){
    echo "Usage: ${COMMAND_NAME} [OPTIONS] [NOM_PROJET]"
    echo "Le type de projet doit obligatoirement être spécifié en option."
    echo ""
    echo "Types de projet disponibles :"
    echo "    - Laravel (-l, --laravel)"
    echo ""
    echo "Options:"
    echo "  -h, --help            Afficher cette aide"
    echo "  -l, --laravel         (Obligatoire) Définir le type de projet, comme Laravel"
    echo "  -P, --path [DIR]      Spécifier le répertoire dans lequel créer le projet"
    echo "                            Exemple :"
    echo "                            ${COMMAND_NAME} -lP \"/home/user/projects\" \"my_project\""
    echo "                            Créera les fichiers du projet dans \"/home/user/projects/my_project\""
    echo "  -U, --update          Effectuer une mise à jour"
    echo "  -v, --version         Afficher la version"
    echo "      --debug           Activer le mode debug, plus verbeux"
    echo "      --no-confirm      Ignore la demmande de confirmation des paramètres en début de script"
    exit 0
}

show_version() {
    [ -z "${COMMAND_NAME}" ] && eout "show_version() : La variable gloale COMMAND_NAME n'est pas initialisée"
    [ -z "${VERSION}" ] && eout "show_version() : La variable gloale VERSION n'est pas initialisée"

    echo -e "-------------------------------------------\n[version]\t${COMMAND_NAME} version ${VERSION}\n-------------------------------------------"
}

show_summary() {
    local BOLD='\033[1m'
    local COLOR_2='\033[0;32m'
    local COLOR_3='\033[1;33m'
    local NC='\033[0m'
    
    # --- PARAMÈTRES DE TAILLE ---
    local width=70
    local label_width=25
    # ----------------------------
    
    print_table_row() {
        local label=$1
        local value=$2
        
        # Construction de la partie gauche fixe
        local left_part=$(printf "  %-*s : " "$label_width" "$label")
        
        # Calcul du remplissage dynamique pour la bordure droite
        local used_space=$((${#left_part} + ${#value}))
        local padding=$((width - used_space))
        
        # Sécurité si la valeur est trop longue
        [[ $padding -lt 0 ]] && padding=0

        printf "${COLOR_2}│${NC}%s${COLOR_2}%s%*s│${NC}\n" "$left_part" "$value" "$padding" ""
    }

    # Bordure haute
    echo -e "${COLOR_2}┌$(printf '─%.0s' $(seq 1 $width))┐${NC}"
    
    # Titre centré dynamiquement
    local title="RÉSUMÉ DE LA CONFIGURATION"
    local title_len=${#title}
    local title_space=$(( (width - title_len) / 2 ))
    local title_res=$(( (width - title_len) % 2 )) # Pour gérer les nombres impairs
    printf "${COLOR_2}│${NC}%*s${BOLD}${COLOR_3}%s${NC}%*s${COLOR_2}│${NC}\n" "$title_space" "" "$title" "$((title_space + title_res))" ""
    
    echo -e "${COLOR_2}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"
    
    # Lignes du tableau
    print_table_row "Nom du projet" "${PROJECT_NAME}"
    print_table_row "Type d'application" "${PROJECT_TYPE}"
    print_table_row "Répertoire racine" "${PROJECTS_DIR}"

    echo -e "${COLOR_2}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"
    
    # Chemin complet
    echo -e "${COLOR_2}│${NC}  ${BOLD}Chemin complet :${NC}$(printf '%*s' $((width - 18)) "")${COLOR_2}│${NC}"
    
    local path_display="${PROJECT_PATH}"
    if [ ${#path_display} -gt $((width - 4)) ]; then
        path_display="...${path_display: -$((width - 7))}"
    fi
    local path_pad=$((width - ${#path_display} - 2))
    echo -e "${COLOR_2}│${NC}  ${path_display}$(printf '%*s' $path_pad "")${COLOR_2}│${NC}"
    
    # Bordure basse
    echo -e "${COLOR_2}└$(printf '─%.0s' $(seq 1 $width))┘${NC}"
}
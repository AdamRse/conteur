PARSED_OPTIONS=$(getopt -o lP: --long laravel,path: -n "$0" -- "$@")

# On vérifie si getopt a rencontré une erreur
if [ $? -ne 0 ]; then
    eout "L'interpreteur de commande n'a pas fonctionné"
fi

# Réorganisation des arguments pour le parsing
eval set -- "$PARSED_OPTIONS"

while true; do
    case "$1" in
        -l|--laravel)
            PROJECT_TYPE="laravel"
            shift
            ;;
        -P|--path)
            PROJECTS_DIR="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            eout "Erreur interne de parsing"
            ;;
    esac
done

# Gestion de l'argument obligatoire (PROJECT_NAME) qui reste après les options
if [ -n "$1" ]; then
    PROJECT_NAME="$1"
fi

# --- Validation des paramètres obligatoires ---
if [ -z "$PROJECT_TYPE" ]; then
    eout "Erreur : L'option -l ou --laravel est obligatoire."
fi

if [ -z "$PROJECT_NAME" ]; then
    fout "Erreur : Le nom du projet est obligatoire."
    eout "Usage: $0 --laravel [options] 'nom_du_projet'"
fi

PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"
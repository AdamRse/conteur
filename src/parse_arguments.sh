PARSED_OPTIONS=$(getopt -o hlUP: --long laravel,updatehelp,debug,no-confirm,path: -n "${0}" -- "${@}")

if [ $? -ne 0 ]; then
    eout "L'interpreteur de commande n'a pas fonctionné"
fi

eval set -- "${PARSED_OPTIONS}"

while true; do
    case "${1}" in
        -h|--help)
            usage
            ;;
        -l|--laravel)
            PROJECT_TYPE="laravel"
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --no-confirm)
            CONFIRM_OPTIONS=false
            shift
            ;;
        -U|--update)
            update_conteur
            exit 0
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

# -- CHECKS --
PROJECT_NAME="${1}"

if [ -z "${PROJECT_TYPE}" ]; then
    eout "Le type de projet doit être défini. Pour créer un projet laravel, utiliser l'option -l ou --laravel."
fi

if [ -z "${PROJECT_NAME}" ]; then
    eout "Le nom du projet est obligatoire.\n\tUsage :\n\t${COMMAND_NAME} --laravel [options] 'nom_du_projet'"
fi

PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"
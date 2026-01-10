# return null|string
check_packages_requirements() {
    if ! command -v docker &> /dev/null; then
        eout "Docker n'est pas installé"
    fi
    if ! command -v curl &> /dev/null; then
        eout "curl n'est pas installé"
    fi
    if ! command -v jq &> /dev/null; then
        eout "jq n'est pas installé. Installez-le avec: sudo apt install jq"
    fi
    if ! command -v envsubst >/dev/null 2>&1; then
        eout "envsubst n'est pas disponible. Installez-le avec : sudo apt install gettext-base"
    fi
}

# return null
set_directory() {
    if [ -n "$PJ" ]; then
        debug_ "Dev architecture détectée"
        if [ ! -d "${PJ}" ]; then
            wout "Le répertoire ${PJ} n'existe pas"
        fi
        project_dir="$PJ"
    fi
}

# return bool
check_project_type() {
    [ -z "$1" ] && eout "check_project_type() : Aucun nom de projet passé."
    
    local $project_name_check = $1

    [ -d "${script_dir}/templates/${project_name_check}" ] || eout "Type de projet ${project_name_check} inconnu. Aucun template associé pour ce type de projet."
    [ -f "${script_dir}/lib/${project_name_check}.lib.sh" ] || eout "Type de projet ${project_name_check} inconnu. Aucune bibliothèque associé pour ce type de projet."
}

# $1 : <name>             : obligatoire : Nom exact du fichier à copier. La fonction ira chercher dans ./templates/$project_type/$nom.template
# $2 : <output directory> : obligatoire : Répertoire absolu dans lequel copier le fichier (le nom est déduit de $1)
# $3 : [variables name]   : optionnel   : Tableau (séparateur Espace) avec le nom des variables exclusives (sans le $) à remplacer dans le template. Sinon les variables trouvées sont remplacées par une chaîne vide dans le template.
copy_file_from_template() {
    debug_ "copy_file_from_template() : paramètres passés :\n\t- \$1 : ${1}\n\t- \$2 : ${2}\n\t- \$3 : ${3}"
    local file_name=$1
    local output_dir=$2
    local variables_name=$3
    local destination_file_path="${output_dir}/${file_name}"

    # CHECKS
    [ -z "${file_name}" ] && eout "copy_file_from_template() : Impossible de copier le template, aucun nom de fichier donné en premier paramètre."
    [ -z "${output_dir}" ] && eout "copy_file_from_template() : Impossible de copier le template, aucun répertoire de sortie donné en deucième paramètre."

    # Vérification de l'existance du répertoire de destination
    if [ ! -d "${output_dir}" ]; then
        if ask_yn "Le répertoire dans lequel copier le fichier ${file_name} n'a pas été trouvé dans '${output_dir}'. Création du répertoire ou abandon du script : Faut-il créer le répertoire ?"; then
            mkdir -p "${output_dir}" || eout "La création du répertoire a échoué, droit probablement insuffisants. Abandon..."
        else
            eout "Le répertoire cible ne sera pas créé, Abandon..."
        fi
    fi

    # Vérification de l'existance d'un fichier destination
    if [ -f "${destination_file_path}" ]; then
        wout "${file_name} détecté dans '${output_dir}'"
        if ! ask_yn "La procédure continuera en cas de refus, le fichier ${file_name} sera simplement ignoré. Faut-il écraser le fichier ${file_name} existant ?"; then
            lout "Le fichier ${file_name} existe déjà, l'utilisateur préfère garder la version existante, ${file_name} est ignoré."
            return 0
        fi
    fi

    # Obtention du template associé à $file_name --
    local template_name_possibilities_by_priority=(
        "${script_dir}/templates/${project_type}/custom/${file_name}"
        "${script_dir}/templates/${project_type}/custom/${file_name}.template"
        "${script_dir}/templates/${project_type}/default/${file_name}.template"
    )
    local found_template_path=""
    for template_path in "${template_name_possibilities_by_priority[@]}"; do
        if [ -f "${template_path}" ]; then
            found_template_path="$template_path"
            debug_ "Template ${found_template_path} trouvé pour le fichier ${file_name}"
            break
        fi
    done
    [ -z "${found_template_path}" ] && eout "copy_file_from_template() : Le nom du fichier donné en premier paramère '${file_name}' n'a aucun template associé dans './templates/${project_type}/custom ou default'. Abandon..."
    # --

    # Export des variables et construction de $envsubst_exported_vars pour envsubst
    local envsubst_exported_vars=""
    # Si des variables à exporter sont passées en 3ème paramètre, on les exporte et on les intègre dans la chaine qui servira
    if [ -n "${variables_name}" ]; then
        debug_ "export des variables : ${variables_name} pour prise en compte dans le remplacement dynamique du template"
        for var_name in $variables_name
        do
            if [ -n "${!var_name}" ]; then
                export $var_name
                envsubst_exported_vars="\$$var_name ${envsubst_exported_vars}"
                debug_ "variable \$${var_name} exportée"
            else
                fout "La variable '$var_name' passée en 3ème paramètre de 'copy_file_from_template()' ne pointe sur aucune valeur, elle est ignoré et ne modifiera pas le template. Vérifiez le nom de la variable passée à 'copy_file_from_template()', elle doit comporter une erreur de nom."
            fi
        done
    fi

    # ÉCRITURE DU TEMPLATE
    lout "Création du fichier ${file_name} dans ${output_dir}"
    if [ -z "${envsubst_exported_vars}" ]; then
        debug_ "Aucune variable dynamique donné, le template sera copié tel quel."
        debug_ "copie de '${found_template_path}' à '${destination_file_path}'"
        cp "${found_template_path}" "${destination_file_path}"
    else
        debug_ "Variables dynamiques à rempalcer dans le template : ${envsubst_exported_vars}"
        debug_ "envsubst : copie de '${found_template_path}' à '${destination_file_path}'"
        if envsubst "${envsubst_exported_vars}" < "$found_template_path" > "$destination_file_path"; then
            sout "${file_name} créé !"
            return 0
        else
            fout "copy_file_from_template() : envsubst n'a pas pu créer le fichier '${file_name}' à partir du template ${found_template_path}"
            return 1
        fi
    fi
}
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

check_project_type() {
    [ -z "$1" ] && eout "check_project_type() : Aucun nom de projet passé."
    
    local $project_name_check = $1

    [ -d "${script_dir}/templates/${project_name_check}" ] || eout "Type de projet ${project_name_check} inconnu. Aucun template associé pour ce type de projet."
    [ -f "${script_dir}/lib/${project_name_check}.lib.sh" ] || eout "Type de projet ${project_name_check} inconnu. Aucune bibliothèque associé pour ce type de projet."
}

# $1 : <name>             : obligatoire : Nom exact du fichier à copier. La fonction ira chercher dans ./templates/$project_type/$nom.template
# $2 : <output directory> : obligatoire : Répertoire dans lequel copier le fichier (le nom est déduit de $1)
# $3 : [variables name]   : optionnel   : Tableau (séparateur Espace) avec le nom des variables exclusives (sans le $) à remplacer dans le template. Sinon les variables trouvées sont remplacées par une chaîne vide dans le template.
copy_file_from_template() {
    debug_ "copy_file_from_template() : paramètres passés :\n\t- \$1 : ${1}\n\t- \$2 : ${2}\n\t- \$3 : ${3}"
    local variables_name=$3

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




    # ------------------------------------------------------------------------------------------------

    lout "Création du dockerfile (${project_dockerfile_path})"
    if [ -f "${project_dockerfile_path}" ]; then
        wout "Dockerfile détecté dans '${project_dockerfile_path}'"
        ask_yn "Faut-il écraser le Dockerfile existant ?"
    fi

    if envsubst '$PHP_VERSION' < "$dockerfile_template_path" > "$project_dockerfile_path"; then # Ajouter les variables à remplacer, sinon envsubst remplace les variables inconues
        sout "Dockerfile créé dans $project_dockerfile_path"
        return 0
    else
        fout "${laravel_script_name} laravel_create_dockerfile() : envsubst n'a pas pu créer le Dockerfile à partir du template ${dockerfile_template_path}"
        return 1
    fi
}
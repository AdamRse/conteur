debug "md.docker.sh Création du projet Laravel ${LARAVEL_VERSION} avec PHP ${PHP_VERSION} dans : ${project_dir}"
[ -z "${LARAVEL_VERSION}" ] && eout "cmd.docker.sh : La variable 'LARAVEL_VERSION' doit être initialisée."
[ -z "${PHP_VERSION}" ] && eout "cmd.docker.sh : La variable 'PHP_VERSION' doit être initialisée."
[ -z "${project_dir}" ] && eout "cmd.docker.sh : La variable 'project_dir' doit être initialisée."
    
docker run --rm \
    -v "${project_dir}:/app" \
    -w /app \
    -u "$(id -u):$(id -g)" \
    php:${PHP_VERSION}-cli \
    bash -c "composer create-project laravel/laravel . \"${LARAVEL_VERSION}.*\" --prefer-dist"

if [ $? -eq 0 ]; then
    sout "✅ Projet Laravel créé avec succès."
else
    eout "❌ Erreur lors de la création du projet."
fi
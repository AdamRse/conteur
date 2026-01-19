debug_ "md.docker.sh Création du projet Laravel :\n\tLaravel : ${LARAVEL_VERSION}\n\tPHP : ${PHP_VERSION}\n\tRépertoire : ${project_dir}\n\tNom du projet : ${project_name}"
[ -z "${LARAVEL_VERSION}" ] && eout "cmd.docker.sh : La variable 'LARAVEL_VERSION' doit être initialisée."
[ -z "${PHP_VERSION}" ] && eout "cmd.docker.sh : La variable 'PHP_VERSION' doit être initialisée."
[ -z "${project_dir}" ] && eout "cmd.docker.sh : La variable 'project_dir' doit être initialisée."
[ -z "${project_name}" ] && eout "cmd.docker.sh : La variable 'project_name' doit être initialisée."

IMAGE_TAG="2-php${PHP_VERSION}"
    
docker run --rm \
    -v "${project_dir}:/app" \
    -w /app \
    -u "$(id -u):$(id -g)" \
    composer/composer:latest-php${PHP_VERSION} \
    composer create-project laravel/laravel "${project_name}" "${LARAVEL_VERSION}" --prefer-dist

if [ $? -eq 0 ]; then
    sout "Projet Laravel créé avec succès."
else
    eout "Docker a échoué à créer le projet"
fi
debug_ "md.docker.sh Création du projet Laravel :\n\tLaravel : ${LARAVEL_VERSION}\n\tPHP : ${PHP_VERSION}\n\tRépertoire : ${PROJECTS_DIR}\n\tNom du projet : ${PROJECT_NAME}"
[ -z "${LARAVEL_VERSION}" ] && eout "cmd.docker.sh : La variable 'LARAVEL_VERSION' doit être initialisée."
[ -z "${PHP_VERSION}" ] && eout "cmd.docker.sh : La variable 'PHP_VERSION' doit être initialisée."
[ -z "${PROJECTS_DIR}" ] && eout "cmd.docker.sh : La variable 'PROJECTS_DIR' doit être initialisée."
[ -z "${PROJECT_NAME}" ] && eout "cmd.docker.sh : La variable 'PROJECT_NAME' doit être initialisée."

IMAGE_TAG="2-php${PHP_VERSION}"
    
docker run --rm \
    -v "${PROJECTS_DIR}:/app" \
    -w /app \
    -u "$(id -u):$(id -g)" \
    composer/composer:latest-php${PHP_VERSION} \
    composer create-project laravel/laravel "${PROJECT_NAME}" "${LARAVEL_VERSION}" --prefer-dist

if [ $? -eq 0 ]; then
    sout "Projet Laravel créé avec succès."
else
    eout "Docker a échoué à créer le projet"
fi
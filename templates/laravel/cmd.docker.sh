# -- VARIABLES GLOBALES DISPONIBLES --

# ${LARAVEL_VERSION}    : Version de laravel:latest (Exemple "12.1.1.0")
# ${PHP_VERSION}        : Version de PHP requise pour laravel:latest (Exemple "8.4")

# ${PROJECT_NAME}       : Nom du projet, PATH friendly
# ${PROJECTS_DIR}       : Emplacement local où créer le répertoire du projet (Exemple "/home/user/projets")
# ${PROJECT_PATH}       : Emplacement local du répertoire du projet qui contient les fichiers du projet (Exemple "/home/user/projets/nom_projet")

# --

# -- COMMANDE(S) DOCKER A EFFECTUER

# DEBUG TEMPORAIRE
mkdir -p "${PROJECT_PATH}"
echo "<h1>Nouveau Projet ${PROJECT_NAME}</h1><p>Page de test pour le projet ${PROJECT_PATH}, debug temporaire</p>" > "${PROJECT_PATH}/index.html"

mkdir -p "${PROJECT_PATH}/config"
echo "Fichier de config" > "${PROJECT_PATH}/config/conf.json"

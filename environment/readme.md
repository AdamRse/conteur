# ./environment
Contient les variables d'environement susceptibles d'être passées aux templates pour créer les fichiers.

## Ajout d'une variable d'environement
Il est préférable de créer un nouveau fichier `env` sans supprimer `env.default`. Les variable dans un nouveau fichier remplaceront les variables par défaut.

Pour toutes nouvelles variables qui doit être chargée dans un template, il faudra s'assurer de l'ajouter dans le `envsubst` qui copie le template.
Par exemple pour un nouveau projet laravel, pour ajouter une variable d'environement `LARAVEL_PORT` qui change le port exposé du conteneur, il faudra :
- Aréer un fichier dans `./environment/`
- Dans ce fichier, ajouter une variable `LARAVEL_PORT=3333`
- Identifier les fichiers et paramètres à modifier :
    - On veut changer le port d'exposition du dockerfile, donc modifier le template `templates/laravel/Dockerfile.template`, on remplace `EXPOSE 9000` par `EXPOSE ${LARAVEL_PORT}`.
    - Ajouter `$LARAVEL_PORT` dans la fonction qui lit le template avec `envsubst`, ici c'est `laravel_create_dockerfile()` dans `lib/laravel.lib.sh`. On avait : `envsubst '$PHP_VERSION' ...`, on ajoute la variable `LARAVEL_PORT` : `envsubst '$PHP_VERSION $LARAVEL_PORT' ...`

La variable du dockerfile sera bien prisz en compte !
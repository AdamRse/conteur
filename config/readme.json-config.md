# Fichiers de configuration JSON

Il y a 3 fichiers de configuration possibles : `config/default.json`, `config/custom.json` et `./config.json` (à la racine).

Il est conseillé de ne pas modifier `default.json`, mais uniquement `custom.json`. Les fichiers sont fusionnés par le script : **l'ordre de priorité est `./config.json` > `config/custom.json` > `config/default.json`.**

## Subtilité de configuration

Il est possible d'ajouter des valeurs dynamiques (variables globales bash) mises à disposition par les bibliothèques dans `/lib`.

Les variables sont consultables dans chaque fichier bibliothèque `lib/<bibliothèque>.lib.sh`, dans la section `-- GLOBALS AVAILABLES --` au début du fichier.

## Exemple d'utilisation de variables

J'ai un template `Dockerfile.template` dans lequel je veux créer une image à partir de la version de PHP requise pour la dernière version Laravel.

1. Dans `templates/laravel/custom/Dockerfile.template`, j'écris la ligne : `FROM php:${PHP_LARAVEL_LATEST}-fpm`.
2. Dans `config/custom.json`, je demande à remplacer `${PHP_LARAVEL_LATEST}` dans le fichier généré par la version de PHP fournie par la bibliothèque `lib/laravel.lib.sh`.
3. Pour ce faire, je définis la variable `PHP_LARAVEL_LATEST` dans la section `variables` du fichier concerné, et je lui assigne `${PHP_VERSION}` (variable fournie par Conteur) :
```json
{
    "projects": {
        "laravel": {
            "files": [
                {
                    "selected": true,
                    "template": "Dockerfile",
                    "variables": {
                        "PHP_LARAVEL_LATEST": "${PHP_VERSION}"
                    }
                }
            ]
        }
    }
}
```
Une fois le script lancé, le `Dockerfile` sera généré en remplaçant `${PHP_LARAVEL_LATEST}` par la valeur réelle contenue dans `${PHP_VERSION}` !

## Aide des sections du JSON de configuration

- `settings.default_project_dir` : (optionnel) Répertoire où seront créés les projets.
    - `projects` : Contient la configuration par type de projet.
- `<bibliothèque>`: Options relatives à la création d'un projet avec la bibliothèque nommée (par ex : `laravel`).
    - `settings.project_docker_files_dir` : Répertoire de destination des fichiers Docker (relatif au projet).
    - `settings.sail` : Configuration de Laravel Sail.
        - `useSail` : Booléen. Si `false`, les options Sail sont ignorées.
        - `devcontainer` : Booléen, ajoute le support Devcontainer.
        - `services` : Liste des services Sail (mysql, pgsql, redis, etc.) à activer (`true`/`false`).
    - `files` : Liste des templates à traiter. Chaque objet de la liste contient :
        - `template` : **(Obligatoire)** Nom du template (ex: `nginx.conf`).
        - `selected` : Booléen. Si `false`, le fichier n'est pas généré.
        - `custom_filename` : (optionnel) Nom différent pour le fichier de destination.
        - `custom_project_dir` : (optionnel) Écrase le répertoire de destination par défaut pour ce fichier précis.
        - `variables` : Paires Clé/Valeur pour le remplacement textuel. Les variables Bash comme `${PROJECT_NAME}` sont interprétées.

## Liste exhaustive des variables globales disponibles par bibliothèque

Ces variables sont utilisables partout dans vos templates ou dans les valeurs du JSON :

- **Variables communes (tous projets) :**
    - `${PROJECT_NAME}` : Nom que vous avez donné au projet.
    - `${PROJECT_PATH}` : Chemin complet vers le dossier du projet.
- **Pour la bibliothèque Laravel :**
    - `${LARAVEL_VERSION}` : Dernière version stable de Laravel détectée.
    - `${PHP_VERSION}` : Version de PHP recommandée pour cette version de Laravel.
# Fichiers de configuration JSON
Il  y a 2 fichiers de configuration : `config/default.json` et `config/custom.json`  
Il est conseillé de ne pas modifier `default.json`, mais uniquement `custom.json`. Les 2 JSON seront fusionnés : **les données de `custom.json` sont prioritaires.**
## Subtilité de configuration
Il est possible d'ajouter des valeurs dynamiques (variables global bash) disponibles mises à disposition par les bibliothèques `/lib`.  

Les variables sont consultables dans fichier bibliothèque `lib/<bibliothèque>.lib.sh`, dans la section `-- GLOBALS AVAILABLES --`, placée au début, ou dans la section `Liste exhaustive des variables gloabal disponibles ` à la fin de ce fichier.
## Exemple d'utilisation de variables
J'ai un template `Dockerfile.template` dans lequel je veux créer une image à partir de la version de PHP requise pour la dernière version Laravel.
- Dans `templates/laravel/custom/Dockerfile.template`, j'écris la ligne : `FROM php:${PHP_LARAVEL_LATEST}-fpm`.
- Dans `config/custom.json`, je demmande alors de remplacer `${PHP_LARAVEL_LATEST}` dans le template `Dockerfile` créé, par la version de PHP que met à disposition la bibliothèque `lib/laravel.lib.sh`.
- Pour le faire, je définis la variable `PHP_LARAVEL_LATEST` ce JSON, et demmande de la rempalcer par `PHP_VERSION`, fourni par la bibliothèque laravel, dans `.projects.laravel.templates.Dockerfile.variables[]` :
```json
{
    "projects":{
        "laravel":{
            "templates":{
                "Dockerfile":{
                    "variables":{
                        "PHP_LARAVEL_LATEST":"${PHP_VERSION}"
                    }
                }
            }
        }
    }
}
```
- Il n'y a plus qu'a lancer le script, et le Dockerfile sera généré à partir du template, en remplaçant `PHP_LARAVEL_LATEST` par la version de php `PHP_VERSION` fournie par la bibliothèque Laravel !
## Aide des sections du JSON de configuration
- `settings.default_projects_dir` : (optionnel) Répertoire où seront créé les projets
- `projects` : Liste des bibliothèques disponibles
    - `laravel`: Options relatives à la création d'un projet laravel
        - `project_docker_files_dir` : Répertoire par défaut des templates dans le projet (chemin relatif au projet)
        - `sail` : Configurations de laravel Sail au lieu d'utiliser le système de templates. Si `false`, aucune des option sail ne seront lues.
            - `useSail` : Booléen, configurations de laravel Sail au lieu d'utiliser le système de templates
            - `devcontainer` : Booléen, ajout de decontainer au projet
            - `services` : Options relatives à la création d'un projet via laravel sail, quelle base techno utiliser.
                - `mysql` : Booléen, utiliser mysql
                - `pgsql` : Booléen, utiliser pgsql
                - `mariadb` : Booléen, utiliser mariadb
                - `redis` : Booléen, utiliser redis
                - `memcached` : Booléen, utiliser memcached
                - `meilisearch` : Booléen, utiliser meilisearch
                - `minio` : Booléen, utiliser minio
                - `selenium` : Booléen, utiliser selenium
                - `mailpit` : Booléen, utiliser mailpit
    - `laravel.templates` : Options relative à l'écriture depuis les templates définis dans `templates/laravel/default` et `templates/laravel/custom`
        - `<nom de fichier>` : Le nom du template, sensible à la case, à configurer. Obligatoire pour tout template à utiliser.
            - `selected` : Booléen, `false` ignore ce template et n'écrira pas de fichier dans le projet relatif à ce template.
            - `project_path` : (optionel) Répertoire dans lequel écrire le fichier issu du template, écrase l'option `projects.projects.project_docker_files_dir` si défini. Pour la racine du projet, utiliser `/`, `.` ou `./`
            - `variables` : Variables du templates à remplacer dans l'écriture du fichier. Peut être un texte ou une variable bash globale définie par la bibliothèque associée. La variable bash sera interprétée. Voir la section `Liste exhaustive des variables gloabal disponibles par bibliothèque`
    
## Liste exhaustive des variables gloabal disponibles par bibliothèque
- pour la bibliothèque laravel :
    - `${LARAVEL_VERSION}` : Dernière version stable de Laravel
    - `${PHP_VERSION}` : Version de PHP associée à la dernière version stable de laravel
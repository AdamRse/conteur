# Ajouter une bibliothèque pour un nouveau type de projet conteur
## Marche à suivre
Ajouter un répertoire dans `./lib` du nom du type de projet, attention le nom du répertoire est important pour trouver la bibliothèque.  
Il est très conseillé de s'inspirer de `./lib/laravel` pour comprendre le fonctionnement d'une bibliothèque.
### Architecture
```
lib/<nouveau_type>/
├── cmd.docker.sh
├── main.lib.sh 
└── templates
    ├── docker-compose.yml.template # Exemple de templates par défaut
    ├── Dockerfile.template
    └── nginx.conf.template
```
- `cmd.docker.sh` Ensemble commandes pour créer le nouveau projet avec des technologies à jour.
- `main.lib.sh ` Script qui défini des variables globales liées au type de projet et qui executera `cmd.docker.sh`. Doit contenir la fonction `create_project()` qui sera appelée par conteur.
- `templates` Répertoire où sont stockés les templates par défaut, si l'utilisateur n'a pas créé de templates personnalisés.
> [!NOTE]
> Le nom des templates est important, il donnera son nom aux fichiers générés si l'utilisateur ne les définis pas
### default.json
Pour activer la nouvelle bibliothèque, il faut mettre à jour `./config/default.json` :
- Ajouter un nouveau champ dans `.projects`. Attention, le nom de ce champ doit correspondre exactement au nom de la bibliothèque que vous avez créé dans `./lib`. conteur se sert de ce champ pour aller chercher la bibliothèque correspondante dans `./lib`
    - Par exemple : `"projects":{ ... ,"<nouveau_type>":{ }}`
- Ajouter les options (settings), avec un champ `project_docker_files_dir`, pour spécifier où seront copiés par défaut les fichiers. Si vide, alors ce sera la racine du projet. Vous pouvez ajouter ici des options dont vous avez besoin pour votre bibliothèque.
    - Par exemple : 
    ```json
    "projects":{ ... 
        ,"<nouveau_type>":{
            "settings":{
                "project_docker_files_dir":".docker/development"
            }
        }}
    ```
- Ajouter les templates par défaut avec un nouveau tableau d'objets `.files[]`
    - Par exemple :
    ```json
    "projects":{ ... 
        ,"<nouveau_type>":{
            "settings":{
                "project_docker_files_dir":".docker/development"
            }
            ,"files":[
                # templates par défaut
            ]
        }}
    ```
- Chaque tempalte par défaut doit contenir les champs :
    - `"selected"` : Booléen, permet de sélectionner ou déselectionner le template
    - `"template"` : Nom du template associé, sans l'extension `.template`
    - `"custom_filename"` (optionel) : Nom fichier de destination copiés dans le projet, à partir du template. Par défaut, même nom que le template
    - `"custom_project_dir"` (optionel)  : répertoire relatif au projet où sera copié le fichier à partir du template. Par défaut c'est `.projects.<nouveau_type>.settings.project_docker_files_dir` qui s'applique. Si aussi vide, c'est la racine du projet.
        - Pour cibler la racine : `.`, `./` ou `/` fonctionnent
    - `"variables"` (optionel) : Contiendra les variables à remplacer dans le template lors de la copie, s'il y en a. Les valeurs du script bash peuvent être utilisées, elles seront interprétées par bash.
        - Exemple : `"variables":{ "PROJECT_NAME":"${PROJECT_NAME}", "AUTHOR":"your name" }`, dans le template ciblé :
            - `$PROJECT_NAME` sera remplacé par le nom du projet (variable globale de conteur) lors de la copie dans le projet.
            - `$AUTHOR` sera remplacé par `your name` lors de la copie dans le projet.
Aperçu complet de l'exemple :
```json
{
    "settings":{
        "default_project_dir":""
    }
    ,"projects":{
            "<nouveau_type>":{
                "settings":{
                    "project_docker_files_dir":".docker/development"
                    ,"my_settings":{
                        "author":"me"
                    }
                }
                ,"files":[
                    {
                        "selected":true
                        ,"template":"docker-compose.yml"
                        ,"custom_filename":"docker-compose.yaml"
                        ,"custom_project_dir":"./"
                        ,"variables":{
                            "PROJECT_NAME":"${PROJECT_NAME}"
                        }
                    }
                    ,{
                        "selected":true
                        ,"template":"Dockerfile"
                        ,"custom_filename":""
                        ,"custom_project_dir":""
                        ,"variables":{
                            "PROJECT_NAME":"${PROJECT_NAME}"
                            ,"PHP_VERSION":"${PHP_VERSION}"
                        }
                    }
                ]
            }
        }
}
```
### Ajouter un exemple pour l'utilisateur
L'utilisateur peut avoir besoin de personnaliser la commande `cmd.docker.sh`. Pour l'aider, un fichier sera généré dans son dossier de configuration, et vous pouvez en préciser l'utilisation avec des commentaires. Par exemple pour spécifier les variables globales rendues disponibles par votre nouvelle bibliothèque. 

Vous n'avez qu'à créer un fichier `./config/cmd.docker.<nouveau_type>.example`, remplacez `<nouveau_type>` par le nom exact de votre bibliothèque dans le json `config/default.json`. 
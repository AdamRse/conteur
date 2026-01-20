# Conteur

**Conteur** est un script bash qui permet de créer et configurer automatiquement des projets web dans un environnement conteneurisé Docker, avec les technologies les plus récentes, sans avoir besoin d'installer de dépendances localement (hormis Docker).

## Pourquoi Conteur ?

- ✅ **Environnement isolé** : Développez sur n'importe quelle machine sans installer de dépendances
- ✅ **Versions à jour** : Utilise automatiquement les dernières versions stables des frameworks
- ✅ **Configurations prêtes** : Docker, Nginx, et autres fichiers de configuration générés automatiquement
- ✅ **Extensible** : Architecture modulaire permettant d'ajouter facilement de nouveaux types de projets
- ✅ **Personnalisable** : Système de templates et configuration JSON flexible

## Prérequis

- Docker installé sur votre machine
- Bash (Linux/macOS ou WSL sur Windows)

## Installation

```bash
# Clonez ou téléchargez le projet conteur
git clone <url-du-repo> conteur
cd conteur

# Rendez le script exécutable
chmod +x conteur.sh
```

## Utilisation de base

### Syntaxe

```bash
./conteur.sh [OPTIONS] [NOM_PROJET]
```

### Types de projet disponibles

Actuellement, Conteur supporte :
- **Laravel** (`-l`, `--laravel`)

### Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Afficher l'aide |
| `-l`, `--laravel` | Créer un projet Laravel (obligatoire pour spécifier le type) |
| `-P`, `--path [DIR]` | Spécifier le répertoire de destination du projet |
| `--debug` | Activer le mode debug (sortie plus verbeuse) |
| `--no-confirm` | Ignorer la demande de confirmation des paramètres |

### Exemples

```bash
# Créer un projet Laravel nommé "mon_blog"
./conteur.sh --laravel mon_blog

# Créer un projet dans un répertoire spécifique
./conteur.sh -l -P "/home/user/projets" mon_blog

# Créer un projet sans confirmation
./conteur.sh -l --no-confirm mon_api
```

## Configuration

### Fichiers de configuration

Conteur utilise deux fichiers de configuration JSON :

- **`config/default.json`** : Configuration par défaut (ne pas modifier)
- **`config/custom.json`** : Configuration personnalisée (prioritaire)

Les deux fichiers sont fusionnés automatiquement, **`custom.json` étant prioritaire**.

### Configuration de base

#### Répertoire des projets

```json
{
    "settings": {
        "default_projects_dir": "/chemin/vers/mes/projets"
    }
}
```

#### Configuration Laravel

##### Utiliser Laravel Sail

```json
{
    "PROJECT_TYPE": {
        "laravel": {
            "sail": {
                "useSail": true,
                "devcontainer": false,
                "services": {
                    "mysql": true,
                    "redis": true,
                    "mailpit": true,
                    "pgsql": false,
                    "mariadb": false,
                    "memcached": false,
                    "meilisearch": false,
                    "minio": false,
                    "selenium": false
                }
            }
        }
    }
}
```

##### Utiliser le système de templates

```json
{
    "PROJECT_TYPE": {
        "laravel": {
            "sail": {
                "useSail": false
            },
            "project_docker_files_dir": "docker",
            "templates": {
                "Dockerfile": {
                    "selected": true,
                    "PROJECTS_DIR": "docker",
                    "variables": {
                        "PHP_LARAVEL_LATEST": "${PHP_VERSION}"
                    }
                },
                "docker-compose.yml": {
                    "selected": true
                },
                "nginx.conf": {
                    "selected": true,
                    "PROJECTS_DIR": "docker/nginx"
                }
            }
        }
    }
}
```

## Système de templates

### Fonctionnement

Les templates permettent de générer automatiquement les fichiers Docker nécessaires au projet.

### Emplacement des templates

```
templates/laravel/
├── cmd.docker.sh              # Commandes Docker à exécuter
├── custom/                    # Templates personnalisés (prioritaires)
│   └── readme.md
└── default/                   # Templates par défaut
    ├── Dockerfile.template
    ├── docker-compose.yml.template
    └── nginx.conf.template
```

### Ordre de priorité

Conteur recherche les templates dans l'ordre suivant :

1. `templates/laravel/custom/MonFichier.template`
2. `templates/laravel/custom/MonFichier`
3. `templates/laravel/default/MonFichier.template`

### Créer un template personnalisé

#### Étape 1 : Créer le fichier template

Créez votre fichier dans `templates/laravel/custom/` avec l'extension `.template` :

```bash
# Exemple : templates/laravel/custom/Dockerfile.template
FROM php:${PHP_LARAVEL_LATEST}-fpm

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    && docker-php-ext-install pdo_mysql
```

#### Étape 2 : Configurer le template dans custom.json

```json
{
    "PROJECT_TYPE": {
        "laravel": {
            "templates": {
                "Dockerfile": {
                    "selected": true,
                    "PROJECTS_DIR": "docker",
                    "variables": {
                        "PHP_LARAVEL_LATEST": "${PHP_VERSION}"
                    }
                }
            }
        }
    }
}
```

#### Étape 3 : Générer le projet

Lancez conteur et le fichier sera créé avec les variables remplacées !

### Variables disponibles

Les templates peuvent utiliser des variables globales fournies par les bibliothèques.

#### Variables Laravel (`lib/laravel.lib.sh`)

| Variable | Description | Exemple |
|----------|-------------|---------|
| `${LARAVEL_VERSION}` | Dernière version stable de Laravel | `12.1.1.0` |
| `${PHP_VERSION}` | Version de PHP pour Laravel latest | `8.4` |
| `${PROJECTS_DIR}` | Répertoire de destination des projets | `/home/user/projets` |
| `${PROJECT_PATH}` | Chemin complet du projet | `/home/user/projets/mon_projet` |

### Configuration des templates

Pour chaque template, vous pouvez définir :

```json
{
    "NomDuTemplate": {
        "selected": true,                    // false = ignore ce template
        "PROJECTS_DIR": "chemin/destination", // Où écrire le fichier
        "variables": {                       // Variables à remplacer
            "MA_VARIABLE": "${PHP_VERSION}"
        }
    }
}
```

## Commandes Docker personnalisées

Le fichier `templates/laravel/cmd.docker.sh` contient les commandes Docker à exécuter lors de la création du projet.

Vous pouvez le personnaliser selon vos besoins. Les variables globales y sont disponibles :

```bash
# Exemple de cmd.docker.sh
docker run --rm \
    -v ${PROJECT_PATH}:/app \
    -w /app \
    composer create-project laravel/laravel:${LARAVEL_VERSION} .
```

## Structure du projet

```
conteur/
├── conteur.sh                 # Script principal
├── config/                    # Configuration JSON
│   ├── default.json
│   ├── custom.json
│   └── readme.md
├── lib/                       # Bibliothèques par type de projet
│   └── laravel.lib.sh
├── fct/                       # Fonctions utilitaires
│   ├── common.fct.sh
│   └── terminal-tools.fct.sh
├── src/                       # Code source
│   └── parse_arguments.sh
├── templates/                 # Templates par type de projet
│   └── laravel/
│       ├── cmd.docker.sh
│       ├── custom/
│       └── default/
└── readme.md
```

## Dépannage

### Mode debug

Pour diagnostiquer un problème, utilisez le mode debug :

```bash
./conteur.sh --laravel --debug mon_projet
```

### Vérifier les templates utilisés

Le mode debug affiche quels templates sont chargés et dans quel ordre.

### Problèmes courants

- **Docker non installé** : Vérifiez que Docker est installé et en cours d'exécution
- **Permissions** : Assurez-vous que `conteur.sh` est exécutable (`chmod +x conteur.sh`)
- **Variables non remplacées** : Vérifiez la syntaxe dans `custom.json` et que les variables existent dans la bibliothèque

## Contribuer

Conteur est conçu pour être extensible. Pour ajouter un nouveau type de projet :

1. Créez une bibliothèque dans `lib/monframework.lib.sh`
2. Ajoutez les templates dans `templates/monframework/default/`
3. Configurez les options dans `config/default.json`

## Licence

Ce projet est sous licence **GNU GPL v3**. 
Consultez le fichier [LICENSE](LICENSE) pour plus de détails

## Auteur

Adam Rousselle

---

**Note** : Ce projet est en développement actif. D'autres types de projets seront ajoutés prochainement.
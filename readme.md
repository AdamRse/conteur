# Conteur Beta version

**Conteur** est un outil en ligne de commande qui permet de créer et configurer automatiquement des projets web dans un environnement conteneurisé Docker, avec les technologies les plus récentes, sans avoir besoin d'installer de dépendances localement (hormis Docker).

## Pourquoi Conteur ?

- ✅ **Environnement isolé** : Développez sur n'importe quelle machine sans installer de dépendances
- ✅ **Versions à jour** : Utilise automatiquement les dernières versions stables des frameworks
- ✅ **Configurations prêtes** : Docker, Nginx, et autres fichiers de configuration générés automatiquement
- ✅ **Extensible** : Architecture modulaire permettant d'ajouter facilement de nouveaux types de projets
- ✅ **Personnalisable** : Système de templates et configuration JSON flexible

## Prérequis

- **Système d'exploitation** : Linux (testé sur Debian/Ubuntu)
- **Docker** installé et fonctionnel
- **Bash** 4.0 ou supérieur

> ⚠️ **Note** : Conteur n'est actuellement pas compatible avec Windows (même WSL) ou macOS. Seules les distributions Linux sont supportées.
> La version actuelle est en bêta et en cours de développement

## Installation

### Installation automatique

```bash
# Clonez le dépôt
git clone <url-du-repo> conteur
cd conteur

# Lancez le script d'installation
chmod +x install.sh
sudo ./install.sh
```

Le script d'installation vous proposera deux options :

1. **Installation globale** (`/opt/conteur`) : Recommandée pour une utilisation système
2. **Installation locale** (répertoire actuel) : Utile pour le développement ou les tests

Après l'installation, la commande `conteur` sera disponible globalement dans votre terminal.

### Installation manuelle

Si vous préférez ne pas utiliser le script d'installation :

```bash
# Clonez le dépôt
git clone <url-du-repo> conteur
cd conteur

# Rendez le script exécutable
chmod +x conteur.sh

# Utilisez le script directement
./conteur.sh [OPTIONS] [NOM_PROJET]
```

### Personnalisation du répertoire d'installation

Pour installer Conteur dans un répertoire personnalisé, déplacez simplement le dépôt à l'emplacement souhaité avant de lancer `install.sh` et choisissez l'installation locale.

## Utilisation de base

### Syntaxe

```bash
conteur [OPTIONS] [NOM_PROJET]
```

Ou si vous n'avez pas utilisé le script d'installation :

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
conteur --laravel mon_blog

# Créer un projet dans un répertoire spécifique
conteur -l -P "/home/user/projets" mon_blog

# Créer un projet sans confirmation
conteur -l --no-confirm mon_api

# Mode debug pour diagnostiquer les problèmes
conteur --laravel --debug mon_projet
```

## Configuration

### Fichiers de configuration

Conteur utilise deux fichiers de configuration JSON situés dans le répertoire `config/` :

- **`config/default.json`** : Configuration par défaut (ne pas modifier)
- **`config/custom.json`** : Configuration personnalisée (prioritaire, non versionné)

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
    "projects": {
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
    "projects": {
        "laravel": {
            "sail": {
                "useSail": false
            },
            "project_docker_files_dir": "docker",
            "templates": {
                "Dockerfile": {
                    "selected": true,
                    "project_path": "docker",
                    "variables": {
                        "PHP_LARAVEL_LATEST": "${PHP_VERSION}"
                    }
                },
                "docker-compose.yml": {
                    "selected": true
                },
                "nginx.conf": {
                    "selected": true,
                    "project_path": "docker/nginx"
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
    "projects": {
        "laravel": {
            "templates": {
                "Dockerfile": {
                    "selected": true,
                    "project_path": "docker",
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
        "project_path": "chemin/destination", // Où écrire le fichier
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
├── install.sh                 # Script d'installation
├── global.var.sh              # Variables globales (nom de commande)
├── config/                    # Configuration JSON
│   ├── default.json           # Configuration par défaut
│   ├── custom.json            # Configuration utilisateur (non versionné)
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
│       │   └── readme.md
│       └── default/
│           ├── Dockerfile.template
│           ├── docker-compose.yml.template
│           └── nginx.conf.template
└── readme.md
```

## Dépannage

### Mode debug

Pour diagnostiquer un problème, utilisez le mode debug :

```bash
conteur --laravel --debug mon_projet
```

### Vérifier les templates utilisés

Le mode debug affiche quels templates sont chargés et dans quel ordre.

### Problèmes courants

- **Docker non installé** : Vérifiez que Docker est installé et en cours d'exécution avec `docker --version`
- **Permissions** : Si l'installation échoue, vérifiez que vous avez les droits sudo
- **Commande non trouvée après installation** : Vérifiez que `/usr/local/bin` est dans votre PATH avec `echo $PATH`
- **Variables non remplacées** : Vérifiez la syntaxe dans `custom.json` et que les variables existent dans la bibliothèque
- **Incompatibilité système** : Conteur ne fonctionne que sur Linux

### Désinstallation

Pour désinstaller Conteur :

```bash
# Si installation globale
sudo rm -rf /opt/conteur
sudo rm /usr/local/bin/conteur

# Si installation locale
# Supprimez simplement le répertoire du projet
```

## Contribuer

Conteur est conçu pour être extensible. Pour ajouter un nouveau type de projet :

1. Créez une bibliothèque dans `lib/monframework.lib.sh`
2. Ajoutez les templates dans `templates/monframework/default/`
3. Configurez les options dans `config/default.json`
4. Mettez à jour `src/parse_arguments.sh` pour gérer les nouvelles options

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

Ce projet est sous licence **GNU GPL v3**. 
Consultez le fichier [LICENSE](LICENSE) pour plus de détails.

## Auteur

Adam Rousselle

---

**Note** : Ce projet est en développement. D'autres types de projets et le support d'autres systèmes d'exploitation seront ajoutés prochainement.
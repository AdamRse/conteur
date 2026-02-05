# Conteur

Un outil en ligne de commande écrit en Bash pour générer des projets web dockerisés à partir de templates, conçu pour démarrer rapidement sans installer de dépendances (hormis Docker).

## 📋 Description

**Conteur** est orienté pour la création de nouveaux projets dockerisés dans la phase de développement. L'objectif initial est de ne pas avoir à installer de dépendances pour commencer un projet web (à part Docker), et d'avoir automatiquement les dernières technologies disponibles.

Pour l'instant, le projet ne supporte que Laravel, mais Conteur est conçu pour ajouter d'autres types de projets facilement, suivant l'avancement du développement.

## ✨ Fonctionnalités

- 🚀 Création rapide de projets Laravel dockerisés
- 📦 Aucune dépendance à installer (sauf Docker)
- 🔧 Système de templates personnalisables
- ⚙️ Configuration flexible via fichiers JSON
- 🎯 Support optionnel de Laravel Sail
- 🔄 Architecture extensible pour d'autres frameworks

## 🚀 Installation

### Installation globale (recommandée)

```bash
git clone <url-du-repo> /chemin/vers/conteur
cd /chemin/vers/conteur
./install.sh
# Répondre OUI à "Installer conteur de manière globale ?"
```

Conteur sera installé dans `/opt/conteur` et sera accessible globalement via la commande `conteur`.

### Installation locale

```bash
git clone <url-du-repo> /chemin/vers/conteur
cd /chemin/vers/conteur
./install.sh
# Répondre NON à "Installer conteur de manière globale ?"
```

### Utilisation sans installation

```bash
git clone <url-du-repo> /chemin/vers/conteur
cd /chemin/vers/conteur
./conteur.sh [OPTIONS] [NOM_PROJET]
```

## 📖 Usage

```bash
conteur [OPTIONS] [NOM_PROJET]
```

Le type de projet doit obligatoirement être spécifié en option.

### Types de projet disponibles

- **Laravel** : `-l`, `--laravel`

### Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Afficher l'aide |
| `-l`, `--laravel` | (Obligatoire) Définir le type de projet comme Laravel |
| `-P`, `--path [DIR]` | Spécifier le répertoire dans lequel créer le projet |
| `--debug` | Activer le mode debug, plus verbeux |
| `--no-confirm` | Ignorer la demande de confirmation des paramètres en début de script |

### Exemples

```bash
# Créer un projet Laravel dans le répertoire courant
conteur -l mon_projet

# Créer un projet Laravel dans un répertoire spécifique
conteur -l -P "/home/user/projects" mon_projet

# Créer un projet sans confirmation
conteur -l --no-confirm mon_projet

# Mode debug
conteur -l --debug mon_projet
```

## ⚙️ Configuration

Conteur utilise un système de configuration JSON flexible avec fusion de fichiers.

### Fichiers de configuration

- `config/default.json` : Configuration par défaut (ne pas modifier)
- `config/custom.json` : Configuration personnalisée (recommandé)
- `./config.json` : Configuration alternative à la racine

**Ordre de priorité** : `./config.json` > `config/custom.json` > `config/default.json`

### Créer une configuration personnalisée

Il est recommandé de créer un fichier `config/custom.json` plutôt que de modifier `config/default.json`.

**Exemple de `config/custom.json` :**

```json
{
  "settings": {
    "default_project_dir": "/home/user/mes-projets"
  },
  "projects": {
    "laravel": {
      "settings": {
        "project_docker_files_dir": ".docker/dev",
        "sail": {
          "useSail": true,
          "devcontainer": true,
          "services": {
            "mysql": true,
            "redis": true,
            "mailpit": true
          }
        }
      },
      "files": [
        {
          "selected": true,
          "template": "docker-compose.yml",
          "custom_filename": "docker-compose.yaml",
          "custom_project_dir": "./",
          "variables": {
            "PROJECT_NAME": "${PROJECT_NAME}"
          }
        }
      ]
    }
  }
}
```

### Options de configuration Laravel

#### Settings généraux

- `default_project_dir` : Répertoire par défaut pour créer les projets
- `project_docker_files_dir` : Répertoire relatif au projet pour les fichiers Docker (par défaut : `.docker/development`)

#### Laravel Sail

- `useSail` : Utiliser Laravel Sail (true/false)
- `devcontainer` : Créer un devcontainer (true/false)
- `services` : Services Docker à inclure (mysql, pgsql, mariadb, redis, memcached, meilisearch, minio, selenium, mailpit)

> ⚠️ **Note** : Si `useSail` est activé mais qu'aucun service n'est à `true`, les options par défaut de Laravel Sail seront appliquées.

#### Configuration des fichiers

Chaque fichier template peut être configuré avec :

- `selected` : Copier le fichier ou l'ignorer (true/false)
- `template` : Nom du template (l'extension `.template` est optionnelle)
- `custom_filename` : Nom personnalisé pour le fichier de destination (optionnel)
- `custom_project_dir` : Répertoire de destination relatif au projet (optionnel)
- `variables` : Variables à remplacer dans le template (optionnel)

## 📁 Architecture du projet

```
.
├── config/                     # Fichiers de configuration
│   ├── default.json           # Configuration par défaut
│   └── readme.md
├── conteur.sh                 # Point d'entrée principal
├── fct/                       # Fonctions utilitaires
│   ├── common.fct.sh
│   └── terminal-tools.fct.sh
├── install.sh                 # Script d'installation
├── lib/                       # Bibliothèques par type de projet
│   └── laravel.lib.sh
├── LICENSE
├── readme.md
├── src/                       # Sources
│   └── parse_arguments.sh
├── templates/                 # Templates de fichiers
│   └── laravel/
│       ├── cmd.docker.sh      # Commandes Docker
│       ├── custom/            # Templates personnalisés (prioritaires)
│       │   └── readme.md
│       └── default/           # Templates par défaut
│           ├── docker-compose.yml.template
│           ├── Dockerfile.template
│           └── nginx.conf.template
└── test.sh
```

## 🎨 Créer des templates personnalisés

Les templates personnalisés doivent être placés dans `templates/laravel/custom/` et sont prioritaires sur les templates par défaut.

### Convention de nommage

- Le template doit terminer par l'extension `.template` (recommandé, prioritaire)
- Le nom du fichier servira de base pour le fichier de destination

### Ordre de priorité des templates

Lors de la recherche d'un template, Conteur vérifie dans cet ordre :

1. `templates/laravel/custom/monTemplate.template`
2. `templates/laravel/custom/monTemplate`
3. `templates/laravel/default/monTemplate.template`

### Variables disponibles dans les templates

Les variables suivantes sont disponibles dans tous les templates :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `${LARAVEL_VERSION}` | Version de Laravel | `12.1.1.0` |
| `${PHP_VERSION}` | Version de PHP requise | `8.4` |
| `${PROJECT_NAME}` | Nom du projet | `mon_projet` |
| `${PROJECTS_DIR}` | Répertoire parent du projet | `/home/user/projets` |
| `${PROJECT_PATH}` | Chemin complet du projet | `/home/user/projets/mon_projet` |

### Exemple de template personnalisé

**Fichier : `templates/laravel/custom/docker-compose.yml.template`**

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${PROJECT_NAME}_app
    volumes:
      - ./:/var/www/html
    environment:
      - PHP_VERSION=${PHP_VERSION}
```

## 🔧 Fichier cmd.docker.sh

Le fichier `templates/laravel/cmd.docker.sh` contient les commandes Docker à exécuter pour créer le projet. Il peut être modifié selon vos besoins.

### Variables globales disponibles

Les mêmes variables que dans les templates sont disponibles dans ce fichier.

## 📄 Licence

Ce projet est sous licence **GPL 3.0**.

## 👤 Auteur

**Adam Rousselle**

---

**Note** : D'autres types de projets seront ajoutés progressivement selon l'avancement du développement.
# Conteur

**Version 1.0** | Licence GPL 3.0 | Par Adam Rousselle

Conteur est un outil en ligne de commande pour créer des projets web dockerisés avec les dernières technologies disponibles. Sa particularité : générer ses propres fichiers dans le projet à partir de templates dynamiques personnalisables.

## État du projet

✅ Supporté : Laravel  
🚧 En développement : Autres frameworks (à venir)

## Installation

### Prérequis
- Linux (Ubuntu 24 ou similaire)
- Accès root

### Procédure

1. Téléchargez l'archive depuis [les releases GitHub](https://github.com/votre-repo/conteur/releases)
2. Extrayez l'archive
3. Exécutez le script d'installation en tant que root :
```bash
sudo ./install/install.sh
```

Le programme s'installera dans `/usr/local/share/conteur` avec un lien symbolique dans `/usr/local/bin/`.

> **Note** : La fonctionnalité d'auto-update sera disponible en version 1.1

## Utilisation

### Syntaxe de base
```bash
conteur [OPTIONS] [NOM_PROJET]
```

### Options disponibles

| Option | Description |
|--------|-------------|
| `-h, --help` | Afficher l'aide |
| `-l, --laravel` | **[Obligatoire]** Créer un projet Laravel |
| `-P, --path [DIR]` | Spécifier le répertoire de destination du projet |
| `-U, --update` | Effectuer une mise à jour |
| `-V, --version` | Afficher la version |
| `--debug` | Activer le mode debug (plus verbeux) |
| `--no-confirm` | Ignorer la demande de confirmation des paramètres |

### Exemples

Créer un projet Laravel dans le répertoire courant :
```bash
conteur --laravel mon_projet
```

Créer un projet Laravel dans un répertoire spécifique :
```bash
conteur -lP "/home/user/projects" mon_projet
```

## Configuration

### Fichiers de configuration

Conteur utilise un système de configuration JSON flexible :

- **Fichier par défaut** : `config/default.json` (ne pas modifier)
- **Fichier utilisateur** : `~/.config/conteur/config.json` (personnalisable)

Le fichier utilisateur a la priorité et fusionne avec le fichier par défaut.

### Structure de configuration utilisateur
```
~/.config/conteur/
├── config.json
└── laravel/
    ├── cmd.docker.sh (optionnel)
    └── templates/ (optionnel)
        ├── docker-compose.yml
        └── Dockerfile
```

### Exemple de configuration

Voici un exemple de `config.json` pour Laravel :
```json
{
  "settings": {
    "default_project_dir": "/home/user/projects"
  },
  "projects": {
    "laravel": {
      "settings": {
        "project_docker_files_dir": ".docker/development",
        "sail": {
          "useSail": false,
          "devcontainer": true,
          "services": {
            "mysql": false,
            "pgsql": false,
            "mariadb": false,
            "redis": false
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

## Templates personnalisés

### Créer un nouveau template

1. Créez votre template dans `~/.config/conteur/laravel/templates/`
2. Nommez-le avec l'extension `.template` (ex: `Dockerfile.template`)
3. Utilisez des variables bash dans le template : `$VARIABLE` ou `${VARIABLE}`
4. Déclarez le template dans votre `config.json`

### Variables disponibles

Dans vos templates, vous pouvez utiliser ces variables globales :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `${PROJECT_NAME}` | Nom du projet | `mon_projet` |
| `${PROJECT_PATH}` | Chemin complet du projet | `/home/user/projets/mon_projet` |
| `${PROJECTS_DIR}` | Répertoire parent des projets | `/home/user/projets` |
| `${LARAVEL_VERSION}` | Version de Laravel | `12.1.1.0` |
| `${PHP_VERSION}` | Version de PHP requise | `8.4` |

### Exemple : Ajouter un Dockerfile personnalisé

**1. Créez le template** : `~/.config/conteur/laravel/templates/Dockerfile.template`
```dockerfile
FROM php:${PHP_VERSION}-fpm

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Installation des extensions PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définir le répertoire de travail
WORKDIR /var/www/html

# Copier les fichiers du projet
COPY . .

# Installation des dépendances Laravel
RUN composer install --no-interaction --optimize-autoloader

EXPOSE 9000
CMD ["php-fpm"]
```

**2. Ajoutez-le dans votre config.json** :
```json
{
  "projects": {
    "laravel": {
      "files": [
        {
          "selected": true,
          "template": "Dockerfile",
          "custom_filename": "Dockerfile",
          "custom_project_dir": ".docker/development",
          "variables": {
            "PROJECT_NAME": "${PROJECT_NAME}",
            "PHP_VERSION": "${PHP_VERSION}"
          }
        }
      ]
    }
  }
}
```

**Résultat** : Conteur générera automatiquement un Dockerfile avec la bonne version de PHP pour votre projet Laravel.

### Configuration du template

Chaque template dans `files[]` accepte ces propriétés :

| Propriété | Type | Description |
|-----------|------|-------------|
| `selected` | booléen | Active ou désactive le template |
| `template` | string | Nom du fichier template (sans `.template`) |
| `custom_filename` | string | Nom du fichier final (optionnel) |
| `custom_project_dir` | string | Répertoire de destination (optionnel, `.` pour la racine) |
| `variables` | objet | Variables à remplacer dans le template |

### Ordre de priorité des templates

Conteur recherche les templates dans cet ordre :

1. `~/.config/conteur/laravel/templates/mon-template.template`
2. `~/.config/conteur/laravel/templates/mon-template`
3. Templates par défaut de Conteur

## Personnalisation avancée

### Commande Docker personnalisée

Pour personnaliser la création du projet Docker, créez le fichier :
`~/.config/conteur/laravel/cmd.docker.sh`

Toutes les variables globales de Conteur y sont disponibles. Consultez `config/cmd.docker.laravel.example` pour un exemple commenté.

## Dépannage

### Mode debug

Activez le mode debug pour plus d'informations :
```bash
conteur --laravel --debug mon_projet
```

### Réinitialiser la configuration

Supprimez votre configuration utilisateur pour revenir aux paramètres par défaut :
```bash
rm -rf ~/.config/conteur/
```

## Licence

GPL 3.0 - Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Contribution

Les contributions sont les bienvenues ! Consultez le guide de développement pour plus d'informations.

---

**Note** : Ce README concerne l'utilisation de Conteur. Pour contribuer au développement, consultez la documentation développeur séparée.
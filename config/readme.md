# cmd.docker.sh
Les fichier `cmd.docker.sh` servent à créer le projet du type voulu, avec une commande docker.
- `lib/<bibliothèque>/cmd.docker.sh` : Commande par défaut, si l'utilisateur ne personnalise pas sa propre commande
- `~/.config/conteur/<bibliothèque>/cmd.docker.sh` : Commande personnalisée, utilisée par l'utilisateur. Si le fichier est vide ou similaire à `config/cmd.docker.*.example`, il sera ignoré, c'est `lib/<bibliothèque>/cmd.docker.sh` qui servira à créer le projet.
- `config/cmd.docker.all.example` : Template utilisé pour donner un exemple d'utilisation et des instructions à l'utilisateur
- `config/cmd.docker.<bibliothèque>.example` Template utilisé pour donner un exemple d'utilisation et des instructions à l'utilisateur pour une bibliothèque précise. Si ce template existe pour la bibliothèque, alors il sera priorisé.
- Les fichiers `config/cmd.docker.*.example` sont copiés par défaut dans `~/.config/conteur/<bibliothèque>/cmd.docker.sh` correspondant, pour donner un exemple ou des instructions d'utilisatuion à l'utilisateur.
# Ajouter un fichier d'exemple de commande
Les fichiers `config/cmd.docker.*.example` seront utilisés comme fichiers d'exemple dans le répertoire de configuration (par défaut dans `~/.config/conteur`, configurable avec la variable `CONFIG_DIR` dans le .env).  
Lors de la création d'une nouvelle bibliothèque (`/lib`), il est conseillé de donner un exemple d'utilisation avec un fichier `config/cmd.docker.<bibliothèque>.example` associé.
- **Règle de nommage** : `config/cmd.docker.<bibliothèque>.example`  
    - `<bibliothèque>` doit correspondre au nom d'un champ `.projects.<bibliothèque>` dans `config/default.json`
- Si `config/cmd.docker.<bibliothèque>.example` n'est pas trouvé, c'est `config/cmd.docker.all.example` qui sera pris en exemple.
- Si aucun fichier existe, aucun fichier d'exemple ne sera créé

> [!NOTE]
> - Si le fichier `config/cmd.docker.<bibliothèque>.example` correspond à `~/.config/conteur/<bibliothèque>/cmd.docker.sh`, ce qui est le cas par défaut, alors le fichier de configuration `~/.config/conteur/<bibliothèque>/cmd.docker.sh` sera ignoré, c'est `lib/<bibliothèque>/cmd.docker.sh` qui sera utilisé.  
> - Le fichier `~/.config/conteur/<bibliothèque>/cmd.docker.sh` sera considéré comme un exemple non modifié par l'utilisateur, et ne sera pas pris en compte.  
> - La comparaison entre `~/.config/conteur/<bibliothèque>/cmd.docker.sh` et `config/cmd.docker.<bibliothèque>.example` ne prend pas en compte les modifications d'espaces ou de saut de ligne
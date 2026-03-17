# main.lib.sh
Fichier executé à l'appel de la bibliothèque. Il doit impérativement contenur la fonction `create_project`, appelée par le script principal, et lancera la création de projet.

# cmd.docker.sh
Les fichier `cmd.docker.sh` servent à créer le projet du type voulu, avec une commande docker.  
Il est conseillé d'ajouter des commentaires pour détailler les variables globales disponibles dans la bibliothèque. Ce fichier est copié dans les fichiers de configutation utilisateur, et personalisable. 

### deprecated.cmd.docker.sh
En cas de mise à jour de `cmd.docker.sh`, une fonction a été implémentée pour suprimer l'ancienne version, sans risquer de suprimer un script personnalisé de l'utilisateur.  
`deprecated.cmd.docker.sh` permet de donner le modèle obsolète qui doit être supprimé. Si l'utilisateur a personnalisé son script, il ne sera pas remplacé.

# templates/
Contient les templates dynamiques qui seront utilisés par `copy_files_from_template()` dans `fct/common.fct.sh`.  
Par défaut, les templates donneront leur nom au fichier, débarassé de l'extension `.template`, sauf su un nom de fichier est précisé dans le json de config pour le fichier.  
Le template peux contenir des variables bash qui seront interprétées, c'est tout l'enjeu des templates dynamiques.

### templates/deprecated/
Avec la même logique que `deprecated.cmd.docker.sh`, il est possible de spécifier des templates à remplacer. Les templates ne sont pas mis à jour par défaut car il peut s'agir de templates personalisés par l'utilisateur.  
Pour spécifier qu'un template utilisateur est obsolète, il faut déplacer le template obsolète dans ce répertoire, et ajouter un nouveau template du même nom dans `templates/`
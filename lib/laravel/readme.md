# main.lib.sh
Fichier executé à l'appel de la bibliothèque. Il doit impérativement contenur la fonction `create_project`, appelée par le script principal, et lancera la création de projet.

# cmd.docker.sh
Les fichier `cmd.docker.sh` servent à créer le projet du type voulu, avec une commande docker.  
Il est conseillé d'ajouter des commentaires pour détailler les variables globales disponibles dans la bibliothèque. Ce fichier est copié dans les fichiers de configutation utilisateur, et personalisable.

# templates/
Contient les templates dynamiques qui seront utilisés par `copy_files_from_template()` dans `fct/common.fct.sh`.  
Par défaut, les templates donneront leur nom au fichier, débarassé de l'extension `.template`, sauf su un nom de fichier est précisé dans le json de config pour le fichier.  
Le template peux contenir des variables bash qui seront interprétées, c'est tout l'enjeu des templates dynamiques.
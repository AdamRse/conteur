# Fichiers de configuration
Le fichier de configuration contient les variables personnalisées du template dynamique associé. Les variables du fichier template seront remplacées par les variables correspondantes contenues dans le fichier de configuration associé.
## Convention
**Nom de fichier** : Il doit correspondre au nom du template associé, sensible à la case, en remplaçant l'extension `.template` par `.conf`. En cas de différence de nom, il ne sera pas executé pour le template associé.  
La correspondance d'un fichier `.conf` avec un fichier `.template` ne sera recherchée que dans le même type de projet (Par exemple `laravel`).  
> Exemple :
> - **Template** : `templates/laravel/custom/Dockerfile.template`  
> - Nommage du **fichier de configuration** associé : `templates/laravel/conf/Dockerfile.conf`  
> Respect du même type de projet (`laravel`) et du même nom de fichier soustrait de l'extension (`Dockerfile`)

> [!NOTE]
> Le fichier de configuration est executé par l'interpreteur ***bash***, il doit donc respecter les règles de nommage des variables ***bash***.
> En cas d'erreur dans le script, les variables seront ignorée et un message d'erreur affiché.
---
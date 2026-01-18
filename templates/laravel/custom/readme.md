# Templates custom
Les templates personalisables sont créés ici par l'utilisateur. Ils ont le même comportement que les templates par défaut, mais sont prioritaires.
## Convention
- Le template doit terminer par l'extension `.template` (conseillé, prioritaire) et avoir de nom de fichier exact qui servira au fichier de destination.  
- Les variables du template seront remplacées par les variables du JSON de configuration `config/default.json` et `config/custom.json`.
## Configuration JSON
Il  y a 2 fichiers de configuration : `config/default.json` et `config/custom.json`  
Il est conseillé de ne pas modifier `default.json`, mais uniquement `custom.json`. Les 2 JSON seront fusionnés : **les données de `custom.json` sont prioritaires.**
## Exemple
Je créé un template `templates/laravel/custom/MonTemplate.template`, les variables de ce template seront rempalcées par les variables du fichier de configuration `config/default.json` et `config/custom.json`.
> [!NOTE]
> L'ordre des priorités des templates est le suivant :
> - `templates/laravel/custom/monTemplate.template`
> - `templates/laravel/custom/monTemplate`
> - `templates/laravel/default/monTemplate.template`
>
> Prioritées définies par `fct/common.fct.sh` -> `find_template_from_name()` -> `local template_path_possibility_by_priorities`
# Templates custom
Les templates personalisables sont créés ici par l'utilisateur. Ils ont le même comportement que les templates par défaut, mais sont prioritaires.
## Convention
- Le template doit terminer par l'extension `.template` (conseillé) et avoir de nom de fichier exact qui servira au fichier de destination.  
- Les variables du template seront remplacées par les variables du fichier de configuration `templates/<type projet>/conf/<nom template>.conf`  
## Exemple
Je créé un template `templates/laravel/custom/MonTemplate.template`, les variables de ce tempalte seront rempalcées par les variables du fichier de configuration `templates/laravel/conf/MonTemplate.conf`

> [!NOTE]
> L'ordre des priorités des templates est le suivant :
> - `templates/laravel/custom/monTemplate.template`
> - `templates/laravel/custom/monTemplate`
> - `templates/laravel/default/monTemplate.template`
>
> Prioritées définies par `fct/common.fct.sh` -> `copy_file_from_template()` -> `local template_name_possibilities_by_priority`
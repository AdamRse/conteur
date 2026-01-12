Note :
Le type de projet dans la variable $project_type (par ex: laravel) doit absolument avoir une Correspondance dans ./lib et ./templates/ dans le ./lib/$project_type.lib.sh, la fonction create_project() est appelée par le script principal après avoir chargé la bibliothèque dynamiquement.
environement/$project_type doit corresponde aussi, mais ce fichier est optionnel.

templates/laravel/conf
    fichiers qui seront interpretés par bash
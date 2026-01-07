# Prépare les variables et vérifie les fichiers de configuration
# return null
laravel_set_requirments() {
    dockerfile_template_path="${script_dir}/templates/laravel/Dockerfile.template"
    [ -f "${dockerfile_template_path}" ] || eout "Dockerfile laravel non trouvé. Fichier attendu : ${dockerfile_template_path}"
}
# En cas de réussite il est certain qu'on retourne une version laravel et php
# return string|bool
laravel_get_json_latest_info() {
    local packagist_link="https://repo.packagist.org/p2/laravel/laravel.json"
    
    # Récupérer et traduire la réponse JSON
    local json_response=$(curl -s --max-time 10 "${packagist_link}" | jq -r '
        .packages."laravel/laravel"[0] as $p |
        {
            "laravel_version": $p.version_normalized,
            "php_version": ($p.require.php // "" | sub("^\\^"; ""))
        }
    ')

    local version_regex='^[0-9]+(\.[0-9]+)*$'
    if [[ "$(jq -r ".laravel_version" <<< "$json_response")" =~ $version_regex ]] && [[ "$(jq -r ".php_version" <<< "$json_response")" =~ $version_regex ]]; then
        echo $json_response
        return 0
    else
        fout "Échec de récupération des infos sur la dernière version de laravel"
        return 1
    fi
}

laravel_create_dockerfile() {
    echo "ok"
}

laravel_create_docker_compose() {
    echo "ok"
}
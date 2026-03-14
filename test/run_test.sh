#!/bin/bash

cd "$(dirname "$0")/.." || exit 1

echo "🛠️  Construction de l'image de test..."
docker build -t conteur-test -f test/Dockerfile .

echo "🚀 Lancement du conteneur de test..."
docker run -it --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    conteur-test \
    /bin/bash -c "
        echo '--- Environnement de test prêt ---'
        echo 'Pour installer, lance : sudo ./install/install.sh'
        echo '-----------------------------------'
        /bin/bash
    "
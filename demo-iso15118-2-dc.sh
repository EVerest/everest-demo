#!/usr/bin/env bash

DEMO_COMPOSE_FILE_NAME='docker-compose.iso15118-dc.yml'
DEMO_DIR="$(mktemp -d)"

START_OPTION="auto"

delete_temporary_directory() { rm -rf "${DEMO_DIR}"; }
trap delete_temporary_directory EXIT

if [[ ! "${DEMO_DIR}" || ! -d "${DEMO_DIR}" ]]; then
    echo 'Error: Failed to create a temporary directory for the demo.'
    exit 1
fi

download_demo_file() {
    local -r repo_file_path="$1"
    local -r repo_raw_url='https://raw.githubusercontent.com/everest/everest-demo/main'
    local -r destination_path="${DEMO_DIR}/${repo_file_path}"

    mkdir -p "$(dirname ${destination_path})"
    curl -s -o "${destination_path}" "${repo_raw_url}/${repo_file_path}"
    if [[ "$?" != 0 ]]; then
        echo "Error: Failed to retrieve \"${repo_file_path}\" from the demo"
	echo 'repository. If this issue persists, please report this as an'
	echo 'issue in the EVerest project:'
	echo '    https://github.com/EVerest/EVerest/issues'
	exit 1
    fi
}

download_demo_file "${DEMO_COMPOSE_FILE_NAME}"
download_demo_file .env

docker compose --project-name everest-ac-demo \
	       --file "${DEMO_DIR}/${DEMO_COMPOSE_FILE_NAME}" up
docker cp "${DEMO_DIR}/manager/config-sil-dc.yaml"  everest-ac-demo-manager-1:/ext/source/config/config-sil-dc.yaml

if [[ "$START_OPTION" == "auto" ]]; then
  echo "Starting software in the loop simulation automatically"
  docker exec everest-ac-demo-manager-1 sh /ext/build/run-scripts/run-sil-dc.sh
else
  echo "Please start the software in the loop simulation manually by running"
  echo "on your laptop: docker exec -it everest-ac-demo-manager-1 /bin/bash"
  echo "in the container: sh /ext/build/run-scripts/run-sil-dc.sh"
  echo "You can now stop and restart the manager without re-creating the container"
fi

#!/usr/bin/env bash

DEMO_COMPOSE_FILE_NAME='docker-compose.automated-tests.yml'
DEMO_DIR="$(mktemp -d)"

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

#!/usr/bin/env bash

DEMO_COMPOSE_FILE_NAME='docker-compose.ocpp201.yml'
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

    echo "Downloading ${repo_raw_url}/${repo_file_path} to ${destination_path}"

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

echo "Cloning MaEVe CSMS and starting it"
git clone https://github.com/thoughtworks/maeve-csms.git ${DEMO_DIR}/maeve-csms
pushd ${DEMO_DIR}/maeve-csms
download_demo_file "maeve/maeve-csms.patch"
mv ../maeve/maeve-csms.patch .
patch -p1 -i maeve-csms.patch
docker compose up -d
echo "MaEVe CSMS started, adding charge station"

curl http://localhost:9410/api/v0/cs/cp001 -H 'content-type: application/json' \
    -d '{"securityProfile": 0, "base64SHA256Password": "3oGi4B5I+Y9iEkYtL7xvuUxrvGOXM/X2LQrsCwf/knA="}'

echo "Charge station added, adding user token"

curl http://localhost:9410/api/v0/token -H 'content-type: application/json' -d '{
  "countryCode": "GB",
  "partyId": "TWK",
  "type": "RFID",
  "uid": "DEADBEEF",
  "contractId": "GBTWK012345678V",
  "issuer": "Thoughtworks",
  "valid": true,
  "cacheMode": "ALWAYS"
}'

echo "User token added, starting EVerest..."

docker compose --project-name everest-ac-demo \
	       --file "${DEMO_DIR}/${DEMO_COMPOSE_FILE_NAME}" up

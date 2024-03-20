#!/usr/bin/env bash

DEMO_COMPOSE_FILE_NAME='docker-compose.ocpp201.sp2.yml'
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

echo "Cloning EVerest into ${DEMO_DIR}/everest-demo"
cd ${DEMO_DIR}
git clone https://github.com/Everest/everest-demo.git everest-demo

echo "Cloning MaEVe CSMS into ${DEMO_DIR}/maeve-csms and starting it"
git clone https://github.com/thoughtworks/maeve-csms.git maeve-csms
cp everest-demo/manager/cached_certs_correct_name.tar.gz maeve-csms
pushd maeve-csms

echo "Copying certs into ${DEMO_DIR}/maeve-csms/config/certificates"
tar xf cached_certs_correct_name.tar.gz
cat dist/etc/everest/certs/client/csms/CSMS_LEAF.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
  > config/certificates/csms.pem
cat dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
  > config/certificates/trust.pem
cp dist/etc/everest/certs/client/csms/CSMS_LEAF.key config/certificates/csms.key
cp dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem config/certificates/root-V2G-cert.pem

echo "Validating that the certificates are set up correctly"
openssl verify -show_chain \
  -CAfile config/certificates/root-V2G-cert.pem \
  -untrusted config/certificates/trust.pem \
  config/certificates/csms.pem

echo "Starting the CSMS"
docker compose up -d

echo "Waiting 10s for CSMS to start..."
sleep 10

echo "MaEVe CSMS started, adding charge station. Note that profiles in MaEVe start with 0 so SP 0 == OCPP SP 1"
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
popd

pushd everest-demo
docker compose --project-name everest-ac-demo \
	--file "${DEMO_COMPOSE_FILE_NAME}" up -d --wait

ls -al manager

echo "Copying device DB, configured to SecurityProfile: 1"
docker cp manager/device_model_storage_maeve_sp1.db everest-ac-demo-manager-1:/workspace/dist/share/everest/modules/OCPP201/device_model_storage.db

echo "Starting software in the loop simulation"
docker exec -it everest-ac-demo-manager-1 sh /workspace/build/run-scripts/run-sil-ocpp201.sh

# echo "All configuration done, please run 'docker exec -it everest-ac-demo-manager-1 /bin/bash' and then (in the container) 'sh ./build/run-scripts/run-sil-ocpp201.sh'"
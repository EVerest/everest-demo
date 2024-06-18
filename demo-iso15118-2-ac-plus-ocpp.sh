#!/usr/bin/env bash


DEMO_REPO="https://github.com/everest/everest-demo.git"
DEMO_BRANCH="main"

MAEVE_REPO="https://github.com/louisg1337/maeve-csms.git"
# MAEVE_BRANCH="b990d0eddf2bf80be8d9524a7b08029fbb305c7d" # patch files are based on this commit
MAEVE_BRANCH="set_charging_profile"

CITRINEOS_REPO="https://github.com/citrineos/citrineos-core.git"
CITRINEOS_BRANCH="feature/everest-demo"



usage="usage: $(basename "$0") [-r <repo>] [-b <branch>] [-j|1|2|3|c] [-h]

This script will run EVerest ISO 15118-2 AC charging with OCPP demos.

Pro Tip: to use a local copy of this everest-demo repo, provide the current
directory to the -r option (e.g., '-r \$(pwd)').

where:
    -r   URL to everest-demo repo to use (default: $DEMO_REPO)
    -b   Branch of everest-demo repo to use (default: $DEMO_BRANCH)
    -j   OCPP v1.6j
    -1   OCPP v2.0.1 Security Profile 1
    -2   OCPP v2.0.1 Security Profile 2
    -3   OCPP v2.0.1 Security Profile 3
    -c   Use CitrineOS CSMS (default: MaEVe)
    -h   Show this message"


DEMO_VERSION=
DEMO_COMPOSE_FILE_NAME=
DEMO_CSMS=maeve


# loop through positional options/arguments
while getopts ':r:b:j123ch' option; do
  case "$option" in
    r)  DEMO_REPO="$OPTARG" ;;
    b)  DEMO_BRANCH="$OPTARG" ;;
    j)  DEMO_VERSION="v1.6j"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp16j.yml" ;;
    1)  DEMO_VERSION="v2.0.1-sp1"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    2)  DEMO_VERSION="v2.0.1-sp2"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    3)  DEMO_VERSION="v2.0.1-sp3"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    c)  DEMO_CSMS="citrineos" ;;
    h)  echo -e "$usage"; exit ;;
    \?) echo -e "illegal option: -$OPTARG\n" >&2
        echo -e "$usage" >&2
        exit 1 ;;
  esac
done


if [[ ! "${DEMO_VERSION}" ]]; then
  echo 'Error: no demo version option provided.'
  echo
  echo -e "$usage"

  exit 1
fi

DEMO_DIR="$(mktemp -d)"


if [[ ! "${DEMO_DIR}" || ! -d "${DEMO_DIR}" ]]; then
  echo 'Error: Failed to create a temporary directory for the demo.'
  exit 1
fi


delete_temporary_directory() { rm -rf "${DEMO_DIR}"; }
trap delete_temporary_directory EXIT


echo "DEMO REPO:    $DEMO_REPO"
echo "DEMO BRANCH:  $DEMO_BRANCH"
echo "DEMO VERSION: $DEMO_VERSION"
echo "DEMO CONFIG:  $DEMO_COMPOSE_FILE_NAME"
echo "DEMO DIR:     $DEMO_DIR"
echo "DEMO CSMS:    $DEMO_CSMS"


cd "${DEMO_DIR}" || exit 1


echo "Cloning EVerest from ${DEMO_REPO} into ${DEMO_DIR}/everest-demo"
git clone --branch "${DEMO_BRANCH}" "${DEMO_REPO}" everest-demo

if [[ "$DEMO_VERSION" != v1.6j  && "$DEMO_CSMS" == maeve ]]; then
  echo "Cloning ${DEMO_CSMS} CSMS from ${MAEVE_REPO} into ${DEMO_DIR}/${DEMO_CSMS}-csms and starting it"
  git clone --branch "${MAEVE_BRANCH}" "${MAEVE_REPO}" ${DEMO_CSMS}-csms

  pushd maeve-csms || exit 1

  cp ../everest-demo/manager/cached_certs_correct_name_emaid.tar.gz .

  echo "Patching the CSMS to disable load balancer"
  patch -p1 -i ../everest-demo/maeve/maeve-csms-no-lb.patch

  # Set up certificates for SP2 and SP3
  if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
    echo "Copying certs into ${DEMO_DIR}/maeve-csms/config/certificates"
    tar xf cached_certs_correct_name_emaid.tar.gz
    cat dist/etc/everest/certs/client/csms/CSMS_LEAF.pem \
        dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
        dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
      > config/certificates/csms.pem
    cat dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
        dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
      > config/certificates/trust.pem
    cp dist/etc/everest/certs/client/csms/CSMS_LEAF.key config/certificates/csms.key
    cp dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem config/certificates/root-V2G-cert.pem
    cp dist/etc/everest/certs/ca/mo/MO_ROOT_CA.pem config/certificates/root-MO-cert.pem

    echo "Validating that the certificates are set up correctly"
    openssl verify -show_chain \
      -CAfile config/certificates/root-V2G-cert.pem \
      -untrusted config/certificates/trust.pem \
      config/certificates/csms.pem

    echo "Patching the CSMS to enable EVerest organization"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-everest-org.patch

    echo "Patching the CSMS to enable local mo root"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-local-mo-root.patch

    echo "Patching the CSMS to enable local mo root"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-ignore-ocsp.patch

  else
    echo "Patching the CSMS to disable WSS"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-no-wss.patch
  fi

  docker compose build
  docker compose up -d

  echo "Waiting 5s for MaEVe CSMS to start..."
  sleep 5

  if [[ "$DEMO_VERSION" =~ sp1 ]]; then
    echo "MaEVe CSMS started, adding charge station with Security Profile 1 (note: profiles in MaEVe start with 0 so SP-0 == OCPP SP-1)"
    curl http://localhost:9410/api/v0/cs/cp001 -H 'content-type: application/json' \
      -d '{"securityProfile": 0, "base64SHA256Password": "3oGi4B5I+Y9iEkYtL7xvuUxrvGOXM/X2LQrsCwf/knA="}'
  elif [[ "$DEMO_VERSION" =~ sp2 ]]; then
    echo "MaEVe CSMS started, adding charge station with Security Profile 2 (note: profiles in MaEVe start with 0 so SP-1 == OCPP SP-2)"
    curl http://localhost:9410/api/v0/cs/cp001 -H 'content-type: application/json' \
      -d '{"securityProfile": 1, "base64SHA256Password": "3oGi4B5I+Y9iEkYtL7xvuUxrvGOXM/X2LQrsCwf/knA="}'
  elif [[ "$DEMO_VERSION" =~ sp3 ]]; then
    echo "MaEVe CSMS started, adding charge station with Security Profile 3 (note: profiles in MaEVe start with 0 so SP-2 == OCPP SP-3)"
    curl http://localhost:9410/api/v0/cs/cp001 -H 'content-type: application/json' -d '{"securityProfile": 2}'
  fi

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

  curl http://localhost:9410/api/v0/token -H 'content-type: application/json' -d '{"countryCode": "UK", "partyId": "Switch", "contractId": "UKSWI123456789G", "uid": "UKSWI123456789G", "issuer": "Switch", "valid": true, "cacheMode": "ALWAYS"}'

  popd || exit 1
fi


if [[ "$DEMO_VERSION" != v1.6j  && "$DEMO_CSMS" == 'citrineos' ]]; then
  echo "Cloning CitrineOS CSMS from ${CITRINEOS_REPO} into ${DEMO_DIR}/citrineos-csms and starting it"
  git clone --branch "${CITRINEOS_BRANCH}" "${CITRINEOS_REPO}" citrineos-csms

  pushd citrineos-csms || exit 1

  cp ../everest-demo/manager/cached_certs_correct_name_emaid.tar.gz .

  mkdir -p Server/data/certificates

  echo "Copying certs into ${DEMO_DIR}/citrineos-csms/Server/data/certificates"
  tar xf cached_certs_correct_name_emaid.tar.gz

  # Leaf key
  cp dist/etc/everest/certs/client/csms/CSMS_LEAF.key Server/data/certificates/leafKey.pem

  #Cert chain
  cat dist/etc/everest/certs/client/csms/CSMS_LEAF.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
  > Server/data/certificates/certChain.pem

  # SubCA
  cp dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.key Server/data/certificates/subCAKey.pem

  #TrustedSubCAChain
  cat dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
  > Server/data/certificates/rootCertificate.pem

  #ACME key
  cp ../everest-demo/citrineos/acme_account_key.pem Server/data/certificates/acme_account_key.pem

  pushd Server || exit 1
  echo "Starting the CitrineOS CSMS"
  cat ./docker-compose.yml
  docker compose -f ./docker-compose.yml build
  if ! docker compose --project-name citrineos-csms -f ./docker-compose.yml up -d --wait; then
      echo "Failed to start CitrineOS."
      exit 1
  fi

  echo "Adding a charger to CitrineOS"
  ../../everest-demo/citrineos/add-charger.sh

  popd || exit 1
  popd || exit 1

fi

pushd everest-demo || exit 1
echo "API calls to CSMS finished, Starting everest"
docker compose --project-name everest-ac-demo --file "${DEMO_COMPOSE_FILE_NAME}" up -d --wait
docker cp config-sil-ocpp201-pnc.yaml  everest-ac-demo-manager-1:/ext/source/config/config-sil-ocpp201-pnc.yaml
if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
  docker cp manager/cached_certs_correct_name_emaid.tar.gz everest-ac-demo-manager-1:/ext/source/build
  docker exec everest-ac-demo-manager-1 /bin/bash -c "pushd /ext/source/build && tar xf cached_certs_correct_name_emaid.tar.gz"

  echo "Configured everest certs, validating that the chain is set up correctly"
  docker exec everest-ac-demo-manager-1 /bin/bash -c "pushd /ext/source/build && openssl verify -show_chain -CAfile dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem dist/etc/everest/certs/client/csms/CSMS_LEAF.pem"
fi

if [[ "$DEMO_CSMS" == 'maeve' ]]; then
  if [[ "$DEMO_VERSION" =~ sp1 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 1"
    docker cp manager/device_model_storage_maeve_sp1.db \
      everest-ac-demo-manager-1:/ext/source/build/dist/share/everest/modules/OCPP201/device_model_storage.db
  elif [[ "$DEMO_VERSION" =~ sp2 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 2"
    docker cp manager/device_model_storage_maeve_sp2.db \
      everest-ac-demo-manager-1:/ext/source/build/dist/share/everest/modules/OCPP201/device_model_storage.db
  elif [[ "$DEMO_VERSION" =~ sp3 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 3"
    docker cp manager/device_model_storage_maeve_sp3.db \
      everest-ac-demo-manager-1:/ext/source/build/dist/share/everest/modules/OCPP201/device_model_storage.db
  fi
fi

if [[ "$DEMO_CSMS" == 'citrineos' ]]; then
  if [[ "$DEMO_VERSION" =~ sp1 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 1"
    docker cp manager/device_model_storage_citrineos_sp1.db \
      everest-ac-demo-manager-1:/ext/source/build/dist/share/everest/modules/OCPP201/device_model_storage.db
  elif [[ "$DEMO_VERSION" =~ sp2 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 2"
    docker cp manager/device_model_storage_citrineos_sp2.db \
      everest-ac-demo-manager-1:/ext/source/build/dist/share/everest/modules/OCPP201/device_model_storage.db
  elif [[ "$DEMO_VERSION" =~ sp3 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 3"
    docker cp manager/device_model_storage_citrineos_sp3.db \
      everest-ac-demo-manager-1:/ext/source/build/dist/share/everest/modules/OCPP201/device_model_storage.db
  fi
fi

if [[ "$DEMO_VERSION" =~ v2.0.1 ]]; then
  echo "Starting software in the loop simulation"
  docker exec everest-ac-demo-manager-1 sh /ext/source/build/run-scripts/run-sil-ocpp201-pnc.sh
fi
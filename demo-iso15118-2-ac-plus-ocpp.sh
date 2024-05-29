#!/usr/bin/env bash


DEMO_REPO="https://github.com/everest/everest-demo.git"
DEMO_BRANCH="main"

CSMS_REPO="https://github.com/thoughtworks/maeve-csms.git"
# MAEVE_BRANCH="b990d0eddf2bf80be8d9524a7b08029fbb305c7d" # patch files are based on this commit
CSMS="maeve"



usage="usage: $(basename "$0") [-r <repo>] [-b <branch>] [-c <csms>] [-j|1|2|3] [-h]

This script will run EVerest ISO 15118-2 AC charging with OCPP demos.

Pro Tip: to use a local copy of this everest-demo repo, provide the current
directory to the -r option (e.g., '-r \$(pwd)').

where:
    -r   URL to everest-demo repo to use (default: $DEMO_REPO)
    -b   Branch of everest-demo repo to use (default: $DEMO_BRANCH)
    -c   Use CitrineOS CSMS (default: MaEVe)
    -j   OCPP v1.6j
    -1   OCPP v2.0.1 Security Profile 1
    -2   OCPP v2.0.1 Security Profile 2
    -3   OCPP v2.0.1 Security Profile 3
    -h   Show this message"


DEMO_VERSION=
DEMO_COMPOSE_FILE_NAME=


# loop through positional options/arguments
while getopts ':r:b:cj123h' option; do
  case "$option" in
    r)  DEMO_REPO="$OPTARG" ;;
    b)  DEMO_BRANCH="$OPTARG" ;;
    c)  CSMS="citrine"
        CSMS_REPO="https://github.com/citrineos/citrineos-core" ;;
    j)  DEMO_VERSION="v1.6j"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp16j.yml" ;;
    1)  DEMO_VERSION="v2.0.1-sp1"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    2)  DEMO_VERSION="v2.0.1-sp2"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    3)  DEMO_VERSION="v2.0.1-sp3"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
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


cd "${DEMO_DIR}" || exit 1


echo "Cloning EVerest from ${DEMO_REPO} into ${DEMO_DIR}/everest-demo"
git clone --branch "${DEMO_BRANCH}" "${DEMO_REPO}" everest-demo

if [[ "$DEMO_VERSION" != v1.6j ]]; then
  echo "Cloning ${CSMS} CSMS from ${CSMS_REPO} into ${DEMO_DIR}/${CSMS}-csms and starting it"
  git clone ${CSMS_REPO} ${CSMS}-csms

  pushd ${CSMS}-csms || exit 1

  # Set up CSMS
  echo "Setting up ${CSMS}"
  if [[ "$CSMS" == "citrine" ]]; then   
    npm run install-all
    if [[ "$?" != 0 ]]; then
      echo 'Error: Failed to install dependencies.'
      exit 1
    fi
    npm run build
    if [[ "$?" != 0 ]]; then
      echo 'Error: Failed to build the project.'
      exit 1
    fi
  else
    git reset --hard ${MAEVE_BRANCH}
    cp ../everest-demo/manager/cached_certs_correct_name_emaid.tar.gz .

    echo "Patching the CSMS to disable load balancer"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-no-lb.patch
  fi 

  # Set up certificates for SP2 and SP3
  if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
    if [[ "$CSMS" == "citrine" ]]; then 
      echo "Security profile 2/3 is not supported with Citrine yet!"
      exit 1
    else
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

    fi
  elif [[ ${CSMS} == "maeve" ]]; then 
    echo "Patching the CSMS to disable WSS"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-no-wss.patch
  fi

  # Start the CSMS
  echo "Starting the CSMS"
  if [[ ${CSMS} == "citrine" ]]; then 
    cd "Server"
    # Remap the CitrineOS 8081 port (HTTP w/ no auth) to 80 port
    CITRINE_DOCKER="docker-compose.yml"

    if [[ -f "$CITRINE_DOCKER" ]]; then
      # Use sed to find and replace the string
      sed -i '' 's/8081:8081/80:8081/g' "$CITRINE_DOCKER"
      echo "Replaced mapping CitrineOS 8081 to 80 completed successfully."
    else
      echo "Error: File $CITRINE_DOCKER does not exist."
      exit 1
    fi

    docker-compose -f ./docker-compose.yml up -d
  else
    docker compose up -d
  fi

  echo "Waiting 5s for CSMS to start..."
  sleep 5

  if [[ ${CSMS} == "citrine" ]]; then 
    echo "TODO: Fill in Citrine API calls here!"
  else
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
  fi 

  echo "API calls to CSMS finished, starting EVerest..."

  popd || exit 1
fi


pushd everest-demo || exit 1
docker compose --project-name everest-ac-demo --file "${DEMO_COMPOSE_FILE_NAME}" up -d --wait
docker cp config-sil-ocpp201-pnc.yaml  everest-ac-demo-manager-1:/ext/source/config/config-sil-ocpp201-pnc.yaml
if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
  docker cp manager/cached_certs_correct_name_emaid.tar.gz everest-ac-demo-manager-1:/workspace/
  docker exec everest-ac-demo-manager-1 /bin/bash -c "tar xf cached_certs_correct_name_emaid.tar.gz"

  echo "Configured everest certs, validating that the chain is set up correctly"
  docker exec everest-ac-demo-manager-1 /bin/bash -c "openssl verify -show_chain -CAfile dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem dist/etc/everest/certs/client/csms/CSMS_LEAF.pem"
fi

if [[ ${CSMS} == "citrine" ]]; then 
  echo "TODO: Copy over certs for Citrine!"
else 
  if [[ "$DEMO_VERSION" =~ sp1 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 1"
    docker cp manager/device_model_storage_maeve_sp1.db \
      everest-ac-demo-manager-1:/workspace/dist/share/everest/modules/OCPP201/device_model_storage.db
  elif [[ "$DEMO_VERSION" =~ sp2 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 2"
    docker cp manager/device_model_storage_maeve_sp2.db \
      everest-ac-demo-manager-1:/workspace/dist/share/everest/modules/OCPP201/device_model_storage.db
  elif [[ "$DEMO_VERSION" =~ sp3 ]]; then
    echo "Copying device DB, configured to SecurityProfile: 3"
    docker cp manager/device_model_storage_maeve_sp3.db \
      everest-ac-demo-manager-1:/workspace/dist/share/everest/modules/OCPP201/device_model_storage.db
  fi
fi

if [[ "$DEMO_VERSION" =~ v2.0.1 ]]; then
  echo "Starting software in the loop simulation"
  docker exec everest-ac-demo-manager-1 sh /workspace/build/run-scripts/run-sil-ocpp201-pnc.sh
fi

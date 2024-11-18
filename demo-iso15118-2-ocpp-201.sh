#!/usr/bin/env bash


DEMO_REPO="https://github.com/everest/everest-demo.git"
DEMO_BRANCH="main"

START_OPTION="auto"

usage="usage: $(basename "$0") [-r <repo>] [-b <branch>] [-c <csms>] [1|2|3] [-h]

This script will run EVerest ISO 15118-2 AC charging with OCPP demos.

Pro Tip: to use a local copy of this everest-demo repo, provide the current
directory to the -r option (e.g., '-r \$(pwd)').

where:
    -r   URL to everest-demo repo to use (default: $DEMO_REPO, '$PWD' uses the current dir)
    -b   Branch of everest-demo repo to use (default: $DEMO_BRANCH)
    -1   OCPP v2.0.1 Security Profile 1
    -2   OCPP v2.0.1 Security Profile 2
    -3   OCPP v2.0.1 Security Profile 3
    -c   Use CitrineOS CSMS (default: MaEVe)
    -m   Start the manager manually (useful while debugging to stop and restart)
    -h   Show this message"


DEMO_VERSION=
DEMO_COMPOSE_FILE_NAME=
DEMO_CSMS=maeve

# loop through positional options/arguments
while getopts ':r:b:123chm' option; do
  case "$option" in
    r)  DEMO_REPO="$OPTARG" ;;
    b)  DEMO_BRANCH="$OPTARG" ;;
    1)  DEMO_VERSION="v2.0.1-sp1"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    2)  DEMO_VERSION="v2.0.1-sp2"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    3)  DEMO_VERSION="v2.0.1-sp3"
        DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml" ;;
    c)  DEMO_CSMS="citrineos" ;;
    m)  START_OPTION="manual" ;;
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


echo "DEMO REPO:        $DEMO_REPO"
echo "DEMO BRANCH:      $DEMO_BRANCH"
echo "DEMO VERSION:     $DEMO_VERSION"
echo "DEMO CONFIG:      $DEMO_COMPOSE_FILE_NAME"
echo "DEMO DIR:         $DEMO_DIR"
echo "DEMO CSMS:        $DEMO_CSMS"
echo "CSMS_SP1_URL:     $CSMS_SP1_URL"
echo "CSMS_SP2_URL:     $CSMS_SP2_URL"
echo "CSMS_SP3_URL:     $CSMS_SP3_URL"


cd "${DEMO_DIR}" || exit 1


echo "Cloning EVerest from ${DEMO_REPO} into ${DEMO_DIR}/everest-demo"
if [[ "$DEMO_REPO" =~ "http" || "$DEMO_REPO" =~ "git" ]]; then
    git clone --branch "${DEMO_BRANCH}" "${DEMO_REPO}" everest-demo
else
    cp -r "$DEMO_REPO" everest-demo
fi

# BEGIN: Setting up the CSMS
  pushd everest-demo/${DEMO_CSMS} || exit 1

  # Copy over the environment variable so we can get the tag
  cp ../.env .

  cp ../manager/cached_certs_correct_name_emaid.tar.gz .

  if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
    source ../${DEMO_CSMS}/copy-certs.sh
  fi

  source ../${DEMO_CSMS}/apply-runtime-patches.sh

  if ! docker compose --project-name "${DEMO_CSMS}"-csms up -d --wait; then
      echo "Failed to start ${DEMO_CSMS}"
      exit 1
  fi

  # note that docker compose --wait only waits for the
  # containers to be up, not necessarily the services in those
  # containers.
  echo "Waiting 5s for ${DEMO_CSMS} services to finish starting..."
  sleep 5

  echo "Adding a charger and RFID card to ${DEMO_CSMS}"
  source ../${DEMO_CSMS}/add-charger-and-rfid-card.sh

  popd || exit 1
# END: Setting up the CSMS

pushd everest-demo || exit 1
echo "API calls to CSMS finished, Starting everest"
docker compose --project-name everest-ac-demo --file "${DEMO_COMPOSE_FILE_NAME}" up -d --wait
docker cp manager/config-sil-ocpp201-pnc.yaml  everest-ac-demo-manager-1:/ext/source/config/config-sil-ocpp201-pnc.yaml
docker exec everest-ac-demo-manager-1 rm /ext/dist/share/everest/modules/OCPP201/component_config/custom/EVSE_2.json
docker exec everest-ac-demo-manager-1 rm /ext/dist/share/everest/modules/OCPP201/component_config/custom/Connector_2_1.json

if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
  docker cp manager/cached_certs_correct_name_emaid.tar.gz everest-ac-demo-manager-1:/ext/source/build
  docker exec everest-ac-demo-manager-1 /bin/bash -c "pushd /ext/source/build && tar xf cached_certs_correct_name_emaid.tar.gz"

  echo "Configured everest certs, validating that the chain is set up correctly"
  docker exec everest-ac-demo-manager-1 /bin/bash -c "pushd /ext/source/build && openssl verify -show_chain -CAfile dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem dist/etc/everest/certs/client/csms/CSMS_LEAF.pem"
fi

if [[ "$DEMO_VERSION" =~ sp1 ]]; then
echo "Configured to SecurityProfile: 1, disabling TLS and configuring server to ${CSMS_SP1_URL}"
docker exec everest-ac-demo-manager-1 /bin/bash -c "sed -i 's#ws://localhost:9000#${CSMS_SP1_URL}#' /ext/dist/share/everest/modules/OCPP201/component_config/standardized/InternalCtrlr.json"
docker cp manager/disable_iso_tls.patch everest-ac-demo-manager-1:/tmp/
docker exec everest-ac-demo-manager-1 /bin/bash -c "pushd /ext/source && patch -p0 -i /tmp/disable_iso_tls.patch"
elif [[ "$DEMO_VERSION" =~ sp2 ]]; then
echo "Configured to SecurityProfile: 2, configuring server to  ${CSMS_SP2_URL}"
docker exec everest-ac-demo-manager-1 /bin/bash -c "sed -i 's#ws://localhost:9000#${CSMS_SP2_URL}#' /ext/dist/share/everest/modules/OCPP201/component_config/standardized/InternalCtrlr.json"
elif [[ "$DEMO_VERSION" =~ sp3 ]]; then
echo "Running with SP3, TLS should be enabled"
echo "Configured to SecurityProfile: 2, configuring server to  ${CSMS_SP3_URL}"
docker exec everest-ac-demo-manager-1 /bin/bash -c "sed -i 's#ws://localhost:9000#${CSMS_SP3_URL}#' /ext/dist/share/everest/modules/OCPP201/component_config/standardized/InternalCtrlr.json"
fi

if [[ "$START_OPTION" == "auto" ]]; then
  echo "Starting software in the loop simulation automatically"
  docker exec everest-ac-demo-manager-1 sh /ext/build/run-scripts/run-sil-ocpp201-pnc.sh
else
  echo "Please start the software in the loop simulation manually by running"
  echo "on your laptop: docker exec -it everest-ac-demo-manager-1 /bin/bash"
  echo "in the container: sh /ext/build/run-scripts/run-sil-ocpp201-pnc.sh"
  echo "You can now stop and restart the manager without re-creating the container"
fi

#!/usr/bin/env bash


DEMO_REPO="${DEMO_REPO:-https://github.com/everest/everest-demo.git}"
DEMO_BRANCH="main"
CHARGE_STATION_ID="cp001"

START_OPTION="auto"

usage="usage: $(basename "$0") [-r <repo>] [-b <branch>] [-c <csms>] [1|2|3] [-h]

This script will run EVerest ISO 15118-2 AC charging with OCPP demos.

Pro Tip: to use a local copy of this everest-demo repo, provide the current
directory to the -r option (e.g., '-r \$(pwd)').

where:
    -r   URL to everest-demo repo to use (default: $DEMO_REPO, '$PWD' uses the current dir)
    -b   Branch of everest-demo repo to use (default: $DEMO_BRANCH)
    -s   Charge Station ID (cp001 by default)
    -1   OCPP v2.0.1 Security Profile 1
    -2   OCPP v2.0.1 Security Profile 2
    -3   OCPP v2.0.1 Security Profile 3
    -c   Use CitrineOS CSMS (default: MaEVe)
    -m   Start the manager manually (useful while debugging to stop and restart)
    -h   Show this message"


DEMO_VERSION=
DEMO_COMPOSE_FILE_NAME="docker-compose.ocpp201.yml"
DEMO_CSMS=maeve

# loop through positional options/arguments
while getopts ':r:b:s:123chm' option; do
  case "$option" in
    r)  DEMO_REPO="$OPTARG" ;;
    b)  DEMO_BRANCH="$OPTARG" ;;
    s)  CHARGE_STATION_ID="$OPTARG" ;;
    1)  DEMO_VERSION="v2.0.1-sp1" ;;
    2)  DEMO_VERSION="v2.0.1-sp2" ;;
    3)  DEMO_VERSION="v2.0.1-sp3" ;;
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
echo "CHARGE STATION:   $CHARGE_STATION_ID"


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
      source "../$DEMO_CSMS/copy-certs.sh"
  fi

  source "../$DEMO_CSMS/apply-runtime-patches.sh"

  echo "CSMS_SP1_BASE:     $CSMS_SP1_BASE"
  echo "CSMS_SP2_BASE:     $CSMS_SP2_BASE"
  echo "CSMS_SP3_BASE:     $CSMS_SP3_BASE"

  if [[ "$DEMO_CSMS" == "citrineos" ]]; then
    # CSMS="citrine"
    CSMS_REPO="https://github.com/citrineos/citrineos-core" 
    CSMS_BRANCH="0be080f6b6abd6463c7eeb39d529f81fe9fd5d46"

    echo "Cloning ${CSMS} CSMS from ${CSMS_REPO} into ${DEMO_DIR}/${DEMO_CSMS}-csms and starting it"
    git clone ${CSMS_REPO} ${DEMO_CSMS}-csms

    pushd ${DEMO_CSMS}-csms || exit 1

    git reset --hard ${CSMS_BRANCH}

    # Set up certificates for SP2 and SP3
    if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
      if [[ "$DEMO_CSMS" == "citrineos" ]]; then 
        echo "Security profile 2/3 is not supported with Citrine yet!"
        exit 1
      fi
    fi

    # Start the CSMS
    echo "Starting the CSMS"
    if [[ ${DEMO_CSMS} == "citrineos" ]]; then 
      OS=$(uname -s)

      if [ "$OS" == "Darwin" ]; then
        CITRINE_DOCKER="docker-compose.arm64.yml"
      else
        CITRINE_DOCKER="docker-compose.yml"
      fi

      ls ../../citrineos
      cp ../../citrineos/docker-compose.arm64.yml Server
      cd "Server"
      # Remap the CitrineOS 8081 port (HTTP w/ no auth) to 80 port
      CITRINE_DOCKER="docker-compose.arm64.yml"

      if [[ -f "$CITRINE_DOCKER" ]]; then
        # Use sed to find and replace the string
        sed -i '' 's/8082:8082/80:8082/g' "$CITRINE_DOCKER"
        echo "Replaced mapping CitrineOS 8082 to 80 completed successfully."
      else
        echo "Error: File $CITRINE_DOCKER does not exist."
        exit 1
      fi
    fi

    docker-compose -f docker-compose.arm64.yml up -d

    popd || exit 1
  else
      echo "Using MaEVe CSMS, using the default docker compose file"
      if ! docker compose --project-name "${DEMO_CSMS}"-csms up -d --wait; then
        echo "Failed to start ${DEMO_CSMS}"
        exit 1
      fi
  fi

  # note that docker compose --wait only waits for the
  # containers to be up, not necessarily the services in those
  # containers.
  echo "Waiting 5s for ${DEMO_CSMS} services to finish starting..."
  sleep 5

  echo "Adding a charger and RFID card to ${DEMO_CSMS}"
  source "../${DEMO_CSMS}/add-charger-and-rfid-card.sh"
  
  popd || exit 1
# END: Setting up the CSMS

pushd everest-demo || exit 1
echo "API calls to CSMS finished, Starting everest"
docker compose --project-name everest-ac-demo --file "${DEMO_COMPOSE_FILE_NAME}" up -d --wait
docker cp manager/config-sil-ocpp201-pnc.yaml  everest-ac-demo-manager-1:/ext/source/config/config-sil-ocpp201-pnc.yaml
docker exec \
        -e DEMO_VERSION="${DEMO_VERSION}" \
        -e CSMS_SP1_BASE="${CSMS_SP1_BASE}" \
        -e CSMS_SP2_BASE="${CSMS_SP2_BASE}" \
        -e CSMS_SP3_BASE="${CSMS_SP3_BASE}" \
        -e CHARGE_STATION_ID="${CHARGE_STATION_ID}" \
        everest-ac-demo-manager-1 \
        /bin/bash /tmp/ocpp201-sp-config.sh

if [[ "$START_OPTION" == "auto" ]]; then
  echo "Starting software in the loop simulation automatically"
  docker exec everest-ac-demo-manager-1 sh /ext/build/run-scripts/run-sil-ocpp201-pnc.sh
else
  echo "Please start the software in the loop simulation manually by running"
  echo "on your laptop: docker exec -it everest-ac-demo-manager-1 /bin/bash"
  echo "in the container: sh /ext/build/run-scripts/run-sil-ocpp201-pnc.sh"
  echo "You can now stop and restart the manager without re-creating the container"
fi

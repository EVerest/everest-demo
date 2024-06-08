#!/usr/bin/env bash


DEMO_REPO="https://github.com/everest/everest-demo.git"
DEMO_BRANCH="main"

CSMS_REPO="https://github.com/louisg1337/maeve-csms.git"
# CSMS_BRANCH="b990d0eddf2bf80be8d9524a7b08029fbb305c7d" # patch files are based on this commit
CSMS_BRANCH="set_charging_profile"
CSMS="maeve"



usage="usage: $(basename "$0") [-r <repo>] [-b <branch>] [-c <csms>] [-s] [-j|1|2|3] [-h]

This script will run EVerest ISO 15118-2 AC charging with OCPP demos.

Pro Tip: to use a local copy of this everest-demo repo, provide the current
directory to the -r option (e.g., '-r \$(pwd)').

where:
    -r   URL to everest-demo repo to use (default: $DEMO_REPO)
    -b   Branch of everest-demo repo to use (default: $DEMO_BRANCH)
    -c   Use CitrineOS CSMS (default: MaEVe)
    -s   Run with Edgeshark
    -j   OCPP v1.6j
    -1   OCPP v2.0.1 Security Profile 1
    -2   OCPP v2.0.1 Security Profile 2
    -3   OCPP v2.0.1 Security Profile 3
    -h   Show this message"


DEMO_VERSION=
DEMO_COMPOSE_FILE_NAME=
RUN_WITH_EDGESHARK=false

# loop through positional options/arguments
while getopts ':r:b:c:sj123h' option; do
  case "$option" in
    r)  DEMO_REPO="$OPTARG" ;;
    b)  DEMO_BRANCH="$OPTARG" ;;
    c)  CSMS="citrine"
        CSMS_REPO="https://github.com/citrineos/citrineos-core" 
        CSMS_BRANCH="63670f3adc09266a0977862d972b0f7e440c577f" ;;
    s)  RUN_WITH_EDGESHARK=true ;;
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

echo "Run with Edgeshark? $RUN_WITH_EDGESHARK"

if [[ "$RUN_WITH_EDGESHARK" = true ]]; then
  wget -q --no-cache -O - \
  https://github.com/siemens/edgeshark/raw/main/deployments/wget/docker-compose-localhost.yaml \
  | docker compose -f - up -d
fi

if [[ "$DEMO_VERSION" != v1.6j ]]; then
  echo "Cloning ${CSMS} CSMS from ${CSMS_REPO} into ${DEMO_DIR}/${CSMS}-csms and starting it"
  git clone --branch "${CSMS_BRANCH}" "${CSMS_REPO}" ${CSMS}-csms

  pushd ${CSMS}-csms || exit 1

  git reset --hard ${CSMS_BRANCH}

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
      sed -i '' 's/8082:8082/80:8082/g' "$CITRINE_DOCKER"
      echo "Replaced mapping CitrineOS 8082 to 80 completed successfully."
    else
      echo "Error: File $CITRINE_DOCKER does not exist."
      exit 1
    fi
  fi

  docker compose build 
  docker compose up -d

  echo "Waiting 5s for CSMS to start..."
  sleep 5



  if [[ ${CSMS} == "citrine" ]]; then 
    # Configuration
    DIRECTUS_API_URL="http://localhost:8055"
    CHARGEPOINT_ID="cp001"
    CP_PASSWORD="DEADBEEFDEADBEEF"
    DIRECTUS_EMAIL="admin@citrineos.com"
    DIRECTUS_PASSWORD="CitrineOS!"
    
    # Function to get the Directus token
    get_directus_token() {
        local login_url="${DIRECTUS_API_URL}/auth/login"
        local json_body=$(printf '{"email": "%s", "password": "%s"}' "$DIRECTUS_EMAIL" "$DIRECTUS_PASSWORD")
        local response=$(curl -s -X POST "$login_url" -H "Content-Type: application/json" -d "$json_body")

        # Extract token from the response
        local token=$(jq -r '.data.access_token' <<< "$response")
        echo "$token"
    }

    # Create new charger location
    add_location() {
      local token=$1
      local response=$(curl -s -X POST "${DIRECTUS_API_URL}/items/Locations" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer ${token}" \
          -d '{
              "id": "2",
              "name": "New EVerst",
              "coordinates": {
                  "type": "Point",
                  "coordinates": [-74.0620872, 41.041548]
              }
          }' | tee /dev/tty && echo)

      local location_id=$(jq -r '.data.id' <<< "$response")
      echo "$location_id"
    }

    # Function to add a charging station
    add_charging_station() {
        local token=$1
        local location_id=$2
        local chargepointId=$3
        curl -s --request POST \
            --url "${DIRECTUS_API_URL}/items/ChargingStations" \
            --header "Authorization: Bearer $token" \
            --header "Content-Type: application/json" \
            --data '{
                "id": "'"$chargepointId"'",
                "locationId": "'"$location_id"'"
            }' | tee /dev/tty && echo
      }

    
    # Function to update SP1 password
    add_cp001_password() {
        local response
        local success=false
        local attempt=1
        local passwordString=$1

        until $success; do
            echo "Attempt $attempt: Updating SP1 password..."
            response=$(curl -s -o /dev/null -w "%{http_code}" --location --request PUT "http://localhost:8080/data/monitoring/variableAttribute?stationId=${CHARGEPOINT_ID}&setOnCharger=true" \
                --header "Content-Type: application/json" \
                --data-raw '{
                    "component": {
                        "name": "SecurityCtrlr"
                    },
                    "variable": {
                        "name": "BasicAuthPassword"
                    },
                    "variableAttribute": [
                        {
                            "value": "'"$passwordString"'"
                        }
                    ],
                    "variableCharacteristics": {
                        "dataType": "passwordString",
                        "supportsMonitoring": false
                    }
                }' | tee /dev/tty)


            if [[ $response -ge 200 && $response -lt 300 ]]; then
                echo "Password update successful."
                success=true
            else
                echo "Password update failed with HTTP status: $response.  Retrying in 2 second..."
                sleep 2
                ((attempt++))
            fi
        done
    }

    # Main script execution
    TOKEN=$(get_directus_token)
    echo "Received Token: $TOKEN"

    if [ -z "$TOKEN" ]; then
        echo "Failed to retrieve access token."
        exit 1
    fi

    echo "Adding a new location..."
    LOCATION_ID=$(add_location "$TOKEN")

    if [ -z "$LOCATION_ID" ]; then
        echo "Failed to add new location."
        exit 1
    fi

    echo "Location ID: $LOCATION_ID"

    echo "Adding new station..."
    add_charging_station "$TOKEN" "$LOCATION_ID" "$CHARGEPOINT_ID"

    echo "Add cp001 password to citrine..."
    add_cp001_password "$CP_PASSWORD"
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
  docker cp manager/cached_certs_correct_name_emaid.tar.gz everest-ac-demo-manager-1:/ext/source/build
  docker exec everest-ac-demo-manager-1 /bin/bash -c "pushd /ext/source/build && tar xf cached_certs_correct_name_emaid.tar.gz"

  echo "Configured everest certs, validating that the chain is set up correctly"
  docker exec everest-ac-demo-manager-1 /bin/bash -c "pushd /ext/source/build && openssl verify -show_chain -CAfile dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem dist/etc/everest/certs/client/csms/CSMS_LEAF.pem"
fi

if [[ ${CSMS} == "citrine" && ! ("$DEMO_VERSION" =~ sp1) ]]; then
  echo "TODO: Set up device model correctly!"
else 
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

if [[ "$DEMO_VERSION" =~ v2.0.1 ]]; then
  echo "Starting software in the loop simulation"
  docker exec everest-ac-demo-manager-1 sh /ext/source/build/run-scripts/run-sil-ocpp201-pnc.sh
fi

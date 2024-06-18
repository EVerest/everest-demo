#!/usr/bin/env bash

# Configuration
DIRECTUS_API_URL="http://localhost:8055"
CHARGEPOINT_ID="cp001"
CP_PASSWORD="DEADBEEFDEADBEEF"
DIRECTUS_EMAIL="admin@citrineos.com"
DIRECTUS_PASSWORD="CitrineOS!"
ID_TOKEN="DEADBEEF"
ID_TOKEN_TYPE="ISO14443"

#TODO put github images
PROJECT_LOGO_IMAGE_URL="https://public-citrineos-logo.s3.amazonaws.com/Citrine-Directus-Project-Logo.png"
PUBLIC_BACKGROUND_IMAGE_URL="https://public-citrineos-logo.s3.amazonaws.com/Citrine-Directus-Public-Background.png"

# Function to get the Directus token
get_directus_token() {
    local login_url="${DIRECTUS_API_URL}/auth/login"
    local json_body=$(printf '{"email": "%s", "password": "%s"}' "$DIRECTUS_EMAIL" "$DIRECTUS_PASSWORD")
    local response=$(curl -s -X POST "$login_url" -H "Content-Type: application/json" -d "$json_body")

    # Extract token from the response
    local token=$(jq -r '.data.access_token' <<< "$response")
    echo "$token"
}

# Function to upload an image via URL to Directus
upload_image() {

    local token=$1
    local image_url=$2
    local title=$3
    local response=$(curl -s -X POST "${DIRECTUS_API_URL}/files/import" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"url\": \"${image_url}\",
            \"data\": {

            \"title\": \"${title}\"
            }
        }"| tee /dev/tty && echo)

    local file_id=$(jq -r '.data.id' <<< "$response")

    echo "$file_id"
}

# Function to set the project image
set_project_image() {
    local token=$1
    local project_logo=$2
    local project_background=$3
    curl -s -X PATCH "${DIRECTUS_API_URL}/settings" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"project_logo\": \"${project_logo}\",
            \"public_background\": \"${project_background}\"
        }" | tee /dev/tty && echo
}

# Function to add a new location
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
    local token="$1"
    local location_id="$2"
    local chargepointId="$3"
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

# Function to add new ev driver authorization information
add_evdriver_authorization() {
 local response
     local success=false
     local attempt=1
     local idToken=$1
     local idTokenType=$2

     until $success; do
         echo "Attempt $attempt: Adding ev driver authorization..."
         response=$(curl -s -o /dev/null -w "%{http_code}" --location --request PUT "http://localhost:8080/data/evdriver/authorization?idToken=${idToken}&type=${idTokenType}" \
             --header "Content-Type: application/json" \
             --data-raw '{
                "idToken": {
                    "idToken": "'"$idToken"'",
                    "type": "'"$idTokenType"'"
                },
                "idTokenInfo": {
                    "status": "Accepted"
                }
            }' | tee /dev/tty)


        if [[ $response -ge 200 && $response -lt 300 ]]; then
            echo "Authorization update successful."
            success=true
         else
             echo "Authorization update failed with HTTP status: $response.  Retrying in 2 second..."
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

# Upload image and set as project logo
echo "Uploading project images..."
FILE_ID_LOGO=$(upload_image "$TOKEN" "$PROJECT_LOGO_IMAGE_URL" "Citrine Logo")

if [ -z "$FILE_ID_LOGO" ]; then
    echo "Failed to upload project image."
    exit 1
fi
FILE_ID_BACKGROUND=$(upload_image "$TOKEN" "$PUBLIC_BACKGROUND_IMAGE_URL" "Citrine Background")
if [ -z "$FILE_ID_BACKGROUND" ]; then
    echo "Failed to upload project image."
    exit 1
fi

echo "Setting project image..."
set_project_image "$TOKEN" "$FILE_ID_LOGO" "$FILE_ID_BACKGROUND"

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

echo "Add ev driver rfid authorization to citrine..."
add_evdriver_authorization "$ID_TOKEN" "$ID_TOKEN_TYPE"
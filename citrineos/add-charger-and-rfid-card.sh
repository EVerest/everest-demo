#!/usr/bin/env bash

# Configuration
GRAPHQL_API_URL="http://localhost:8090/v1/graphql"
CHARGEPOINT_ID="cp001"
CP_PASSWORD="DEADBEEFDEADBEEF"
ID_TOKEN="DEADBEEF"
ID_TOKEN_TYPE="ISO14443"

# Function to show usage
show_usage() {
    echo "Usage: $0 [--cleanup]"
    echo "  (no flags)  : Create test location, charging station, and RFID authorization"
    echo "  --cleanup   : Delete the test data created by this script"
    exit 1
}

# Function to execute GraphQL mutation
execute_graphql() {
    local query="$1"
    echo "DEBUG: Executing query: $query" >&2
    local json_payload=$(jq -n --arg query "$query" '{"query": $query}')
    echo "DEBUG: JSON payload: $json_payload" >&2
    local response=$(curl -s -X POST "$GRAPHQL_API_URL" \
        -H "Content-Type: application/json" \
        -d "$json_payload")
    echo "$response"
}

# Function to add a new location via GraphQL
add_location() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing location
    local existing_query="query { Locations(where: {name: {_eq: \"New EVerst\"}}) { id name address } }"
    echo "Checking for existing location..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_id=$(echo "$existing_response" | jq -r '.data.Locations[0].id // empty')
    
    if [ -n "$existing_id" ]; then
        echo "Found existing location with ID: $existing_id" >&2
        echo "$existing_id"
        return
    fi
    
    local query="mutation { insert_Locations_one(object: { name: \"New EVerst\", address: \"123 EV Station Rd\", city: \"Electric City\", state: \"NY\", country: \"USA\", postalCode: \"10001\", createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id name address } }"
    
    echo "Adding a new location via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "Location response: $response" >&2
    
    local location_id=$(echo "$response" | jq -r '.data.insert_Locations_one.id')
    echo "$location_id"
}

# Function to add a charging station via GraphQL
add_charging_station() {
    local location_id="$1"
    local chargepointId="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing charging station
    local existing_query="query { ChargingStations(where: {id: {_eq: \"$chargepointId\"}}) { id locationId chargePointVendor } }"
    echo "Checking for existing charging station..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_station=$(echo "$existing_response" | jq -r '.data.ChargingStations[0].id // empty')
    
    if [ -n "$existing_station" ]; then
        echo "Found existing charging station with ID: $existing_station" >&2
        return
    fi
    
    local query="mutation { insert_ChargingStations_one(object: { id: \"$chargepointId\", locationId: $location_id, chargePointVendor: \"EVerest\", chargePointModel: \"Demo Station\", protocol: \"OCPP2.0.1\", createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id locationId chargePointVendor } }"
    
    echo "Adding charging station via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "Charging station response: $response" >&2
}

# Function to add RFID token via GraphQL
add_rfid_token() {
    local idToken="$1"
    local idTokenType="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing token
    local existing_query="query { IdTokens(where: {idToken: {_eq: \"$idToken\"}, type: {_eq: \"$idTokenType\"}}) { id idToken type } }"
    echo "Checking for existing RFID token..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_id=$(echo "$existing_response" | jq -r '.data.IdTokens[0].id // empty')
    
    if [ -n "$existing_id" ]; then
        echo "Found existing RFID token with ID: $existing_id" >&2
        echo "$existing_id"
        return
    fi
    
    local query="mutation { insert_IdTokens_one(object: { idToken: \"$idToken\", type: \"$idTokenType\", createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id idToken type } }"
    
    echo "Adding RFID token via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "RFID token response: $response" >&2
    
    local token_id=$(echo "$response" | jq -r '.data.insert_IdTokens_one.id')
    echo "$token_id"
}

# Function to add authorization for RFID token via GraphQL
add_authorization() {
    local token_id="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing authorization
    local existing_query="query { Authorizations(where: {idTokenId: {_eq: $token_id}}) { id idTokenId } }"
    echo "Checking for existing authorization..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_auth=$(echo "$existing_response" | jq -r '.data.Authorizations[0].id // empty')
    
    if [ -n "$existing_auth" ]; then
        echo "Found existing authorization with ID: $existing_auth" >&2
        return
    fi
    
    local query="mutation { insert_Authorizations_one(object: { idTokenId: $token_id, createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id idTokenId } }"
    
    echo "Adding authorization via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "Authorization response: $response" >&2
}

# Function to update SP1 password (same as original - uses different API)
add_cp001_password() {
    local response
    local success=false
    local attempt=1
    local passwordString=$1

    until $success; do
        echo "Attempt $attempt: Updating SP1 password..."
        echo "checking http code? $http_code"
        # echo "http://localhost:8080/data/monitoring/variableAttribute?stationId=${CHARGEPOINT_ID}&setOnCharger=true&tenantId=1"
        response=$(curl -s -o /dev/null -w "%{http_code}" --location --request PUT "http://localhost:8080/data/monitoring/variableAttribute?stationId=${CHARGEPOINT_ID}&setOnCharger=true" \
            --header 'accept: */*' \
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
            }')

        if [[ $response -ge 200 && $response -lt 300 ]]; then
            echo "Password update successful."
            success=true
        else
            echo "Password update failed with HTTP status: $response. Retrying in 2 seconds..."
            echo $response
            sleep 2
            ((attempt++))
        fi
    done
}

# Function to add new ev driver authorization information (same as original - uses different API)
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
           }')

        if [[ $response -ge 200 && $response -lt 300 ]]; then
            echo "Authorization update successful."
            success=true
        else
            echo "Authorization update failed with HTTP status: $response. Retrying in 2 seconds..."
            sleep 2
            ((attempt++))
        fi
    done
}

# Function to cleanup test data
cleanup_test_data() {
    echo "🧹 Cleaning up ALL CitrineOS test data..."
    echo "⚠️  WARNING: This will delete ALL locations, charging stations, and authorizations!"
    
    # Delete ALL authorizations
    echo "1. Deleting ALL Authorizations..." >&2
    local delete_all_auth="mutation { delete_Authorizations(where: {}) { affected_rows } }"
    local auth_response=$(execute_graphql "$delete_all_auth")
    echo "  Deleted authorizations: $auth_response" >&2
    
    # Delete ALL VariableAttributes
    echo "2. Deleting ALL VariableAttributes..." >&2
    local delete_all_vars="mutation { delete_VariableAttributes(where: {}) { affected_rows } }"
    local vars_response=$(execute_graphql "$delete_all_vars")
    echo "  Deleted VariableAttributes: $vars_response" >&2
    
    # Delete ALL charging stations
    echo "3. Deleting ALL Charging Stations..." >&2
    local delete_all_stations="mutation { delete_ChargingStations(where: {}) { affected_rows } }"
    local stations_response=$(execute_graphql "$delete_all_stations")
    echo "  Deleted charging stations: $stations_response" >&2
    
    # Delete ALL locations
    echo "4. Deleting ALL Locations..." >&2
    local delete_all_locations="mutation { delete_Locations(where: {}) { affected_rows } }"
    local locations_response=$(execute_graphql "$delete_all_locations")
    echo "  Deleted locations: $locations_response" >&2
    
    # Optionally delete ALL IdTokens (commented out by default as they might be needed)
    echo "5. Deleting ALL RFID Tokens..." >&2
    local delete_all_tokens="mutation { delete_IdTokens(where: {}) { affected_rows } }"
    local tokens_response=$(execute_graphql "$delete_all_tokens")
    echo "  Deleted RFID tokens: $tokens_response" >&2
    
    echo "✅ Complete cleanup finished!"
    echo "Note: RFID tokens were preserved. To delete them too, uncomment the relevant section in the script."
}

# Main script execution
echo "Starting GraphQL-based setup..."

# Check if this script is being sourced or executed directly
# When sourced, $0 is the calling script name, not this script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly, parse command line arguments
    case "${1:-}" in
        --cleanup)
            cleanup_test_data
            exit 0
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            # No arguments, continue with normal setup
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            show_usage
            ;;
    esac
fi

# If sourced, skip argument parsing and just run the setup

echo "Adding a new location..."
LOCATION_ID=$(add_location)

if [ -z "$LOCATION_ID" ] || [ "$LOCATION_ID" = "null" ]; then
    echo "Failed to add new location."
    exit 1
fi

echo "Location ID: $LOCATION_ID"

echo "Adding new charging station..."
add_charging_station "$LOCATION_ID" "$CHARGEPOINT_ID"

echo "Adding RFID token..."
TOKEN_ID=$(add_rfid_token "$ID_TOKEN" "$ID_TOKEN_TYPE")

if [ -z "$TOKEN_ID" ] || [ "$TOKEN_ID" = "null" ]; then
    echo "Failed to add RFID token."
    exit 1
fi

echo "Token ID: $TOKEN_ID"

echo "Adding authorization for RFID token..."
add_authorization "$TOKEN_ID"

echo "Adding cp001 password to citrine..."
add_cp001_password "$CP_PASSWORD"

echo "Adding ev driver rfid authorization to citrine..."
add_evdriver_authorization "$ID_TOKEN" "$ID_TOKEN_TYPE"

echo "Setup completed successfully!" 

#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <identifier> <tenantId>"
  exit 1
fi

# Assign arguments to variables
IDENTIFIER=$1
TENANT_ID=$2

echo "setChargingProfile called with Identifier: ${IDENTIFIER} and tenandId: ${TENANT_ID}"

curl -X 'POST' \
  "http://localhost:8080/ocpp/smartcharging/setChargingProfile?identifier=${IDENTIFIER}&tenantId=${TENANT_ID}" \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "customData": {
    "vendorId": "string"
  },
  "evseId": 0,
  "chargingProfile": {
    "customData": {
      "vendorId": "string"
    },
    "id": 0,
    "stackLevel": 0,
    "chargingProfilePurpose": "ChargingStationExternalConstraints",
    "chargingProfileKind": "Absolute",
    "recurrencyKind": "Daily",
    "validFrom": "2024-06-03T21:58:35.240Z",
    "validTo": "2024-06-03T21:58:35.240Z",
    "chargingSchedule": [
      {
        "customData": {
          "vendorId": "string"
        },
        "id": 0,
        "startSchedule": "2024-06-03T21:58:35.240Z",
        "duration": 0,
        "chargingRateUnit": "W",
        "chargingSchedulePeriod": [
          {
            "customData": {
              "vendorId": "string"
            },
            "startPeriod": 0,
            "limit": 0,
            "numberPhases": 0,
            "phaseToUse": 0
          }
        ],
        "minChargingRate": 0,
        "salesTariff": {
          "customData": {
            "vendorId": "string"
          },
          "id": 0,
          "salesTariffDescription": "string",
          "numEPriceLevels": 0,
          "salesTariffEntry": [
            {
              "customData": {
                "vendorId": "string"
              },
              "relativeTimeInterval": {
                "customData": {
                  "vendorId": "string"
                },
                "start": 0,
                "duration": 0
              },
              "ePriceLevel": 0,
              "consumptionCost": [
                {
                  "customData": {
                    "vendorId": "string"
                  },
                  "startValue": 0,
                  "cost": [
                    {
                      "customData": {
                        "vendorId": "string"
                      },
                      "costKind": "CarbonDioxideEmission",
                      "amount": 0,
                      "amountMultiplier": 0
                    }
                  ]
                }
              ]
            }
          ]
        }
      }
    ],
    "transactionId": "string"
  }
}'

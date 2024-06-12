#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <chargingStation>"
  exit 1
fi

CS=$1

echo "setChargingProfile called with Charging Station: ${CS}"

curl -X POST \
  "http://localhost:9410/api/v0/cs/${CS}/setchargingprofile" \
  -H "Content-Type: application/json" \
  -d '{
    "chargingProfileKind": "Absolute",
    "chargingProfilePurpose": "TxProfile",
    "chargingSchedule": [
      {
        "chargingRateUnit": "W",
        "chargingSchedulePeriod": [
          {
            "limit": 22.5,
            "startPeriod": 0,
            "numberPhases": 3
          },
          {
            "limit": 20.0,
            "startPeriod": 3600,
            "numberPhases": 3
          }
        ],
        "id": 1,
        "minChargingRate": 5.0,
        "salesTariff": {
          "id": 1,
          "numEPriceLevels": 2,
          "salesTariffDescription": "Standard Tariff",
          "salesTariffEntry": [
            {
              "relativeTimeInterval": {
                "start": 0,
                "duration": 3600
              },
              "consumptionCost": [
                {
                  "cost": [
                    {
                      "amount": 15,
                      "costKind": "RelativePricePercentage"
                    }
                  ],
                  "startValue": 10.0
                }
              ]
            }
          ]
        }
      }
    ],
    "id": 1,
    "stackLevel": 0,
    "transactionId": "12345",
    "validFrom": "2024-06-07T10:00:00Z",
    "validTo": "2024-06-07T18:00:00Z"
  }'

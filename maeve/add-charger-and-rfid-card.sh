#!/usr/bin/env bash

echo "While running subscript, DEMO_VERSION is " $DEMO_VERSION

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


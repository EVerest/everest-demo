#!/usr/bin/env bash

echo "Build and run"

echo "CitrineOS does not currently build due to issues with npm dependencies. It is disabled until we roll forward. Apologies for the inconvenience!"
exit 1

pushd Server || exit 1

if ! docker compose --project-name "${DEMO_CSMS}"-csms up -d --wait; then
  echo "Failed to start ${DEMO_CSMS}"
  exit 1
fi

popd || exit 1

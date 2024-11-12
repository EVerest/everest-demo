echo "Build and run"

pushd Server || exit 1

docker compose build
if ! docker compose --project-name ${DEMO_CSMS}-csms up -d --wait; then
  echo "Failed to start ${DEMO_CSMS}"
  exit 1
fi

popd || exit 1

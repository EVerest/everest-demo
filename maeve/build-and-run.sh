echo "Build and run"
docker compose build
if ! docker compose --project-name ${DEMO_CSMS}-csms up -d --wait; then
  echo "Failed to start ${DEMO_CSMS}"
  exit 1
fi

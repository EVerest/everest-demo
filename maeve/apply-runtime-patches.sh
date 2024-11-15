#!/usr/bin/env bash

CSMS_SP1_URL="ws://host.docker.internal/ws/cp001"
CSMS_SP2_URL="wss://host.docker.internal/ws/cp001"
CSMS_SP3_URL="wss://host.docker.internal/ws/cp001"

  if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
    echo "Patching the CSMS to enable EVerest organization"
    patch -p1 -i maeve-csms-everest-org.patch

    echo "Patching the CSMS to enable local mo root"
    patch -p1 -i maeve-csms-local-mo-root.patch

  else
    echo "Patching the CSMS to disable WSS"
    patch -p1 -i maeve-csms-no-wss.patch
  fi


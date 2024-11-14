#!/usr/bin/env bash

  if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
    echo "Patching the CSMS to enable EVerest organization"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-everest-org.patch

    echo "Patching the CSMS to enable local mo root"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-local-mo-root.patch

  else
    echo "Patching the CSMS to disable WSS"
    patch -p1 -i ../everest-demo/maeve/maeve-csms-no-wss.patch
  fi


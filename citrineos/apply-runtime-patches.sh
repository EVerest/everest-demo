#!/usr/bin/env bash

export CSMS_SP1_BASE="ws://host.docker.internal:8082"
export CSMS_SP2_BASE="wss://host.docker.internal:8443"
export CSMS_SP3_BASE="wss://host.docker.internal:8444"

git clone https://github.com/citrineos/citrineos-core.git to-copy-templates
cp -r to-copy-templates/Server/data .
cp -r to-copy-templates/Server/hasura-metadata .
rm -rf to-copy-templates

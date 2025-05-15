#!/bin/bash

echo "Applying library patches"

cd / && patch -N -p0 -i /tmp/demo-patches/enable_ocpp_logging.patch
cd / && patch -N -p0 -i /tmp/demo-patches/display-cert-chain.patch

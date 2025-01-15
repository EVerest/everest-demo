#!/bin/bash

echo "Applying library patches"

cd / && patch -p0 -i /tmp/demo-patches/enable_ocpp_logging.patch
cd / && patch -p0 -i /tmp/demo-patches/support_m3_chip.patch

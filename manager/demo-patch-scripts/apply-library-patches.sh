#!/bin/bash

echo "Applying library patches"

cd / && patch -p0 -i /tmp/demo-patches/enable_ocpp_logging.patch

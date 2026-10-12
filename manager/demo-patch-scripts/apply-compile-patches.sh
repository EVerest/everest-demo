#!/bin/bash

echo "Applying compile-time patches"

# 2026.02.1: departure time is merged upstream (2025.12); single-phase is an AC-demo change, not applied
cd / && patch -N -p0 -i /tmp/demo-patches/build-script-hack.patch
# Skip unit tests to shorten the image build
sed -i 's/-DBUILD_TESTING=ON/-DBUILD_TESTING=OFF/' /ext/scripts/compile.sh

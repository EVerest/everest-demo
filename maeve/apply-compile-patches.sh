#!/usr/bin/env bash

# This is a patch to the source code, so we need to apply it
# before we build.
# And there is no harm in turning off OCSP completely

echo "Patching the CSMS to enable local mo root"
patch -p1 -i ../everest-demo/maeve/maeve-csms-ignore-ocsp.patch

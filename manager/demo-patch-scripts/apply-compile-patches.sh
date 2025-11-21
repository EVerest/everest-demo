#!/bin/bash

echo "Applying compile-time patches"

cd / && patch -N -p0 -i /tmp/demo-patches/departure-time-pr.patch
cd / && patch -N -p0 -i /tmp/demo-patches/build-script-hack.patch
# cd / && patch -N -p0 -i /tmp/demo-patches/enable_iso_dt.patch
cd / && patch -N -p1 -i /tmp/demo-patches/composite_schedule_fixes.patch
cd / && patch -N -p1 -i /tmp/demo-patches/switch_to_single_phase.patch
cd / && patch -N -p0 -i /tmp/demo-patches/esdp.patch

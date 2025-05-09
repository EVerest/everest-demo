#!/bin/bash

echo "Applying compile-time patches"

cd / && patch -N -p0 -i /tmp/demo-patches/enable_iso_dt.patch
cd / && patch -N -p1 -i /tmp/demo-patches/composite_schedule_fixes.patch

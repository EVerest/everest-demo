#!/bin/bash

echo "Applying compile-time patches"

cd / && patch -p0 -i /tmp/demo-patches/enable_iso_dt.patch
cd / && patch -p1 -i /tmp/demo-patches/composite_schedule_fixes.patch
cd / && patch -p1 -i /tmp/demo-patches/change_transfer_mode_to_single_phase.patch

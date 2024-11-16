#!/bin/bash

echo "Applying compile-time patches"

cd / && patch -p0 -i /tmp/demo-patches/enable_iso_dt.patch

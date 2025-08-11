#!/bin/bash

echo "Applying iso15118_prevent_m1_crash.patch"
cd / && patch -p0 -N -i /tmp/demo-patches/iso15118_prevent_m1_crash.patch

# echo "Applying enabled_payment_method_in_python.patch"
# cd /ext && patch -N -p0 -i /tmp/demo-patches/enable_payment_method_in_python.patch
# echo "Applying support_payment_in_jsevmanager.patch"
# cd /ext/dist/libexec/everest && patch -N -p1 -i /tmp/demo-patches/support_payment_in_jsevmanager.patch
echo "Applying hw_cap_down_to_16A.patch"
cd / && patch -N -p0 -i /tmp/demo-patches/hw_cap_down_to_16A.patch

cp /tmp/demo-patches/power_curve.py \
/ext/dist/libexec/everest/3rd_party/josev/iso15118/evcc/states/

cp /tmp/demo-patches/enable_evcc_logging.cfg /ext/dist/etc/everest/default_logging.cfg

echo "Applying esdp patch josev iso15118"
cd / && patch -N -p0 -i /tmp/demo-patches/esdp-iso15118.patch

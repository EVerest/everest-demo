#!/bin/bash

echo "Applying comm_session_handler_enabledt.patch"
cd / && patch -p0 -N -i /tmp/demo-patches/comm_session_handler_enabledt.patch
echo "Applying ev_state_enabledt.patch"
cd / && patch -p0 -N -i /tmp/demo-patches/ev_state_enabledt.patch
echo "Applying iso15118_2_states_enabledt.patch"
cd / && patch -p0 -N -i /tmp/demo-patches/iso15118_2_states_enabledt.patch
echo "Applying jsevmanager_index_enabledt.patch"
cd / && patch -p0 -N -i /tmp/demo-patches/jsevmanager_index_enabledt.patch
echo "Applying pyjosev_module_enabledt.patch"
cd / && patch -p0 -N -i /tmp/demo-patches/pyjosev_module_enabledt.patch
echo "Applying simulator_enabledt.patch"
cd / && patch -p0 -N -i /tmp/demo-patches/simulator_enabledt.patch

echo "Applying enabled_payment_method_in_python.patch"
cd /ext && patch -p0 -i /tmp/demo-patches/enable_payment_method_in_python.patch
echo "Applying support_payment_in_jsevmanager.patch"
cd /ext/dist/libexec/everest && patch -p1 -i /tmp/demo-patches/support_payment_in_jsevmanager.patch
echo "Applying hw_cap_down_to_16A.patch"
cd / && patch -p0 -i /tmp/demo-patches/hw_cap_down_to_16A.patch

cp /tmp/demo-patches/power_curve.py \
/ext/dist/libexec/everest/3rd_party/josev/iso15118/evcc/states/

cp /tmp/demo-patches/enable_evcc_logging.cfg /ext/dist/etc/everest/default_logging.cfg

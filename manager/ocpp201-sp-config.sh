#!/bin/bash
echo "Applying generic OCPP configuration with ${DEMO_VERSION}, ${CSMS_SP1_BASE} and ${CHARGE_STATION_ID}"
if [[ "$DEMO_VERSION" =~ sp1 || "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
    cp /tmp/config-sil-ocpp201-pnc.yaml /ext/source/config/config-sil-ocpp201-pnc.yaml
    rm /ext/dist/share/everest/modules/OCPP201/component_config/custom/EVSE_2.json
    rm /ext/dist/share/everest/modules/OCPP201/component_config/custom/Connector_2_1.json
fi

if [[ "$DEMO_VERSION" =~ sp2 || "$DEMO_VERSION" =~ sp3 ]]; then
  cp /tmp/cached_certs_correct_name_emaid.tar.gz /ext/source/build
  pushd /ext/source/build && tar xf cached_certs_correct_name_emaid.tar.gz

  echo "Configured everest certs, validating that the chain is set up correctly"
  openssl verify -show_chain -CAfile dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem --untrusted dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem dist/etc/everest/certs/client/csms/CSMS_LEAF.pem
  popd
fi

if [[ "$DEMO_VERSION" =~ sp1 ]]; then
    CSMS_SP1_URL=${CSMS_SP1_BASE}/${CHARGE_STATION_ID}
    echo "Configured to SecurityProfile: 1, disabling TLS and configuring server to ${CSMS_SP1_URL}"
    sed -i "s#ws://localhost:9000#${CSMS_SP1_URL}#" /ext/dist/share/everest/modules/OCPP201/component_config/standardized/InternalCtrlr.json
    pushd /ext/source && patch -N -p0 -i /tmp/disable_iso_tls.patch && popd
elif [[ "$DEMO_VERSION" =~ sp2 ]]; then
    CSMS_SP2_URL=${CSMS_SP2_BASE}/${CHARGE_STATION_ID}
    echo "Configured to SecurityProfile: 2, configuring server to  ${CSMS_SP2_URL}"
    sed -i "s#ws://localhost:9000#${CSMS_SP2_URL}#" /ext/dist/share/everest/modules/OCPP201/component_config/standardized/InternalCtrlr.json
elif [[ "$DEMO_VERSION" =~ sp3 ]]; then
    CSMS_SP3_URL=${CSMS_SP3_BASE}/${CHARGE_STATION_ID}
    echo "Running with SP3, TLS should be enabled"
    echo "Configured to SecurityProfile: 2, configuring server to  ${CSMS_SP3_URL}"
    sed -i "s#ws://localhost:9000#${CSMS_SP3_URL}#" /ext/dist/share/everest/modules/OCPP201/component_config/standardized/InternalCtrlr.json
fi

if [[ "$CHARGE_STATION_ID" != cp001 ]]; then
    echo "Found non-standard CHARGE_STATION_ID ${CHARGE_STATION_ID}, replacing in InternalCtrlr.json and SecurityCtrlr.json"
    sed -i "s#cp001#${CHARGE_STATION_ID}#" /ext/dist/share/everest/modules/OCPP201/component_config/standardized/InternalCtrlr.json
    sed -i "s#cp001#${CHARGE_STATION_ID}#" /ext/dist/share/everest/modules/OCPP201/component_config/standardized/SecurityCtrlr.json
fi

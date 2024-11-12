#!/usr/bin/env bash

  # Set up certificates for SP2 and SP3
    echo "Copying certs into ${DEMO_DIR}/maeve-csms/config/certificates"
    tar xf cached_certs_correct_name_emaid.tar.gz
    cat dist/etc/everest/certs/client/csms/CSMS_LEAF.pem \
        dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
        dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
      > config/certificates/csms.pem
    cat dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
        dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
      > config/certificates/trust.pem
    cp dist/etc/everest/certs/client/csms/CSMS_LEAF.key config/certificates/csms.key
    cp dist/etc/everest/certs/ca/v2g/V2G_ROOT_CA.pem config/certificates/root-V2G-cert.pem
    cp dist/etc/everest/certs/ca/mo/MO_ROOT_CA.pem config/certificates/root-MO-cert.pem

    echo "Validating that the certificates are set up correctly"
    openssl verify -show_chain \
      -CAfile config/certificates/root-V2G-cert.pem \
      -untrusted config/certificates/trust.pem \
      config/certificates/csms.pem


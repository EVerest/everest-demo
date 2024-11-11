  echo "Copying certs into ${DEMO_DIR}/citrineos-csms/Server/data/certificates"
  tar xf cached_certs_correct_name_emaid.tar.gz

  # Leaf key
  cp dist/etc/everest/certs/client/csms/CSMS_LEAF.key Server/data/certificates/leafKey.pem

  #Cert chain
  cat dist/etc/everest/certs/client/csms/CSMS_LEAF.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
  > Server/data/certificates/certChain.pem

  # SubCA
  cp dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.key Server/data/certificates/subCAKey.pem

  #TrustedSubCAChain
  cat dist/etc/everest/certs/ca/csms/CPO_SUB_CA2.pem \
    dist/etc/everest/certs/ca/csms/CPO_SUB_CA1.pem \
  > Server/data/certificates/rootCertificate.pem

  #ACME key
  cp ../everest-demo/citrineos/acme_account_key.pem Server/data/certificates/acme_account_key.pem

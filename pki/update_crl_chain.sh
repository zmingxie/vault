#!/bin/bash
set -eu

export VAULT_ADDR='http://127.0.0.1:8200'
CERT_DIR='./certs'

if [[ ! -d "${CERT_DIR}" ]]; then
  echo "Error! Directory ${CERT_DIR} is not found"
  exit 1
fi

pushd ${CERT_DIR} >/dev/null
curl --silent ${VAULT_ADDR}/v1/pki/crl/pem > Root_CRL.pem
curl --silent ${VAULT_ADDR}/v1/pki_int/crl/pem > Int_CRL.pem
awk '{print $0}' Root_CRL.pem Int_CRL.pem > CRL_chain.pem
openssl crl -inform PEM -text -noout -in Root_CRL.pem > Root_CRL.info
openssl crl -inform PEM -text -noout -in Int_CRL.pem > Int_CRL.info
popd >/dev/null

echo "Done! CRL Chain is updated."

#!/bin/bash
# ./request_new_cert.sh <Command_Name>
set -eu

export VAULT_ADDR='http://127.0.0.1:8200'
CERT_DIR='./certs'

if [[ ! -d "${CERT_DIR}" ]] || [[ $# -eq 0 ]]; then
  echo "Error! Directory ${CERT_DIR} is not found; Or missing <Command_Name>"
  exit 1
fi

CN=$1

# Request a certificate from the Intermediate CA with the given CN
pushd ${CERT_DIR} >/dev/null
vault write --format=json pki_int/issue/mxie-dot-dev common_name="${CN}" ttl="24h" \
            | tee \
                >(jq -r .data.certificate > ${CN}.crt) \
                >(jq -r .data.private_key > ${CN}.key) \
                > ${CN}.creds.json
openssl x509 -noout -text -in ${CN}.crt > ${CN}.crt.info
popd >/dev/null

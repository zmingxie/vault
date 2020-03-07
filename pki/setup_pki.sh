#!/bin/bash

set -eu

export VAULT_ADDR='http://127.0.0.1:8200'
CERT_DIR='./certs'
COMMON_NAME='mxie.dev'
PKI_INT_ROLE_NAME='mxie-dot-dev'

if [[ -d "${CERT_DIR}" ]]; then
  echo "Warning! Directory ${CERT_DIR} already exisits."
  echo "Continuing this will remove all certs and reinitiate Vault pki"
  read -r -p "Are you sure? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY])
      # Reset Vault pki
      vault secrets disable pki
      vault secrets disable pki_int
      rm -rf ${CERT_DIR} && mkdir -p ${CERT_DIR}
      ;;
    *)
      exit 0
      ;;
  esac
fi

pushd ${CERT_DIR} >/dev/null

# Generate Root CA with 10 years TTL
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault write -field=certificate pki/root/generate/internal \
        common_name="${COMMON_NAME}" \
        ttl=87600h > Root_CA.crt
vault write pki/config/urls \
        issuing_certificates="${VAULT_ADDR}/v1/pki/ca" \
        crl_distribution_points="${VAULT_ADDR}/v1/pki/crl"
openssl x509 -noout -text -in Root_CA.crt > Root_CA.crt.info

# Generate Intermediate CA with 5 years TTL
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write -format=json pki_int/intermediate/generate/internal \
        common_name="${COMMON_NAME} Intermediate Authority" \
        | jq -r '.data.csr' > Int_CA.csr
vault write -format=json pki/root/sign-intermediate csr=@Int_CA.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > Int_CA.crt
vault write pki_int/intermediate/set-signed certificate=@Int_CA.crt
openssl x509 -noout -text -in Int_CA.crt > Int_CA.crt.info

# Create a Role that can issue certs with 1 year TTL
vault write pki_int/roles/"${PKI_INT_ROLE_NAME}" \
        allowed_domains="${COMMON_NAME}" \
        allow_subdomains=true \
        max_ttl="8760h"

# Generate CA and CRL chains
awk '{print $0}' Root_CA.crt Int_CA.crt> CA_chain.pem
curl --silent ${VAULT_ADDR}/v1/pki/crl/pem > Root_CRL.pem
curl --silent ${VAULT_ADDR}/v1/pki_int/crl/pem > Int_CRL.pem
awk '{print $0}' Root_CRL.pem Int_CRL.pem > CRL_chain.pem
openssl crl -inform PEM -text -noout -in Root_CRL.pem > Root_CRL.info
openssl crl -inform PEM -text -noout -in Int_CRL.pem > Int_CRL.info

popd >/dev/null

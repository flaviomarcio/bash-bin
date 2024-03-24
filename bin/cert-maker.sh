#!/bin/bash

export CERT_NAME=${1}

PASSWORD="pass:${RANDOM}"

if [[ ${CERT_NAME} == "" ]];then
    CERT_NAME=cert
fi

# Generate a unique private key (KEY)
openssl genrsa -out ${CERT_NAME}.key 2048

# Generating a Certificate Signing Request (CSR)
openssl req -new -text -passout ${PASSWORD} -subj /CN=localhost -out ${CERT_NAME}.req -keyout ${CERT_NAME}.pem
openssl rsa -in ${CERT_NAME}.pem -passin ${PASSWORD} -out ${CERT_NAME}.key

# Creating a Self-Signed Certificate (CRT), 7300 days or 20 years
openssl req -x509 -days 7300 -in ${CERT_NAME}.req -text -key ${CERT_NAME}.key -out ${CERT_NAME}.crt
# Append KEY and CRT to cert.pem
cat ${CERT_NAME}.key ${CERT_NAME}.crt >> ./${CERT_NAME}.pem

echo ${PASSWORD} > ./${CERT_NAME}.password
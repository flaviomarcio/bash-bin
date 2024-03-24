#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-gen.sh
. ${BASH_BIN}/lib-strings.sh

function certCreate()
{
  local __cert_name=${1}
  local __cert_days=${2}
  local __cert_pass=${3}
  local __cert_dest=${4}

  if [[ ${__cert_name} == "" ]];then
    # default cert name
    local __cert_name=cert
  fi

  if [[ ${__cert_pass} == "" ]]; then
    # auto gen password
    local __cert_pass=$(genPassword)
  fi

  if [[ ${__cert_days} == "" ]]; then
    # 7300 days or 20 years
    local __cert_days=7300
  fi

  if [[ ${__cert_dest} == "" ]]; then
    # current dir
    local __cert_dest=$(pwd)
  fi

  local __cert_pass="pass:${__cert_pass}"

  # Generate a unique private key (KEY)
  openssl genrsa -out ${__cert_name}.key 2048
  # Generating a Certificate Signing Request (CSR)
  openssl req -new -text -passout ${__cert_pass} -subj /CN=localhost -out ${__cert_name}.req -keyout ${__cert_name}.pem
  openssl rsa -in ${__cert_name}.pem -passin ${__cert_pass} -out ${__cert_name}.key
  # Creating a Self-Signed Certificate (CRT)
  openssl req -x509 -days 7300 -in ${__cert_name}.req -text -key ${__cert_name}.key -out ${__cert_name}.crt
  # Append KEY and CRT to cert.pem
  cat ${__cert_name}.key ${__cert_name}.crt >> ./${__cert_name}.pem
  echo ${__cert_pass} > ${__cert_dest}/${__cert_name}.password
}


certCreate
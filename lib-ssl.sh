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

function rsaKeyCreate()
{
  local __rsa_key_name=${1}
  local __rsa_key_dest=${2}
  local __rsa_key_repl=${3}

  if [[ ${__rsa_key_name} == "" ]];then
    local __rsa_key_name=id_rsa
  fi

  if [[ ${__rsa_key_dest} == "" ]]; then
    local __rsa_key_dest=$(pwd)
  fi

  if ! [[ -d ${__rsa_key_dest} ]]; then
    mkdir -p ${__rsa_key_dest}
  fi

  if [[ ${__rsa_key_repl} == true ]]; then
    rm -rf ${__rsa_key_dest}/${__rsa_key_name}*
  fi

  local __rsa_key_file=${__rsa_key_dest}/${__rsa_key_name}

  if [[ -f ${__rsa_key_file} ]]; then
    return 1
  fi

  ssh-keygen -t rsa -f ${__rsa_key_file} -N ''
  return 1
}


function certCreate()
{
  unset __func_return
  local __cert_name=${1}
  local __cert_days=${2}
  local __cert_pass=${3}
  local __cert_dest=${4}
  local __cert_repl=${5}

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

  local __cert_file_pem=${__cert_dest}/${__cert_name}.pem
  local __cert_file_req=${__cert_dest}/${__cert_name}.req
  local __cert_file_key=${__cert_dest}/${__cert_name}.key
  local __cert_file_ctr=${__cert_dest}/${__cert_name}.crt

  local __cert_pass="pass:${__cert_pass}"

  if [[ ${__cert_repl} == true ]]; then
    rm -rf ${__cert_dest}/${__cert_name}.*
  fi

  if [[ -f ${__cert_file_key} ]]; then
    return 1;
  fi

  if ! [[ -d ${__cert_dest} ]]; then
    mkdir -p ${__cert_dest}
  fi

  if ! [[ -d ${__cert_dest} ]]; then
    export __func_return="Cert dir not found: \${__cert_dest}: ${__cert_dest}"
    return 0;
  fi

  # Generate a unique private key (KEY)
  openssl genrsa -out ${__cert_file_key} 2048 
  # Generating a Certificate Signing Request (CSR)
  openssl req -new -text -passout ${__cert_pass} -subj /CN=localhost -out ${__cert_file_req} -keyout ${__cert_file_pem} 
  openssl rsa -in ${__cert_file_pem} -passin ${__cert_pass} -out ${__cert_file_key}
  # Creating a Self-Signed Certificate (CRT)
  openssl req -x509 -days 7300 -in ${__cert_file_req} -text -key ${__cert_file_key} -out ${__cert_file_ctr} 
  # Append KEY and CRT to cert.pem
  cat ${__cert_file_key} ${__cert_file_ctr} >> ${__cert_file_pem}
  echo ${__cert_pass} > ${__cert_dest}/${__cert_name}.password
  return 1
}

# __cert_name=
# __cert_days=
# __cert_pass=
# __cert_dest=${HOME}/temp
# certCreate "${__cert_name}" "${__cert_days}" "${__cert_pass}" "${__cert_dest}" true



# __rsa_key_name=
# __rsa_key_dest=${HOME}/temp
# __rsa_key_repl=true
# rsaKeyCreate "${__rsa_key_name}" "${__rsa_key_dest}" "${__rsa_key_repl}"
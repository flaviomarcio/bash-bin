#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

function genPassword()
{
  local v=${RANDOM}.$(date +%s).${RANDOM}
  local __cert_pass="$(echo ${v} | sha256sum | base64 | head -c 12)"
  echo ${__cert_pass}
}

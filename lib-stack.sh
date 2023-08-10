#!/bin/bash

# if [[ ${BASH_BIN} == "" ]]; then
#   export BASH_BIN=${PWD}
# fi

#. ${BASH_BIN}/lib-strings.sh

function stackEnvsIsConfigured()
{
  export __func_return=
  if [[ ${PUBLIC_STACK_TARGETS_FILE} == "" ]]; then
    export __func_return="Invalid env \${PUBLIC_STACK_TARGETS_FILE}"
    return 0
  fi

  if ! [[ -f ${PUBLIC_STACK_TARGETS_FILE} ]]; then
    export __func_return="Invalid targets file: ${PUBLIC_STACK_TARGETS_FILE}"
    return 0
  fi

  if [[ ${PUBLIC_STACK_ENVS_FILE} == "" ]]; then
    export __func_return="Invalid env \${PUBLIC_STACK_ENVS_FILE}"
    return 0
  fi

  if ! [[ -f ${PUBLIC_STACK_ENVS_FILE} ]]; then
    export __func_return="Invalid stack environment file: ${PUBLIC_STACK_ENVS_FILE}"
    return 0
  fi

  return 1
}


#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh

# export SCRIPT_DIR=

function __private_script_envs_clear()
{
  unset SCRIPT_DIR
}

function __private_script_envs_check()
{
  if [[ ${SCRIPT_ENVIRONMENT} == "" ]]; then
    echR "Invalid \${SCRIPT_ENVIRONMENT}"
    return 0
  fi

  if [[ ${SCRIPT_DIR} == "" ]]; then
    echR "Invalid \${SCRIPT_DIR}"
    return 0
  fi
  mkdir -p ${SCRIPT_DIR}
  if ! [[ -d ${SCRIPT_DIR} ]]; then
    echR "Invalid script dir: ${SCRIPT_DIR}"
    return 0
  fi
  return 1
}

function __private_script_scan_files()
{
  unset __func_return
  local __private_script_scan_files_target_dir=${1}
  local __private_script_scan_files_filters="${2}"

  if ! [[ -d ${__private_script_scan_files_target_dir} ]]; then
    return 0;
  fi


  local __private_script_scan_files_dirs=($(ls ${__private_script_scan_files_target_dir}))
  for __private_script_scan_files_dir in ${__private_script_scan_files_dirs[*]}; 
  do
    local __private_script_scan_files_files=
    if [[ $(echo ${__private_script_scan_files_filter} | grep sl) == "" ]]; then
      local __private_script_scan_files_filter="*.sh"
    fi
    local __private_script_scan_find_files=($(echo $(find ${__private_script_scan_files_target_dir}/${__private_script_scan_files_dir} -iname '*.sh' | sort)))
    for __private_script_scan_find_file in ${__private_script_scan_find_files[*]};
    do
      export __func_return="${__func_return} ${__private_script_scan_find_file}"
    done
  done

  echo ${__func_return}
  return 1  
}

function scriptsExecute()
{
  echG "Script executing"
  __private_script_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  echM "    Executing"
  echB "      -Target dir: ${SCRIPT_DIR}"
  echB "      -Executing"

  local __scriptsExecute_files=($(__private_script_scan_files "${SCRIPT_DIR}"))

  if [[ ${__scriptsExecute_files} == "" ]]; then
    echR "        - No files found"
  else
    echG "        -Executing ${__scriptsExecute_file}"
    for __scriptsExecute_file in ${__scriptsExecute_files[*]};
    do
      echY "          source ${__scriptsExecute_file}"
      source ${__scriptsExecute_file}
    done
  fi
  echB "      Finished"
  echB "    Finished"
  return 1
}

function scriptsPrepare()
{
  export SCRIPT_ENVIRONMENT=${1}
  export SCRIPT_DIR=${2}
  __private_script_envs_check
  if ! [ "$?" -eq 1 ]; then
    echContinue
    return 0;       
  fi
  return 1
}

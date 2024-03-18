#!/bin/bash

. lib-strings.sh

#ref
# https://developer.hashicorp.com/vault/docs/commands

function __private_vaultGetAndConvertToEnv()
{
  unset __func_return=
  if ! [[ ${__private_vault_login_ok} == true ]]; then
    export __func_return="Invalid vault session"
    return 0;
  fi

  local __kv_ext="${1}"
  local __kv_path="${2}"
  local __kv_destine_dir="${3}"

  if [[ ${__kv_path} == "" ]]; then
    export __func_return="Invalid vault path, path is null"
    return 0;
  fi
  vaultKvGet ${__kv_path}
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  if [[ ${__kv_ext} == "sh" ]]; then
    local __ret=$(echo ${__func_return} | jq -r ' to_entries | .[] | "export \(.key)=\"\(.value)\"x:N:x"')
  else
    local __ret=$(echo ${__func_return} | jq -r ' to_entries | .[] | "\(.key)=\"\(.value)\"x:N:x"')
  fi
  if [[ -d ${__kv_destine_dir} ]]; then
    local __out_file=${__kv_destine_dir}/$(basename ${__kv_path}).${__kv_ext}
    echo -n ${__ret}>${__out_file} 
    __private_vault_clean_file ${__out_file}
  fi
  export __func_return=${__ret}
}


function __private_vault_clean_file()
{
  local __out_file=${1}
  if ! [[ -f ${__out_file}  ]]; then
    return 0;
  fi
  #split lines
  sed -i 's/x:N:x/\n/g' ${__out_file}
  #trim lines
  sed -i 's/^[[:space:]]*//; s/[[:space:]]*$//' ${__out_file}
  #remove empty lines
  sed -i '/^$/d' ${__out_file}
  return 1
}

function vaultWaitOnLine()
{
    return 1

}

function vaultEnvCheck()
{
  if [[ ${__private_vault_uri} == "" ]]; then
    export __private_vault_uri="http://${STACK_ENVIRONMENT}-${STACK_TARGET}-vault"
  fi

  if [[ ${__private_vault_port} == "" ]]; then
    export __private_vault_port=80
  fi

  if [[ ${__private_vault_method} == "" ]]; then
    export __private_vault_method=token
  fi

  if [[ ${__private_vault_token} == "" ]]; then
    export __private_vault_token="00000000-0000-0000-0000-000000000000"
  fi

  if [[ ${__private_vault_base_path} == "" ]]; then
    export __private_vault_base_path="kv/${STACK_TARGET}/${STACK_ENVIRONMENT}"
  fi

  if [[ ${__private_vault_username} == "" ]]; then
    __private_vault_username=${STACK_DEFAULT_USERNAME}
    if [[ ${__private_vault_password} == "" ]]; then
        __private_vault_password=${STACK_DEFAULT_PASSWORD}
    fi
  fi
  export VAULT_ADDR=${__private_vault_uri}
  #export VAULT_NAMESPACE=
  export VAULT_FORMAT=json

  return 1;
}

function vaultLogoff()
{
  if [[ ${__private_vault_login_ok} == true ]]; then
    echo $(vault token revoke -mode=path auth/token/lookup-self)&>/dev/null
  fi
  unset __private_vault_login_ok
  unset VAULT_ADDR
  unset VAULT_NAMESPACE=
  unset VAULT_FORMAT=json
  return 1
}

function vaultLogin()
{
  if [[ ${__private_vault_login_ok} == true ]]; then
    return 1;
  fi

  vaultWaitOnLine

  export __private_vault_environment="${1}"
  export __private_vault_base_path=$(echo ${2} | sed 's/vault\:\///g')
  export __private_vault_method="${3}"
  export __private_vault_uri="${4}"
  export __private_vault_token="${5}"
  export __private_vault_username="${6}"
  export __private_vault_password="${7}"

  vaultEnvCheck
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  local __return=$(vault login -method=token -method=${__private_vault_method} -address=${__private_vault_uri} ${__private_vault_token} | jq '.auth.client_token'| sed 's/\"//g')
  if [[ ${__return} != ${__private_vault_token} ]]; then
    export __func_return="vault unauthorized"
    return 0;
  fi

  __private_vault_login_ok=true

  return 1
}

function vaultKvGet()
{
  unset __func_return
  if ! [[ ${__private_vault_login_ok} == true ]]; then
    export __func_return="Invalid vault session"
    return 0;
  fi
  if [[ ${__private_vault_base_path} == "" ]]; then
    local __kv_path=${1}
  else
    local __kv_path=${__private_vault_base_path}/${1}
  fi  
  export __func_return=$(vault kv get --format=json ${__kv_path} | jq '.data.data')
  return 1;
}

function vaultKvPut()
{
  unset __func_return
  if ! [[ ${__private_vault_login_ok} == true ]]; then
    export __func_return="Invalid vault session"
    return 0;
  fi

  if [[ ${1} == "" || ${2} == "" ]]; then
    export __func_return="vaultKvPut: Invalid args \${__kv_path}|\${__kv_source}"
    return 0;
  fi

  if [[ ${__private_vault_base_path} == "" ]]; then
    local __kv_path=${1}
  else
    local __kv_path=${__private_vault_base_path}/${1}
  fi  
  local __kv_source=${2}

  if [[ ${__kv_path} == "" ]]; then
    local __kv_path=${__private_vault_base_path}
  fi

  if [[ ${__kv_path} == "" ]]; then
    export __func_return="Invalid vault path, \${__kv_path} is null"
    return 0;
  fi

  if [[ ${__kv_source} == "" ]]; then
    local __kv_source="{}"
  fi
 
  local _tmp_data=/tmp/data_$RANDOM.tmp
  if [[ -f ${__kv_source} ]]; then
    cat ${__kv_source}>${_tmp_data}
  else
    echo ${__kv_source}>${_tmp_data}
  fi  
  local __return=$(cat ${_tmp_data} | vault kv put --format=json ${__kv_path} -)
  local __return=$(echo ${__return} | jq '.request_id')
  if [[ ${__return} == "" ]]; then
    return 0
  fi
  export __func_return="${__kv_path}"
  return 1;
}

function vaultKvList()
{
  unset __func_return
  if ! [[ ${__private_vault_login_ok} == true ]]; then
    export __func_return="Invalid vault session"
    return 0;
  fi

  local __kv_path="${1}"

  if [[ ${__kv_path} == "" ]]; then
    local __kv_path=${__private_vault_base_path}
  fi

  if [[ ${__kv_path} == "" ]]; then
    export __func_return="Invalid vault path, path is null"
    return 0;
  fi
  export __func_return=$(vault kv list -format=json ${__kv_path} | jq '.[]' | sed 's/\"//g')
  __func_return=$(echo ${__func_return})
  return 1;
}


function vaultKvPullToDir()
{
  unset __func_return
  if ! [[ ${__private_vault_login_ok} == true ]]; then
    export __func_return="Invalid vault session"
    return 0;
  fi

  local __kv_destine_dir="${1}"
  local __kv_path="${2}"

  if [[ ${__kv_path} == "" ]]; then
    local __kv_path=${__private_vault_base_path}
  fi

  if [[ ${__kv_path} == "" ]]; then
    export __func_return="Invalid vault path, path is null"
    return 0;
  elif [[ ${__kv_destine_dir} == "" ]]; then
    export __func_return="Invalid vault export dir. source dir is null"
    return 0;
  fi

  mkdir -p ${__kv_destine_dir}
  if ! [[ -d ${__kv_destine_dir} ]]; then
    export __func_return="Invalid vault export dir not found, ${__kv_destine_dir}"
    return 0;
  fi

  vaultKvList "${__kv_path}"
  if ! [ "$?" -eq 1 ]; then
      return 0;
  fi
  local __kv_key_names=(${__func_return})
  local __kv_name=
  for __kv_name in "${__kv_key_names[@]}"
  do
    local __kv_destine_file=${__kv_destine_dir}/${__kv_name}.json
    vaultKvGet "${__kv_name}"
    if ! [ "$?" -eq 1 ]; then
        return 0;
    fi
    echo ${__func_return} | jq >${__kv_destine_file}
    local __return="${__return} ${__kv_destine_file}"
  done
  export __func_return=${__return}
  return 1;
}


function vaultKvPushFromDir()
{
  unset __func_return
  if ! [[ ${__private_vault_login_ok} == true ]]; then
    export __func_return="Invalid vault session"
    return 0;
  fi

  local __kv_source_dir="${1}"
  local __kv_path="${2}"

  if [[ ${__kv_path} == "" ]]; then
    local __kv_path=${__private_vault_base_path}
  fi

  if [[ ${__kv_path} == "" ]]; then
    export __func_return="Invalid vault path, path is null"
    return 0;
  elif [[ ${__kv_source_dir} == "" ]]; then
    export __func_return="Invalid vault source dir. source dir is null"
    return 0;
  elif ! [[ -d ${__kv_source_dir} ]]; then
    export __func_return="Invalid vault source dir not found, ${__kv_source_dir}"
    return 0;
  fi
 
  unset __return=
  local __kv_source_files=($(find ${__kv_source_dir} -name '*.json'))
  local __kv_source_file=
  for __kv_source_file in "${__kv_source_files[@]}"
  do
    local __kv_name=$(basename ${__kv_source_file})
    local __kv_name=$(echo ${__kv_name} | sed 's/\.json//g')
    vaultKvPut ${__kv_name} ${__kv_source_file}
    if ! [ "$?" -eq 1 ]; then
        return 0;
    fi
    local __return="${__return} ${__kv_name}"
  done
  export __func_return=${__return}
  
  return 1;
}

function vaultGetAndConvertToEnvsJava()
{
  unset __func_return
  __private_vaultGetAndConvertToEnv "env" "${1}" "${2}"
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  return 1
}

function vaultGetAndConvertToEnvsShell()
{
  unset __func_return=
  __private_vaultGetAndConvertToEnv "sh" "${1}" "${2}"
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  return 1
}

function vaultTests()
{
  local __kv_environment=dev
  local __kv_base_path=/secret
  local __kv_method=
  local __kv_uri=
  local __kv_token=
  local __kv_username=
  local __kv_password=
  local __kv_app_path=${__kv_base_path}/test
  local __kv_src_dir=${HOME}/temp
  
  vaultLogin "${__kv_environment}" "${__kv_base_path}" "${__kv_method}" "${__kv_uri}" "${__kv_token}" "${__kv_username}" "${__kv_password}"
  local i=
  for i in $(seq 1 9)
  do
    local __kv_app_data="{\"dt\":\"$(date)\", \"seq\":${i}}"
    local __kv_app_path_final=${__kv_app_path}/app-${i}
    vaultKvPut "${__kv_app_path_final}" "${__kv_app_data}";  echo -n "vaultKvPut: ";echo ${__kv_app_data} | jq
    vaultKvGet "${__kv_app_path_final}"; echo -n "vaultKvGet:"; echo ${__func_return} | jq
  done
  vaultKvPullToDir "${__kv_src_dir}" "${__kv_app_path}"
  vaultKvList "${__kv_app_path}"; echo "vaultKvList: [${__func_return}]"
  local __kv_key_names=(${__func_return})
  local __kv_key_name=
  for __kv_key_name in "${__kv_key_names[@]}"
  do
    local __kv_app_path_final="${__kv_app_path}/${__kv_key_name}"
    vaultGetAndConvertToEnvsJava ${__kv_app_path_final} ${__kv_src_dir}
    vaultGetAndConvertToEnvsShell ${__kv_app_path_final} ${__kv_src_dir}
  done
  vaultLogoff

}


#vaultTests
#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-docker.sh

function __private_stack_mk_dir()
{
  __private_stack_mk_dir_permission=${1}
  __private_stack_mk_dir_dir=${2}
  
  if [[ ${__private_stack_mk_dir_dir} == "" ]]; then
    return 0
  fi

  if [[ -d ${__private_stack_mk_dir_dir} ]]; then
    return 1
  fi

  mkdir -p ${__private_stack_mk_dir_dir}
  chmod ${__private_stack_mk_dir_permission} ${__private_stack_mk_dir_dir}
  if ! [[ -d ${__private_stack_mk_dir_dir} ]]; then
    export __func_return="No create dir: env \${__private_stack_mk_dir_dir}:${__private_stack_mk_dir_dir}"
    return 0
  fi
  return 1
}

function __private_dns_configure_host_name()
{
  export __func_return=
  __private_dns_configure_service_domain=${1}
  __private_dns_configure_service_name=${2}

  if [[ ${__private_dns_configure_service_domain} == "" ]]; then
    export __func_return="Invalid target name: env: \${__private_dns_configure_service_domain}"
    return 0;
  fi

  if [[ ${__private_dns_configure_service_name} == "" ]]; then
    export __func_return="Invalid target name: env: \${__private_dns_configure_service_name}"
    return 0;
  fi



  return 1
}

function __private_stack_mk_dir_lib_configure()
{
  envsSetIfIsEmpty STACK_LIB_DIR "${STACK_APPLICATIONS_DIR}/lib"
  if [[ ${STACK_LIB_DIR} == "" ]]; then
    export __func_return="invalid env \${STACK_LIB_DIR}"
    return 1;
  fi

  if [[ -d ${STACK_LIB_DIR} ]]; then
    return 1;
  fi

  __private_stack_mk_dir_lib_configure_dirs=("/data/lib" "/data/lib.dir" "/mnt/storage/lib.dir")
  for __private_stack_mk_dir_lib_configure_dir in "${__private_stack_mk_dir_lib_configure_dirs[@]}"
  do
    if ! [[ -d ${__private_stack_mk_dir_lib_configure_dir} ]]; then
      continue;
    fi
    echo $(ln -s ${__private_stack_mk_dir_lib_configure_dir} ${STACK_LIB_DIR})&>/dev/null
    break;
  done
  if ! [[ -d ${STACK_LIB_DIR} ]]; then
    export __func_return="lib dir not found, STACK_LIB_DIR: ${STACK_LIB_DIR}"
    return 0;
  fi
  return 1;
}

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

  if [[ ${PUBLIC_STACK_TARGET_ENVS_FILE} == "" ]]; then
    export __func_return="Invalid env \${PUBLIC_STACK_TARGET_ENVS_FILE}"
    return 0
  fi

  if ! [[ -f ${PUBLIC_STACK_TARGET_ENVS_FILE} ]]; then
    export __func_return="Invalid stack environment file: ${PUBLIC_STACK_TARGET_ENVS_FILE}"
    return 0
  fi

  return 1
}

function stackStorageMake()
{
  export __func_return=
  #stack dirs
  __private_stack_mk_dir 755 "${STACK_ROOT_DIR}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="No create \${STACK_ROOT_DIR}: ${STACK_ROOT_DIR}"
    return 0;
  fi

  __private_stack_mk_dir 755 "${STACK_INFRA_DIR}"
  __private_stack_mk_dir 777 "${STORAGE_SERVICE_DIR}"
  __private_stack_mk_dir 755 "${STACK_APPLICATIONS_DIR}"
  __private_stack_mk_dir 755 "${STACK_TARGET_DIR}"


  if [[ ${STACK_SERVICE_STORAGE_DIR} != "" ]]; then
    #stack target dirs
    __private_stack_mk_dir 755 "${STACK_SERVICE_STORAGE_DIR}"
    if ! [ "$?" -eq 1 ]; then
      export __func_return="No create \${STACK_SERVICE_STORAGE_DIR}: ${STACK_SERVICE_STORAGE_DIR}"
      return 0;
    fi
    __private_stack_mk_dir 755 "${STACK_SERVICE_STORAGE_DIR}"
  fi
  __private_stack_mk_dir 755 "${STACK_CERT_DEFAULT_DIR}"
  __private_stack_mk_dir 755 "${STACK_ENVIRONMENT_DIR}"
  __private_stack_mk_dir 755 "${STACK_INFRA_DIR}"
  
  #__private_stack_mk_dir 755 ${STACK_INFRA_CONF_DIR}

  __private_stack_mk_dir_lib_configure
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __private_stack_mk_dir_lib_configure: ${__func_return}"
    return 0;
  fi
  return 1
}

function stackInitTargetEnvFile()
{
  export __func_return=
  if [[ ${PUBLIC_STACK_TARGET_ENVS_FILE} == "" ]]; then
    export __func_return="env \${PUBLIC_STACK_TARGET_ENVS_FILE} is empty on calling __private_initFilesStack"
    return 0
  fi

  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_TZ
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DOMAIN
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_PROXY_PORT_HTTP
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_PROXY_PORT_HTTPS
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_PROXY_LOG_LEVEL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_TOKEN
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_USER
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_PASS
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_NODE_GLOBAL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_NODE_DB
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_NODE_SERVICES

  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_HOST
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_USER
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_PASSWORD
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_DB
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_PORT


  echo $(chmod +x ${PUBLIC_STACK_TARGET_ENVS_FILE})&>/dev/null
  return 1
}

function __private_stackEnvsLoadByStack()
{
  export STACK_NAME=${1}
  export STACK_IMAGE_NAME=
  export STACK_SERVICE_NAME=
  export STACK_SERVICE_HOSTNAME=
  export STACK_SERVICE_HOSTNAME=
  export STACK_SERVICE_HOSTNAME_PUBLIC=
  export STACK_SERVICE_STORAGE_DIR=

  if [[ ${STACK_NAME} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_NAME}"
    return 0
  fi
  if [[ ${STACK_PREFIX} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_PREFIX}"
    return 0
  fi
  __private_services_names_configure_name=${2}

  export STACK_IMAGE_NAME="${STACK_PREFIX}-${STACK_NAME}"
  export STACK_IMAGE_NAME_URL="${STACK_REGISTRY_DNS_PUBLIC}/${STACK_IMAGE_NAME}"
  export STACK_SERVICE_NAME="${STACK_PREFIX}-${STACK_NAME}"
  export STACK_SERVICE_STORAGE_DIR=${STACK_TARGET_STORAGE_DIR}/${STACK_SERVICE_NAME}

  export STACK_SERVICE_HOSTNAME=$(echo ${STACK_SERVICE_NAME} | sed 's/_/-/g')
  export STACK_SERVICE_HOSTNAME=${STACK_SERVICE_NAME}
  export STACK_SERVICE_HOSTNAME_PUBLIC=${STACK_SERVICE_NAME}.${STACK_DOMAIN}

  #load envs DNS

  stackMakeStructure
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackMakeStructure, ${__func_return}"
    return 0;
  fi
  return 1
}

function __private_stackEnvsLoadByTarget()
{
  export STACK_TARGET=${1}
  export STACK_TARGET_DIR=
  export STACK_INFRA_DIR=
  export STACK_INFRA_CONF_DIR=
  export STACK_REGISTRY_DNS_PUBLIC=
  export PUBLIC_STACK_TARGET_ENVS_FILE=

  if [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByTarget, invalid env \${STACK_TARGET}"
    return 0
  fi

  envsSetIfIsEmpty STACK_PREFIX "${STACK_ENVIRONMENT}-${STACK_TARGET}"
  #dirs
    envsSetIfIsEmpty STACK_TARGET_DIR "${STACK_ENVIRONMENT_DIR}/${STACK_TARGET}"
    envsSetIfIsEmpty STACK_INFRA_DIR "${STACK_TARGET_DIR}/infrastructure"
    envsSetIfIsEmpty STACK_INFRA_CONF_DIR "${STACK_TARGET_DIR}/infrastructure/conf"

    __private_stack_mk_dir 755 "${STACK_TARGET_DIR}"
    __private_stack_mk_dir 755 "${STACK_INFRA_DIR}"
    __private_stack_mk_dir 755 "${STACK_INFRA_CONF_DIR}"
    __private_stack_mk_dir 755 "${PUBLIC_STACK_TARGET_ENVS_FILE}"

  envsSetIfIsEmpty STACK_NETWORK_DEFAULT "${STACK_ENVIRONMENT}-${STACK_TARGET}-inbound"
  envsSetIfIsEmpty STACK_REGISTRY_DNS_PUBLIC "${STACK_PREFIX}-registry.${STACK_DOMAIN}:5000"
  export STACK_TARGET_STORAGE_DIR=${STACK_TARGET_DIR}/storage-data


  envsSetIfIsEmpty PUBLIC_STACK_TARGET_ENVS_FILE "${STACK_TARGET_DIR}/stack_envs.env"
  if [[ -f ${PUBLIC_STACK_TARGET_ENVS_FILE} ]]; then
    source ${PUBLIC_STACK_TARGET_ENVS_FILE}
  fi
  return 1
}

function stackEnvsLoad()
{
  __private_stackEnvsLoad_environment=${1}
  __private_stackEnvsLoad_target=${2}

  if [[ ${__private_stackEnvsLoad_environment} == "" ]]; then
    export __func_return="Invalid env: \${__private_stackEnvsLoad_environment}"
    return 0;
  elif [[ ${__private_stackEnvsLoad_target} == "" ]]; then
    export __func_return="Invalid env: \${__private_stackEnvsLoad_target}"
    return 0;
  fi

  export PUBLIC_STACK_TARGETS_FILE=
  export PUBLIC_STACK_TARGET_ENVS_FILE=
  export STACK_ENVIRONMENTS=
  export STACK_ENVIRONMENT="${__private_stackEnvsLoad_environment}"

  if [[ ${STACK_ENVIRONMENT} != "" && ${STACK_TARGET} != "" ]]; then
    export STACK_PREFIX="${STACK_ENVIRONMENT}-${STACK_TARGET}"
  fi

  envsSetIfIsEmpty STACK_ROOT_DIR "${HOME}"
  envsSetIfIsEmpty STACK_APPLICATIONS_DIR "${STACK_ROOT_DIR}/applications"
  envsSetIfIsEmpty STACK_CERT_DEFAULT_DIR "${STACK_APPLICATIONS_DIR}/certs"
  envsSetIfIsEmpty PUBLIC_STACK_TARGETS_FILE "${STACK_APPLICATIONS_DIR}/stack_targets.env"
  envsSetIfIsEmpty PUBLIC_STACK_ENVIRONMENTS_FILE "${STACK_APPLICATIONS_DIR}/stack_environments.env"

  export STACK_ENVIRONMENT_DIR=${STACK_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}
  if ! [[ -f ${PUBLIC_STACK_ENVIRONMENTS_FILE} ]]; then
    envsSetIfIsEmpty STACK_ENVIRONMENTS "testing development stating production"
    echo ${STACK_ENVIRONMENTS}>${PUBLIC_STACK_ENVIRONMENTS_FILE}
  else
    envsSetIfIsEmpty STACK_ENVIRONMENTS "testing development stating production"
  fi

  if ! [[ -f ${PUBLIC_STACK_TARGETS_FILE} ]]; then
    envsSetIfIsEmpty PUBLIC_STACK_TARGETS "company"
    echo ${PUBLIC_STACK_TARGETS}>${PUBLIC_STACK_ENVIRONMENTS_FILE}
  else
    envsSetIfIsEmpty PUBLIC_STACK_TARGETS "company"
  fi

  if ! [[ -f ${PUBLIC_STACK_TARGETS_FILE} ]]; then
    echo "company">${PUBLIC_STACK_TARGETS_FILE}
  fi

  __private_stackEnvsLoadByTarget ${__private_stackEnvsLoad_target}
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __private_stackEnvsLoadByTarget, ${__func_return}"
    return 0;
  elif [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="fail on calling __private_stackEnvsLoadByTarget, env \${STACK_TARGET} not found"
    return 0;
  fi

  #chamados apenas para gerar a limpeza das envs
  __private_stackEnvsLoadByStack

  #obrigatory envs
  envsSetIfIsEmpty STACK_TZ "America/Sao_Paulo"
  envsSetIfIsEmpty STACK_TARGET undefined
  envsSetIfIsEmpty STACK_DOMAIN "portela-professional.com.br"
  envsSetIfIsEmpty STACK_PROTOCOL http
  envsSetIfIsEmpty STACK_PROXY_PORT_HTTP 80
  envsSetIfIsEmpty STACK_PROXY_PORT_HTTPS 443
  envsSetIfIsEmpty STACK_VAULT_TOKEN "00000000-0000-0000-0000-000000000000"

  #cosntruira diretorios de envs carregadas
  stackStorageMake
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackStorageMake, ${__func_return}"
    return 0;
  fi
  

  #default users
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_USER services
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_PASS services
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_DATABASE services

  #nodes
  envsSetIfIsEmpty STACK_SERVICE_NODE_GLOBAL "node.role == manager"
  envsSetIfIsEmpty STACK_SERVICE_NODE_GLOBAL_SERVICES "${STACK_SERVICE_NODE_GLOBAL}"
  envsSetIfIsEmpty STACK_SERVICE_NODE_DB "${STACK_SERVICE_NODE_GLOBAL}"
  envsSetIfIsEmpty STACK_SERVICE_NODE_SERVICES "${STACK_SERVICE_NODE_GLOBAL}"
  envsSetIfIsEmpty STACK_SERVICE_NODE_FW "${STACK_SERVICE_NODE_GLOBAL}"

  #resources limit
  envsSetIfIsEmpty STACK_SERVICE_RESOURCE_CPU "0.5"
  envsSetIfIsEmpty STACK_SERVICE_RESOURCE_MEMORY "1GB"
  envsSetIfIsEmpty STACK_SERVICE_RESOURCE_REPLICA 1

  envsSetIfIsEmpty POSTGRES_HOST localhost
  envsSetIfIsEmpty POSTGRES_USER ${STACK_SERVICE_DEFAULT_USER}
  envsSetIfIsEmpty POSTGRES_PASSWORD ${STACK_SERVICE_DEFAULT_PASS}
  envsSetIfIsEmpty POSTGRES_DB "${STACK_SERVICE_DEFAULT_DATABASE}"
  envsSetIfIsEmpty POSTGRES_PORT 5432

  stackInitTargetEnvFile
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackInitTargetEnvFile"
    return 0;
  fi

  return 1
}

function stackEnvsLoadByStack()
{
  __private_stackEnvsLoadByStack_environment=${1}
  __private_stackEnvsLoadByStack_target=${2}
  __private_stackEnvsLoadByStack_stack_name=${3}


  if [[ ${__private_stackEnvsLoadByStack_environment} == "" ]]; then
    export __func_return="Invaid env: \${__private_stackEnvsLoadByStack_environment}"
    return 0;
  elif [[ ${__private_stackEnvsLoadByStack_target} == "" ]]; then
    export __func_return="Invaid env: \${__private_stackEnvsLoadByStack_target}"
    return 0;
  elif [[ ${__private_stackEnvsLoadByStack_stack_name} == "" ]]; then
    export __func_return="Invaid env: \${__private_stackEnvsLoadByStack_stack_name}"
    return 0;
  fi


  stackEnvsLoad "${__private_stackEnvsLoadByStack_environment}" "${__private_stackEnvsLoadByStack_target}"
  if [[ ${STACK_ENVIRONMENT} == "" ]]; then
    export __func_return="fail on calling stackEnvsLoad: env: \${STACK_ENVIRONMENT}"
    return 0;
  fi

  if [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="fail on calling stackEnvsLoad: env: \${STACK_TARGET}"
    return 0;
  fi

  __private_stackEnvsLoadByStack "${__private_stackEnvsLoadByStack_stack_name}"
  if [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="fail on calling __private_stackEnvsLoadByStack: env: \${STACK_TARGET}"
    return 0;
  fi

  if [[ ${STACK_DOMAIN} == "" ]]; then
    export __func_return="fail on calling stackEnvsLoad, env \${STACK_DOMAIN} not found"
    return 0;
  elif [[ ${STACK_ENVIRONMENT} == "" ]]; then
    export __func_return="fail on calling stackEnvsLoad, env \${STACK_ENVIRONMENT} not found"
    return 0;
  elif [[ ${STACK_LIB_DIR} == "" ]]; then
    export __func_return="fail on calling stackEnvsLoad, env \${STACK_LIB_DIR} not found"
    return 0;
  elif [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="fail on calling __private_stackEnvsLoadByStack, env \${STACK_TARGET} not found"
    return 0;
  elif [[ ${STACK_NAME} == "" ]]; then
    export __func_return="fail on calling __private_stackEnvsLoadByStack, env \${STACK_NAME} not found"
    return 0;
  elif [[ ${STACK_PREFIX} == ""  ]]; then
    echFail "${1}" "fail on calling __private_stackEnvsLoadByStack, invalid env \${STACK_PREFIX}"
    return 0;
  elif [[ ${STACK_IMAGE_NAME} == ""  ]]; then
    echFail "${1}" "fail on calling __private_stackEnvsLoadByStack, invalid env \${STACK_IMAGE_NAME}"
    return 0;
  elif [[  ${STACK_IMAGES_DIR} == "" ]]; then
    echFail "${1}" "fail on calling __private_stackEnvsLoadByStack, invalid env \${STACK_IMAGES_DIR}"
    return 0;
  elif ! [[ -d ${STACK_IMAGES_DIR} ]]; then
    echFail "${1}" "fail on calling __private_stackEnvsLoadByStack, invalid dir \${STACK_IMAGES_DIR}: ${STACK_IMAGES_DIR}"
    return 0;
  fi

  return 1;
}

function stackMakeStructure()
{
  stackStorageMake
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackStorageMake, ${__func_return}"
    return 0;
  fi
  dockerNetworkCreate "${STACK_NETWORK_DEFAULT}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling dockerNetworkCreate, ${__func_return}"
    return 0;
  fi
  return 1
}

function __lib_stack_tests()
{
  stackEnvsLoad development company
  echo "stackEnvsLoad::${__func_return}"
  stackEnvsLoadByStack development company appTest
  echo "stackEnvsLoadByStack::${__func_return}"
  return 1;
}

#__lib_stack_tests

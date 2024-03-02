#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-docker.sh
. ${BASH_BIN}/lib-vault.sh

function __private_stackEnvsLoadByStack()
{
  export STACK_NAME=${1}
  unset STACK_SERVICE_IMAGE
  unset STACK_SERVICE_NAME
  unset STACK_SERVICE_HOSTNAME
  unset STACK_SERVICE_HOSTNAME_PUBLIC
  unset STACK_SERVICE_STORAGE_DATA_DIR
  unset STACK_SERVICE_STORAGE_DB_DIR
  unset STACK_SERVICE_STORAGE_LOG_DIR
  unset STACK_SERVICE_STORAGE_CONFIG_DIR
  unset STACK_SERVICE_STORAGE_BACKUP_DIR
  unset STACK_SERVICE_STORAGE_EXTENSION_DIR
  unset STACK_SERVICE_STORAGE_PLUGIN_DIR
  unset STACK_SERVICE_STORAGE_IMPORT_DIR
  unset STACK_SERVICE_STORAGE_PROVIDER_DIR
  
  if [[ ${STACK_NAME} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_NAME}"
    return 0
  fi
  if [[ ${STACK_PREFIX} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_PREFIX}"
    return 0
  fi
  local __private_services_names_configure_name=${2}

  export STACK_SERVICE_NAME=$(echo "${STACK_PREFIX}-${STACK_NAME}" | sed 's/_/-/g')

  local __private_stackEnvsLoadByStack_storage=${STACK_TARGET_STORAGE_DIR}/${STACK_SERVICE_NAME}
  export STACK_SERVICE_STORAGE_DATA_DIR=${__private_stackEnvsLoadByStack_storage}/data
  export STACK_SERVICE_STORAGE_DB_DIR=${__private_stackEnvsLoadByStack_storage}/db
  export STACK_SERVICE_STORAGE_LOG_DIR=${__private_stackEnvsLoadByStack_storage}/log
  export STACK_SERVICE_STORAGE_CONFIG_DIR=${__private_stackEnvsLoadByStack_storage}/config
  export STACK_SERVICE_STORAGE_BACKUP_DIR=${__private_stackEnvsLoadByStack_storage}/backup
  export STACK_SERVICE_STORAGE_EXTENSION_DIR=${__private_stackEnvsLoadByStack_storage}/extension
  export STACK_SERVICE_STORAGE_PLUGIN_DIR=${__private_stackEnvsLoadByStack_storage}/plugin
  export STACK_SERVICE_STORAGE_IMPORT_DIR=${__private_stackEnvsLoadByStack_storage}/import
  export STACK_SERVICE_STORAGE_PROVIDER_DIR=${__private_stackEnvsLoadByStack_storage}/provider
  
  export STACK_SERVICE_IMAGE="${STACK_SERVICE_NAME}"
  export STACK_SERVICE_IMAGE_URL="${STACK_REGISTRY_DNS_PUBLIC}/${STACK_SERVICE_IMAGE}"

  export STACK_SERVICE_HOSTNAME=${STACK_SERVICE_NAME}
  export STACK_SERVICE_HOSTNAME_PUBLIC=${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}

  unset __dirs
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_DATA_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_DB_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_LOG_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_CONFIG_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_BACKUP_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_EXTENSION_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_PLUGIN_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_IMPORT_DIR}"
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_PROVIDER_DIR}"

  stackMkDir 777 "${__dirs}"

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
  unset STACK_INFRA_DIR
  unset STACK_INFRA_CERT_DIR
  unset STACK_INFRA_CONF_DIR
  unset STACK_REGISTRY_DNS_PUBLIC
  unset PUBLIC_STACK_TARGET_ENVS_FILE

  if [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByTarget, invalid env \${STACK_TARGET}"
    return 0
  fi

  export STACK_PREFIX="${STACK_ENVIRONMENT}-${STACK_TARGET}"
  #dirs
  export ROOT_TARGET_DIR="${ROOT_ENVIRONMENT_DIR}/${STACK_TARGET}"
  export STACK_INFRA_DIR="${ROOT_TARGET_DIR}/infrastructure"
  export STACK_INFRA_CONF_DIR="${ROOT_TARGET_DIR}/infrastructure/conf"
  export STACK_INFRA_CERT_DIR="${STACK_INFRA_CONF_DIR}/cert"
  export STACK_TEMPLATES_DIR="${ROOT_TARGET_DIR}/templates"
  export STACK_TARGET_STORAGE_DIR=${ROOT_TARGET_DIR}/storage-data

  stackMkDir 755 "${ROOT_TARGET_DIR} ${STACK_INFRA_CERT_DIR} ${STACK_INFRA_DIR} ${STACK_INFRA_CONF_DIR} ${STACK_TARGET_STORAGE_DIR}"

  envsSetIfIsEmpty STACK_NETWORK_PREFIX "${STACK_ENVIRONMENT}-${STACK_TARGET}"
  envsSetIfIsEmpty STACK_NETWORK_DEFAULT "${STACK_NETWORK_PREFIX}-inbound"
  envsSetIfIsEmpty STACK_NETWORK_SECURITY "${STACK_NETWORK_PREFIX}-security"
  envsSetIfIsEmpty STACK_NETWORK_SRE "${STACK_NETWORK_PREFIX}-sre"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_LOKI "${STACK_NETWORK_PREFIX}-grafana-loki"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_TEMPO "${STACK_NETWORK_PREFIX}-grafana-tempo"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_K6 "${STACK_NETWORK_PREFIX}-grafana-k6"
  envsSetIfIsEmpty STACK_NETWORK_KONG "${STACK_NETWORK_PREFIX}-kong-net"
  

  envsSetIfIsEmpty STACK_REGISTRY_DNS_PUBLIC "${STACK_PREFIX}-registry.${STACK_DOMAIN}:5000"
  envsSetIfIsEmpty PUBLIC_STACK_ENVS_FILE "${STACK_ROOT_DIR}/stack_envs.env"
  envsSetIfIsEmpty PUBLIC_STACK_TARGET_ENVS_FILE "${ROOT_TARGET_DIR}/stack_envs.env"
  if [[ -f ${PUBLIC_STACK_TARGET_ENVS_FILE} ]]; then
    source ${PUBLIC_STACK_TARGET_ENVS_FILE}
  fi
  return 1
}

function __private_stackEnvsDefaultByStack()
{
  local __environment=${1}
  local __target=${2}
  local __name=${3}

  local __service=${__environment}_${__target}_${__name}
  export APPLICATION_STACK_NAME=${__name}
  export APPLICATION_DEPLOY_NAME=${__service}
  export APPLICATION_DEPLOY_HOSTNAME=${__service}  

  envsSetIfIsEmpty APPLICATION_ACTION app
  envsSetIfIsEmpty APPLICATION_ACTION_SCRIPT run.sh

  envsSetIfIsEmpty APPLICATION_DEPLOY_CPU "${STACK_DEFAULT_DEPLOY_CPU}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_MEMORY "${STACK_DEFAULT_DEPLOY_MEMORY}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_REPLICAS "${STACK_DEFAULT_DEPLOY_REPLICAS}"

  envsSetIfIsEmpty APPLICATION_DEPLOY_LOG_LEVEL ${STACK_SERVICE_DEFAULT_LOG_LEVEL}
  envsSetIfIsEmpty APPLICATION_DEPLOY_PORT ${STACK_SERVICE_DEFAULT_PORT}

  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS ${STACK_SERVICE_HOSTNAME}
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PATH ${STACK_SERVICE_DEFAULT_CONTEXT_PATH}
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PUBLIC "${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PUBLIC_PATH "${APPLICATION_DEPLOY_DNS_PATH}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_3RDPARTY "${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_3RDPARTY_PATH "${APPLICATION_DEPLOY_DNS_PATH}"

  envsSetIfIsEmpty APPLICATION_DEPLOY_IMAGE "${STACK_SERVICE_IMAGE_URL}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_HOSTNAME ${STACK_SERVICE_HOSTNAME}
  envsSetIfIsEmpty APPLICATION_DEPLOY_MODE ${STACK_SERVICE_DEFAULT_NODE_MODE}
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE "${STACK_SERVICE_DEFAULT_NODE_SERVICES}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE_TOOL "${STACK_SERVICE_DEFAULT_NODE_SERVICES}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE_SERVICES ${STACK_SERVICE_DEFAULT_NODE_GLOBAL}
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE_DB ${STACK_SERVICE_DEFAULT_NODE_GLOBAL}
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE_FW ${STACK_SERVICE_DEFAULT_NODE_GLOBAL}
  envsSetIfIsEmpty APPLICATION_DEPLOY_NODE_BUILD "${STACK_SERVICE_DEFAULT_NODE_GLOBAL}"

  envsSetIfIsEmpty APPLICATION_DEPLOY_NETWORK_NAME ${STACK_NETWORK_DEFAULT}
  envsSetIfIsEmpty APPLICATION_DEPLOY_DATA_DIR "${STACK_SERVICE_STORAGE_DATA_DIR}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_DB_DIR "${STACK_SERVICE_STORAGE_DATA_DIR}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_LOG_DIR "${STACK_SERVICE_STORAGE_LOG_DIR}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_CONFIG_DIR "${STACK_SERVICE_STORAGE_CONFIG_DIR}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_BACKUP_DIR "${STACK_SERVICE_STORAGE_BACKUP_DIR}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_SHELF_LIFE "${STACK_SERVICE_DEFAULT_SHELF_LIFE}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_HEALTH_CHECK_INTERVAL "${STACK_SERVICE_HEALTH_CHECK_INTERVAL}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_HEALTH_CHECK_TIMEOUT "${STACK_SERVICE_HEALTH_CHECK_TIMEOUT}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_HEALTH_CHECK_RETRIES "${STACK_SERVICE_HEALTH_CHECK_RETRIES}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_VAULT_IMPORT "${STACK_VAULT_IMPORT}/${APPLICATION_STACK_NAME}"

  envsSetIfIsEmpty APPLICATION_DEPLOY_VAULT_METHOD "${STACK_VAULT_METHOD}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_VAULT_TOKEN "${STACK_VAULT_TOKEN_DEPLOY}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_VAULT_URI "${STACK_VAULT_URI}:${STACK_VAULT_PORT}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_VAULT_APP_ROLE_ID "${STACK_VAULT_APP_ROLE_ID}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_VAULT_APP_ROLE_SECRET "${STACK_VAULT_APP_ROLE_SECRET}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_VAULT_ENABLED "${STACK_VAULT_ENABLED}"
}

function __private_stackMkDir_lib_configure()
{
  envsSetIfIsEmpty STACK_LIB_DIR "${ROOT_APPLICATIONS_DIR}/lib"
  if [[ ${STACK_LIB_DIR} == "" ]]; then
    export __func_return="invalid env \${STACK_LIB_DIR}"
    return 0;
  fi

  if [[ -d ${STACK_LIB_DIR} ]]; then
    return 1;
  fi

  local __private_stackMkDir_lib_configure_dirs=("/data/lib" "/data/lib.dir" "/mnt/storage/lib.dir")
  for __private_stackMkDir_lib_configure_dir in "${__private_stackMkDir_lib_configure_dirs[@]}"
  do
    if ! [[ -d ${__private_stackMkDir_lib_configure_dir} ]]; then
      continue;
    fi
    echo $(ln -s ${__private_stackMkDir_lib_configure_dir} ${STACK_LIB_DIR})&>/dev/null
    break;
  done
  if ! [[ -d ${STACK_LIB_DIR} ]]; then
    mkdir -p ${STACK_LIB_DIR}
  fi

  if ! [[ -d ${STACK_LIB_DIR} ]]; then
    export __func_return="invalid lib dir \${STACK_LIB_DIR}: ${STACK_LIB_DIR}"
    return 0
  fi

  return 1;
}

function stackMkDir()
{
  stackMkDir_permission=${1}
  stackMkDir_dirs=${2}
  
  if [[ ${stackMkDir_dirs} == "" ]]; then
    export __func_return="No valid dir: env \${stackMkDir_dirs}: ${stackMkDir_dirs}"
    return 0
  fi

  stackMkDir_dirs=(${stackMkDir_dirs})

  for stackMkDir_dir in ${stackMkDir_dirs[*]}; 
  do
    if [[ -d ${stackMkDir_dir} ]]; then
      continue
    fi
    mkdir -p ${stackMkDir_dir}
    chmod ${stackMkDir_permission} ${stackMkDir_dir}
    if ! [[ -d ${stackMkDir_dir} ]]; then
      export __func_return="No create dir: env \${stackMkDir_dir}:${stackMkDir_dir}"
      return 0
    fi    
  done 

  return 1
}

function stackEnvsIsConfigured()
{
  unset __func_return
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
  unset __func_return
  #stack dirs
  stackMkDir 755 "${STACK_ROOT_DIR}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="No create \${STACK_ROOT_DIR}: ${STACK_ROOT_DIR}"
    return 0;
  fi

  stackMkDir 755 "${ROOT_APPLICATIONS_DIR} ${ROOT_TARGET_DIR} ${STACK_CERT_DEFAULT_DIR} ${ROOT_ENVIRONMENT_DIR} ${STACK_INFRA_DIR}"
  stackMkDir 777 "${STORAGE_SERVICE_DIR}"


  __private_stackMkDir_lib_configure
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __private_stackMkDir_lib_configure: ${__func_return}"
    return 0;
  fi
  return 1
}

function stackInitTargetEnvFile()
{
  unset __func_return
  if [[ ${PUBLIC_STACK_TARGET_ENVS_FILE} == "" ]]; then
    export __func_return="env \${PUBLIC_STACK_TARGET_ENVS_FILE} is empty on calling __private_initFilesStack"
    return 0
  fi

  #primary default envs
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_TZ
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DOMAIN
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DNS_SERVER_ENABLE
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_PROXY_PORT_HTTP
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_PROXY_PORT_HTTPS
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_PROXY_LOG_LEVEL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_TOKEN
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_TOKEN_DEPLOY

  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_USERNAME
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_PASSWORD
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DATABASE
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_CONTEXT_PATH
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_PORT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_LOG_LEVEL

  #database envs
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_HOST_PG
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_HOST_PG_9
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_PORT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_NAME
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_USERNAME
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_PASSWORD
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_SCHEMA
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEFAULT_DB_URL

  #
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_LOG_LEVEL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_NODE_GLOBAL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_NODE_DB
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_NODE_MODE
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_NODE_SERVICES
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_NODE_FW
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_NODE_TOOL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_TOKEN
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_USER
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_PASS
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_EMAIL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_DATABASE
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_CONTEXT_PATH
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_PORT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_DEFAULT_SHELF_LIFE
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_HEALTH_CHECK_INTERVAL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_HEALTH_CHECK_TIMEOUT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_HEALTH_CHECK_RETRIES

  #postgres envs
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_URL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_HOST
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_USER
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_PASSWORD
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_DATABASE
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} POSTGRES_PORT

  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_PORT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_URI
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_METHOD
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_TOKEN
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_TOKEN_DEPLOY
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_APP_ROLE_ID
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_APP_ROLE_SECRET
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_VAULT_IMPORT

  #gocd
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_GOCD_REGISTER_KEY
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_GOCD_WEB_HOOK_SECRET
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_GOCD_SERVER_ID
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_GOCD_GIT_REPOSITORY
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_GOCD_GIT_BRANCH
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_GOCD_AGENT_REPLICAS

  #services default images 
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_DNSMASQ
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_TRAEFIK
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_REGISTRY
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_POSTGRES
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_POSTGRES_9
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_INFLUXDB
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_MARIADB
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_SERVICE_IMAGE_MYSQL


  echo $(chmod +x ${PUBLIC_STACK_TARGET_ENVS_FILE})&>/dev/null
  return 1
}

function stackEnvsLoad()
{
  local __private_stackEnvsLoad_environment=${1}
  local __private_stackEnvsLoad_target=${2}

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
  export STACK_PREFIX_NAME=$(echo ${STACK_PREFIX} | sed 's/-/_/g')

  envsSetIfIsEmpty STACK_ROOT_DIR "${HOME}"
  #remove barra no final
  export STACK_ROOT_DIR=$(dirname ${STACK_ROOT_DIR}/teste)

  export ROOT_APPLICATIONS_DIR="${STACK_ROOT_DIR}/applications"
  export ROOT_ENVIRONMENT_DIR=${ROOT_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}
  export STACK_CERT_DEFAULT_DIR="${ROOT_APPLICATIONS_DIR}/certs"
  export PUBLIC_STACK_TARGETS_FILE="${ROOT_APPLICATIONS_DIR}/stack_targets.env"
  export PUBLIC_STACK_ENVIRONMENTS_FILE="${ROOT_APPLICATIONS_DIR}/stack_environments.env"


  mkdir -p ${ROOT_APPLICATIONS_DIR}

  if ! [[ -f ${PUBLIC_STACK_ENVIRONMENTS_FILE} ]]; then
    envsSetIfIsEmpty STACK_ENVIRONMENTS "testing development stating production"
    echo ${STACK_ENVIRONMENTS}>${PUBLIC_STACK_ENVIRONMENTS_FILE}
  else
    envsSetIfIsEmpty STACK_ENVIRONMENTS "testing development stating production"
  fi

  if ! [[ -f ${PUBLIC_STACK_TARGETS_FILE} ]]; then
    envsSetIfIsEmpty PUBLIC_STACK_TARGETS "company"
    echo ${PUBLIC_STACK_TARGETS}>${PUBLIC_STACK_TARGETS_FILE}
  else
    envsSetIfIsEmpty PUBLIC_STACK_TARGETS "company"
  fi

  if ! [[ -f ${PUBLIC_STACK_TARGETS_FILE} ]]; then
    echo "${PUBLIC_STACK_TARGETS}">${PUBLIC_STACK_TARGETS_FILE}
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
  
  envsSetIfIsEmpty STACK_VAULT_PORT 8200
  envsSetIfIsEmpty STACK_VAULT_URI "http://${STACK_PREFIX}-vault"
  envsSetIfIsEmpty STACK_VAULT_METHOD token
  envsSetIfIsEmpty STACK_VAULT_TOKEN "${STACK_SERVICE_DEFAULT_TOKEN}"
  envsSetIfIsEmpty STACK_VAULT_TOKEN_DEPLOY "${STACK_VAULT_TOKEN}"
  envsSetIfIsEmpty STACK_VAULT_APP_ROLE_ID "${STACK_SERVICE_DEFAULT_USER}"
  envsSetIfIsEmpty STACK_VAULT_APP_ROLE_SECRET "${STACK_SERVICE_DEFAULT_PASS}"
  envsSetIfIsEmpty STACK_VAULT_IMPORT "vault:/kv/${STACK_TARGET}/${STACK_ENVIRONMENT}"
  envsSetIfIsEmpty STACK_VAULT_ENABLED false

  envsSetIfIsEmpty STACK_DEFAULT_DEPLOY_CPU "1"
  envsSetIfIsEmpty STACK_DEFAULT_DEPLOY_MEMORY "1GB"
  envsSetIfIsEmpty STACK_DEFAULT_DEPLOY_REPLICAS 1

  envsSetIfIsEmpty STACK_HAPROXY_CERT_DIR "${STACK_INFRA_CONF_DIR}/haproxy/cert"
  envsSetIfIsEmpty STACK_HAPROXY_CONFIG_FILE "${STACK_INFRA_CONF_DIR}/haproxy/haproxy.cfg"

  #cosntruira diretorios de envs carregadas
  stackStorageMake
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackStorageMake, ${__func_return}"
    return 0;
  fi

  #primary default envs
  envsSetIfIsEmpty STACK_DNS_SERVER_ENABLE false
  envsSetIfIsEmpty STACK_DEFAULT_TOKEN "00000000-0000-0000-0000-000000000000"
  envsSetIfIsEmpty STACK_DEFAULT_USERNAME services
  envsSetIfIsEmpty STACK_DEFAULT_PASSWORD services
  envsSetIfIsEmpty STACK_DEFAULT_EMAIL "services@${STACK_DOMAIN}"
  envsSetIfIsEmpty STACK_DEFAULT_DATABASE services
  envsSetIfIsEmpty STACK_DEFAULT_CONTEXT_PATH "/"
  envsSetIfIsEmpty STACK_DEFAULT_PORT 8080
  envsSetIfIsEmpty STACK_DEFAULT_LOG_LEVEL INFO

  #database envs
  envsSetIfIsEmpty STACK_DEFAULT_DB_HOST_PG ${STACK_PREFIX}-postgres
  envsSetIfIsEmpty STACK_DEFAULT_DB_HOST_PG_9 ${STACK_PREFIX}-postgres-9
  envsSetIfIsEmpty STACK_DEFAULT_DB_PORT 5432
  envsSetIfIsEmpty STACK_DEFAULT_DB_NAME ${STACK_DEFAULT_DATABASE}
  envsSetIfIsEmpty STACK_DEFAULT_DB_USERNAME ${STACK_DEFAULT_USERNAME}
  envsSetIfIsEmpty STACK_DEFAULT_DB_PASSWORD ${STACK_DEFAULT_PASSWORD}
  envsSetIfIsEmpty STACK_DEFAULT_DB_SCHEMA
  envsSetIfIsEmpty STACK_DEFAULT_DB_URL "jdbc:postgresql://${STACK_PREFIX}-postgres:${STACK_DEFAULT_DB_PORT}/${STACK_DEFAULT_DB_NAME}"

  #postgres envs
  envsSetIfIsEmpty POSTGRES_URL ${STACK_DEFAULT_DB_URL}
  envsSetIfIsEmpty POSTGRES_HOST ${STACK_DEFAULT_DB_HOST_PG}
  envsSetIfIsEmpty POSTGRES_USER ${STACK_DEFAULT_DB_USERNAME}
  envsSetIfIsEmpty POSTGRES_PASSWORD ${STACK_DEFAULT_DB_PASSWORD}
  envsSetIfIsEmpty POSTGRES_DATABASE "${STACK_DEFAULT_DB_PASSWORD}"
  envsSetIfIsEmpty POSTGRES_PORT ${STACK_DEFAULT_DB_PORT}

  #default users
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_TOKEN ${STACK_DEFAULT_TOKEN}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_USER ${STACK_DEFAULT_USERNAME}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_PASS ${STACK_DEFAULT_PASSWORD}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_EMAIL ${STACK_DEFAULT_EMAIL}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_DATABASE ${STACK_DEFAULT_DATABASE}  
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_CONTEXT_PATH ${STACK_DEFAULT_CONTEXT_PATH}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_PORT ${STACK_DEFAULT_PORT}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_LOG_LEVEL ${STACK_DEFAULT_LOG_LEVEL}

  #nodes
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_NODE_MODE global
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_NODE_GLOBAL node.role==manager
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_NODE_DB ${STACK_SERVICE_DEFAULT_NODE_GLOBAL}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_NODE_SERVICES ${STACK_SERVICE_DEFAULT_NODE_GLOBAL}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_NODE_TOOL ${STACK_SERVICE_DEFAULT_NODE_GLOBAL}
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_NODE_FW ${STACK_SERVICE_DEFAULT_NODE_GLOBAL}



  #resources limit
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_SHELF_LIFE "24h"
  envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_INTERVAL "60s"
  envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_TIMEOUT "5s"
  envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_RETRIES "5"
  #services default images
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_DNSMASQ "dockurr/dnsmasq:latest"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_TRAEFIK "traefik:v2.9"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_REGISTRY "registry:latest"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_POSTGRES "postgres:16.1-bullseye"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_POSTGRES_9 "postgres:9.6"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_INFLUXDB "influxdb:1.8.10"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_MARIADB "lscr.io/linuxserver/mariadb"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_MYSQL "mysql:8.0.36-debian"
  

  #temp
  envsSetIfIsEmpty CUR_DATE "$(date +'%Y-%m-%d')"
  envsSetIfIsEmpty CUR_TIME "$(date +'%H:%M:%S')"
  envsSetIfIsEmpty CUR_DATETIME "$(date +'%Y-%m-%d')T$(date +'%H:%M:%S')"


  stackInitTargetEnvFile
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackInitTargetEnvFile"
    return 0;
  fi

  return 1
}

function stackEnvsByStackExportToFile()
{
  envsFileAddIfNotExists "${1}" APPLICATION_ACTION
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_BACKUP_DIR
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_CPU
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_DATA_DIR
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_DNS
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_DNS_3RDPARTY
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_DNS_3RDPARTY_PATH
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_DNS_PATH
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_DNS_PUBLIC
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_DNS_PUBLIC_PATH
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_HEALTH_CHECK_INTERVAL
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_HEALTH_CHECK_RETRIES
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_HEALTH_CHECK_TIMEOUT
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_HOSTNAME
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_IMAGE
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_MEMORY
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_MODE
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_NETWORK_NAME
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_NODE
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_NODE_DB
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_NODE_FW
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_NODE_SERVICES
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_NODE_TOOL
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_PORT
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_REPLICAS
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_SHELF_LIFE
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_FILE
  envsFileAddIfNotExists "${1}" APPLICATION_ENV_FILE
  envsFileAddIfNotExists "${1}" APPLICATION_ENV_TAGS
  envsFileAddIfNotExists "${1}" APPLICATION_GIT
  envsFileAddIfNotExists "${1}" APPLICATION_GIT_BRANCH
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_NAME
  envsFileAddIfNotExists "${1}" APPLICATION_STACK
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_VAULT_IMPORT
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_VAULT_METHOD
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_VAULT_TOKEN
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_VAULT_URI
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_VAULT_APP_ROLE_ID
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_VAULT_APP_ROLE_SECRET
  envsFileAddIfNotExists "${1}" APPLICATION_DEPLOY_VAULT_ENABLED
  
  return 1
}

function stackEnvsClearByStack()
{
  unset APPLICATION_ACTION
  unset APPLICATION_ACTION_SCRIPT
  unset APPLICATION_DEPLOY_BACKUP_DIR
  unset APPLICATION_DEPLOY_CPU
  unset APPLICATION_DEPLOY_DATA_DIR
  unset APPLICATION_DEPLOY_DNS
  unset APPLICATION_DEPLOY_DNS_3RDPARTY
  unset APPLICATION_DEPLOY_DNS_3RDPARTY_PATH
  unset APPLICATION_DEPLOY_DNS_PATH
  unset APPLICATION_DEPLOY_DNS_PUBLIC
  unset APPLICATION_DEPLOY_DNS_PUBLIC_PATH
  unset APPLICATION_DEPLOY_FILE
  unset APPLICATION_DEPLOY_HEALTH_CHECK_INTERVAL
  unset APPLICATION_DEPLOY_HEALTH_CHECK_RETRIES
  unset APPLICATION_DEPLOY_HEALTH_CHECK_TIMEOUT
  unset APPLICATION_DEPLOY_HOSTNAME
  unset APPLICATION_DEPLOY_IMAGE
  unset APPLICATION_DEPLOY_MEMORY
  unset APPLICATION_DEPLOY_MEMORY
  unset APPLICATION_DEPLOY_MODE
  unset APPLICATION_DEPLOY_NAME
  unset APPLICATION_DEPLOY_NETWORK_NAME
  unset APPLICATION_DEPLOY_NODE_DB
  unset APPLICATION_DEPLOY_NODE_FW
  unset APPLICATION_DEPLOY_NODE_SERVICES
  unset APPLICATION_DEPLOY_NODE_TOOL
  unset APPLICATION_DEPLOY_PORT
  unset APPLICATION_DEPLOY_REPLICAS
  unset APPLICATION_DEPLOY_SHELF_LIFE
  unset APPLICATION_DEPLOY_VAULT_APP_ROLE_ID
  unset APPLICATION_DEPLOY_VAULT_APP_ROLE_SECRET
  unset APPLICATION_DEPLOY_VAULT_ENABLED
  unset APPLICATION_DEPLOY_VAULT_IMPORT
  unset APPLICATION_DEPLOY_VAULT_METHOD
  unset APPLICATION_DEPLOY_VAULT_TOKEN
  unset APPLICATION_DEPLOY_VAULT_URI
  unset APPLICATION_ENV_FILE
  unset APPLICATION_ENV_TAGS
  unset APPLICATION_GIT
  unset APPLICATION_GIT_BRANCH
  unset APPLICATION_STACK
  unset APPLICATION_STACK_NAME
  
  return 1
}

function stackEnvsLoadByStack()
{
  local __private_stackEnvsLoadByStack_environment=${1}
  local __private_stackEnvsLoadByStack_target=${2}
  local __private_stackEnvsLoadByStack_stack_name=${3}

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
  __private_stackEnvsDefaultByStack ${__private_stackEnvsLoadByStack_environment} ${__private_stackEnvsLoadByStack_target} ${__private_stackEnvsLoadByStack_stack_name}
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __private_stackEnvsLoadByStack, ${__func_return}"
    return 0;
  elif [[ ${STACK_TARGET} == "" ]]; then
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
  elif [[ ${STACK_SERVICE_IMAGE} == ""  ]]; then
    echFail "${1}" "fail on calling __private_stackEnvsLoadByStack, invalid env \${STACK_SERVICE_IMAGE}"
    return 0;
  elif [[ ${STACK_SERVICE_HOSTNAME} == ""  ]]; then
    echFail "${1}" "fail on calling __private_stackEnvsLoadByStack, invalid env \${STACK_SERVICE_HOSTNAME}"
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
  dockerNetworkCreate "${STACK_NETWORK_DEFAULT} ${STACK_NETWORK_SECURITY} ${STACK_NETWORK_SRE} ${STACK_NETWORK_GRAFANA_LOKI} ${STACK_NETWORK_GRAFANA_TEMPO} ${STACK_NETWORK_GRAFANA_K6} ${STACK_NETWORK_KONG}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling dockerNetworkCreate, ${__func_return}"
    return 0;
  fi
  return 1
}

function stackPublicEnvsConfigure()
{
  __stackPublicEnvs_bashrc="${HOME}/.bashrc"
  __stackPublicEnvs_envFile=$(basename ${PUBLIC_STACK_ENVS_FILE})
  __stackPublicEnvs_envs_args="STACK_TARGET STACK_ENVIRONMENT STACK_ROOT_DIR QT_VERSION"
  __stackPublicEnvs_envs=(${__stackPublicEnvs_envs_args})
  if ! [[ -f ${PUBLIC_STACK_ENVS_FILE} ]]; then
    echo "#!/bin/bash">${PUBLIC_STACK_ENVS_FILE}
  fi
  for __stackPublicEnvs_env in ${__stackPublicEnvs_envs[*]}; 
  do
    sed -i "/${__stackPublicEnvs_env}/d" ${__stackPublicEnvs_bashrc}
    sed -i "/${__stackPublicEnvs_env}/d" ${PUBLIC_STACK_ENVS_FILE}
    echo "export ${__stackPublicEnvs_env}=${!__stackPublicEnvs_env}">>${PUBLIC_STACK_ENVS_FILE}
  done

  sed -i "/${__stackPublicEnvs_envFile}/d" ${__stackPublicEnvs_bashrc}
  echo "source ${PUBLIC_STACK_ENVS_FILE}">>${__stackPublicEnvs_bashrc}
  chmod +x ${PUBLIC_STACK_ENVS_FILE}
  source ${PUBLIC_STACK_ENVS_FILE}
  utilPrepareInit "${STACK_ENVIRONMENT}" "${STACK_TARGET}"
}

function stackPublicEnvs()
{
  clearTerm

  stackPublicEnvsConfigure
  while :
  do
    clearTerm
    __private_print_os_information
    echM "Current public envs values"
    
    for __stackPublicEnvs_env in ${__stackPublicEnvs_envs[*]}; 
    do
      echY "  - ${__stackPublicEnvs_env}: ${!__stackPublicEnvs_env}"
    done
    selector "Select env to edit" "Back ${__stackPublicEnvs_envs_args}" false
    if [[ ${__selector} == "Back" ]]; then
      return 1;
    else
      printf "set ${__selector}: "
      read __stackPublicEnvs_env_value
      export ${__selector}=${__stackPublicEnvs_env_value}
      stackPublicEnvsConfigure
    fi
  done

  return 1

}

function stackVaultLogoff(){
  vaultLogoff
}

function stackVaultLogin(){
 
  vaultLogin "${STACK_ENVIRONMENT}" "${STACK_VAULT_IMPORT}" "${STACK_VAULT_METHOD}" "${STACK_VAULT_URI}" "${STACK_VAULT_TOKEN}" "${STACK_VAULT_APP_ROLE_ID}" "${STACK_VAULT_APP_ROLE_SECRET}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling vaultLogin: ${__func_return}"
    return 0;
  fi
  return 1;
}

function stackVaultList(){
  clearTerm
  vaultKvList
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling vaultKvList: ${__func_return}"
    return 0;
  fi

  if [[ ${__func_return} == "" ]]; then
    echG "  No Keys"
    return 0
  else
    local __kv_path=$(echo ${STACK_VAULT_IMPORT} | sed 's/vault\:\///g')
    local __keys=(${__func_return})
    echB "  Keys"
    export __options=
    for __key in "${__keys[@]}"
    do
      local __path=${__kv_path}/${__key}
      echY "    - vault kv get --format=json ${__path}"
      local __options="${__options} ${__key}"      
    done

    while :
    do
      clearTerm
      selector "Data keys" "Quit ${__options}" false
      if [[ ${__selector} == "Quit" ]]; then
        return 1;
      else
         local __path=${__kv_path}/${__selector}
         clearTerm
         echB "  Keys ${STACK_VAULT_IMPORT}/${__selector}"
         echY "   - $(vault kv get -output-curl-string ${__path})"
         echY "   - vault kv get --format=json ${__path}"
         vault kv get --format=json ${__path} | jq '.data.data'
         read
      fi
    done
  fi
  return 0
}

function stackVaultPull(){
  echB "  Importing keys"
  echC "    - destine: ${STACK_VAULT_IMPORT}"
  echG "    - commans"
  echY "      - export DST_DIR=${STACK_VAULT_DIR}"
  echY ""
  vaultKvPullToDir "${STACK_VAULT_DIR}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling vaultKvPullToDir: ${__func_return}"
    return 0;
  fi
  local __kv_paths=(${__func_return})
  for __kv_destine in "${__kv_paths[@]}"
  do
    local __kv_file=$(basename ${__kv_destine})
    local __kv_path="${__private_vault_base_path}/${__kv_file})"
    local __kv_path=$(echo ${__kv_path} | sed 's/.json//g')
    local __kv_file="\${DST_DIR}/${__kv_file}"
    echY "      - export DST_FILE=${__kv_file}"
    echY "      - vault kv get --format=json ${__kv_path} | jq '.data.data' > \${DST_FILE}"
    echG "        - OK"
  done
  echG "  finished"
  read
  return 1
}

function stackVaultPush(){
  echB "  Exporting keys"
  echC "    - source dir ${STACK_VAULT_IMPORT}"
  vaultKvPushFromDir "${STACK_VAULT_DIR}" "${STACK_VAULT_IMPORT}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling vaultKvPushFromDir: ${__func_return}"
    return 0;
  fi
  local __kv_paths=(${__func_return})
  for __kv_path in "${__kv_paths[@]}"
  do
    local __kv_path="${__private_vault_base_path}/${__kv_path})"
    echY "      - vault kv put --format=json ${__kv_path} -\${SOURCE_BODY}"
    echG "        - OK"
  done
  echG "  finished"
  read
  return 1
}

# function __lib_stack_tests()
# {
#   stackEnvsLoad development company
#   echo "stackEnvsLoad::${__func_return}"
#   stackEnvsLoadByStack development company appTest
#   echo "stackEnvsLoadByStack::${__func_return}"
#   return 1;
# }

# #__lib_stack_tests

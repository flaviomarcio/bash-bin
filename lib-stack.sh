#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-docker.sh
. ${BASH_BIN}/lib-vault.sh

function __private_stackEnvsLoadByStack()
{
  unset __func_return
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
  unset STACK_SERVICE_STORAGE_CERT_DIR
  
  if [[ ${STACK_NAME} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_NAME}"
    return 0
  fi
  if [[ ${STACK_PREFIX} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_PREFIX}"
    return 0
  fi
  local __private_services_names_configure_name=${2}

  local __stack_name_parser=$(echo ${STACK_NAME} | sed 's/_/-/g')

  export STACK_SERVICE_NAME=${STACK_PREFIX}-${__stack_name_parser}

  #hostnames
  export STACK_SERVICE_HOSTNAME="${STACK_PREFIX_HOST}${__stack_name_parser}"
  export STACK_SERVICE_HOSTNAME_PROXY=${STACK_SERVICE_NAME}
  export STACK_SERVICE_HOSTNAME_PUBLIC=${STACK_SERVICE_NAME}.${STACK_DOMAIN}

  local __storage=${STACK_TARGET_STORAGE_DIR}/${STACK_SERVICE_NAME}
  #stograge
  export STACK_SERVICE_STORAGE_DATA_DIR=${__storage}/data
  export STACK_SERVICE_STORAGE_DB_DIR=${__storage}/db
  export STACK_SERVICE_STORAGE_LOG_DIR=${__storage}/log
  export STACK_SERVICE_STORAGE_CONFIG_DIR=${__storage}/config
  export STACK_SERVICE_STORAGE_BACKUP_DIR=${__storage}/backup
  export STACK_SERVICE_STORAGE_EXTENSION_DIR=${__storage}/extension
  export STACK_SERVICE_STORAGE_PLUGIN_DIR=${__storage}/plugin
  export STACK_SERVICE_STORAGE_IMPORT_DIR=${__storage}/import
  export STACK_SERVICE_STORAGE_PROVIDER_DIR=${__storage}/provider
  export STACK_SERVICE_STORAGE_CERT_DIR=${__storage}/certificates
  #image
  export STACK_SERVICE_IMAGE="${STACK_SERVICE_NAME}"
  export STACK_SERVICE_IMAGE_URL="${STACK_REGISTRY_DNS_PUBLIC}/${STACK_SERVICE_IMAGE}"


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
  local __dirs="${__dirs} ${STACK_SERVICE_STORAGE_CERT_DIR}"

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
  unset __func_return
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
  envsSetIfIsEmpty STACK_NETWORK_CAMUNDA "${STACK_NETWORK_PREFIX}-camunda"
  envsSetIfIsEmpty STACK_NETWORK_SRE "${STACK_NETWORK_PREFIX}-sre"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_LOKI "${STACK_NETWORK_PREFIX}-grafana-loki"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_TEMPO "${STACK_NETWORK_PREFIX}-grafana-tempo"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_K6 "${STACK_NETWORK_PREFIX}-grafana-k6"
  envsSetIfIsEmpty STACK_NETWORK_KONG "${STACK_NETWORK_PREFIX}-kong-net"
  

  envsSetIfIsEmpty STACK_REGISTRY_DNS_PUBLIC "${STACK_PREFIX_HOST}registry.${STACK_DOMAIN}:5000"
  envsSetIfIsEmpty PUBLIC_STACK_ENVS_FILE "${STACK_ROOT_DIR}/stack_envs.env"
  envsSetIfIsEmpty PUBLIC_STACK_TARGET_ENVS_FILE "${ROOT_TARGET_DIR}/stack_envs.env"
  
  
  if [[ -f ${PUBLIC_STACK_TARGET_ENVS_FILE} ]]; then
    source ${PUBLIC_STACK_TARGET_ENVS_FILE}
  fi
  return 1
}

function __private_stackEnvsDefaultByStack()
{
  unset __func_return
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
  envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_3RDPARTY "${STACK_ENVIRONMENT}-${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}"
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

function __configure()
{
  unset __func_return
  envsSetIfIsEmpty STACK_LIB_DIR "${ROOT_APPLICATIONS_DIR}/lib"
  if [[ ${STACK_LIB_DIR} == "" ]]; then
    export __func_return="invalid env \${STACK_LIB_DIR}"
    return 0;
  fi

  if [[ -d ${STACK_LIB_DIR} ]]; then
    return 1;
  fi

  local __configure_dirs=("/data/lib" "/data/lib.dir" "/mnt/storage/lib.dir")
  for __configure_dir in "${__configure_dirs[@]}"
  do
    if ! [[ -d ${__configure_dir} ]]; then
      continue;
    fi
    echo $(ln -s ${__configure_dir} ${STACK_LIB_DIR})&>/dev/null
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
  unset __func_return
  local __permission=${1}
  local __dirs=${2}
  
  if [[ ${__dirs} == "" ]]; then
    export __func_return="No valid dir: env \${__dirs}: ${__dirs}"
    return 0
  fi

  local __dirs=(${__dirs})
  local __dir=
  for __dir in ${__dirs[*]}; 
  do
    if [[ -d ${__dir} ]]; then
      continue
    fi
    mkdir -p ${__dir}
    chmod ${__permission} ${__dir}
    if ! [[ -d ${__dir} ]]; then
      export __func_return="No create dir: env \${__dir}:${__dir}"
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


  __configure
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __configure: ${__func_return}"
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
  local __local_add=()
  local __local_add+=(STACK_ADMIN_USERNAME)
  local __local_add+=(STACK_ADMIN_PASSWORD)
  local __local_add+=(STACK_ADMIN_EMAIL)
  local __local_add+=(STACK_TZ)
  local __local_add+=(STACK_DOMAIN)
  local __local_add+=(STACK_DNS_SERVER_ENABLE)
  local __local_add+=(STACK_PROXY_PORT_HTTP)
  local __local_add+=(STACK_PROXY_PORT_HTTPS)
  local __local_add+=(STACK_PREFIX_HOST_ENABLED)
  local __local_add+=(STACK_PROXY_LOG_LEVEL)
  local __local_add+=(STACK_VAULT_TOKEN)
  local __local_add+=(STACK_VAULT_TOKEN_DEPLOY)

  local __local_add+=(STACK_DEFAULT_USERNAME)
  local __local_add+=(STACK_DEFAULT_PASSWORD)
  local __local_add+=(STACK_DEFAULT_DATABASE)
  local __local_add+=(STACK_DEFAULT_CONTEXT_PATH)
  local __local_add+=(STACK_DEFAULT_PORT)
  local __local_add+=(STACK_DEFAULT_LOG_LEVEL)

  #database envs
  local __local_add+=(STACK_DEFAULT_DB_HOST_PG)
  local __local_add+=(STACK_DEFAULT_DB_HOST_PG_9)
  local __local_add+=(STACK_DEFAULT_DB_PORT)
  local __local_add+=(STACK_DEFAULT_DB_NAME)
  local __local_add+=(STACK_DEFAULT_DB_USERNAME)
  local __local_add+=(STACK_DEFAULT_DB_PASSWORD)
  local __local_add+=(STACK_DEFAULT_DB_SCHEMA)
  local __local_add+=(STACK_DEFAULT_DB_URL)

  #
  local __local_add+=(STACK_SERVICE_DEFAULT_LOG_LEVEL)
  local __local_add+=(STACK_SERVICE_DEFAULT_NODE_GLOBAL)
  local __local_add+=(STACK_SERVICE_DEFAULT_NODE_DB)
  local __local_add+=(STACK_SERVICE_DEFAULT_NODE_MODE)
  local __local_add+=(STACK_SERVICE_DEFAULT_NODE_SERVICES)
  local __local_add+=(STACK_SERVICE_DEFAULT_NODE_FW)
  local __local_add+=(STACK_SERVICE_DEFAULT_NODE_TOOL)
  local __local_add+=(STACK_SERVICE_DEFAULT_TOKEN)
  local __local_add+=(STACK_SERVICE_DEFAULT_USER)
  local __local_add+=(STACK_SERVICE_DEFAULT_PASS)
  local __local_add+=(STACK_SERVICE_DEFAULT_EMAIL)
  local __local_add+=(STACK_SERVICE_DEFAULT_DATABASE)
  local __local_add+=(STACK_SERVICE_DEFAULT_CONTEXT_PATH)
  local __local_add+=(STACK_SERVICE_DEFAULT_PORT)
  local __local_add+=(STACK_SERVICE_DEFAULT_SHELF_LIFE)
  local __local_add+=(STACK_SERVICE_HEALTH_CHECK_INTERVAL)
  local __local_add+=(STACK_SERVICE_HEALTH_CHECK_TIMEOUT)
  local __local_add+=(STACK_SERVICE_HEALTH_CHECK_RETRIES)

  #postgres envs
  local __local_add+=(POSTGRES_URL)
  local __local_add+=(POSTGRES_HOST)
  local __local_add+=(POSTGRES_USER)
  local __local_add+=(POSTGRES_PASSWORD)
  local __local_add+=(POSTGRES_DATABASE)
  local __local_add+=(POSTGRES_PORT)

  local __local_add+=(STACK_VAULT_PORT)
  local __local_add+=(STACK_VAULT_URI)
  local __local_add+=(STACK_VAULT_METHOD)
  local __local_add+=(STACK_VAULT_TOKEN)
  local __local_add+=(STACK_VAULT_TOKEN_DEPLOY)
  local __local_add+=(STACK_VAULT_APP_ROLE_ID)
  local __local_add+=(STACK_VAULT_APP_ROLE_SECRET)
  local __local_add+=(STACK_VAULT_IMPORT)

  #gocd
  local __local_add+=(STACK_GOCD_REGISTER_KEY)
  local __local_add+=(STACK_GOCD_WEB_HOOK_SECRET)
  local __local_add+=(STACK_GOCD_SERVER_ID)
  local __local_add+=(STACK_GOCD_GIT_REPOSITORY)
  local __local_add+=(STACK_GOCD_GIT_BRANCH)
  local __local_add+=(STACK_GOCD_AGENT_REPLICAS)

  #services default images 
  local __local_add+=(STACK_SERVICE_IMAGE_DNSMASQ)
  local __local_add+=(STACK_SERVICE_IMAGE_TRAEFIK)
  local __local_add+=(STACK_SERVICE_IMAGE_REGISTRY)
  local __local_add+=(STACK_SERVICE_IMAGE_POSTGRES)
  local __local_add+=(STACK_SERVICE_IMAGE_POSTGRES_9)
  local __local_add+=(STACK_SERVICE_IMAGE_INFLUXDB)
  local __local_add+=(STACK_SERVICE_IMAGE_MARIADB)
  local __local_add+=(STACK_SERVICE_IMAGE_MYSQL)
  local __local_add+=(STACK_SERVICE_IMAGE_REDIS)
  local __local_add+=(STACK_SERVICE_IMAGE_MSSQL)

  # save envs
  envsFileAddIfNotExists "${PUBLIC_STACK_TARGET_ENVS_FILE}" "${__local_add[@]}"

  echo $(chmod +x ${PUBLIC_STACK_TARGET_ENVS_FILE})&>/dev/null
  return 1
}

function stackEnvsLoad()
{
  unset __func_return
  local __private_stackEnvsLoad_environment=${1}
  local __private_stackEnvsLoad_target=${2}

  if [[ ${__private_stackEnvsLoad_environment} == "" ]]; then
    export __func_return="Invalid env: \${__private_stackEnvsLoad_environment}"
    return 0;
  elif [[ ${__private_stackEnvsLoad_target} == "" ]]; then
    export __func_return="Invalid env: \${__private_stackEnvsLoad_target}"
    return 0;
  fi

  unset PUBLIC_STACK_TARGETS_FILE
  unset PUBLIC_STACK_TARGET_ENVS_FILE

  export STACK_ENVIRONMENT="${__private_stackEnvsLoad_environment}"
  if [[ ${STACK_ENVIRONMENT} != "" && ${STACK_TARGET} != "" ]]; then
    export STACK_PREFIX="${STACK_ENVIRONMENT}-${STACK_TARGET}"
  fi
  export STACK_PREFIX_NAME=$(echo ${STACK_PREFIX} | sed 's/-/_/g')
  if [[ ${STACK_PREFIX_HOST_ENABLED} == true ]]; then
    export STACK_PREFIX_HOST="${STACK_PREFIX}-"
  else
    export STACK_PREFIX_HOST="int-"
  fi

  envsSetIfIsEmpty STACK_ROOT_DIR "${HOME}"
  #remove barra no final
  export STACK_ROOT_DIR=$(dirname ${STACK_ROOT_DIR}/ignore)
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
  envsSetIfIsEmpty STACK_PREFIX_HOST_ENABLED false
  
  envsSetIfIsEmpty STACK_VAULT_PORT 8200
  envsSetIfIsEmpty STACK_VAULT_URI "http://${STACK_PREFIX_HOST}vault"
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
  envsSetIfIsEmpty STACK_ADMIN_USERNAME services
  envsSetIfIsEmpty STACK_ADMIN_PASSWORD services
  envsSetIfIsEmpty STACK_ADMIN_EMAIL services@services.com
  envsSetIfIsEmpty STACK_DNS_SERVER_ENABLE false
  envsSetIfIsEmpty STACK_DEFAULT_TOKEN "00000000-0000-0000-0000-000000000000"
  envsSetIfIsEmpty STACK_DEFAULT_USERNAME "${STACK_ADMIN_USERNAME}"
  envsSetIfIsEmpty STACK_DEFAULT_PASSWORD "${STACK_ADMIN_PASSWORD}"
  envsSetIfIsEmpty STACK_DEFAULT_EMAIL "${STACK_DEFAULT_USERNAME}@${STACK_DOMAIN}"
  envsSetIfIsEmpty STACK_DEFAULT_DATABASE ${STACK_DEFAULT_USERNAME}
  envsSetIfIsEmpty STACK_DEFAULT_CONTEXT_PATH "/"
  envsSetIfIsEmpty STACK_DEFAULT_PORT 8080
  envsSetIfIsEmpty STACK_DEFAULT_LOG_LEVEL INFO

  #database envs
  envsSetIfIsEmpty STACK_DEFAULT_DB_HOST_PG ${STACK_PREFIX_HOST}postgres
  envsSetIfIsEmpty STACK_DEFAULT_DB_HOST_PG_9 ${STACK_PREFIX_HOST}postgres-9
  envsSetIfIsEmpty STACK_DEFAULT_DB_PORT 5432
  envsSetIfIsEmpty STACK_DEFAULT_DB_NAME ${STACK_DEFAULT_DATABASE}
  envsSetIfIsEmpty STACK_DEFAULT_DB_USERNAME ${STACK_DEFAULT_USERNAME}
  envsSetIfIsEmpty STACK_DEFAULT_DB_PASSWORD ${STACK_DEFAULT_PASSWORD}
  envsSetIfIsEmpty STACK_DEFAULT_DB_SCHEMA
  envsSetIfIsEmpty STACK_DEFAULT_DB_URL "jdbc:postgresql://${STACK_PREFIX_HOST}postgres:${STACK_DEFAULT_DB_PORT}/${STACK_DEFAULT_DB_NAME}"

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
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_REDIS "redis:bookworm"
  envsSetIfIsEmpty STACK_SERVICE_IMAGE_MSSQL "mcr.microsoft.com/mssql/server"

  

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
  unset __func_return
  local __local_add=()
  local __local_add+=(APPLICATION_ACTION)
  local __local_add+=(APPLICATION_DEPLOY_BACKUP_DIR)
  local __local_add+=(APPLICATION_DEPLOY_CPU)
  local __local_add+=(APPLICATION_DEPLOY_DATA_DIR)
  local __local_add+=(APPLICATION_DEPLOY_DNS)
  local __local_add+=(APPLICATION_DEPLOY_DNS_3RDPARTY)
  local __local_add+=(APPLICATION_DEPLOY_DNS_3RDPARTY_PATH)
  local __local_add+=(APPLICATION_DEPLOY_DNS_PATH)
  local __local_add+=(APPLICATION_DEPLOY_DNS_PUBLIC)
  local __local_add+=(APPLICATION_DEPLOY_DNS_PUBLIC_PATH)
  local __local_add+=(APPLICATION_DEPLOY_HEALTH_CHECK_INTERVAL)
  local __local_add+=(APPLICATION_DEPLOY_HEALTH_CHECK_RETRIES)
  local __local_add+=(APPLICATION_DEPLOY_HEALTH_CHECK_TIMEOUT)
  local __local_add+=(APPLICATION_DEPLOY_HOSTNAME)
  local __local_add+=(APPLICATION_DEPLOY_IMAGE)
  local __local_add+=(APPLICATION_DEPLOY_MEMORY)
  local __local_add+=(APPLICATION_DEPLOY_MODE)
  local __local_add+=(APPLICATION_DEPLOY_NETWORK_NAME)
  local __local_add+=(APPLICATION_DEPLOY_NODE)
  local __local_add+=(APPLICATION_DEPLOY_NODE_DB)
  local __local_add+=(APPLICATION_DEPLOY_NODE_FW)
  local __local_add+=(APPLICATION_DEPLOY_NODE_SERVICES)
  local __local_add+=(APPLICATION_DEPLOY_NODE_TOOL)
  local __local_add+=(APPLICATION_DEPLOY_PORT)
  local __local_add+=(APPLICATION_DEPLOY_REPLICAS)
  local __local_add+=(APPLICATION_DEPLOY_SHELF_LIFE)
  local __local_add+=(APPLICATION_DEPLOY_FILE)
  local __local_add+=(APPLICATION_ENV_FILE)
  local __local_add+=(APPLICATION_ENV_TAGS)
  local __local_add+=(APPLICATION_GIT)
  local __local_add+=(APPLICATION_GIT_BRANCH)
  local __local_add+=(APPLICATION_DEPLOY_NAME)
  local __local_add+=(APPLICATION_STACK)
  local __local_add+=(APPLICATION_DEPLOY_VAULT_IMPORT)
  local __local_add+=(APPLICATION_DEPLOY_VAULT_METHOD)
  local __local_add+=(APPLICATION_DEPLOY_VAULT_TOKEN)
  local __local_add+=(APPLICATION_DEPLOY_VAULT_URI)
  local __local_add+=(APPLICATION_DEPLOY_VAULT_APP_ROLE_ID)
  local __local_add+=(APPLICATION_DEPLOY_VAULT_APP_ROLE_SECRET)
  local __local_add+=(APPLICATION_DEPLOY_VAULT_ENABLED)

  envsFileAddIfNotExists "${1}" "${__local_add[@]}"  
  
  return 1
}

function stackEnvsClearByStack()
{
  unset __func_return
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
  unset __func_return
  local __environment=${1}
  local __target=${2}
  local __stack_name=${3}

  if [[ ${__environment} == "" ]]; then
    export __func_return="Invaid env: \${__environment}"
    return 0;
  elif [[ ${__target} == "" ]]; then
    export __func_return="Invaid env: \${__target}"
    return 0;
  elif [[ ${__stack_name} == "" ]]; then
    export __func_return="Invaid env: \${__stack_name}"
    return 0;
  fi

  stackEnvsLoad "${__environment}" "${__target}"
  if [[ ${STACK_ENVIRONMENT} == "" ]]; then
    export __func_return="fail on calling stackEnvsLoad: env: \${STACK_ENVIRONMENT}"
    return 0;
  fi

  if [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="fail on calling stackEnvsLoad: env: \${STACK_TARGET}"
    return 0;
  fi

  __private_stackEnvsLoadByStack "${__stack_name}"
  __private_stackEnvsDefaultByStack ${__environment} ${__target} ${__stack_name}
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
  unset __func_return
  stackStorageMake
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackStorageMake, ${__func_return}"
    return 0;
  fi
  dockerNetworkCreate "${STACK_NETWORK_DEFAULT} ${STACK_NETWORK_SECURITY} ${STACK_NETWORK_SRE} ${STACK_NETWORK_GRAFANA_LOKI} ${STACK_NETWORK_GRAFANA_TEMPO} ${STACK_NETWORK_GRAFANA_K6} ${STACK_NETWORK_KONG} ${STACK_NETWORK_CAMUNDA}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling dockerNetworkCreate, ${__func_return}"
    return 0;
  fi
  return 1
}

function stackPublicEnvsConfigure()
{
  unset __func_return
  local __bashrc="${HOME}/.bashrc"
  local __envFile=$(basename ${PUBLIC_STACK_ENVS_FILE})
  local __envs_args="STACK_TARGET STACK_ENVIRONMENT STACK_ROOT_DIR QT_VERSION"
  local __envs=(${__envs_args})
  if ! [[ -f ${PUBLIC_STACK_ENVS_FILE} ]]; then
    echo "#!/bin/bash">${PUBLIC_STACK_ENVS_FILE}
  fi
  local __env=
  for __env in ${__envs[*]}; 
  do
    sed -i "/${__env}/d" ${__bashrc}
    sed -i "/${__env}/d" ${PUBLIC_STACK_ENVS_FILE}
    echo "export ${__env}=${!__env}">>${PUBLIC_STACK_ENVS_FILE}
  done

  sed -i "/${__envFile}/d" ${__bashrc}
  echo "source ${PUBLIC_STACK_ENVS_FILE}">>${__bashrc}
  chmod +x ${PUBLIC_STACK_ENVS_FILE}
  source ${PUBLIC_STACK_ENVS_FILE}
  utilPrepareInit "${STACK_ENVIRONMENT}" "${STACK_TARGET}"
}

function stackPublicEnvs()
{
  unset __func_return
  clearTerm

  stackPublicEnvsConfigure
  while :
  do
    clearTerm
    __private_print_os_information
    echM "Current public envs values"
    local __env=
    for __env in ${__envs[*]}; 
    do
      echY "  - ${__env}: ${!__env}"
    done
    selector "Select env to edit" "Back ${__envs_args}" false
    if [[ ${__selector} == "Back" ]]; then
      return 1;
    else
      printf "set ${__selector}: "
      read __env_value
      export ${__selector}=${__env_value}
      stackPublicEnvsConfigure
    fi
  done

  return 1

}

function stackVaultLogoff()
{
  unset __func_return
  vaultLogoff
}

function stackVaultLogin()
{
  unset __func_return 
  vaultLogin "${STACK_ENVIRONMENT}" "${STACK_VAULT_IMPORT}" "${STACK_VAULT_METHOD}" "${STACK_VAULT_URI}" "${STACK_VAULT_TOKEN}" "${STACK_VAULT_APP_ROLE_ID}" "${STACK_VAULT_APP_ROLE_SECRET}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling vaultLogin: ${__func_return}"
    return 0;
  fi
  return 1;
}

function stackVaultList()
{
  unset __func_return
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
    local __key=
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

function stackVaultPull()
{
  unset __func_return
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

function stackVaultPush()
{
  unset __func_return
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

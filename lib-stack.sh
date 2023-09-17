#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-docker.sh

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


function stackMkDir_lib_configure()
{
  envsSetIfIsEmpty STACK_LIB_DIR "${ROOT_APPLICATIONS_DIR}/lib"
  if [[ ${STACK_LIB_DIR} == "" ]]; then
    export __func_return="invalid env \${STACK_LIB_DIR}"
    return 1;
  fi

  if [[ -d ${STACK_LIB_DIR} ]]; then
    return 1;
  fi

  stackMkDir_lib_configure_dirs=("/data/lib" "/data/lib.dir" "/mnt/storage/lib.dir")
  for stackMkDir_lib_configure_dir in "${stackMkDir_lib_configure_dirs[@]}"
  do
    if ! [[ -d ${stackMkDir_lib_configure_dir} ]]; then
      continue;
    fi
    echo $(ln -s ${stackMkDir_lib_configure_dir} ${STACK_LIB_DIR})&>/dev/null
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
  stackMkDir 755 "${STACK_ROOT_DIR}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="No create \${STACK_ROOT_DIR}: ${STACK_ROOT_DIR}"
    return 0;
  fi

  stackMkDir 755 "${STACK_INFRA_DIR} ${ROOT_APPLICATIONS_DIR} ${ROOT_TARGET_DIR} ${STACK_CERT_DEFAULT_DIR} ${ROOT_ENVIRONMENT_DIR} ${STACK_INFRA_DIR}"
  stackMkDir 777 "${STORAGE_SERVICE_DIR}"


  stackMkDir_lib_configure
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackMkDir_lib_configure: ${__func_return}"
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
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_CPU_DEFAULT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_MEMORY_DEFAULT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEPLOY_REPLICAS
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEPLOY_SHELF_LIFE
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEPLOY_HEALTH_CHECK_INTERVAL
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEPLOY_HEALTH_CHECK_TIMEOUT
  envsFileAddIfNotExists ${PUBLIC_STACK_TARGET_ENVS_FILE} STACK_DEPLOY_HEALTH_CHECK_RETRIES


  echo $(chmod +x ${PUBLIC_STACK_TARGET_ENVS_FILE})&>/dev/null
  return 1
}

function __private_stackEnvsLoadByStack()
{
  export STACK_NAME=${1}
  export STACK_IMAGE_NAME=
  export STACK_SERVICE_NAME=
  export STACK_SERVICE_HOSTNAME=
  export STACK_SERVICE_HOSTNAME_PUBLIC=
  export STACK_SERVICE_STORAGE_DATA_DIR=
  export STACK_SERVICE_STORAGE_BACKUP_DIR=

  if [[ ${STACK_NAME} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_NAME}"
    return 0
  fi
  if [[ ${STACK_PREFIX} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_PREFIX}"
    return 0
  fi
  __private_services_names_configure_name=${2}

  export STACK_SERVICE_NAME=$(echo "${STACK_PREFIX}-${STACK_NAME}" | sed 's/_/-/g')

  export __private_stackEnvsLoadByStack_storage=${STACK_TARGET_STORAGE_DIR}/${STACK_SERVICE_NAME}
  export STACK_SERVICE_STORAGE_DATA_DIR=${__private_stackEnvsLoadByStack_storage}/data
  export STACK_SERVICE_STORAGE_BACKUP_DIR=${__private_stackEnvsLoadByStack_storage}/backup

  export STACK_IMAGE_NAME="${STACK_SERVICE_NAME}"
  export STACK_IMAGE_NAME_URL="${STACK_REGISTRY_DNS_PUBLIC}/${STACK_IMAGE_NAME}"

  export STACK_SERVICE_HOSTNAME=${STACK_SERVICE_NAME}
  export STACK_SERVICE_HOSTNAME_PUBLIC=${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}

  stackMkDir 755 "${STACK_SERVICE_STORAGE_DATA_DIR} ${STACK_SERVICE_STORAGE_BACKUP_DIR}"

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
  export STACK_INFRA_DIR=
  export STACK_INFRA_CONF_DIR=
  export STACK_REGISTRY_DNS_PUBLIC=
  export PUBLIC_STACK_TARGET_ENVS_FILE=

  if [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByTarget, invalid env \${STACK_TARGET}"
    return 0
  fi

  export STACK_PREFIX="${STACK_ENVIRONMENT}-${STACK_TARGET}"
  #dirs
  export ROOT_TARGET_DIR="${ROOT_ENVIRONMENT_DIR}/${STACK_TARGET}"
  export STACK_INFRA_DIR="${ROOT_TARGET_DIR}/infrastructure"
  export STACK_INFRA_CONF_DIR="${ROOT_TARGET_DIR}/infrastructure/conf"
  export STACK_TEMPLATES_DIR="${ROOT_TARGET_DIR}/templates"
  export STACK_TARGET_STORAGE_DIR=${ROOT_TARGET_DIR}/storage-data


  stackMkDir 755 "${ROOT_TARGET_DIR} ${STACK_INFRA_DIR} ${STACK_INFRA_CONF_DIR} ${STACK_TARGET_STORAGE_DIR}"

  envsSetIfIsEmpty STACK_NETWORK_DEFAULT "${STACK_ENVIRONMENT}-${STACK_TARGET}-inbound"
  envsSetIfIsEmpty STACK_REGISTRY_DNS_PUBLIC "${STACK_PREFIX}-registry.${STACK_DOMAIN}:5000"
  envsSetIfIsEmpty PUBLIC_STACK_ENVS_FILE "${STACK_ROOT_DIR}/stack_envs.env"
  envsSetIfIsEmpty PUBLIC_STACK_TARGET_ENVS_FILE "${ROOT_TARGET_DIR}/stack_envs.env"
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
  #remove barra no final
  export STACK_ROOT_DIR=$(dirname ${STACK_ROOT_DIR}/teste)

  export ROOT_APPLICATIONS_DIR="${STACK_ROOT_DIR}/applications"
  export ROOT_ENVIRONMENT_DIR=${ROOT_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}
  export STACK_CERT_DEFAULT_DIR="${ROOT_APPLICATIONS_DIR}/certs"
  export PUBLIC_STACK_TARGETS_FILE="${ROOT_APPLICATIONS_DIR}/stack_targets.env"
  export PUBLIC_STACK_ENVIRONMENTS_FILE="${ROOT_APPLICATIONS_DIR}/stack_environments.env"

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
  envsSetIfIsEmpty STACK_CPU_DEFAULT 1
  envsSetIfIsEmpty STACK_MEMORY_DEFAULT "1GB"
  envsSetIfIsEmpty STACK_DEPLOY_REPLICAS 1

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
  envsSetIfIsEmpty STACK_SERVICE_DEFAULT_CONTEXT_PATH "/"

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
  envsSetIfIsEmpty STACK_SERVICE_SHELF_LIFE "24h"
  envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_INTERVAL "30s"
  envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_TIMEOUT "5s"
  envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_RETRIES "5"

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

function stackEnvsClearByStack()
{
  export APPLICATION_STACK=
  export APPLICATION_NAME=
  export APPLICATION_GIT=
  export APPLICATION_GIT_BRANCH=
  export APPLICATION_DEPLOY_PORT=
  export APPLICATION_DEPLOY_DNS=
  export APPLICATION_DEPLOY_DNS_PATH=
  export APPLICATION_DEPLOY_DNS_PUBLIC=
  export APPLICATION_DEPLOY_DNS_PUBLIC_PATH=
  export APPLICATION_DEPLOY_DNS_3RDPARTY=
  export APPLICATION_DEPLOY_DNS_3RDPARTY_PATH=
  export APPLICATION_DEPLOY_IMAGE=
  export APPLICATION_DEPLOY_HOSTNAME=
  export APPLICATION_DEPLOY_NODE=
  export APPLICATION_DEPLOY_MODE=
  export APPLICATION_DEPLOY_REPLICAS=
  export APPLICATION_DEPLOY_DATA_DIR=
  export APPLICATION_DEPLOY_BACKUP_DIR=
  export APPLICATION_DEPLOY_NETWORK_NAME=

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
  elif [[ ${STACK_IMAGE_NAME} == ""  ]]; then
    echFail "${1}" "fail on calling __private_stackEnvsLoadByStack, invalid env \${STACK_IMAGE_NAME}"
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
  dockerNetworkCreate "${STACK_NETWORK_DEFAULT}"
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

function __lib_stack_tests()
{
  stackEnvsLoad development company
  echo "stackEnvsLoad::${__func_return}"
  stackEnvsLoadByStack development company appTest
  echo "stackEnvsLoadByStack::${__func_return}"
  return 1;
}

#__lib_stack_tests

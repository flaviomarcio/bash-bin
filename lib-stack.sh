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
. ${BASH_BIN}/lib-ssl.sh

function __private_envsLoadTraefik()
{
  unset __func_return
  local __domain=${1}

  envsSetIfIsEmpty STACK_TRAEFIK_USER ${STACK_SERVICE_DEFAULT_USER}
  envsSetIfIsEmpty STACK_TRAEFIK_PASS ${STACK_SERVICE_DEFAULT_PASS}
  envsSetIfIsEmpty STACK_TRAEFIK_API_ENABLED false
  envsSetIfIsEmpty STACK_TRAEFIK_DASHBOARD_ENABLED false
  envsSetIfIsEmpty STACK_TRAEFIK_API_INSECURE true
  envsSetIfIsEmpty STACK_TRAEFIK_TLS_ENABLED false
  envsSetIfIsEmpty STACK_TRAEFIK_TLS_DOMAIN ${__domain}
  envsSetIfIsEmpty STACK_TRAEFIK_TLS_DOMAIN_SANS "*.${__domain}"

  envsSetIfIsEmpty STACK_TRAEFIK_PORT_HTTP "${STACK_PROXY_PORT_HTTP}"
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_HTTPS "${STACK_PROXY_PORT_HTTPS}"
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_VAULT 8200
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_REGISTRY 5000
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_POSTGRES 5432
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_RABBITMQ 5672
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_INFLUXDB 8086
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_MYSQL 3306
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_REDIS 6379
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_MSSQL 1433
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_ACTIVEMQ 61616
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_CASSANDRA 9042
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_LOCALSTACK 4566
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_S3 9000
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_NFS 2049
  envsSetIfIsEmpty STACK_TRAEFIK_PORT_MEMCACHED 11211

  return 1
}

function __private_envsLoadHaProxy()
{
  unset __func_return

  envsSetIfIsEmpty STACK_PROXY_PORT_HTTP "${STACK_PROXY_PORT_HTTP}"
  envsSetIfIsEmpty STACK_PROXY_PORT_HTTPS "${STACK_PROXY_PORT_HTTPS}"

  return 1
}

function __private_envsLoadGoCD()
{
  #gocd
  envsSetIfIsEmpty STACK_GOCD_REGISTER_KEY "00000000-0000-0000-0000-000000000000"
  envsSetIfIsEmpty STACK_GOCD_WEB_HOOK_SECRET "00000000-0000-0000-0000-000000000000"
  envsSetIfIsEmpty STACK_GOCD_SERVER_ID "00000000-0000-0000-0000-000000000000"
  envsSetIfIsEmpty STACK_GOCD_GIT_REPOSITORY
  envsSetIfIsEmpty STACK_GOCD_GIT_BRANCH
  envsSetIfIsEmpty STACK_GOCD_AGENT_REPLICAS 1
  return 1
}


function __private_stackEnvsLoadByStack()
{
  unset __func_return
  export STACK_NAME=${1}

  unset STACK_SERVICE_IMAGE
  unset STACK_SERVICE_NAME
  envsUnSet STACK_SERVICE_HOSTNAME STACK_SERVICE_STORAGE_

  if [[ ${STACK_DOMAIN} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_DOMAIN}"
    return 0
  elif [[ ${STACK_NAME} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_NAME}"
    return 0
  elif [[ ${STACK_PREFIX} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByStack, invalid env \${STACK_PREFIX}"
    return 0
  else
    local __private_services_names_configure_name=${2}

    local __stack_name_parser=$(echo ${STACK_NAME} | sed 's/_/-/g')

    export STACK_SERVICE_NAME=${STACK_PREFIX}-${__stack_name_parser}

    #hostnames
    export STACK_SERVICE_HOSTNAME="${STACK_PREFIX_HOST}${__stack_name_parser}"
    export STACK_SERVICE_HOSTNAME_PROXY=${STACK_SERVICE_NAME}
    export STACK_SERVICE_HOSTNAME_PUBLIC=${STACK_SERVICE_NAME}.${STACK_DOMAIN}


    # export STACK_SERVICE_STORAGE_DATA_DIR="${__storage_base_dir}data"
    # export STACK_SERVICE_STORAGE_DB_DIR="${__storage_base_dir}db"
    # export STACK_SERVICE_STORAGE_LOG_DIR="${__storage_base_dir}log"
    # export STACK_SERVICE_STORAGE_CONFIG_DIR="${__storage_base_dir}config"
    # export STACK_SERVICE_STORAGE_BACKUP_DIR="${__storage_base_dir}backup"
    # export STACK_SERVICE_STORAGE_EXTENSION_DIR="${__storage_base_dir}extension"
    # export STACK_SERVICE_STORAGE_PLUGIN_DIR="${__storage_base_dir}plugin"
    # export STACK_SERVICE_STORAGE_ADDON_DIR="${__storage_base_dir}addon"
    # export STACK_SERVICE_STORAGE_IMPORT_DIR="${__storage_base_dir}import"
    # export STACK_SERVICE_STORAGE_PROVIDER_DIR="${__storage_base_dir}provider"
    # export STACK_SERVICE_STORAGE_CERT_DIR="${__storage_base_dir}certificates"
    # export STACK_SERVICE_STORAGE_THEME_DIR="${__storage_base_dir}theme"
    # export STACK_SERVICE_STORAGE_SSH_DIR="${__storage_base_dir}ssh"

    #image
    export STACK_SERVICE_IMAGE="${STACK_SERVICE_NAME}"
    export STACK_SERVICE_IMAGE_URL="${PUBLIC_STACK_REGISTRY_DNS}/${STACK_SERVICE_IMAGE}"

    #load envs DNS
    stackMakeStructure
    if ! [ "$?" -eq 1 ]; then
      export __func_return="fail on calling stackMakeStructure, ${__func_return}"
      return 0;
    fi
    return 1

  fi
}

function __private_stackEnvsLoadByTarget()
{
  unset __func_return
  export STACK_TARGET=${1}
  unset STACK_INFRA_DIR
  unset STACK_INFRA_CERT_DIR
  unset STACK_INFRA_CONF_DIR
  unset PUBLIC_STACK_REGISTRY_DNS
  unset PUBLIC_STACK_TARGET_ENVS_FILE

  if [[ ${STACK_TARGET} == "" ]]; then
    export __func_return="failt on calling __private_stackEnvsLoadByTarget, invalid env \${STACK_TARGET}"
    return 0
  fi

  #dirs
  export STACK_TARGET_ROOT_DIR="${ROOT_ENVIRONMENT_DIR}/${STACK_TARGET}"
  export STACK_INFRA_DIR="${STACK_TARGET_ROOT_DIR}/infrastructure"
  export STACK_INFRA_CONF_DIR="${STACK_TARGET_ROOT_DIR}/infrastructure/conf"
  export STACK_INFRA_CERT_DIR="${STACK_INFRA_CONF_DIR}/cert"
  export STACK_TEMPLATES_DIR="${STACK_TARGET_ROOT_DIR}/templates"
  
  stackMkDir 755 "${STACK_TARGET_ROOT_DIR} ${STACK_INFRA_CERT_DIR} ${STACK_INFRA_DIR} ${STACK_INFRA_CONF_DIR} ${STACK_STORAGE_DIR}"

  envsSetIfIsEmpty STACK_NETWORK_PREFIX "${STACK_ENVIRONMENT}-${STACK_TARGET}"
  envsSetIfIsEmpty STACK_NETWORK_DEFAULT "${STACK_NETWORK_PREFIX}-inbound"
  envsSetIfIsEmpty STACK_NETWORK_SECURITY "${STACK_NETWORK_PREFIX}-security"
  envsSetIfIsEmpty STACK_NETWORK_CAMUNDA "${STACK_NETWORK_PREFIX}-camunda"
  envsSetIfIsEmpty STACK_NETWORK_SRE "${STACK_NETWORK_PREFIX}-sre"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_LOKI "${STACK_NETWORK_PREFIX}-grafana-loki"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_TEMPO "${STACK_NETWORK_PREFIX}-grafana-tempo"
  envsSetIfIsEmpty STACK_NETWORK_GRAFANA_K6 "${STACK_NETWORK_PREFIX}-grafana-k6"
  envsSetIfIsEmpty STACK_NETWORK_KONG "${STACK_NETWORK_PREFIX}-kong-net"

  envsSetIfIsEmpty PUBLIC_STACK_FIX_ENVS_FILE "${STACK_DATA_DIR}/stack_envs.env"
  envsSetIfIsEmpty PUBLIC_STACK_TARGET_ENVS_FILE "${STACK_TARGET_ROOT_DIR}/stack_envs.env"
   
  envsSetIfIsEmpty PUBLIC_STACK_REGISTRY_DNS "${STACK_ENVIRONMENT}-${STACK_TARGET}-registry.${STACK_DOMAIN}:5000"

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
  if [[ ${STACK_DOMAIN} != ""  ]]; then
    envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PUBLIC "${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}"
    envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_PUBLIC_PATH "${APPLICATION_DEPLOY_DNS_PATH}"
    envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_3RDPARTY "${STACK_ENVIRONMENT}-${STACK_SERVICE_HOSTNAME}.${STACK_DOMAIN}"
    envsSetIfIsEmpty APPLICATION_DEPLOY_DNS_3RDPARTY_PATH "${APPLICATION_DEPLOY_DNS_PATH}"
  fi

  envsSetIfIsEmpty APPLICATION_DEPLOY_IMAGE "${STACK_SERVICE_IMAGE_URL}"
  envsSetIfIsEmpty APPLICATION_DEPLOY_HOSTNAME ${STACK_SERVICE_HOSTNAME}  
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

function __private_storage_base_dir()
{
  if [[ ${STACK_NFS_ENABLED} == true ]]; then
    local __return=${STACK_NFS_REMOTE_DATA_DIR}/storage-data
  else
    local __return=${STACK_STORAGE_DIR}
  fi
  echo ${__return}
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

function stackSettingWrittenSingle()
{
  unset __func_return
  local __stack_name=${1}
  local __source_dir=${2}
  local __destine_dir=${3}
  # export STACK_SCOPE_INITED=

  if [[ ${__stack_name} == "" ]]; then
    export __func_return="Invalid env: \${__stack_name}"
    return 0;
  elif [[ ${__source_dir} == "" ]]; then
    export __func_return="Invalid env: \${__source_dir}"
    return 0;
  elif ! [[ -d ${__source_dir} ]]; then
    return 1;
  elif [[ ${__destine_dir} == "" ]]; then
    export __func_return="Invalid env: \${__destine_dir}"
    return 0;
  elif [[ ${STACK_CONFIG_LOCAL_DIR} == "" ]]; then
    export __func_return="Invalid env \${STACK_CONFIG_LOCAL_DIR}"
    return 0;
  elif ! [[ -d ${STACK_CONFIG_LOCAL_DIR} ]]; then
    export __func_return="Dir not found : ${STACK_CONFIG_LOCAL_DIR}"
    return 0;
  else
    # rm -rf ${__destine_dir}
    # mkdir ${__destine_dir}
    # if ! [[ -d ${__destine_dir} ]]; then
    #   mkdir ${__destine_dir}
    # fi

    if ! [[ -d ${__destine_dir} ]]; then
      export __func_return="Destine dir not found: ${__destine_dir}"
      return 0;      
    fi

    local __config_dir=$(dirname ${STACK_INFRA_CONF_DIR})

    echM "      Copying settings"
    echC "        Coping to volume: ${COLOR_BLUE}\${STACK_SERVICE_STORAGE_ICONFIG_DIR}: ${COLOR_YELLOW}${STACK_SERVICE_STORAGE_ICONFIG_DIR}"
    echC "          Executing..."
    #echB "           - rm ${COLOR_CIANO}-rf ${COLOR_YELLOW}${__destine_dir}"
    echB "            - export __source_dir=${COLOR_YELLOW}${__source_dir}"
    echB "            - export __destine_dir=${COLOR_YELLOW}${__destine_dir}"
    echB "            - cp ${COLOR_CIANO}-rf ${COLOR_YELLOW}\${__source_dir} \${__destine_dir}"

    function __parser_file()
    {
      local __file=${1}
      if ! [ -w "${__file}" ]; then
        echY "                - $(basename ${__file}) ${COLOR_GREEN}skipped, ${COLOR_RED}no writable"
      else
        local __ext=$(strExtractFileExtension ${__list_file})
        if [[ ${__ext} == "crt" || ${__ext} == "key" || ${__ext} == "csr" || ${__ext} == "pem" || ${__ext} == "ca" ]]; then
          echY "                - ${__file}, ${COLOR_GREEN}ignored"
        elif [[ ${__filter} == "sh" ]]; then
          echY "                - ${__file}, ${COLOR_GREEN}set +x"
          echo $(chmod +x ${__file})>/dev/null
        else
          local __ignore_check=$(cat ${__file} | grep "\#\[\[envs-ignore-replace\]\]")
          local __fileName=$(basename ${__file})
          if [[ ${__ignore_check} != "" ]]; then
            echY "                - ${__file} ${COLOR_GREEN}skipped, ${COLOR_BLUE}using ${COLOR_YELLOW}#[[envs-ignore-replace]]"
          else
            local __file_temp="/tmp/$(basename ${__file}).tmp"
            cat ${__file}>${__file_temp}
            echo $(envsubst < ${__file_temp} > ${__file})>/dev/null
            echY "                - ${__file}, ${COLOR_GREEN}parsed"
          fi
        fi
      fi
    }

    if ! [[ -w ${__destine_dir} ]]; then
      export __func_return="No writable directory ${__destine_dir}"
      return 0;
    fi

    #rm -rf ${__destine_dir} 2> /dev/null
    local __list_files=($(find ${__source_dir} -name '*.*'))
    local __list_file=
    for __list_file in ${__list_files[*]};
    do
      local __argA=$(echo ${__source_dir} | sed 's/\//\\\//g')
      local __argB=$(echo ${__destine_dir} | sed 's/\//\\\//g')
      local __list_file_dst=$(echo ${__list_file} | sed "s/${__argA}/${__argB}/g")
      local __fileName=$(basename ${__list_file})

      if [[ -f ${__list_file_dst} ]]; then
        local __ext=$(strExtractFileExtension ${__list_file})
        if [[ ${__ext} == "crt" || ${__ext} == "csr" || ${__ext} == "key" ]]; then
          echB "              - file exists ${COLOR_YELLOW}$(basename ${__list_file}), ${COLOR_GREEN}ignored ${COLOR_RED}special file"
          continue;
        fi
        unset __ext
      fi
      echB "              - copying ${COLOR_YELLOW}$(basename ${__list_file})"
      local __list_file_path=$(dirname ${__list_file_dst})
      mkdir -p ${__list_file_path}
      cp -rf ${__list_file} ${__list_file_dst} 2> /dev/null
      __parser_file ${__list_file_dst}

    done

    #cp -rf ${__source_dir} ${__destine_dir} 2> /dev/null

    local __filters=(sh cfg conf yml yaml hcl properties xml sql ldif)
    local __filter=
    echY "          Parsing ..."
    for __filter in ${__filters[*]};
    do
      local __files=$(find  ${__destine_dir} -iname "*.${__filter}" | sort)
      if [[ ${__files} != "" ]]; then
        echB "            - *.${__filter}${COLOR_GREEN}(FOUND)"

        local __files=(${__files})
        local __file=
        for __file in ${__files[*]};
        do
          __parser_file ${__file}
        done
      fi
    done 
    echG "        Finished"
    echG "      Finished"
  fi
  return 1

}

function stackSettingWritten()
{
  unset __func_return

  local __stack_name=${1}
  local __yml_file=${2}
  local __bash_file=${3}

  if [[ ${__stack_name} == "" ]]; then
    export __func_return="Invalid env \${__stack_name}"
    return 0;
  fi

  local __storage_base_dir=$(__private_storage_base_dir)
  # echo "\${STACK_NFS_ENABLED}: ${STACK_NFS_ENABLED}"
  # echo "\${STACK_NFS_REMOTE_DATA_DIR}: ${STACK_NFS_REMOTE_DATA_DIR}"
  # echo "\${STACK_STORAGE_DIR}: ${STACK_STORAGE_DIR}"
  # echo "\${__storage_base_dir}: ${__storage_base_dir}"

  local __vol_subdirs=(cert ssh iconfig letsencrypt)
  local __vol_subir=
  local __pwd=${PWD}

  for __vol_subir in ${__vol_subdirs[*]};
  do
    local __env_name=$(toUpper STACK_SERVICE_STORAGE_${__vol_subir}_DIR)
    local __check=$(cat ${__yml_file} | grep ${__env_name})
    if [[ ${__check} != "" ]]; then
      local __vol_dir="${__storage_base_dir}/${__stack_name}/${__vol_subir}"   

      if [[ ${__vol_subir} == "iconfig" ]]; then
        local __vol_dir="${STACK_STORAGE_DIR}/${__stack_name}/${__vol_subir}"   
        local __config_dir=${STACK_CONFIG_LOCAL_DIR}/${STACK_NAME}
        stackSettingWrittenSingle "${__stack_name}" "${__config_dir}" "${__vol_dir}"
        if ! [ "$?" -eq 1 ]; then
          export __func_return="fail on calling stackSettingWrittenSingle, ${__func_return}"
          return 0;
        fi
      elif [[ -d ${__vol_dir} ]]; then
        cd ${__vol_dir}
        if [[ ${__vol_subir} == "ssh" ]]; then
          local __rsa_key_name=id_rsa
          local __rsa_key_dest=${__vol_dir}
          local __rsa_key_repl=false
          rsaKeyCreate "${__rsa_key_name}" "${__rsa_key_dest}" "${__rsa_key_repl}"
          if ! [ "$?" -eq 1 ]; then
            export __func_return="fail on calling rsaKeyCreate, ${__func_return}"
            return 0;
          fi
        elif [[ ${__vol_subir} == "cert" ]]; then
          local __cert_name=cert
          local __cert_days=""
          local __cert_pass=""
          local __cert_dest=${__vol_dir}
          local __cert_repl=false
          certCreate "${__cert_name}" "${__cert_days}" "${__cert_pass}" "${__cert_dest}" "${__cert_repl}"
          if ! [ "$?" -eq 1 ]; then
            export __func_return="fail on calling certCreate, ${__func_return}"
            return 0;
          fi
        fi
      fi
    fi
  done
  return 1
}

function stackMkVolumes()
{
  unset __func_return

  local __stack_name=${1}
  local __yml_file=${2}
  local __vol_bash_file=${3}

  if [[ ${__stack_name} == "" ]]; then
    export __func_return="Invalid env \${__stack_name}"
    return 0;
  elif ! [[ -f ${__yml_file} ]]; then
    export __func_return="Invalid env \${__yml_file}"
    return 0;
  else
    local __storage_base_dir=$(__private_storage_base_dir)

    local __vol_subdirs=(data db log config backup extension plugin addon import provider cert theme ssh m2 iconfig letsencrypt shared script agent_data)
    local __vol_subir=

    local __vol_dir=
    bashAppend "${__vol_bash_file}" "export volumeBaseDir=${STACK_STORAGE_DIR}/${__stack_name}"
    #criar localmente os diretorios remotos
    for __vol_subir in ${__vol_subdirs[*]};
    do
      local __env_name=$(toUpper STACK_SERVICE_STORAGE_${__vol_subir}_DIR)
      stackMkDir 777 "${STACK_STORAGE_DIR}/${__stack_name}/${__vol_subir}"
      local __check=$(cat ${__yml_file} | grep ${__env_name})
      if [[ ${__check} != "" ]]; then
        bashAppend "${__vol_bash_file}" "mkdir -p \${volumeBaseDir}/${__vol_subir}"
        bashAppend "${__vol_bash_file}" "chmod 777 \${volumeBaseDir}/${__vol_subir}"
      fi
    done

    #loop para criar apenas os volumes defininos no docker-compose.yml
    for __vol_subir in ${__vol_subdirs[*]};
    do
      local __env_name=$(toUpper STACK_SERVICE_STORAGE_${__vol_subir}_DIR)
      local __env_value=$(toLower "${__stack_name}_${__vol_subir}" | sed 's/-/_/g')
      local __vol_dir="${__storage_base_dir}/${__stack_name}/${__vol_subir}"

      local __check=$(cat ${__yml_file} | grep ${__env_name})
      if [[ ${__check} != "" ]]; then
        export ${__env_name}=${__env_value}
        if [[ ${STACK_NFS_ENABLED} == true ]]; then
          dockerVolumeCreateNFS "${__env_value}" "${STACK_NFS_SERVER}" "${__vol_dir}" "${__vol_bash_file}"
          if ! [ "$?" -eq 1 ]; then
            export __func_return="fail on calling dockerVolumeCreateNFS, ${__func_return}"
            return 0;
          fi
        else
          dockerVolumeCreateLocal "${__env_value}" "${__vol_dir}" "${__vol_bash_file}"
          if ! [ "$?" -eq 1 ]; then
            export __func_return="fail on calling dockerVolumeCreateLocal, ${__func_return}"
            return 0;
          fi
        fi
      fi
    done
    return 1
  fi
}

function stackVolumePrepare()
{
  local __service_name=${1}
  local __compose_file_dst=${2}
  local __bash_file=${3}
  stackMkVolumes "${__service_name}" "${__compose_file_dst}" "${__bash_file}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackMkVolumes, ${__func_return}"
    return 0;
  fi
  stackSettingWritten "${__service_name}" "${__compose_file_dst}" "${__bash_file}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling stackSettingWritten, ${__func_return}"
    return 0;
  fi

  return 1
}

function stackEnvironmentConfigure()
{
  clearTerm

  local __root_dir=${STACK_DATA_DIR}
  local __environment=${STACK_ENVIRONMENT}
  local __target=${STACK_TARGET}
  local __domain=${STACK_DOMAIN}

  echM $'\n'"Configure environments ${STACK_PREFIX}"$'\n'

  function __select_root_dir()
  {
    unset __func_return
    if [[ ${STACK_ROOT_DIR} != "" ]]; then
      local __default=${STACK_ROOT_DIR}
    else
      local __default=${HOME}/stack-root-dir
    fi
    echC ""
    echM "New value"
    echC "  - Set root-dir, default: ${COLOR_YELLOW}[${__default}]"$'\n'
    read __value
    if [[ ${__value} == "" ]]; then
      local __value=${__default}
    fi
    export __func_return=${__value}
    return 1
  }

  function __select_environment()
  {
    unset __func_return
    if [[ ${STACK_DOMAIN} != "" ]]; then
      local __default=${STACK_ENVIRONMENT}
    else
      local __default=testing
    fi
    local options=(Back testing development staging production)
    echC ""
    echM "New value"
    echC "  - Set environment, default: ${COLOR_YELLOW}[${__default}]"$'\n'
    PS3=$'\n'"Choose option:"
    select opt in "${options[@]}"
    do
      if [[ ${opt} == "Back" ]]; then
        retuirn 2
      else
        local __env=
        for __env in ${options[*]};
        do
          if [[ "${__env}" == "${opt}" ]]; then
            export __func_return=${opt}
            return 1;
          fi
        done
      fi
    done
    return 0
  }

  function __select_target()
  {
    unset __func_return
    if [[ ${STACK_DOMAIN} != "" ]]; then
      local __default=${STACK_TARGET}
    else
      local __default=company
    fi
    echC ""
    echM "New value"
    echC "  - Set target, default: ${COLOR_YELLOW}[${__default}]"$'\n'
    read __value
    if [[ ${__value} == "" ]]; then
      local __value=${__default}
    fi
    export __func_return=${__value}
    return 1
  }

  function __select_domain()
  {
    unset __func_return
    if [[ ${STACK_DOMAIN} != "" ]]; then
      local __default=${STACK_DOMAIN}
    else
      local __default=${__target}.local
    fi
    echM ""
    echM "New value"
    echC "  - Set domain, default: ${COLOR_YELLOW}[${__default}]"$'\n'
    read __value
    if [[ ${__value} == "" ]]; then
      local __value=${__default}
    fi
    export __func_return=${__value}
    return 1
  }

  function __select_print()
  {
    clearTerm
    local __root_dir=${1}
    local __environment=${2}
    local __target=${3}
    local __domain=${4}
    echM "Values set"
    echC "  - STACK_ROOT_DIR: ${COLOR_YELLOW}${__root_dir}"
    echC "  - STACK_ENVIRONMENT: ${COLOR_YELLOW}${__environment}"
    echC "  - STACK_TARGET: ${COLOR_YELLOW}${__target}"
    echC "  - STACK_DOMAIN: ${COLOR_YELLOW}${__domain}"
    return 1
  }

  while :
  do
    __select_print "${__root_dir}" "${__environment}" "${__target}" "${__domain}"
    __select_root_dir
    local __ret="$?"
    if [[ "${__ret}" -eq 1 ]]; then
      local __root_dir=${__func_return}
      break
    elif [[ "${__ret}" -eq 2 ]]; then
      return 1
    fi
  done

  while :
  do
    __select_print "${__root_dir}" "${__environment}" "${__target}" "${__domain}"
    __select_environment
    local __ret="$?"
    if [[ "${__ret}" -eq 1 ]]; then
      local __environment=${__func_return}
      break
    elif [[ "${__ret}" -eq 2 ]]; then
      return 1
    fi
  done

  while :
  do
    __select_print "${__root_dir}" "${__environment}" "${__target}" "${__domain}"
    __select_target
    local __ret="$?"
    if [[ "${__ret}" -eq 1 ]]; then
      local __target=${__func_return}
      break
    elif [[ "${__ret}" -eq 2 ]]; then
      return 1
    fi
  done

  while :
  do
    __select_print "${__root_dir}" "${__environment}" "${__target}" "${__domain}"
    __select_domain
    local __ret="$?"
    if [[ "${__ret}" -eq 1 ]]; then
      local __domain=${__func_return}
      break
    elif [[ "${__ret}" -eq 2 ]]; then
      return 1
    fi
  done

  echG "Confirme values to write to ${COLOR_YELLOW}${PUBLIC_STACK_FIX_ENVS_FILE}"
  __select_print "${__root_dir}" "${__environment}" "${__target}" "${__domain}"

  echB ""
  echo -e -n "${COLOR_CIANO}Choose: ${COLOR_GREEN}Yes(Y|y), ${COLOR_CIANO}default: ${COLOR_YELLOW} [Y|y]: "
  local __value=
  read __value
  if [[  ${__value} == "" ]]; then
    local __value="Y"
  fi
  if [[ "${__value}" != "Y" && "${__value}" != "y" ]]; then
    return 1
  fi
  echC "    selected option: ${COLOR_YELLOW}[${__value}]"
  sleep 1

  sed -i '/STACK_ROOT_DIR/d' -i ${PUBLIC_STACK_FIX_ENVS_FILE}
  sed -i '/STACK_ENVIRONMENT/d' -i ${PUBLIC_STACK_FIX_ENVS_FILE}
  sed -i '/STACK_TARGET/d' -i ${PUBLIC_STACK_FIX_ENVS_FILE}
  sed -i '/STACK_DOMAIN/d' -i ${PUBLIC_STACK_FIX_ENVS_FILE}
  sed -i '/STACK_DATA_DIR/d' -i ${PUBLIC_STACK_FIX_ENVS_FILE}
  sed -i '/STACK_STORAGE_DIR/d' -i ${PUBLIC_STACK_FIX_ENVS_FILE}

  if ! [[ -f ${PUBLIC_STACK_FIX_ENVS_FILE} ]]; then
    echo "#!/bin/bash">${PUBLIC_STACK_FIX_ENVS_FILE}
  fi
  echo "">>${PUBLIC_STACK_FIX_ENVS_FILE}

  export STACK_ROOT_DIR=${__root_dir}
  export STACK_ENVIRONMENT=${__environment}
  export STACK_TARGET=${__target}
  export STACK_DOMAIN=${__domain}

  echG "  - To check, use the shell command: ${COLOR_YELLOW}# cat ${PUBLIC_STACK_FIX_ENVS_FILE}"
  echG ""
  echG "Successfull"

  if [[ -f ${PUBLIC_STACK_FIX_ENVS_FILE} ]]; then
    echo ""
    echM "Run in current terminal:"
    echY "  - source ${PUBLIC_STACK_FIX_ENVS_FILE}"  
    echG "Finished"
    echo ""
  fi

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

  return 1
}

function stackStorageMake()
{
  unset __func_return
  stackMkDir 755 "${STACK_DATA_DIR} ${STACK_STORAGE_DIR}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="No create \${STACK_DATA_DIR} \${STACK_STORAGE_DIR}"
    return 0;
  fi
  stackMkDir 755 "${ROOT_APPLICATIONS_DIR} ${STACK_TARGET_ROOT_DIR} ${STACK_CERT_DEFAULT_DIR} ${ROOT_ENVIRONMENT_DIR} ${STACK_INFRA_DIR}"
  stackMkDir 777 "${STORAGE_SERVICE_DIR}"
  return 1
}

function stackInitTargetEnvFile()
{
  unset __func_return
  if [[ ${PUBLIC_STACK_TARGET_ENVS_FILE} == "" ]]; then
    export __func_return="env \${PUBLIC_STACK_TARGET_ENVS_FILE} is empty on calling __private_initFilesStack"
    return 0
  fi
  if [[ ${__private_stackInitTargetEnvFile_inited} == 1 ]]; then
    return 1
  fi

  export __private_stackInitTargetEnvFile_inited=1

  #primary default envs

  #stack defaults
  local __local_add="
  STACK_TZ
  STACK_NO_DOCKER_RESET
  STACK_DOMAIN
  STACK_PREFIX_HOST_ENABLED
  $(envsGet STACK_ADMIN_ STACK_PROXY_ STACK_DEFAULT_ STACK_SERVICE_DEFAULT_ STACK_SERVICE_HEALTH_ STACK_GOCD_ STACK_SERVICE_IMAGE STACK_VOLUME_ STACK_LDAP_ STACK_TRAEFIK_ STACK_NFS_ POSTGRES_ STACK_VAULT_)
  "

  # save envs
  envsFileAddIfNotExists "${PUBLIC_STACK_TARGET_ENVS_FILE}" "${__local_add}"

  return 1
}

function stackPrepareInit()
{
  local __stack_environment=${1}
  local __stack_target=${2}
  local __stack_name=${3}

  if [[ ${__stack_name} == "" ]];then
    stackEnvsLoad "${__stack_environment}" "${__stack_target}"
    if ! [ "$?" -eq 1 ]; then
      export __func_return="fail on calling stackEnvsLoad, ${__func_return}"
      return 0;
    fi
  else
    stackEnvsLoadByStack "${__stack_environment}" "${__stack_target}" "${__stack_name}"
    if ! [ "$?" -eq 1 ]; then
      export __func_return="fail on calling stackEnvsLoadByStack, ${__func_return}"
      return 0;
    fi
  fi

  __private_envsLoadTraefik ${STACK_DOMAIN}
  if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __private_envsLoadTraefik: ${__func_return}"
    return 0;
  fi

  __private_envsLoadHaProxy ${STACK_DOMAIN}
    if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __private_envsLoadHaProxy: ${__func_return}"
    return 0;
  fi

  __private_envsLoadGoCD
    if ! [ "$?" -eq 1 ]; then
    export __func_return="fail on calling __private_envsLoadGoCD: ${__func_return}"
    return 0;
  fi

  export STACK_ACTIONS_DIR=${STACK_RUN_BIN}/actions
  export STACK_YML_DIR=${ROOT_DIR}/stack
  export STACK_PLUGINS_DIR=${ROOT_DIR}/plugins
  export STACK_IMAGES_DIR=${ROOT_DIR}/images
  export STACK_CONFIG_LOCAL_DIR=${ROOT_DIR}/conf

  stackInitTargetEnvFile

  return 1
}

function stackEnvsLoad()
{
  function __defaultCheck()
  {
    envsSetIfIsEmpty STACK_NO_DOCKER_RESET true
    #obrigatory envs
    envsSetIfIsEmpty STACK_TZ "America/Sao_Paulo"
    envsSetIfIsEmpty STACK_TARGET undefined
    envsSetIfIsEmpty STACK_DOMAIN "local"

    envsSetIfIsEmpty STACK_PROTOCOL http
    envsSetIfIsEmpty STACK_PROXY_PORT_HTTP 80
    envsSetIfIsEmpty STACK_PROXY_PORT_HTTPS 443
    envsSetIfIsEmpty STACK_PREFIX_HOST_ENABLED false

    #resources limit
    envsSetIfIsEmpty STACK_SERVICE_DEFAULT_SHELF_LIFE "24h"
    envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_INTERVAL "60s"
    envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_TIMEOUT "5s"
    envsSetIfIsEmpty STACK_SERVICE_HEALTH_CHECK_RETRIES "5"

    #services default images
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_DEBIAN "debian:latest"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_DNSMASQ "dockurr/dnsmasq:latest"
    
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_KONG "kong:3.7"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_TRAEFIK "traefik:v2.11.0"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_REGISTRY "registry:latest"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_POSTGRES_09 "postgres:9-bullseye"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_POSTGRES_15 "postgres:15-bullseye"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_POSTGRES_16 "postgres:16-bullseye"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_POSTGRES "${STACK_SERVICE_IMAGE_POSTGRES_16}"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_INFLUXDB "influxdb:1.8"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_MARIADB "lscr.io/linuxserver/mariadb"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_MYSQL "mysql:8.0.36-debian"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_REDIS "docker.io/bitnami/redis:7.2"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_MSSQL "mcr.microsoft.com/mssql/server"
    envsSetIfIsEmpty STACK_SERVICE_IMAGE_VAULT "hashicorp/vault:1.16"

    #VAULT
    envsSetIfIsEmpty STACK_VAULT_PORT 8200
    envsSetIfIsEmpty STACK_VAULT_URI "http://int-vault"
    envsSetIfIsEmpty STACK_VAULT_METHOD token
    envsSetIfIsEmpty STACK_VAULT_TOKEN "${STACK_SERVICE_DEFAULT_TOKEN}"
    envsSetIfIsEmpty STACK_VAULT_TOKEN_DEPLOY "${STACK_VAULT_TOKEN}"
    envsSetIfIsEmpty STACK_VAULT_APP_ROLE_ID "${STACK_SERVICE_DEFAULT_USER}"
    envsSetIfIsEmpty STACK_VAULT_APP_ROLE_SECRET "${STACK_SERVICE_DEFAULT_TOKEN}"
    envsSetIfIsEmpty STACK_VAULT_IMPORT "vault:/kv/${STACK_TARGET}/${STACK_ENVIRONMENT}"
    envsSetIfIsEmpty STACK_VAULT_ENABLED false

    envsSetIfIsEmpty STACK_DEFAULT_DEPLOY_CPU "1"
    envsSetIfIsEmpty STACK_DEFAULT_DEPLOY_MEMORY "2GB"
    envsSetIfIsEmpty STACK_DEFAULT_DEPLOY_REPLICAS 1

    #HAPROXY
    envsSetIfIsEmpty STACK_HAPROXY_CERT_DIR "${STACK_INFRA_CONF_DIR}/haproxy/cert"
    envsSetIfIsEmpty STACK_HAPROXY_CONFIG_FILE "${STACK_INFRA_CONF_DIR}/haproxy/haproxy.cfg"

    #NFS
    envsSetIfIsEmpty STACK_NFS_ENABLED false
    envsSetIfIsEmpty STACK_NFS_SERVER 127.0.0.1
    envsSetIfIsEmpty STACK_NFS_MOUNT_DIR /mnt/stack-data
    envsSetIfIsEmpty STACK_NFS_REMOTE_DATA_DIR "/mnt/stack-data"
    envsSetIfIsEmpty STACK_NFS_LOCAL_SHARE_DIR "/mnt/nfs_share"
    envsSetIfIsEmpty STACK_NFS_LOCAL_EXPORT_FILE "/etc/exports"

    #LDAP
    envsSetIfIsEmpty STACK_LDAP_DOMAIN "${STACK_TARGET}.int"
    envsSetIfIsEmpty STACK_LDAP_ROOT_DN "dc=${STACK_TARGET},dc=int"

  }
  unset __func_return
  unset PUBLIC_STACK_TARGETS_FILE
  local __environment=${1}
  local __target=${2}

  __defaultCheck

  if [[ ${__environment} == "" ]]; then
    export __func_return="Invalid env: \${__environment}"
  elif [[ ${__target} == "" ]]; then
    export __func_return="Invalid env: \${__target}"
  elif [[ ${STACK_DOMAIN} == "" ]]; then
    export __func_return="Invalid env: \${STACK_DOMAIN}"
  else
    export STACK_TARGET=${__target}

    export STACK_ENVIRONMENT="${__environment}"
    if [[ ${STACK_ENVIRONMENT} != "" && ${STACK_TARGET} != "" ]]; then
      export STACK_PREFIX="${STACK_ENVIRONMENT}-${STACK_TARGET}"
    fi
    export STACK_PREFIX_NAME=$(echo ${STACK_PREFIX} | sed 's/-/_/g')
    if [[ ${STACK_PREFIX_HOST_ENABLED} == true ]]; then
      export STACK_PREFIX_HOST="${STACK_PREFIX}-"
    else
      export STACK_PREFIX_HOST="int-"
    fi

    envsSetIfIsEmpty STACK_ROOT_DIR "${HOME}/stack-root-dir"
    export STACK_DATA_DIR=${STACK_ROOT_DIR}/data
    export STACK_STORAGE_DIR=${STACK_ROOT_DIR}/storage-data
    export ROOT_APPLICATIONS_DIR="${STACK_DATA_DIR}/applications"
    export ROOT_ENVIRONMENT_DIR=${ROOT_APPLICATIONS_DIR}/${STACK_ENVIRONMENT}
    export STACK_CERT_DEFAULT_DIR="${ROOT_APPLICATIONS_DIR}/certs"
    export PUBLIC_STACK_TARGETS_FILE="${ROOT_APPLICATIONS_DIR}/stack_targets.env"
    export PUBLIC_STACK_ENVIRONMENTS_FILE="${ROOT_APPLICATIONS_DIR}/stack_environments.env"

    mkdir -p ${STACK_STORAGE_DIR}
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
    __private_stackEnvsLoadByTarget ${__target}
    if ! [ "$?" -eq 1 ]; then
      export __func_return="fail on calling __private_stackEnvsLoadByTarget, ${__func_return}"
    elif [[ ${STACK_TARGET} == "" ]]; then
      export __func_return="fail on calling __private_stackEnvsLoadByTarget, env \${STACK_TARGET} not found"
    else
      __defaultCheck
      #cosntruira diretorios de envs carregadas
      stackStorageMake
      if ! [ "$?" -eq 1 ]; then
        export __func_return="fail on calling stackStorageMake, ${__func_return}"
      else
        #primary default envs
        envsSetIfIsEmpty STACK_ADMIN_USERNAME services
        envsSetIfIsEmpty STACK_ADMIN_PASSWORD services
        envsSetIfIsEmpty STACK_ADMIN_EMAIL services@services.com
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

        #temp
        export CUR_DATE="$(date +'%Y-%m-%d')"
        export CUR_TIME="$(date +'%H:%M:%S')"
        export CUR_DATETIME="$(date +'%Y-%m-%d')T$(date +'%H:%M:%S')"


        stackInitTargetEnvFile
        if ! [ "$?" -eq 1 ]; then
          export __func_return="fail on calling stackInitTargetEnvFile"
        else
          return 1
        fi
      fi
    fi
  fi
  return 0;
}

function stackEnvsByStackExportToFile()
{
  unset __func_return
  unset __local_add
  local __local_add="
                      $(printenv | awk -F '=' '{print $1}' | grep STACK_SERVICE_)
                      $(printenv | awk -F '=' '{print $1}' | grep APPLICATION_)
                    "
  envsFileAddIfNotExists "${1}" "${__local_add}"   
  cat ${1}
  return 1
}

function stackEnvsClearByStack()
{
  unset __func_return
  envsUnSet APPLICATION_
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
  else
    stackEnvsLoad "${__environment}" "${__target}"
    if [[ ${STACK_ENVIRONMENT} == "" ]]; then
      export __func_return="fail on calling stackEnvsLoad: env: \${STACK_ENVIRONMENT}"
      return 0;
    elif [[ ${STACK_TARGET} == "" ]]; then
      export __func_return="fail on calling stackEnvsLoad: env: \${STACK_TARGET}"
      return 0;
    else
      __private_stackEnvsLoadByStack "${__stack_name}"
      __private_stackEnvsDefaultByStack ${__environment} ${__target} ${__stack_name}
      if ! [ "$?" -eq 1 ]; then
        export __func_return="fail on calling __private_stackEnvsLoadByStack, ${__func_return}"
        return 0;
      elif [[ ${STACK_TARGET} == "" ]]; then
        export __func_return="fail on calling __private_stackEnvsLoadByStack: env: \${STACK_TARGET}"
        return 0;
      elif [[ ${STACK_ENVIRONMENT} == "" ]]; then
        export __func_return="fail on calling stackEnvsLoad, env \${STACK_ENVIRONMENT} not found"
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
    fi
  fi
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
  local __envFile=$(basename ${PUBLIC_STACK_FIX_ENVS_FILE})
  local __envs_args="STACK_TARGET STACK_ENVIRONMENT STACK_DATA_DIR QT_VERSION"
  local __envs=(${__envs_args})
  if ! [[ -f ${PUBLIC_STACK_FIX_ENVS_FILE} ]]; then
    echo "#!/bin/bash">${PUBLIC_STACK_FIX_ENVS_FILE}
  fi
  local __env=
  for __env in ${__envs[*]}; 
  do
    sed -i "/${__env}/d" ${__bashrc}
    sed -i "/${__env}/d" ${PUBLIC_STACK_FIX_ENVS_FILE}
    echo "export ${__env}=${!__env}">>${PUBLIC_STACK_FIX_ENVS_FILE}
  done

  sed -i "/${__envFile}/d" ${__bashrc}
  echo "source ${PUBLIC_STACK_FIX_ENVS_FILE}">>${__bashrc}
  chmod +x ${PUBLIC_STACK_FIX_ENVS_FILE}
  source ${PUBLIC_STACK_FIX_ENVS_FILE}
  stackPrepareInit "${STACK_ENVIRONMENT}" "${STACK_TARGET}"
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
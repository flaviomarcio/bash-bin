#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh
. ${BASH_BIN}/lib-util-date.sh

# export DOCKER_OPTION=
# export DOCKER_SCOPE=
# export DOCKER_DIR=

function __private_docker_envsubst()
{
  if [[ ${1} == "" ]]; then
    return 0
  fi
  local __private_docker_envsubst_files=(${1})
  for __private_docker_envsubst_file_src in "${__private_docker_envsubst_files[@]}"
  do
    if [[ -f ${__private_docker_envsubst_file_src} ]]; then
      local __private_docker_envsubst_file_ori=${__private_docker_envsubst_file_src}.ori
      cat ${__private_docker_envsubst_file_src}>${__private_docker_envsubst_file_ori}
      envsubst < ${__private_docker_envsubst_file_ori} > ${__private_docker_envsubst_file_src}
    fi
  done  

  return 1;
}

function __private_dockerParserName()
{
  # if [[ ${1} == "" ]]; then
  #   return 0;
  # fi
  echo ${1}
}

function __private_dockerParserServiceName()
{
  echo "$@"
}

function __private_dockerParserHostName()
{
  if [[ ${1} == "" ]]; then
    return 0;
  fi
  local __docker_parser_name=${1}
  local __docker_parser_tags=("_" "|" "\.")
  for __docker_parser_tag in "${__docker_parser_tags[@]}"
  do
    local __docker_parser_name=$(echo ${__docker_parser_name} | sed "s/${__docker_parser_tag}/-/g")
  done  
  echo ${__docker_parser_name}
}

function dockerSwarmState()
{
  echo $(docker info --format '{{ .Swarm.LocalNodeState }}')
  return 1
}

function dockerSwarmIsActive()
{
  local __check=$(dockerSwarmState)
  if [[ ${__check} == "active" ]]; then
    return 1;
  fi
  return 0;
}

function dockerSwarmVerify()
{
  dockerSwarmIsActive
  if [ "$?" -eq 1 ]; then
    return 1
  fi
  dockerSwarmInit true "${PUBLIC_HOST_IPv4}"
  if [ "$?" -eq 1 ]; then
    return 1
  fi
  return 0
}

function dockerCleanup()
{
  echM "    Docker cleanup"
  local __docker_cleanup_tags=${1}
  local __docker_cleanup_removed=false
  if [[ ${__docker_cleanup_tags} == "" ]]; then
    local __docker_cleanup_tags=($(docker service ls --quiet))
    for __docker_cleanup_tag in "${__docker_cleanup_tags[@]}"
    do
      local __docker_cleanup_tag=$(docker service inspect ${__docker_cleanup_tag} --format '{{ .Spec.Name }}')
      echR "      Removing service [${__docker_cleanup_tag}]..."
      echo $(docker --log-level ERROR service rm ${__docker_cleanup_tag} )&>/dev/null
      local __docker_cleanup_removed=true
    done
  else
    local __docker_cleanup_tags=($(__private_dockerParserServiceName ${__docker_cleanup_tags}))
    for __docker_cleanup_tag in "${__docker_cleanup_tags[@]}"
    do
      local __docker_cleanup_check=$(docker service ls | grep ${__docker_cleanup_tag} | awk '{print $1}')
      if [[ ${__docker_cleanup_check} != "" ]]; then
        break
      fi
    done

    for __docker_cleanup_tag in "${__docker_cleanup_tags[@]}"
    do
      local __docker_cleanup_cmd="docker --log-level ERROR service rm \$(docker service ls | grep ${__docker_cleanup_tag} | awk '{print \$1}')"
      echR "      Removing tag[${__docker_cleanup_tag}]..."
      echY "        - ${__docker_cleanup_cmd}"  
      local __docker_cleanup_check=$(docker service ls | grep ${__docker_cleanup_tag} | awk '{print $1}')
      if [[ ${__docker_cleanup_check} == "" ]]; then
        continue
      fi
      echo $(docker --log-level ERROR service rm $(docker service ls | grep ${__docker_cleanup_tag} | awk '{print $1}') )&>/dev/null
      local __docker_cleanup_removed=true
    done

  fi
    if [[ ${__docker_cleanup_removed} == false ]]; then
      echC "      - No services to clear"
      echG "    Finished"
      return 1
    fi
  echG "    Finished"
  return 1
}

function dockerPrune()
{
  local __cmd="docker --log-level ERROR system prune --all --volumes --force"
  echM "    Docker prune"
  echR "      Removing ..."
  echY "        - ${__cmd}"
  sleep 2
  for i in {1..5}
  do
    echB "        - step: ${i}"
    echo $(${__cmd})&>/dev/null
    sleep 1
  done
  echG "    Finished"
}

function dockerReset()
{
  echo ""
  echR "  =============================  "
  echR "  ***********CRITICAL**********  "
  echR "  =============================  "
  echo ""
  echY "  =============================  "
  echY "  ********DOCKER RESET*********  "
  echY "  =============================  "
  echo ""
  selectorWaitSeconds 3 "" "${COLOR_YELLOW_B}"

  selectorYesNo "Docker reset"
  if ! [ "$?" -eq 1 ]; then
    return 1
  fi
  echo ""
  echR "  =============================  "
  echR "  ***********CRITICAL**********  "
  echR "  =============================  "
  echo ""
  echY "  =============================  "
  echY "  ********DOCKER RESET*********  "
  echY "  =============================  "
  echo ""
  selectorWaitSeconds 10 "" "${COLOR_YELLOW_B}"
  # local __docker_reset_tags=${1}
  echG "  Docker reset"
  dockerCleanup
  dockerPrune
  echG "  Finished"
}

function dockerList()
{
  while :
  do
    clear
    docker service ls
    echo ""
    echG "[CTRL+C] para sair"
    echo ""
    sleep 2
  done
}

function dockerSwarmInit()
{
  local __action=${1}
  local __swarm_ip=${2}

  if [[ ${STACK_DNS_SERVER_ENABLE} == true ]]; then
    local __cmd="docker swarm init --dns ${STACK_PREFIX_HOST}dnsserver --advertise-addr ${__swarm_ip}"
  else
    local __cmd="docker swarm init --advertise-addr ${__swarm_ip}"
  fi

  if [[ ${__action} == true ]]; then
    clearTerm
    echB "  Docker swarm não está instalado"
    echG ""
    echG "  [ENTER] para configurar"
    echG ""
    read
    echB "  Action: [Swam-Init]"
    echY "    - ${__cmd}"
    echB "  Executing ..."
    echo $(${__cmd})
    dockerSwarmIsActive
    if [ "$?" -eq 1 ]; then
      echG "    - Successfull"
    else
      echE "    - [FAIL] docker swarm não configurado"
    fi
    echG "  Finished"
    echG ""
    echG "  [ENTER para continuar]"
    echG ""
    read
  else
    echo ${__cmd}
  fi  
  return 1
}

function dockerSwarmLeave()
{
  local __cmd="docker swarm leave --force"
  if [[ ${__action} == true ]]; then
    echB "  Action: [Swam-Leave]"
    echY "    - ${__cmd}"
    echB "  Executing ..."
    echo $(${__cmd})
    echG "  Finished"
  else
    echo ${__cmd}
  fi
  return 1
}

function dockerSwarmConfigure()
{
  clearTerm
  echM $'\n'"Docker configure"$'\n'
  PS3=$'\n'"Choose a option: "
  local options=(Back Swarm-Init Swarm-Leave)
  select opt in "${options[@]}"
  do
    unset __cmd
    if [[ ${opt} == "Back" ]]; then
      return 1
    elif [[ ${opt} == "Swarm-Init" ]]; then
      local __cmd=$(dockerSwarmInit)
    elif [[ ${opt} == "Swarm-Leave" ]]; then
      local __cmd=$(dockerSwarmLeave)
    fi
    echB "    Action: [${__cmd}]"
    echY "      - ${__cmd}"
    echB "      Executing ..."
    echo $(${__cmd})
    echG "    Finished"
    break
  done
}

function dockerNetworkCreate()
{
  local __names=${1}
  if [[ ${__names} == "" ]]; then
    echo "Invalid \${__names}"
    return 0
  fi
  local __names=(${__names})
  

  for __name in "${__names[@]}"
  do
    local __check=$(docker network ls | grep ${__name})
    if [[ ${__check} != "" ]]; then
      continue
    fi

    if [[ ${STACK_DNS_SERVER_ENABLE} == true ]]; then
      #docker --log-level ERROR network create --driver overlay --attachable --opt com.docker.network.bridge.name=my_network --opt com.docker.network.bridge.enable_icc=true --opt com.docker.network.bridge.enable_ip_masquerade=true --opt com.docker.network.bridge.host_binding_ipv4=0.0.0.0 --opt com.docker.network.driver.mtu=1500 --subnet=10.0.0.0/24 --gateway=10.0.0.1 --aux-address=\"host=10.0.0.254\" --aux-address=\"dhcp=10.0.0.253\" --dns=10.0.0.2 my_custom_network
      local __cmd="docker --log-level ERROR network create --driver overlay --attachable --opt --opt com.docker.network.driver.mtu=1500 --subnet=10.0.0.0/24 --gateway=10.0.0.1 --aux-address=\"host=10.0.0.254\" --aux-address=\"dhcp=10.0.0.253\" --dns=10.0.0.2 my_custom_network"
    else
      local __cmd="docker --log-level ERROR network create --driver=overlay ${__name}"
    fi

    echo $(${__cmd})&>/dev/null

    local __check=$(docker network ls | grep ${__name})
    if [[ ${__check} == "" ]]; then
      export __func_return="fail on create netweork \${__name}: ${__name}"
      return 0
    fi
  done
  return 1
}

function dockerBuildCompose()
{
  local __docker_build_name=${1}
  local __docker_build_image=${2}
  local __docker_build_dockerfile=${3}
  local __docker_build_compose_file=${4}
  local __docker_build_env_file=${5}
  local __docker_build_builder_dir=${6}
  local __docker_build_binary_name=${7}
  local __docker_build_network_name=${8}

  echM "    Docker containers create"  
  if ! [[ -f  ${__docker_build_compose_file} ]]; then
    echY "  File not found: ${__docker_build_compose_file}"  
    echR "  ===============================  "
    echR "  *******************************  "
    echR "  *docker compose-file not found*  "
    echR "  *******************************  "
    echR "  ===============================  "
    return 0;
  fi

  local __docker_build_compose_dir=$(dirname ${__docker_build_compose_file})
  local __docker_build_service=$(__private_dockerParserServiceName ${__docker_build_name})  
  local __docker_build_hostname=$(__private_dockerParserHostName ${__docker_build_name})  
  local __docker_build_env_file_static=${__docker_build_builder_dir}/${__docker_build_service}-static.env
  local __docker_build_env_file_export=${__docker_build_builder_dir}/${__docker_build_service}-run.env
  local __docker_build_env_file_docker=${__docker_build_builder_dir}/${__docker_build_service}.env
  local __docker_build_compose_sh_file=${__docker_build_builder_dir}/${__docker_build_service}.sh
  local __docker_build_binary_file=${__docker_build_builder_dir}/${__docker_build_binary_name}

  cd ${__docker_build_compose_dir}

  export APPLICATION_ENV_FILE=${__docker_build_env_file_docker}
  export APPLICATION_DEPLOY_IMAGE=${__docker_build_image}
  export APPLICATION_DEPLOY_HOSTNAME=${__docker_build_hostname}
  export APPLICATION_DEPLOY_NETWORK_NAME=${__docker_build_network_name}

  if [[ ${APPLICATION_DEPLOY_HEALTH_CHECK_URL} == "" ]]; then
    export APPLICATION_DEPLOY_HEALTH_CHECK_URL="${APPLICATION_DEPLOY_DNS}:${APPLICATION_DEPLOY_PORT}"
    if [[ ${APPLICATION_CONTEXT_PATH} != "" && ${APPLICATION_CONTEXT_PATH} != "/" ]]; then
      export APPLICATION_DEPLOY_HEALTH_CHECK_URL="${APPLICATION_DEPLOY_HEALTH_CHECK_URL}/${APPLICATION_CONTEXT_PATH}"
    fi
    export APPLICATION_DEPLOY_HEALTH_CHECK_URL=${APPLICATION_DEPLOY_HEALTH_CHECK_URL/\/\//\/}
    export APPLICATION_DEPLOY_HEALTH_CHECK_URL="http://localhost:8080/actuator/health"
  else
    export APPLICATION_DEPLOY_HEALTH_CHECK_URL=${APPLICATION_DEPLOY_HEALTH_CHECK_URL/\/\//\/}
  fi

  export COMPOSE_HTTP_TIMEOUT=$(parserTime ${APPLICATION_DEPLOY_SHELF_LIFE})

  # ref https://docs.docker.com/compose/environment-variables/envvars/

  local __docker_build_old_file=${__docker_build_dockerfile}
  if [[ -f ${__docker_build_old_file} ]]; then
    local __docker_build_dockerfile=${__docker_build_builder_dir}/${__docker_build_service}.dockerfile
    mv ${__docker_build_old_file} ${__docker_build_dockerfile}
  fi

  local __docker_build_old_file=${__docker_build_compose_file}
  if [[ -f ${__docker_build_old_file} ]]; then
    local __docker_build_compose_file=${__docker_build_builder_dir}/${__docker_build_service}.yml
    mv ${__docker_build_old_file} ${__docker_build_compose_file}
  fi

  local __docker_build_old_file=${__docker_build_builder_dir}/env_file-static.env
  if [[ -f ${__docker_build_old_file} ]]; then    
    mv ${__docker_build_old_file} ${__docker_build_env_file_static}
  fi

  local __docker_build_old_file=${__docker_build_env_file}
  if [[ -f ${__docker_build_old_file} ]]; then    
    mv ${__docker_build_old_file} ${__docker_build_env_file_docker}
    envsFileConvertToExport ${__docker_build_env_file_docker} ${__docker_build_env_file_export}
  fi

  stackEnvsByStackExportToFile ${__docker_build_env_file_export}
  envsFileAddIfNotExists ${__export_file} COMPOSE_CONVERT_WINDOWS_PATHS
  envsFileAddIfNotExists ${__export_file} COMPOSE_HTTP_TIMEOUT

  local __docker_build_cmd_1="docker --log-level ERROR build --quiet --file $(basename ${__docker_build_dockerfile}) -t ${__docker_build_service} ."
  local __docker_build_cmd_2="docker --log-level ERROR image tag ${__docker_build_service} ${__docker_build_image}"
  local __docker_build_cmd_3="docker --log-level ERROR push ${__docker_build_image}"
  local __docker_build_cmd_4="docker --log-level ERROR stack rm ${__docker_build_service}"
  local __docker_build_cmd_5="docker --log-level ERROR stack deploy --compose-file $(basename ${__docker_build_compose_file}) ${__docker_build_service}"
  local __docker_build_cmd_6="docker service logs -f ${__docker_build_service}"
  
  echB "      Information"
  echC "        - Path: ${PWD}"
  echC "        - Target: $(basename ${__docker_build_compose_file})"
  echC "        - Service: [${__docker_build_service}]"
  echC "        - Network: ${__docker_build_network_name}"
  echC "        - Hostname: ${__docker_build_hostname}"
  echB "      Environment files"
  echC "        - static envs: $(basename ${__docker_build_env_file_static})"
  echC "        - runner envs $(basename ${__docker_build_env_file_export})"
  echC "        - docker envs: $(basename ${__docker_build_env_file_docker})"
  if [[ -f ${__docker_build_binary_file} ]]; then
  echC "        - application file: ${__docker_build_binary_file}"
  fi

  echo "#!/bin/bash"                                                                     >${__docker_build_compose_sh_file}
  echo ""                                                                               >>${__docker_build_compose_sh_file}
  if [[ -f ${__docker_build_env_file_static} ]]; then
  echo "source ./$(basename ${__docker_build_env_file_static})"                         >>${__docker_build_compose_sh_file}
  fi
  if [[ -f ${__docker_build_env_file_export} ]]; then
  echo "source ./$(basename ${__docker_build_env_file_export})"                         >>${__docker_build_compose_sh_file}
  fi
  echo ""                                                                               >>${__docker_build_compose_sh_file}
  if [[ ${__docker_build_binary_file} ]]; then
  echo "export APPLICATION_DEPLOY_FILE=$(basename ${__docker_build_binary_file})"       >>${__docker_build_compose_sh_file}
  echo "if [[ \${1} == \"--run\" ]]; then"                                              >>${__docker_build_compose_sh_file}
  echo "    if [[ \$(echo \${APPLICATION_DEPLOY_FILE} | grep '.jar') != \"\" ]]; then"  >>${__docker_build_compose_sh_file}
  echo "        java -jar ./\${APPLICATION_DEPLOY_FILE}"                                >>${__docker_build_compose_sh_file}
  echo "    else"                                                                       >>${__docker_build_compose_sh_file}
  echo "        ./\${APPLICATION_DEPLOY_FILE}"                                          >>${__docker_build_compose_sh_file}
  echo "    fi"                                                                         >>${__docker_build_compose_sh_file}
  echo "    exit 0"                                                                     >>${__docker_build_compose_sh_file}
  echo "fi"                                                                             >>${__docker_build_compose_sh_file}
  fi
  echo ""                                                                               >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_1}\""                                               >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_1}                                                          >>${__docker_build_compose_sh_file}
  echo ""                                                                               >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_2}\""                                               >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_2}                                                          >>${__docker_build_compose_sh_file}
  echo ""                                                                               >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_5}\""                                               >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_5}                                                          >>${__docker_build_compose_sh_file}
  echo ""                                                                               >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_6}\""                                               >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_6}                                                          >>${__docker_build_compose_sh_file}
  echo ""                                                                               >>${__docker_build_compose_sh_file}

  chmod +x ${__docker_build_compose_sh_file}  


    #format config files 
  __private_docker_envsubst ${__docker_build_dockerfile}
  __private_docker_envsubst ${__docker_build_compose_file}

  echB "      Building ..."
  echY "        - ${__docker_build_cmd_1}"
  echo $(${__docker_build_cmd_1})&>/dev/null
  echY "        - ${__docker_build_cmd_2}"
  echo $(${__docker_build_cmd_2})&>/dev/null
  echY "        - ${__docker_build_cmd_3}"
  echo $(${__docker_build_cmd_3})&>/dev/null
  echY "        - ${__docker_build_cmd_5}"
  echo $(${__docker_build_cmd_5})&>/dev/null
  local __check=$(docker service ls | grep ${__docker_build_service})

  export COMPOSE_HTTP_TIMEOUT=$(parserTime 1y)
  if [[ ${__check} == "" ]]; then
  echR "    [FAIL]Service not found:${__docker_build_service}"
    return 0
  fi
  echG "    Finished"

  return 1
}

function dockerRegistryImageCheck()
{
  local __image=${1}
  local __check=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET "http://${STACK_REGISTRY_DNS_PUBLIC}/v2/${__image}/manifests/latest" | jq '.config.mediaType')
  if [[ ${__check} == "" || ${__check} == "null" ]]; then
    return 0;
  fi
  __func_return=1  
  return 1;
}



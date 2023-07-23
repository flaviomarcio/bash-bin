#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh

# export DOCKER_OPTION=
# export DOCKER_SCOPE=
# export DOCKER_DIR=

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
  __docker_parser_name=${1}
  __docker_parser_tags=("_" "|" "\.")
  for __docker_parser_tag in "${__docker_parser_tags[@]}"
  do
    export __docker_parser_name=$(echo ${__docker_parser_name} | sed "s/${__docker_parser_tag}/-/g")
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
  __docker_swarm_check=$(dockerSwarmState)
  if [[ ${__docker_swarm_check} == "active" ]]; then
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
  dockerSwarmInit true
  if [ "$?" -eq 1 ]; then
    return 1
  fi
  return 0
}

function dockerCleanup()
{
  echM "    Docker cleanup"
  __docker_cleanup_tags=${1}
  __docker_cleanup_removed=false
  if [[ ${__docker_cleanup_tags} == "" ]]; then
    __docker_cleanup_tags=($(docker service ls --quiet))
    for __docker_cleanup_tag in "${__docker_cleanup_tags[@]}"
    do
      __docker_cleanup_tag=$(docker service inspect ${__docker_cleanup_tag} --format '{{ .Spec.Name }}')
      echR "      Removing service [${__docker_cleanup_tag}]..."
      echo $(docker --log-level ERROR service rm ${__docker_cleanup_tag} )&>/dev/null
      __docker_cleanup_removed=true
    done
  else
    __docker_cleanup_tags=($(__private_dockerParserServiceName ${__docker_cleanup_tags}))
    for __docker_cleanup_tag in "${__docker_cleanup_tags[@]}"
    do
      __docker_cleanup_check=$(docker service ls | grep ${__docker_cleanup_tag} | awk '{print $1}')
      if [[ ${__docker_cleanup_check} != "" ]]; then
        break
      fi
    done

    for __docker_cleanup_tag in "${__docker_cleanup_tags[@]}"
    do
      __docker_cleanup_cmd="docker --log-level ERROR service rm \$(docker service ls | grep ${__docker_cleanup_tag} | awk '{print \$1}')"
      echR "      Removing tag[${__docker_cleanup_tag}]..."
      echY "        - ${__docker_cleanup_cmd}"  
      __docker_cleanup_check=$(docker service ls | grep ${__docker_cleanup_tag} | awk '{print $1}')
      if [[ ${__docker_cleanup_check} == "" ]]; then
        continue
      fi
      echo $(docker --log-level ERROR service rm $(docker service ls | grep ${__docker_cleanup_tag} | awk '{print $1}') )&>/dev/null
      __docker_cleanup_removed=true
    done

  fi
    if [[ ${__docker_cleanup_removed} == false ]]; then
      echC "      - No services for clear"
      echG "    Finished"
      return 1
    fi
  echG "    Finished"
  return 1
}

function dockerPrune()
{
  __docker_prune_cmd="docker --log-level ERROR system prune -a --all --force"
  echM "    Docker prune"
  echR "      Removing ..."
  echY "        - ${__docker_prune_cmd}"
  echo $(${__docker_prune_cmd})&>/dev/null
  echG "    Finished"
}

function dockerReset()
{
  __docker_reset_tags=${1}
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
  __docker_swarm_action=${1}
  __docker_swarm_ip=${2}

  __docker_swarm_cmd="docker swarm init --advertise-addr ${__docker_swarm_ip}"
  if [[ ${__docker_swarm_action} == true ]]; then
    clearTerm
    echB "  Docker swarm não está instalado"
    echG ""
    echG "  [ENTER] para configurar"
    echG ""
    read
    echB "  Action: [Swam-Init]"
    echY "    - ${__docker_swarm_cmd}"
    echB "  Executing ..."
    echo $(${__docker_swarm_cmd})
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
    echo ${__docker_swarm_cmd}
  fi  
  return 1
}

function dockerSwarmLeave()
{
  __docker_swarm_cmd="docker swarm leave --force"
  if [[ ${__docker_swarm_action} == true ]]; then
    echB "  Action: [Swam-Leave]"
    echY "    - ${__docker_swarm_cmd}"
    echB "  Executing ..."
    echo $(${__docker_swarm_cmd})
    echG "  Finished"
  else
    echo ${__docker_swarm_cmd}
  fi
  return 1
}

function dockerConfigure()
{
  clearTerm
  echM $'\n'"Docker configure"$'\n'
  PS3=$'\n'"Choose a option: "
  options=(Back Swarm-Init Swarm-Leave)
  select opt in "${options[@]}"
  do
    __docker_configure_cmd=
    if [[ ${opt} == "Back" ]]; then
      return 1
    elif [[ ${opt} == "Swarm-Init" ]]; then
      __docker_configure_cmd=$(dockerSwarmInit)
    elif [[ ${opt} == "Swarm-Leave" ]]; then
      __docker_configure_cmd=$(dockerSwarmLeave)
    fi
    echB "    Action: [${__docker_configure_cmd}]"
    echY "      - ${__docker_configure_cmd}"
    echB "      Executing ..."
    echo $(${__docker_configure_cmd})
    echG "    Finished"
    break
  done
}

function dockerNetworkCreate()
{
  __docker_network_name=${1}
  if [[ ${__docker_network_name} == "" ]]; then
    echo "Invalid \${__docker_network_name}"
    return 0
  fi
  __docker_network_check=$(docker network ls | grep ${__docker_network_name})
  if [[ ${__docker_network_check} != "" ]]; then
    return 1
  fi
  __docker_network_cmd="docker --log-level ERROR network create --driver=overlay ${__docker_network_name}"
  echM "    Docker network configuration"
  echC "      - Network: ${__docker_network_name}"
  echY "      - ${__docker_network_cmd}"
  echo $(${__docker_network_cmd})&>/dev/null

  __docker_network_check=$(docker network ls | grep ${__docker_network_name})
  if [[ ${__docker_network_check} == "" ]]; then
    echY "      target: [${__docker_network_name}]"
    echR "      ===============================  "
    echR "              ***************          "
    echR "      ********Invalid network********  "
    echR "              ***************          "
    echR "      ===============================  "
    return 0
  fi
  echG "    Finished"
  return 1
}

function dockerBuildDockerFile()
{
  IMAGE_NAME=${2}
  FILE_SRC=${3}
  FILE_DST=${4}

  if [[ -d ${DOCKER_CONF_DIR} ]]; then
    cp -r -T ${DOCKER_CONF_DIR} ${BUILD_TEMP_DIR}
  fi

  log "Building docker image [${IMAGE_NAME}]"
  if ! [[ -f ${FILE_SRC} ]]; then
      logError ${1} "Docker file not found [${FILE_SRC}]"
    __RETURN=1;
  else
    rm -rf ${FILE_DST};
    cp -r ${FILE_SRC} ${FILE_DST}
    cd ${BUILD_TEMP_DIR}
    docker --log-level ERROR build --quiet --network host -t ${IMAGE_NAME} .

    cd ${ROOT_DIR}
    __RETURN=1;
  fi
  return ${__RETURN}
}

function dockerBuildCompose()
{
  __docker_build_bin_jar=
  __docker_build_compose_dir=

  __docker_build_name=${1}
  __docker_build_image=${2}
  __docker_build_dockerfile=${3}
  __docker_build_compose_file=${4}
  __docker_build_env_file=${5}
  __docker_build_builder_dir=${6}
  __docker_build_bin_dir=${7}
  __docker_build_bin_name=${8}
  __docker_build_network_name=${9}

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

  __docker_build_compose_dir=$(dirname ${__docker_build_compose_file})

  if [[ ${__docker_build_bin_name} != "" ]]; then
    __docker_build_bin_jar=${__docker_build_bin_dir}/${__docker_build_bin_name}.jar
  fi

  __docker_build_service=$(__private_dockerParserServiceName ${__docker_build_name})  
  __docker_build_hostname=$(__private_dockerParserHostName ${__docker_build_name})  
  __docker_build_env_file_static=${__docker_build_builder_dir}/${__docker_build_service}-static.env
  __docker_build_env_file_stack=${__docker_build_builder_dir}/${__docker_build_service}-stack.env
  __docker_build_env_file_docker=${__docker_build_builder_dir}/${__docker_build_service}.env
  __docker_build_compose_sh_file=${__docker_build_builder_dir}/${__docker_build_service}.sh

  cd ${__docker_build_compose_dir}

  # ref https://docs.docker.com/compose/environment-variables/envvars/

  __docker_build_old_file=${__docker_build_dockerfile}
  if [[ -f ${__docker_build_old_file} ]]; then
    __docker_build_dockerfile=${__docker_build_builder_dir}/${__docker_build_service}.dockerfile
    mv ${__docker_build_old_file} ${__docker_build_dockerfile}
  fi

  __docker_build_old_file=${__docker_build_compose_file}
  if [[ -f ${__docker_build_old_file} ]]; then
    __docker_build_compose_file=${__docker_build_builder_dir}/${__docker_build_service}.yml
    mv ${__docker_build_old_file} ${__docker_build_compose_file}
  fi

  __docker_build_old_file=${__docker_build_builder_dir}/env_file_static.env
  if [[ -f ${__docker_build_old_file} ]]; then    
    mv ${__docker_build_old_file} ${__docker_build_env_file_static}
  fi

  __docker_build_old_file=${__docker_build_builder_dir}/env_file_stack.env
  if [[ -f ${__docker_build_old_file} ]]; then    
    mv ${__docker_build_old_file} ${__docker_build_env_file_stack}
  fi

  __docker_build_old_file=${__docker_build_env_file}
  if [[ -f ${__docker_build_old_file} ]]; then    
    mv ${__docker_build_old_file} ${__docker_build_env_file_docker}
  fi

  __docker_build_cmd_1="docker --log-level ERROR build --quiet --file $(basename ${__docker_build_dockerfile}) -t ${__docker_build_service} ."
  __docker_build_cmd_2="docker --log-level ERROR image tag ${__docker_build_service} ${__docker_build_image}"
  __docker_build_cmd_3="docker --log-level ERROR push ${__docker_build_image}"
  __docker_build_cmd_4="docker --log-level ERROR stack deploy --compose-file $(basename ${__docker_build_compose_file}) ${__docker_build_service}"
  
  echB "      Information"
  echC "        - Path: ${PWD}"
  echC "        - Target: $(basename ${__docker_build_compose_file})"
  echC "        - Service: [${__docker_build_service}]"
  echC "        - Network: ${__docker_build_network_name}"
  echC "        - Hostname: ${__docker_build_hostname}"
  echB "      Environment files"
  echC "        - $(basename ${__docker_build_env_file_static})"
  echC "        - $(basename ${__docker_build_env_file_stack})"
  echC "        - $(basename ${__docker_build_env_file_docker})"
  if [[ -f ${__docker_build_bin_jar} ]]; then
  echC "        - JAR name: ${__docker_build_bin_jar}"
  fi
  
  export APPLICATION_NAME=${__docker_build_service}
  export APPLICATION_SERVICE=$(echo ${__docker_build_service} | sed 's/-/_/g')
  export APPLICATION_DEPLOY_BINARY_DIR=${__docker_build_builder_dir}
  export APPLICATION_DEPLOY_IMAGE=${__docker_build_image}
  export APPLICATION_DEPLOY_HOSTNAME=${__docker_build_hostname}
  export APPLICATION_DEPLOY_APP_DIR=${__docker_build_compose_dir}
  export APPLICATION_DEPLOY_NETWORK_NAME=${__docker_build_network_name}
  export APPLICATION_DEPLOY_DNS=${__docker_build_service}
  envsReplaceFile ${__docker_build_compose_file}

  echo "#!/bin/bash"                                                                 >${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  if [[ -f ${__docker_build_env_file_static} ]]; then
  echo "source ./$(basename ${__docker_build_env_file_static})"                     >>${__docker_build_compose_sh_file}
  fi
  if [[ -f ${__docker_build_env_file_stack} ]]; then
  echo "source ./$(basename ${__docker_build_env_file_stack})"                      >>${__docker_build_compose_sh_file}
  fi
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_NAME=${APPLICATION_NAME}"                                >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_SERVICE=${APPLICATION_SERVICE}"                          >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_DEPLOY_APP_DIR=${APPLICATION_DEPLOY_APP_DIR}"            >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_DEPLOY_BINARY_DIR=${APPLICATION_DEPLOY_BINARY_DIR}"      >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_DEPLOY_DNS=${APPLICATION_DEPLOY_DNS}"                    >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_DEPLOY_IMAGE=${APPLICATION_DEPLOY_IMAGE}"                >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_DEPLOY_HOSTNAME=${APPLICATION_DEPLOY_HOSTNAME}"          >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_DEPLOY_NETWORK_NAME=${APPLICATION_DEPLOY_NETWORK_NAME}"  >>${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_1}\""                                           >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_1}                                                      >>${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_2}\""                                           >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_2}                                                      >>${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_3}\""                                           >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_3}                                                      >>${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_4}\""                                           >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_4}                                                      >>${__docker_build_compose_sh_file}
  chmod +x ${__docker_build_compose_sh_file}  

  export COMPOSE_CONVERT_WINDOWS_PATHS=1
  if ! [[ -f ${__docker_build_bin_jar} ]]; then
    export DOCKER_JAR_NAME=${__docker_build_bin_jar}
  fi

  echB "      Building ..."
  echY "        - ${__docker_build_cmd_1}"
  echo $(${__docker_build_cmd_1})&>/dev/null
  echY "        - ${__docker_build_cmd_2}"
  echo $(${__docker_build_cmd_2})&>/dev/null
  echY "        - ${__docker_build_cmd_3}"
  echo $(${__docker_build_cmd_3})&>/dev/null
  echY "        - ${__docker_build_cmd_4}"
  echo $(${__docker_build_cmd_4})&>/dev/null
  __docker_build_check=$(docker service ls | grep ${__docker_build_service})
  if [[ ${__docker_build_check} == "" ]]; then
  echR "    [FAIL]Service not found:${__docker_build_service}"
    return 0
  fi
  echG "    Finished"

  return 1
}

# function dockerPrepare()
# { 
#   export DOCKER_SCOPE=${1}
#   export DOCKER_DIR=${2}
#   export DOCKER_DIR_DATA=${3}
#   export DOCKER_OPTION=${5}
  
#   if [[ ${DOCKER_SCOPE} == "" ]]; then
#     echR "    [FAIL]Invalid scope: ${DOCKER_SCOPE}"
#     return 0;
#   fi

#   if [[ ${DOCKER_DIR} == "" ]]; then
#     echR "    [FAIL]Invalid \${DOCKER_DIR}"
#     return 0;
#   fi

#   if ! [[ -d ${DOCKER_DIR} ]]; then
#     echR "    [FAIL]Invalid DOCKER_DIR: ${DOCKER_DIR}"
#     return 0;
#   fi

#   if [[ ${DOCKER_OPTION} == "" ]]; then
#     echR "    [FAIL]Invalid \${DOCKER_OPTION}"
#     return 0
#   fi

#   export STACK_NETWORK_NAME="${DOCKER_SCOPE}-network"
 

#   export DOCKER_INIT_DIR=${DOCKER_DIR}/init 
#   export DOCKER_BIN_DIR=${DOCKER_DIR_DATA}/bin
#   export DOCKER_BIN_RUN=${DOCKER_BIN_DIR}/run.sh

#   mkdir -p ${DOCKER_BIN_DIR}
#   echo "#!/bin/bash">${DOCKER_BIN_RUN}
#   echo "">>${DOCKER_BIN_RUN}
#   echo "">>${DOCKER_BIN_RUN}
#   echo "#default envs">>${DOCKER_BIN_RUN}
#   echo "ENV_FILE=./default.env">>${DOCKER_BIN_RUN}
#   echo "if [[ -f \${ENV_FILE} ]]; then">>${DOCKER_BIN_RUN}
#   echo "  source \${ENV_FILE}">>${DOCKER_BIN_RUN}
#   echo "fi">>${DOCKER_BIN_RUN}
#   echo "">>${DOCKER_BIN_RUN}
#   echo "#jar envs">>${DOCKER_BIN_RUN}
#   echo "ENV_FILE=echo \$(echo \"\$@\" | sed 's/jar/env/g')">>${DOCKER_BIN_RUN}
#   echo "if [[ -f \${ENV_FILE} ]]; then">>${DOCKER_BIN_RUN}
#   echo "  source \${ENV_FILE}">>${DOCKER_BIN_RUN}
#   echo "fi">>${DOCKER_BIN_RUN}
#   echo "">>${DOCKER_BIN_RUN}
#   echo "java -jar \"\$@\"">>${DOCKER_BIN_RUN}

#   echo "">>${DOCKER_BIN_RUN}
#   chmod +x ${DOCKER_BIN_RUN}
#   return 1
# }

function dockerRegistryImageCheck()
{
  export __dockerRegistryImageCheckImage=${1}
  __dockerRegistryImageCheck=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET "http://${STACK_REGISTRY_DNS}/v2/${__dockerRegistryImageCheckImage}/manifests/latest" | jq '.config.mediaType')
  if [[ ${__dockerRegistryImageCheck} == "" || ${__dockerRegistryImageCheck} == "null" ]]; then
    return 0;
  fi
  __func_return=1  
  return 1;
}



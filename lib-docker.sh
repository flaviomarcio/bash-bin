#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh

# export DOCKER_OPTION=
# export DOCKER_SCOPE=
# export DOCKER_DIR=

function __private_docker_envsubst()
{
  if [[ ${1} == "" ]]; then
    return 0
  fi
  __private_docker_envsubst_files=(${1})
  for __private_docker_envsubst_file_src in "${__private_docker_envsubst_files[@]}"
  do
    if [[ -f ${__private_docker_envsubst_file_src} ]]; then
      __private_docker_envsubst_file_ori=${__private_docker_envsubst_file_src}.ori
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
  __docker_build_name=${1}
  __docker_build_image=${2}
  __docker_build_dockerfile=${3}
  __docker_build_compose_file=${4}
  __docker_build_env_file=${5}
  __docker_build_builder_dir=${6}
  __docker_build_binary_name=${7}
  __docker_build_network_name=${8}

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
  __docker_build_service=$(__private_dockerParserServiceName ${__docker_build_name})  
  __docker_build_hostname=$(__private_dockerParserHostName ${__docker_build_name})  
  __docker_build_env_file_static=${__docker_build_builder_dir}/${__docker_build_service}-static.env
  __docker_build_env_file_export=${__docker_build_builder_dir}/${__docker_build_service}-run.env
  __docker_build_env_file_docker=${__docker_build_builder_dir}/${__docker_build_service}.env
  __docker_build_compose_sh_file=${__docker_build_builder_dir}/${__docker_build_service}.sh
  __docker_build_binary_file=${__docker_build_builder_dir}/${__docker_build_binary_name}

  cd ${__docker_build_compose_dir}

  export APPLICATION_ENV_FILE=${__docker_build_env_file_export}
  export APPLICATION_NAME=${__docker_build_service}
  export APPLICATION_SERVICE=$(echo ${__docker_build_service} | sed 's/-/_/g')
  export APPLICATION_DEPLOY_BINARY_DIR=${__docker_build_builder_dir}
  export APPLICATION_DEPLOY_IMAGE=${__docker_build_image}
  export APPLICATION_DEPLOY_HOSTNAME=${__docker_build_hostname}
  export APPLICATION_DEPLOY_APP_DIR=${__docker_build_compose_dir}
  export APPLICATION_DEPLOY_NETWORK_NAME=${__docker_build_network_name}

  export APPLICATION_DEPLOY_DNS=${__docker_build_service}
  if [[ ${APPLICATION_DEPLOY_DNS_PUBLIC} == "" ]]; then
    export APPLICATION_DEPLOY_DNS_PUBLIC=${__docker_build_service}
  fi

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

  __docker_build_old_file=${__docker_build_builder_dir}/env_file-static.env
  if [[ -f ${__docker_build_old_file} ]]; then    
    mv ${__docker_build_old_file} ${__docker_build_env_file_static}
  fi

  __docker_build_old_file=${__docker_build_env_file}
  if [[ -f ${__docker_build_old_file} ]]; then    
    mv ${__docker_build_old_file} ${__docker_build_env_file_docker}
    envsFileConvertToExport ${__docker_build_env_file_docker} ${__docker_build_env_file_export}
  fi

  if ! [[ -f ${__docker_build_env_file_export} ]]; then
    echo "#!/bin/bash">${__docker_build_env_file_export}
  fi
  echo "export COMPOSE_CONVERT_WINDOWS_PATHS=${COMPOSE_CONVERT_WINDOWS_PATHS}"      >>${__docker_build_env_file_export}
  echo "export APPLICATION_ENV_FILE=${APPLICATION_ENV_FILE}"                        >>${__docker_build_env_file_export}
  echo "export APPLICATION_NAME=${APPLICATION_NAME}"                                >>${__docker_build_env_file_export}
  echo "export APPLICATION_SERVICE=${APPLICATION_SERVICE}"                          >>${__docker_build_env_file_export}
  echo "export APPLICATION_DEPLOY_APP_DIR=${APPLICATION_DEPLOY_APP_DIR}"            >>${__docker_build_env_file_export}
  echo "export APPLICATION_DEPLOY_BINARY_DIR=${APPLICATION_DEPLOY_BINARY_DIR}"      >>${__docker_build_env_file_export}
  echo "export APPLICATION_DEPLOY_DNS=${APPLICATION_DEPLOY_DNS}"                    >>${__docker_build_env_file_export}
  echo "export APPLICATION_DEPLOY_IMAGE=${APPLICATION_DEPLOY_IMAGE}"                >>${__docker_build_env_file_export}
  echo "export APPLICATION_DEPLOY_HOSTNAME=${APPLICATION_DEPLOY_HOSTNAME}"          >>${__docker_build_env_file_export}
  echo "export APPLICATION_DEPLOY_NETWORK_NAME=${APPLICATION_DEPLOY_NETWORK_NAME}"  >>${__docker_build_env_file_export}
  if [[ -f ${__docker_build_binary_file} ]]; then
  echo "export APPLICATION_FILE=${__docker_build_binary_file}"        >>${__docker_build_env_file_export}
  fi
  

  __docker_build_cmd_1="docker --log-level ERROR build --quiet --file $(basename ${__docker_build_dockerfile}) -t ${__docker_build_service} ."
  __docker_build_cmd_2="docker --log-level ERROR image tag ${__docker_build_service} ${__docker_build_image}"
  __docker_build_cmd_3="docker --log-level ERROR push ${__docker_build_image}"
  __docker_build_cmd_4="docker --log-level ERROR stack rm ${__docker_build_service}"
  __docker_build_cmd_5="docker --log-level ERROR stack deploy --compose-file $(basename ${__docker_build_compose_file}) ${__docker_build_service}"
  __docker_build_cmd_6="docker service logs -f ${__docker_build_service}"
  
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
  




  echo "#!/bin/bash"                                                                 >${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  if [[ -f ${__docker_build_env_file_static} ]]; then
  echo "source ./$(basename ${__docker_build_env_file_static})"                     >>${__docker_build_compose_sh_file}
  fi
  if [[ -f ${__docker_build_env_file_export} ]]; then
  echo "source ./$(basename ${__docker_build_env_file_export})"                     >>${__docker_build_compose_sh_file}
  fi
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "export APPLICATION_FILE=$(basename ${__docker_build_binary_file})"          >>${__docker_build_compose_sh_file}
  echo "if [[ \${1} == \"--run\" ]]; then"                                          >>${__docker_build_compose_sh_file}
  echo "    if [[ \$(echo \${APPLICATION_FILE} | grep '.jar') != \"\" ]]; then"     >>${__docker_build_compose_sh_file}
  echo "        java -jar ./\${APPLICATION_FILE}"                                   >>${__docker_build_compose_sh_file}
  echo "    else"                                                                   >>${__docker_build_compose_sh_file}
  echo "        ./\${APPLICATION_FILE}"                                             >>${__docker_build_compose_sh_file}
  echo "    fi"                                                                     >>${__docker_build_compose_sh_file}
  echo "    exit 0"                                                                 >>${__docker_build_compose_sh_file}
  echo "fi"                                                                         >>${__docker_build_compose_sh_file}
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
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_5}\""                                           >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_5}                                                      >>${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}
  echo "echo \"${__docker_build_cmd_6}\""                                           >>${__docker_build_compose_sh_file}
  echo ${__docker_build_cmd_6}                                                      >>${__docker_build_compose_sh_file}
  echo ""                                                                           >>${__docker_build_compose_sh_file}

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
  __docker_build_check=$(docker service ls | grep ${__docker_build_service})
  if [[ ${__docker_build_check} == "" ]]; then
  echR "    [FAIL]Service not found:${__docker_build_service}"
    return 0
  fi
  echG "    Finished"

  return 1
}

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



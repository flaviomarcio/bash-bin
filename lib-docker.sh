#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh
. ${BASH_BIN}/lib-util-date.sh

function __private_docker_envsubst()
{
  if [[ ${1} == "" ]]; then
    return 0
  fi
  local __files=(${1})
  for __file_src in "${__files[@]}"
  do
    if [[ -f ${__file_src} ]]; then
      local __file_ori=${__file_src}.ori
      cat ${__file_src}>${__file_ori}
      envsubst < ${__file_ori} > ${__file_src}
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
  local __name=${1}
  local __tags=("_" "|" "\.")
  local __tag=
  for __tag in "${__tags[@]}"
  do
    local __name=$(echo ${__name} | sed "s/${__tag}/-/g")
  done  
  echo ${__name}
}

function dockerIsRunning()
{
  unset __func_return
  local __check=$(which docker)
  if [[ ${__check} == "" ]]; then
    export __func_return="Docker is not installed"
    return 0;
  fi
  local __check=$(systemctl status docker.service | grep "Active: active")
  if [[ ${__check} == "" ]]; then
    export __func_return="Docker service is not running"
    return 0;
  fi
  return 1;
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
  echM "Docker swarm verify"
  dockerIsRunning
  if ! [ "$?" -eq 1 ]; then
    export __func_return="Error on calling dockerIsRunning: ${__func_return}"
    return 0
  else
    echC "  - Docker: ${COLOR_YELLOW}running"
    dockerSwarmIsActive
    if ! [ "$?" -eq 1 ]; then
      dockerSwarmInit true "${PUBLIC_HOST_IPv4}"
      if ! [ "$?" -eq 1 ]; then
        export __func_return="Error on calling dockerSwarmInit: ${__func_return}"
        return 0
      fi
    fi
    echC "  - Swarm: ${COLOR_YELLOW}inited"
  fi
  dockerSwarmNodeLabelInit true "${PUBLIC_HOST_IPv4}"
  if ! [ "$?" -eq 1 ]; then
    export __func_return="Error on calling dockerSwarmNodeLabelInit: ${__func_return}"
    return 0
  fi
  echC "  - Labels: ${COLOR_YELLOW}added"
  echG "Finished"
  return 1
}

function dockerSwarmNodeLabels()
{
  echo "stack-type-master
 stack-type-infrastructure
 stack-type-waf
 stack-type-fw
 stack-type-tools
 stack-type-database
 stack-type-sre
 stack-type-security
 stack-type-deploy
 stack-type-streaming
 stack-type-observability
 stack-type-documentation
 stack-type-mcs"
  return 1
}

function dockerSwarmNodeLabelValue()
{
  local __node=${1}
  local __label=${2}
  local __value=$(docker node inspect ${__node} --format '{{ json .Spec.Labels }}' | jq -r ".[\"${__label}\"]")
  if [[ ${__value} != "null" ]]; then
    echo ${__value}
  fi
  return 1
}

function dockerSwarmNodeLabelInit()
{
  unset __func_return
  local __nodes=($(docker node ls --quiet))
  local __labels=($(dockerSwarmNodeLabels))
  local __node_count=${#__nodes[@]}

  if [[ ${__node_count} == 1 ]]; then    
    local __node=
    for __node in "${__nodes[@]}"
    do
      local __label=
      for __label in "${__labels[@]}"
      do
        local __label_value=$(dockerSwarmNodeLabelValue ${__node} ${__label})
        if [[ ${__label_value} == true ]]; then
          continue;
        fi
        $(docker node update --label-add "${__label}=true" ${__node})>/dev/null 2>&1
        local __label_value=$(dockerSwarmNodeLabelValue ${__node} ${__label})
        if [[ ${__label_value} != true ]]; then
          export __func_return="Error on set: ${__cmd}"
          return 0
        fi
      done
    done
  fi
  return 1;
}

function dockerSwarmNodesPrint()
{
  local __nodes=($(docker node ls --quiet))
  local __labels=($(dockerSwarmNodeLabels))
  echM "Docker nodes"
  for __node in "${__nodes[@]}"
  do
    local __node_name=$(docker node inspect ${__node} | jq '.[].Description.Hostname' | sed 's/\"//g')
    local __node_status=$(docker node inspect ${__node} | jq '.[].Status.State' | sed 's/\"//g')
    local __node_ip=$(docker node inspect ${__node} | jq '.[].Status.Addr' | sed 's/\"//g')
    echB "  - Node: ${COLOR_YELLOW} ${__node_name}: ${COLOR_CIANO}Status: ${COLOR_YELLOW}${__node_status}${COLOR_CIANO}, Ip: ${COLOR_YELLOW}${__node_ip}"
    echC "    Labels"
    local __label=
    for __label in "${__labels[@]}"
    do
      local __label_value=$(dockerSwarmNodeLabelValue ${__node} ${__label})
      echC "      - ${__label}: ${COLOR_YELLOW}${__label_value}"
    done
  done

  echG "\n[ENTER] to continue"
  read
  return 1;  
}

function dockerSwarmLabelNodesPrint()
{
  local __nodes=($(docker node ls --quiet))
  local __labels=($(dockerSwarmNodeLabels))
  echM "Docker nodes by label"
  for __label in "${__labels[@]}"
  do
    echB "  - Label: ${COLOR_YELLOW}${__label}" 
    local __node=
    for __node in "${__nodes[@]}"
    do
      local __label_value=$(dockerSwarmNodeLabelValue ${__node} ${__label})
      if [[ ${__label_value} == true ]]; then
        local __node_name=$(docker node inspect ${__node} | jq '.[].Description.Hostname' | sed 's/\"//g')
        local __node_status=$(docker node inspect ${__node} | jq '.[].Status.State' | sed 's/\"//g')
        local __node_ip=$(docker node inspect ${__node} | jq '.[].Status.Addr' | sed 's/\"//g')
        echB "    - Node: ${COLOR_YELLOW} ${__node_name}: ${COLOR_CIANO}Status: ${COLOR_YELLOW}${__node_status}${COLOR_CIANO}, Ip: ${COLOR_YELLOW}${__node_ip}"
      fi
    done
  done

  echG "\n[ENTER] to continue"
  read
  return 1;  
}

function dockerSwarmJoinPrint()
{
  echM "Docker Swarm Join"
  local __join_token_worker=$(docker swarm join-token worker | grep '\-\-token')
  local __join_token_manager=$(docker swarm join-token manager | grep '\-\-token')
  local __join_token_worker=$(strTrim "${__join_token_worker}")
  local __join_token_manager=$(strTrim "${__join_token_manager}")    
  echC "  - worker: ${COLOR_YELLOW}${__join_token_worker}"
  echC "  - manager: ${COLOR_YELLOW}${__join_token_manager}"
  echG "Finished"
  echG ""
  echG "[ENTER para continuar]"
  read
}

function dockerSwarmInit()
{
  local __action=${1}
  local __swarm_ip=${2}

  local __cmd="docker swarm init --advertise-addr ${__swarm_ip}"

  if [[ ${__action} == true ]]; then
    clearTerm
    echB "  Docker swarm não está instalado"
    echG ""
    echG "  [ENTER] para configurar"
    echG ""
    read
    echB "  Action: [Swarm-Init]"
    echY "    - ${__cmd}"
    echo $(${__cmd})>/dev/null 2>&1
    dockerSwarmIsActive
    if [ "$?" -eq 1 ]; then
      echG "    Successfull"
      echB "  JOIN Tokens"
      local __join_token_worker=$(docker swarm join-token worker | grep '\-\-token')
      local __join_token_manager=$(docker swarm join-token manager | grep '\-\-token')
      local __join_token_worker=$(strTrim "${__join_token_worker}")
      local __join_token_manager=$(strTrim "${__join_token_manager}")    
      echC "    - worker: ${COLOR_YELLOW}${__join_token_worker}"
      echC "    - manager: ${COLOR_YELLOW}${__join_token_manager}"
    else
      echE "    [FAIL] docker swarm não configurado"
    fi
    echG "  Finished"
    echG ""
    echG "  [ENTER para continuar]"
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
  local options=(Back Swarm-Init Swarm-Leave Swarm-Nodes Swarm-Join Label-Nodes)
  while :
  do
    clearTerm
    __private_print_os_information
    echM $'\n'"Docker configure"$'\n'
    PS3=$'\n'"Choose a option: "
    select opt in "${options[@]}"
    do
      local __cmd=
      if [[ ${opt} == "Back" ]]; then
        return 1
      elif [[ ${opt} == "Swarm-Init" ]]; then
        local __cmd=$(dockerSwarmInit)
      elif [[ ${opt} == "Swarm-Leave" ]]; then
        local __cmd=$(dockerSwarmLeave)
      elif [[ ${opt} == "Swarm-Join" ]]; then
        dockerSwarmJoinPrint
        break
      elif [[ ${opt} == "Swarm-Nodes" ]]; then
        dockerSwarmNodesPrint
        break
      elif [[ ${opt} == "Label-Nodes" ]]; then
        dockerSwarmLabelNodesPrint
        break
      fi
      echB "    Action: [${__cmd}]"
      echY "      - ${__cmd}"
      echB "      Executing ..."
      echo $(${__cmd})
      echG "    Finished"
      break
    done
  done
  return 1
}

function dockerCleanup()
{
  echM "    Docker cleanup"
  local __tags=${1}
  local __removed=false
  if [[ ${__tags} == "" ]]; then
    local __tags=($(docker service ls --quiet))
    local __tag=
    for __tag in "${__tags[@]}"
    do
      local __tag=$(docker service inspect ${__tag} --format '{{ .Spec.Name }}')
      echR "      Removing service [${__tag}]..."
      echo $(docker --log-level ERROR service rm ${__tag} )&>/dev/null
      local __removed=true
    done
  else
    local __tags=($(__private_dockerParserServiceName ${__tags}))
    local __tag=
    for __tag in "${__tags[@]}"
    do
      local __check=$(docker service ls | grep ${__tag} | awk '{print $1}')
      if [[ ${__check} != "" ]]; then
        break
      fi
    done

    local __tag=
    for __tag in "${__tags[@]}"
    do
      local __cmd="docker --log-level ERROR service rm \$(docker service ls | grep ${__tag} | awk '{print \$1}')"
      echR "      Removing tag[${__tag}]..."
      echY "        - ${__cmd}"  
      local __check=$(docker service ls | grep ${__tag} | awk '{print $1}')
      if [[ ${__check} == "" ]]; then
        continue
      fi
      echo $(docker --log-level ERROR service rm $(docker service ls | grep ${__tag} | awk '{print $1}') )&>/dev/null
      local __removed=true
    done

  fi
    if [[ ${__removed} == false ]]; then
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
  local i=
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

function dockerPluginsInstall()
{
  local __plugins_file=${STACK_PLUGINS_DIR}/docker-plugins
  if ! [[ -f ${__plugins_file} ]]; then
    return 1;
  fi
  local __plugins=($(cat ${__plugins_file}))
  local __plugin=
  local __plugins_selected=()
  for __plugin in "${__plugins[@]}"
  do
    local __check=$(docker plugin ls | grep "${__plugin}")
    if [[ ${__check} == "" ]]; then
      local __plugins_selected+=(${__plugin})
    fi
  done

  if [[ ${__plugins_selected} == "" ]]; then
    return 1;
  fi

  echM "      Docker plugins install"
  for __plugin in "${__plugins_selected[@]}"
  do
    local __cmd="docker plugin install --grant-all-permissions ${__plugin}"
    echB "        Plugin: ${COLOR_YELLOW}${__plugin}"
    echY "          - ${__cmd}"
    echo $(${__cmd}) >/dev/null 2>&1     
  done
  return 1
}

function dockerNetworkCreate()
{
  unset __func_return
  local __names=${1}
  if [[ ${__names} == "" ]]; then
    echo "Invalid \${__names}"
    return 0
  fi
  local __names=(${__names})
  
  local __name=
  for __name in "${__names[@]}"
  do
    local __check=$(docker network ls | grep ${__name})
    if [[ ${__check} != "" ]]; then
      continue
    fi

    local __cmd="docker --log-level ERROR network create --driver=overlay ${__name}"

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
  local __name=${1}
  local __image=${2}
  local __dockerfile=${3}
  local __compose_file=${4}
  local __env_file=${5}
  local __builder_dir=${6}
  local __binary_name=${7}
  local __hostname=${8}
  local __network_name=${9}

  echM "    Docker containers create"
  if ! [[ -f  ${__compose_file} ]]; then
    echY "  File not found: ${__compose_file}"  
    echR "  ===============================  "
    echR "  *******************************  "
    echR "  *docker compose-file not found*  "
    echR "  *******************************  "
    echR "  ===============================  "
    return 0;
  fi

  local __compose_dir=$(dirname ${__compose_file})
  local __service=$(__private_dockerParserServiceName ${__name})  
  local __hostname=$(__private_dockerParserHostName ${__hostname})  
  local __env_file_static=${__builder_dir}/${__service}-static.env
  local __env_file_export=${__builder_dir}/${__service}-run.env
  local __env_file_docker=${__builder_dir}/${__service}.env
  local __compose_sh_file=${__builder_dir}/${__service}.sh
  local __binary_file=${__builder_dir}/${__binary_name}

  cd ${__compose_dir}

  export APPLICATION_ENV_FILE=${__env_file_docker}
  export APPLICATION_DEPLOY_IMAGE=${__image}
  export APPLICATION_DEPLOY_HOSTNAME=${__hostname}
  export APPLICATION_DEPLOY_NETWORK_NAME=${__network_name}

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

  local __old_file=${__dockerfile}
  if [[ -f ${__old_file} ]]; then
    local __dockerfile=${__builder_dir}/${__service}.dockerfile
    mv ${__old_file} ${__dockerfile}
  fi

  local __old_file=${__compose_file}
  if [[ -f ${__old_file} ]]; then
    local __compose_file=${__builder_dir}/${__service}.yml
    mv ${__old_file} ${__compose_file}
  fi

  local __old_file=${__builder_dir}/env_file-static.env
  if [[ -f ${__old_file} ]]; then    
    mv ${__old_file} ${__env_file_static}
  fi

  local __old_file=${__env_file}
  if [[ -f ${__old_file} ]]; then    
    mv ${__old_file} ${__env_file_docker}
    envsFileConvertToExport ${__env_file_docker} ${__env_file_export}
  fi

  stackEnvsByStackExportToFile ${__env_file_export}
  envsFileAddIfNotExists ${__export_file} COMPOSE_CONVERT_WINDOWS_PATHS
  envsFileAddIfNotExists ${__export_file} COMPOSE_HTTP_TIMEOUT

  local __cmd_1="docker --log-level ERROR build --quiet --file $(basename ${__dockerfile}) -t ${__service} ."
  local __cmd_2="docker --log-level ERROR image tag ${__service} ${__image}"
  local __cmd_3="docker --log-level ERROR push ${__image}"
  local __cmd_4="docker --log-level ERROR stack rm ${__service}"
  local __cmd_5="docker --log-level ERROR stack deploy --detach=true --compose-file $(basename ${__compose_file}) ${__service}"
  local __cmd_6="docker service logs -f ${__service}"
  
  echB "      Information"
  echC "        - Path: ${PWD}"
  echC "        - Target: $(basename ${__compose_file})"
  echC "        - Service: [${__service}]"
  echC "        - Network: ${__network_name}"
  echC "        - Hostname: ${__hostname}"
  echB "      Environment files"
  echC "        - static envs: $(basename ${__env_file_static})"
  echC "        - runner envs $(basename ${__env_file_export})"
  echC "        - docker envs: $(basename ${__env_file_docker})"
  if [[ -f ${__binary_file} ]]; then
  echC "        - application file: ${__binary_file}"
  fi

  echo "#!/bin/bash"                                                                     >${__compose_sh_file}
  echo ""                                                                               >>${__compose_sh_file}
  if [[ -f ${__env_file_static} ]]; then
  echo "source ./$(basename ${__env_file_static})"                                      >>${__compose_sh_file}
  fi
  if [[ -f ${__env_file_export} ]]; then
  echo "source ./$(basename ${__env_file_export})"                                      >>${__compose_sh_file}
  fi
  echo ""                                                                               >>${__compose_sh_file}
  if [[ ${__binary_file} ]]; then
  echo "export APPLICATION_DEPLOY_FILE=$(basename ${__binary_file})"                    >>${__compose_sh_file}
  echo "if [[ \${1} == \"--run\" ]]; then"                                              >>${__compose_sh_file}
  echo "    if [[ \$(echo \${APPLICATION_DEPLOY_FILE} | grep '.jar') != \"\" ]]; then"  >>${__compose_sh_file}
  echo "        java -jar ./\${APPLICATION_DEPLOY_FILE}"                                >>${__compose_sh_file}
  echo "    else"                                                                       >>${__compose_sh_file}
  echo "        ./\${APPLICATION_DEPLOY_FILE}"                                          >>${__compose_sh_file}
  echo "    fi"                                                                         >>${__compose_sh_file}
  echo "    exit 0"                                                                     >>${__compose_sh_file}
  echo "fi"                                                                             >>${__compose_sh_file}
  fi
  echo ""                                                                               >>${__compose_sh_file}
  echo "echo \"${__cmd_1}\""                                                            >>${__compose_sh_file}
  echo ${__cmd_1}                                                                       >>${__compose_sh_file}
  echo ""                                                                               >>${__compose_sh_file}
  echo "echo \"${__cmd_2}\""                                                            >>${__compose_sh_file}
  echo ${__cmd_2}                                                                       >>${__compose_sh_file}
  echo ""                                                                               >>${__compose_sh_file}
  echo "echo \"${__cmd_5}\""                                                            >>${__compose_sh_file}
  echo ${__cmd_5}                                                                       >>${__compose_sh_file}
  echo ""                                                                               >>${__compose_sh_file}
  echo "echo \"${__cmd_6}\""                                                            >>${__compose_sh_file}
  echo ${__cmd_6}                                                                       >>${__compose_sh_file}
  echo ""                                                                               >>${__compose_sh_file}

  chmod +x ${__compose_sh_file}  


    #format config files 
  __private_docker_envsubst ${__dockerfile}
  __private_docker_envsubst ${__compose_file}

  echB "      Building ..."
  echY "        - ${__cmd_1}"
  echo $(${__cmd_1})&>/dev/null
  echY "        - ${__cmd_2}"
  echo $(${__cmd_2})&>/dev/null
  echY "        - ${__cmd_3}"
  echo $(${__cmd_3})&>/dev/null
  echY "        - ${__cmd_5}"
  echo $(${__cmd_5})&>/dev/null
  local __check=$(docker service ls | grep ${__service})

  export COMPOSE_HTTP_TIMEOUT=$(parserTime 1y)
  if [[ ${__check} == "" ]]; then
  echR "    [FAIL]Service not found:${__service}"
    return 0
  fi
  echG "    Finished"

  return 1
}

function dockerRegistryImageCheck()
{
  unset __func_return
  local __dns=${1}
  local __image=${2}
  if [[ ${__dns} == "" ]]; then
    export __func_return="Invalid env \${__dns}"
    return 0
  elif [[ ${__image} == "" ]]; then
    export __func_return="Invalid env \${__image}"
    return 0
  else
    local __check=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET "http://${__dns}/v2/${__image}/manifests/latest" | jq '.config.mediaType')
    if [[ ${__check} == "" || ${__check} == "null" ]]; then
      return 0;
    fi
    export __func_return=1  
    return 1;
  fi
}
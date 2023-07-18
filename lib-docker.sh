#!/bin/bash

. lib-bash.sh

# export DOCKER_OPTION=
# export DOCKER_SCOPE=
# export DOCKER_DIR=

function __prepare_container_envs()
{
  if [[ ${1} == "" ]]; then
    return 0
  fi

  if [[ ${2} == "" ]]; then
    __stack_name_curent=${1}
  else
    __stack_name_curent="${1}_${2}"
  fi
  
  if [[ ${__stack_name_last} == "${__stack_name_curent}" ]]; then
    return 1;
  fi
  
  __stack_name_last=${__stack_name_curent}

  export DOCKER_ENV_FILE_DEFAULT=${DOCKER_BIN_DIR}/default.env
  if [[ -f ${DOCKER_JAR_NAME} ]]; then
    export DOCKER_ENV_FILE=$(echo ${DOCKER_JAR_NAME} | sed 's/jar/env/g')
  else
    export DOCKER_ENV_FILE=${DOCKER_BIN_DIR}/${__stack_name_curent}.env
  fi
  rm -rf ${DOCKER_ENV_FILE}
  TAGS=(default "${1}" "${2}")
  for TAG in "${TAGS[@]}"
  do
    if [[ ${TAG} == "" ]]; then
      continue;
    fi

    export TAG=$(echo ${TAG} | sed 's/-/_/g')   
    TAG_FILE=${DOCKER_BIN_DIR}/envs_${TAG}.env
    cat ${DOCKER_INIT_DIR}/env_file_default.json | jq ".${TAG}[]" | sed 's/\"//g' > ${TAG_FILE}
    if ! [[ -f ${DOCKER_ENV_FILE} ]]; then
      cat ${TAG_FILE} > ${DOCKER_ENV_FILE}
    else
      cat ${TAG_FILE} >> ${DOCKER_ENV_FILE}
    fi    
  done

  echo ${DOCKER_ENV_FILE}

  return 1
}

function dockerSwarmIsActive()
{
  DOCKER_SWARM_STATS=$(docker info --format '{{ .Swarm.LocalNodeState }}')
  if [[ ${DOCKER_SWARM_STATS} == "active" ]]; then
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
  TAGS=(${1})
  TAGGO=false
  for TAG in "${TAGS[@]}"
  do
    CHECK=$(docker service ls | grep ${TAG} | awk '{print $1}')
    if [[ ${CHECK} != "" ]]; then
      TAGGO=true
      break
    fi
  done

  if [[ ${TAGGO} == false ]]; then
    return 1;
  fi

  echM "    Docker cleanup"
  for TAG in "${TAGS[@]}"
  do
    CMD="docker --log-level ERROR service rm \$(docker service ls | grep ${TAG} | awk '{print \$1}')"
    echR "      Removing tag[${TAG}]..."
    echY "        - ${CMD}"  
    CHECK=$(docker service ls | grep ${TAG} | awk '{print $1}')
    if [[ ${CHECK} == "" ]]; then
      continue
    fi
    echo $(docker --log-level ERROR service rm $(docker service ls | grep ${TAG} | awk '{print $1}') )&>/dev/null
  done
  echG "    Finished"
  return 1
}

function dockerPrune()
{
  echM "    Docker prune"
  CMD="docker --log-level ERROR system prune -a --all --force"
  echR "      Removing ..."
  echY "        - ${CMD}"
  echo $(${CMD})&>/dev/null
  echG "    Finished"
}

function dockerReset()
{
  echG "  Docker reset"
  dockerCleanup "adm mcs srv"
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

  CMD="docker swarm init --advertise-addr ${PUBLIC_HOST_IPv4}"
  if [[ ${__docker_swarm_action} == true ]]; then
    clearTerm
    echB "  Docker swarm não está instalado"
    echG ""
    echG "  [ENTER] para configurar"
    echG ""
    read
    echB "  Action: [Swam-Init]"
    echY "    - ${CMD}"
    echB "  Executing ..."
    echo $(${CMD})
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
    echo ${CMD}
  fi  
  return 1
}

function dockerSwarmLeave()
{
  CMD="docker swarm leave --force"
  if [[ ${__docker_swarm_action} == true ]]; then
    echB "  Action: [Swam-Leave]"
    echY "    - ${CMD}"
    echB "  Executing ..."
    echo $(${CMD})
    echG "  Finished"
  else
    echo ${CMD}
  fi
  return 1
}

function dockerConfigure()
{
  export COMPOSE_CONVERT_WINDOWS_PATHS=1
  PS3="Docker configure"$'\n'"Choose a option "
  options=(Back Swarm-Init Swarm-Leave)
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "Back" ]]; then
      return 1
    elif [[ ${opt} == "Swarm-Init" ]]; then
      CMD=$(dockerSwarmInit)
    elif [[ ${opt} == "Swarm-Leave" ]]; then
      CMD=$(dockerSwarmLeave)
    fi
    echB "    Action: [${opt}]"
    echY "      - ${CMD}"
    echB "      Executing ..."
    echo $(${CMD})
    echG "    Finished"
    break
  done
}

function dockerNetworkConfigure()
{
  if [[ ${DOCKER_NETWORK} == "" ]]; then
    echo "Invalid \${DOCKER_NETWORK}"
    return 0
  fi
  CHECK=$(docker network ls | grep ${DOCKER_NETWORK})
  if [[ ${CHECK} != "" ]]; then
    return 1
  fi
  CMD="docker --log-level ERROR network create --driver=overlay ${DOCKER_NETWORK}"
  echM "    Docker network configuration"
  echC "      - Network: ${DOCKER_NETWORK}"
  echY "      - ${CMD}"
  echo $(${CMD})&>/dev/null

  CHECK=$(docker network ls | grep ${DOCKER_NETWORK})
  if [[ ${CHECK} == "" ]]; then
    echR "    [FAIL] network not found: [${DOCKER_NETWORK}]"
    return 0
  fi
  echG "    Finished"
  return 1
}

function dockerParserHostName()
{
  if [[ ${1} == "" ]]; then
    return 0;
  fi
  NAME=${1}
  TARGETS=("_" "|" "\.")
  for TARGET in "${TARGETS[@]}"
  do
    export NAME=$(echo ${NAME} | sed "s/${TARGET}/-/g")
  done  
  echo ${NAME}
}

function dockerParserName()
{
  if [[ ${1} == "" ]]; then
    return 0;
  fi
  NAME=${1}
  NAME=$(replaceString ${NAME} insurance ins)
  NAME=$(replaceString ${NAME} apolice apl)
  NAME=$(replaceString ${NAME} persistence pst)
  NAME=$(replaceString ${NAME} ingester igt)
  NAME=$(replaceString ${NAME} sro_mcs mcs)
  NAME=$(replaceString ${NAME} sro )
  NAME=$(replaceString ${NAME} orch orc)
  NAME=$(replaceString ${NAME} movimento mvt)
  NAME=$(replaceString ${NAME} "\." "_" )
  NAME=$(replaceString ${NAME} "-" "_" )
  NAME=$(replaceString ${NAME} "__" "_" )
  NAME="-H-${NAME}-H-"
  NAME=$(replaceString ${NAME} "-H-_" )
  NAME=$(replaceString ${NAME} "_-H-" )
  NAME=$(replaceString ${NAME} "-H-" )

  echo ${NAME}
}

function dockerBuildCompose()
{
  export STACK_TYPE=${1}
  export STACK_NAME=${2}  
  
  if [[ ${STACK_TYPE} == "mcs" ]]; then
    if [[ ${DOCKER_JAR_NAME} == "" ]]; then
      echR "    Invalid \${DOCKER_JAR_NAME}"
      return 0
    fi

    if ! [[ -f ${DOCKER_JAR_NAME} ]]; then
      echR "    Invalid jar: DOCKER_JAR_NAME=${DOCKER_JAR_NAME}"
      return 0
    fi
  fi

  cd ${DOCKER_DIR}
  export STACK_FILE_NAME=docker-compose-${STACK_TYPE}.yml

  if ! [[ -f  ${STACK_FILE_NAME} ]]; then
    echR "    File not found: ${STACK_FILE_NAME}"  
    return 0;
  fi

  export STACK_SERVICE=${STACK_NAME}
  export STACK_HOSTNAME=${STACK_NAME}

  export DOCKER_ENV_FILE=$(__prepare_container_envs ${STACK_TYPE} ${STACK_NAME} ${DOCKER_JAR_NAME})

  export STACK_SERVICE=$(dockerParserName ${STACK_SERVICE})
  export STACK_HOSTNAME=$(dockerParserHostName ${STACK_HOSTNAME})

  if [[ ${STACK_SERVICE} == "" ]]; then
    export STACK_SERVICE=${STACK_TYPE}
  else
    export STACK_SERVICE=${STACK_TYPE}_${STACK_SERVICE}
  fi
  if [[ ${STACK_HOSTNAME} == "" ]]; then
    export STACK_HOSTNAME=${STACK_TYPE}
  else
    export STACK_HOSTNAME=${STACK_TYPE}-${STACK_HOSTNAME}
  fi
  
  
  dockerCleanup ${STACK_SERVICE}

  cd ${DOCKER_DIR}
  export CMD=
  if [[ ${DOCKER_OPTION} == "Docker-Stack" ]]; then
    # ref https://docs.docker.com/compose/environment-variables/envvars/
    CMD="docker stack deploy --compose-file ${STACK_FILE_NAME} ${STACK_SERVICE}"
  elif [[ ${DOCKER_OPTION} == "Docker-Compose" ]]; then
    # ref https://docs.docker.com/compose/environment-variables/envvars/
    CMD="docker compose --file ${STACK_FILE_NAME} up --detach "
  else
    echR "    Invalid DOCKER_OPTION: ${DOCKER_OPTION}"
    return 0;
  fi

  echM "    Docker containers create"  
  echB "      Information"
  echC "        - Stack name: [${STACK_SERVICE}]"
  echC "        - Path: ${PWD}"
  echC "        - Target: ${STACK_FILE_NAME}"
  echC "        - Network: ${DOCKER_NETWORK}"
  echC "        - Hostname: ${STACK_HOSTNAME}.local"
  echB "      Environments"
  if [[ -f ${DOCKER_ENV_FILE} ]]; then
  echC "        - Env file: ${DOCKER_ENV_FILE}"
  fi
  if [[ -f ${DOCKER_JAR_NAME} ]]; then
  echC "        - JAR name: ${DOCKER_JAR_NAME}"
  fi
  
  echB "      Building ..."
  echY "        - ${CMD}"
  echo $(${CMD})&>/dev/null
  CHECK=$(docker service ls | grep ${STACK_SERVICE})
  if [[ ${CHECK} == "" ]]; then
  echR "    [FAIL]Service not found:${STACK_SERVICE}"
    return 0
  fi
  echG "    Finished"

  return 1
}

function mavenPrepare()
{
  export STACK_TYPE=${1}
  export STACK_NAME=${2}
  export DOCKER_JAR_NAME=${DOCKER_DIR_DATA}/bin/${STACK_NAME}.jar
  export DOCKER_ENV_FILE=$(__prepare_container_envs ${STACK_TYPE} ${STACK_NAME} ${DOCKER_JAR_NAME}) 
}

function mavenBuild()
{
  export STACK_TYPE=${1}
  export STACK_NAME=${2}
  mavenPrepare ${STACK_TYPE} ${STACK_NAME}
  echG "  Source building"
  cd ${PUBLIC_ROOT_DIR}
  MAVEN_CHECK=$(mvn --version)
  MAVEN_CHECK=$(mvn --version | grep Apache)

  if [[ ${MAVEN_CHECK} != *"Apache"*  ]]; then
    echR "  ==============================  "
    echR "  ***MAVEN não está instalado***  "
    echR "  ***MAVEN não está instalado***  "
    echR "  ==============================  "
    return 0
  fi

  cd ${DOCKER_DIR_DATA}/src


  REPOSITORY_SSH="git@bitbucket.org:crdc_portal_registro/${STACK_NAME}.git"
  SRC_DIR=${DOCKER_DIR_DATA}/src/${STACK_NAME}
  DST_DIR=${DOCKER_DIR_DATA}/bin/${STACK_NAME}.jar

  rm -rf ${DST_DIR}
  rm -rf ${SRC_DIR};

  CMD="git clone -q ${REPOSITORY_SSH}"
  echM "    Git cloning repository"
  echC "      - ${REPOSITORY_SSH}"
  echC "      - Branch: ${DOCKER_GIT_BRANCH}"
  echC "      - Source dir: ${SRC_DIR}"
  echY "      - ${CMD}"
  echo $(${CMD})>/dev/null 2>&1
  if ! [[ -d ${SRC_DIR} ]]; then
    echR "      ==============================  "
    echR "      *****Repository not found*****  "
    echR "      *****Repository not found*****  "
    echR "      ==============================  "
    
    return 0
  fi
  cd ${SRC_DIR}
  CMD="git checkout ${DOCKER_GIT_BRANCH} -q"
  echY "      - ${CMD}"
  echo $(${CMD})>/dev/null 2>&1
  echG "    Finished"


  CMD="mvn install -DskipTests"
  echM "    Maven build"
  echC "      - Source dir: ${SRC_DIR}"
  echC "      - JAR file: ${DOCKER_JAR_NAME}"
  echY "      - ${CMD}"
  OUTPUT=$(${CMD})
  CHECK=$(echo ${OUTPUT} | grep ERROR)
  if [[ ${CHECK} != "" ]]; then
    echR "    source build fail:"
    echR "    ==============================  "
    echR "    *******Maven build fail*******  "
    echR "    *******Maven build fail*******  "
    echR "    ==============================  "
    printf "${OUTPUT}"
    return 0;
  fi
  echG "    Finished"
  
  echM "    Preparing jar for container"
  echC "      - JAR file: ${DST_DIR}"
  export JAR_FILE=$(find ${SRC_DIR} -name 'app*.jar')
  cp -r ${JAR_FILE} ${DST_DIR}

  if ! [[ -f ${DST_DIR} ]]; then
    echR "      ==============================  "
    echR "      ******JAR file not found******  "
    echR "      ******JAR file not found******  "
    echR "      ==============================  "
    return 0;
  fi
  echG "    Finished"
  return 1
}

function dockerPrepare()
{ 
  export DOCKER_SCOPE=${1}
  export DOCKER_DIR=${2}
  export DOCKER_DIR_DATA=${3}
  export DOCKER_GIT_BRANCH=${4}
  export DOCKER_OPTION=${5}
  
  if [[ ${DOCKER_SCOPE} == "" ]]; then
    echR "    [FAIL]Invalid scope: ${DOCKER_SCOPE}"
    return 0;
  fi

  if [[ ${DOCKER_DIR} == "" ]]; then
    echR "    [FAIL]Invalid \${DOCKER_DIR}"
    return 0;
  fi

  if ! [[ -d ${DOCKER_DIR} ]]; then
    echR "    [FAIL]Invalid DOCKER_DIR: ${DOCKER_DIR}"
    return 0;
  fi

  if [[ ${DOCKER_GIT_BRANCH} == "" ]]; then
    echR "    [FAIL]Invalid \${DOCKER_GIT_BRANCH}"
    return 0;
  fi

  if [[ ${DOCKER_OPTION} == "" ]]; then
    echR "    [FAIL]Invalid \${DOCKER_OPTION}"
    return 0
  fi

  export DOCKER_NETWORK="${DOCKER_SCOPE}-network"

  #IP'S 
  export HOST_IP="127.0.0.1"
  if [[ -d /mnt ]]; then
      export PUBLIC_HOST_IPv4=$(ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')
  else
      export PUBLIC_HOST_IPv4=$(ipconfig.exe | grep -a IPv4 | grep -a 192 | sed 's/ //g' | sed 's/Endere□oIPv4//g' | awk -F ':' '{print $2}')
  fi
 

  export DOCKER_INIT_DIR=${DOCKER_DIR}/init 
  export DOCKER_BIN_DIR=${DOCKER_DIR_DATA}/bin
  export DOCKER_BIN_RUN=${DOCKER_BIN_DIR}/run.sh

  mkdir -p ${DOCKER_BIN_DIR}
  echo "#!/bin/bash">${DOCKER_BIN_RUN}
  echo "">>${DOCKER_BIN_RUN}
  echo "">>${DOCKER_BIN_RUN}
  echo "#default envs">>${DOCKER_BIN_RUN}
  echo "ENV_FILE=./default.env">>${DOCKER_BIN_RUN}
  echo "if [[ -f \${ENV_FILE} ]]; then">>${DOCKER_BIN_RUN}
  echo "  source \${ENV_FILE}">>${DOCKER_BIN_RUN}
  echo "fi">>${DOCKER_BIN_RUN}
  echo "">>${DOCKER_BIN_RUN}
  echo "#jar envs">>${DOCKER_BIN_RUN}
  echo "ENV_FILE=echo \$(echo \"\$@\" | sed 's/jar/env/g')">>${DOCKER_BIN_RUN}
  echo "if [[ -f \${ENV_FILE} ]]; then">>${DOCKER_BIN_RUN}
  echo "  source \${ENV_FILE}">>${DOCKER_BIN_RUN}
  echo "fi">>${DOCKER_BIN_RUN}
  echo "">>${DOCKER_BIN_RUN}
  echo "java -jar \"\$@\"">>${DOCKER_BIN_RUN}

  echo "">>${DOCKER_BIN_RUN}
  chmod +x ${DOCKER_BIN_RUN}
  return 1
}
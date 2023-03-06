#!/bin/bash

if [[ ${ROOT_DIR} == "" ]]; then
  export ROOT_DIR=${PWD}
fi
export STACK_RUN_BIN=${ROOT_DIR}/bin


function toInt()
{
  v=${1}
  if [[ ${v} == "" ]]; then
    v=0
  fi
  [ ! -z "${v##*[!0-9]*}" ] && echo -n ${v} || echo 0;
}

function incInt()
{
  v=${1}
  if [[ ${v} == "" ]]; then
    v=0
  fi
  v=$(toInt ${v})
  let "v=${v} + 1"
  echo ${v}
}

function logIdent()
{
  IDENT=$(toInt ${1})
  CHAR=${2}

  if [[ ${CHAR} == "" ]]; then
    CHAR="."
  fi

  if [[ ${IDENT} == "" ]]; then
    echo -n ${CHAR}
    return;
  fi

  for i in $(seq 1 4);
  do
    TEXT="${TEXT}${CHAR}"
  done
  TEXT="${TEXT}"
  
  for i in $(seq 1 ${IDENT})
  do
    CHARS="${TEXT}${CHARS}"
  done
  echo -n ${CHARS}

  return;
}

function log()
{
  echo "$@"
}

function logOut()
{
  if [[ ${STACK_LOG} == 1 || ${STACK_LOG_VERBOSE} == 1 || ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    if [[ ${2} != "" ]]; then
      echo "log: $(logIdent ${1})${2}"
    fi
  fi
}

function logMethod()
{
  logOut "$(incInt ${1})" "${2}" "${3}"
}

function logForce()
{
  v=${2}
  log "$(logIdent ${1}) ${v}"
}

function logInfo()
{
  if [[ ${STACK_LOG} == 1 || ${STACK_LOG_VERBOSE} == 1 || ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    if [[ ${2} != "" && ${3} != "" ]]; then
      LOG="${2}: ${3}"
    else
      LOG="${2}"
    fi
    if [[ ${LOG} != "" ]]; then
      logMethod ${1} "-${LOG}"
    fi
  fi
}

function logCommand()
{
  logInfo ${1} "command" "${2}"
}

function logTarget()
{
  logInfo ${1} "target" "${2}"
}

function logMessage()
{
  logInfo ${1} "message" "${2}"
}

function logWarning()
{
  logInfo ${1} "warning" "${2}"
}

function logError()
{
  if [[ ${2} != "" ]]; then
    logInfo ${1} "error" "${2}"
    log "error: ${2}"
  fi
}

function logSuccess()
{
  if [[ ${2} == "" ]]; then
    logInfo ${1} "result" "success"
  else
    logInfo ${1} "result" "success" "${2}"
  fi
}

function logStart()
{
  logOut ${1} "${2}: started"
  if [[ ${3} != "" ]]; then
    logMessage ${1} "${3}"
  fi
}

function logFinished()
{
  if [[ ${3} != "" ]]; then
    logMessage ${1} "${3}"
  fi
  logOut ${1} "${2}: finished"
}

function runSource()
{
  RUN_FILE=${2}
  RUN_PARAMS=${3}
  idt="$(toInt ${1})"
  logStart ${idt} "runSource"
  logTarget ${idt} "${RUN_FILE}"

  if [[ ${RUN_FILE} == "" ]]; then
    logError ${idt} "run file is empty"
  elif ! [[ -f ${RUN_FILE} ]]; then
    logError ${idt} "run file not found"
  else
    chmod +x ${RUN_FILE}
    source ${RUN_FILE} ${RUN_PARAMS}
    logSuccess ${idt}
    logFinished ${idt} "runSource"
    return 1
  fi
  logFinished ${idt} "runSource" ${RUN_FILE}
  return 0
}

function cdDir()
{
  idt="$(toInt ${1})"
  NEW_DIR=${2}
  OLD_DIR=${PWD}
  logStart ${idt} "cdDir"
  logInfo ${idt} "of" ${OLD_DIR}
  logInfo ${idt} "to" ${NEW_DIR}
  if ! [[ -d ${NEW_DIR} ]]; then
    logError ${idt} "invalid-dir: ${NEW_DIR}"
    return 0;
  fi
  cd ${NEW_DIR}
  if [[ ${PWD} != ${NEW_DIR} ]]; then
    logError ${idt} "no-access-dir:${NEW_DIR}"
    logFinished ${idt} "cdDir"
    return 0;
  fi
  logSuccess ${idt}
  logFinished ${idt} "cdDir"
  return 1;
}

function fileExists()
{
  idt="$(toInt ${1})"
  logStart ${idt} "fileExists"
  TARGET=${2}
  DIR=${3}
  if [[ ${DIR} == "" ]]; then
    DIR=${PWD}
  fi

  logTarget ${idt} ${TARGET}
  logInfo ${idt} "dir" ${DIR}
  FILE=${DIR}/${TARGET}
  if ! [[ -f ${FILE} ]]; then
    logError ${idt} "file-not-found|fileName:${FILE}"
    logFinished ${idt} "fileExists"
    return 0;
  fi
  logSuccess ${idt}
  logFinished ${idt} "fileExists"
  return 1;
}


function makeDir()
{
  idt="$(toInt ${1})"
  logStart ${idt} "makeDir"
  MAKE_DIR=${2}
  MAKE_PERMISSION=${3}

  logTarget ${idt} ${MAKE_DIR}
  logInfo ${idt} "permission" ${MAKE_PERMISSION}

  if [[ ${MAKE_DIR} == "" || ${MAKE_PERMISSION} == "" ]]; then
    logError ${idt} "Invalid-parameters:MAKE_DIR==${MAKE_DIR},MAKE_PERMISSION==${MAKE_PERMISSION}"
    return;
  fi

  if [[ ${MAKE_DIR} == "" ]]; then
    MSG="dir-is-empty"
    logError ${idt} "${MSG}"
    return;
  fi

  if ! [[ -d ${MAKE_DIR}  ]]; then
    mkdir -p ${MAKE_DIR}
    if ! [[ -d ${MAKE_DIR}  ]]; then
      logError ${idt} "no-create-dir:${MSG}"
      return 0
    fi
  fi  


  if [[ ${MAKE_PERMISSION} != "" ]]; then
    chmod ${MAKE_PERMISSION} ${MAKE_DIR};
  fi

  logSuccess ${idt}
  logFinished ${idt} "makeDir"
  return 1;
}

function copyFile()
{
  idt="$(toInt ${1})"
  logStart ${idt} "copyFile"
  SRC=${2}
  DST=${3}

  logTarget ${idt} ${SRC}
  logInfo ${idt} "destine" ${DST}

  logMethod ${1} "Copying ${SRC} to ${DST}"
  if [[ -f ${SRC} ]]; then
    logError ${idt} "sources-does-not-exists[${SRC}]"
  elif [[ -f ${DST} ]]; then
    logError ${idt} "destine-exists-[${DST}]"
  else
    cp -r ${SRC} ${DST}
    if [[ -f ${DST} ]]; then
      logSuccess ${idt}
    fi
  fi
  logFinished ${idt} "copyFile"
}

function fileDedupliceLines()
{
  logStart ${idt} "fileDedupliceLines"
  idt="$(toInt ${1})"
  DEDUP_FILENAME=${2}

  if [[ ${DEDUP_FILENAME} == "" ]]; then
    return 1;
  fi

  logTarget ${idt} "${DEDUP_FILENAME}"

  if ! [[ -f ${DEDUP_FILENAME} ]]; then
    return 1;
  fi

  TMP_DEDUP_FILENAME="/tmp/fileDedupliceLines-${RANDOM}.tmp"
  if [[ -f ${TMP_DEDUP_FILENAME}  ]]; then
    rm -rf ${TMP_DEDUP_FILENAME}
  fi
  
  while IFS= read -r line
  do
    if [[ ${line} == "" ]]; then
      echo ${line} > ${TMP_DEDUP_FILENAME} 
    elif ! [[ -f ${TMP_DEDUP_FILENAME} ]]; then
      echo ${line} > ${TMP_DEDUP_FILENAME} 
    elif [[ "${line}" == *'/'* ]]; then
      echo ${line} >> ${TMP_DEDUP_FILENAME}
    else
      #remove existing lines
      sed -i "/$line/d" ${TMP_DEDUP_FILENAME}
      echo ${line} >> ${TMP_DEDUP_FILENAME} 
    fi    
  done < "${DEDUP_FILENAME}"

  rm -rf ${DEDUP_FILENAME}
  mv ${TMP_DEDUP_FILENAME} ${DEDUP_FILENAME}
  

  logFinished ${idt} "fileDedupliceLines"
  if [[ -f ${DEDUP_FILENAME} ]]; then
    return 1
  else
    return 0
  fi
}


function copyFileIfNotExists()
{
  idt="$(toInt ${1})"
  logStart ${idt} "copyFileIfNotExists"
  SRC=$2
  DST=$3
  
  logTarget ${idt} ${SRC}
  logInfo ${idt} "destine" ${DST}
  if ! [[ -f ${SRC} ]]; then
    logError ${idt} "source-does-not-exists-[${SRC}]"
  else
    if [[ -d ${DST} ]]; then
      rm -rf ${DST}
      logInfo ${idt} "remove" ${DST}
    fi
    cp -r ${SRC} ${DST}
    if [[ -d ${DST} ]]; then
      logSuccess ${idt}
    fi
  fi
  logFinished ${idt} "copyFileIfNotExists"
}

function utilInitialize()
{
  idt="$(toInt ${1})"
  logStart ${idt} "utilInitialize"
  export STACK_LOG=0            
  export STACK_LOG_VERBOSE=0            
  export STACK_LOG_VERBOSE_SUPER=0
  for PARAM in "$@"
  do
    if [[ $PARAM == "-l" ]]; then
      export STACK_LOG=1            
    elif [[ $PARAM == "-lv" ]]; then
      export STACK_LOG=1            
      export STACK_LOG_VERBOSE=1            
    elif [[ $PARAM == "-lvs" ]]; then
      export STACK_LOG=1            
      export STACK_LOG_VERBOSE=1            
      export STACK_LOG_VERBOSE_SUPER=1
    fi
  done

  if [[ ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    echo "Log super verbose enabled"
  elif [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    echo "Log verbose enabled"
  elif [[ ${STACK_LOG} == 1 ]]; then
    echo "Log enabled"
  fi

  export PATH=${PATH}:${STACK_RUN_BIN}

  #export BASH_BIN=${PWD}/installer/bash-bin

  logFinished ${idt} "utilInitialize"
}

function envsParserFile()
{
  idt="$(toInt ${1})"
  FILE=$2
  logStart ${idt} "envsParserFile"
  logTarget ${idt} "${FILE}"
  if [[ -f ${FILE} ]]; then
    ENVSLIST=($(printenv))
  
    FILE_BACK=${FILE}-sed.bak
    rm -rf ${FILE_BACK}
    cp -r ${FILE} ${FILE_BACK}

    for ENV in "${ENVSLIST[@]}"
    do
      ENV=(${ENV//=/ })
      replace="\${${ENV[0]}}"
      replacewith=${ENV[1]}
      if [[ "$replacewith" == *"/"* ]]; then
        continue;
      else
        echo $(sed -i s/${replace}/${replacewith}/g ${FILE})&>/dev/null
      fi
    done

    logSuccess ${idt}
    logFinished ${idt} "envsParserFile"
    return 1;
  fi
  logFinished ${idt} "envsParserFile"
  return 0;
}

function envsToSimpleEnvs()
{
  idt="$(toInt ${1})"
  FILE=$2
  logStart ${idt} "envsToSimpleEnvs"
  logTarget ${idt} "${FILE}"
  if [[ -f ${FILE} ]]; then

    FILE_BACK=${FILE}-sed.bak
    rm -rf ${FILE_BACK}
    cp -r ${FILE} ${FILE_BACK}

    #REMOVE
    ENVSLIST=()
    ENVSLIST+=("#")
    for PHRASE in "${ENVSLIST[@]}"
    do
      echo $(sed -i /${PHRASE}/d ${FILE})&>/dev/null
    done

    #EMPTY LINES
    ENV_TO_SIMPLE_FILENAME="/tmp/envsToSimpleEnvs-${RANDOM}.tmp"
    sort ${FILE} > ${ENV_TO_SIMPLE_FILENAME}
    echo $(sed -i '/^$/d' ${ENV_TO_SIMPLE_FILENAME})&>/dev/null    
    fileDedupliceLines ${idt} "${ENV_TO_SIMPLE_FILENAME}"

    #REPLACE
    ENVSLIST=()
    ENVSLIST+=("export ")
    ENVSLIST+=("export;")
    for ENV in "${ENVSLIST[@]}"
    do
      ENV=(${ENV//=/ })
      replace=${ENV[0]}
      if [[ ${replace} == "" ]]; then
        continue;
      else
        echo $(sed -i "s/${replace}//g" ${ENV_TO_SIMPLE_FILENAME})&>/dev/null
      fi
    done

    #move temp file to source file
    sort ${ENV_TO_SIMPLE_FILENAME}>${FILE}
    rm -rf ${ENV_TO_SIMPLE_FILENAME}

    logSuccess ${idt}
    logFinished ${idt} "envsToSimpleEnvs"
    return 1;
  fi
  logFinished ${idt} "envsToSimpleEnvs"
  return 0;
}

function envsParserDir()
{
  idt="$(toInt ${1})"
  logStart ${idt} "envsParserDir"
  export DIR=${2}
  export EXT=${3}

  if [[ ${DIR} == "" || ${EXT} == "" ]]; then
    if [[ -d ${DIR} ]]; then
      logInfo ${idt} "parser-dir" ${DIR}
      FILELIST=($(find ${DIR} -name ${EXT}))
      for FILE in "${FILELIST[@]}"
      do
        if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
          logInfo ${idt} "parser-file" ${FILE}
        fi
        envsParserFile "$(incInt ${1})" ${FILE}
      done
    fi
  fi

  logFinished ${idt} "envsParserDir"
  return 1;
}
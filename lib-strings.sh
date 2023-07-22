#!/bin/bash

export COLOR_RED="\e[31m"
export COLOR_GREEN="\e[32m"
export COLOR_YELLOW="\e[33m"
export COLOR_BLUE="\e[34m"
export COLOR_MAGENTA="\e[35m"
export COLOR_CIANO="\e[36m"

if [[ ${ROOT_DIR} == "" ]]; then
  export ROOT_DIR=${PWD}
fi

export REPLACE_SEPARADOR_250="%REPLACE-250"
export STACK_RUN_BIN=${ROOT_DIR}/bin
export STACK_RUN_ACTIONS=${STACK_RUN_BIN}/actions

function logVerboseSet()
{
  STACK_LOG=1
  STACK_LOG_VERBOSE=1
  STACK_LOG_VERBOSE_SUPER=1
}

function toInt()
{
  v="${1}"
  if [[ ${v} == "" ]]; then
    v=0
  fi
  [ ! -z "${v##*[!0-9]*}" ] && echo -n ${v} || echo 0;
}

function incInt()
{
  v=$(toInt ${1})
  i=$(toInt ${2})
  if [[ ${i} == 0 ]]; then
    i=1
  fi
  let "v=${v} + ${i}"
  echo ${v}
}

function logIdent()
{
  IDENT=$(toInt ${1})
  CHAR="${2}"

  if [[ ${CHAR} == "" ]]; then
    CHAR="."
  fi

  if [[ ${IDENT} == "" ]]; then
    echo -n ${CHAR}
    return 0;
  fi

  echo $(strRightJustified 4 ${CHAR} ${CHAR} )
  return 1

  # for i in $(seq 1 4);
  # do
  #   TEXT="${TEXT}${CHAR}"
  # done
  # TEXT="${TEXT}"
  
  # for i in $(seq 1 ${IDENT})
  # do
  #   CHARS="${TEXT}${CHARS}"
  # done
  # echo -n ${CHARS}

  return 0;
}

function log()
{
  echo "$@"
}

function logOut()
{
  if [[ ${STACK_LOG} == 1 || ${STACK_LOG_VERBOSE} == 1 || ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    if [[ "${2}" != "" ]]; then
      echo "log: $(logIdent ${1})${2}"
    fi
  fi
}

function logMethod()
{
  logOut "$(incInt ${1})" ${2} "${3}"
}

function logForce()
{
  v="${2}"
  log "$(logIdent ${1}) ${v}"
}

function logInfo()
{
  if [[ ${STACK_LOG} == 1 || ${STACK_LOG_VERBOSE} == 1 || ${STACK_LOG_VERBOSE_SUPER} == 1 ]]; then
    if [[ "${2}" != "" && "${3}" != "" ]]; then
      LOG="${2}: ${3}"
    else
      LOG="${2}"
    fi
    if [[ ${LOG} != "" ]]; then
      logMethod "${1}" "-${LOG}"
    fi
  fi
}

function logCommand()
{
  logInfo "${1}" "command" "${2}"
}

function logTarget()
{
  logInfo "${1}" "target" "${2}"
}

function logMessage()
{
  logInfo "${1}" "message" "${2}"
}

function logWarning()
{
  logInfo "${1}" "warning" "${2}"
}

function logError()
{
  if [[ "${2}" != "" ]]; then
    logInfo "${1}" "error" "${2}"
    log "error: ${2}"
  fi
}

function logSuccess()
{
  if [[ "${2}" == "" ]]; then
    logInfo "${1}" "result" "success"
  else
    logInfo "${1}" "result" "success" "${2}"
  fi
}

function logStart()
{
  logOut "${1}" "${2}: started"
  if [[ "${3}" != "" ]]; then
    logMessage "${1}" "${3}"
  fi
}

function logFinished()
{
  if [[ "${3}" != "" ]]; then
    logMessage "${1}" "${3}"
  fi
  logOut "${1}" "${2}: finished"
}

function runSource()
{
  RUN_FILE="${2}"
  RUN_PARAMS="${3}"
  idt="$(toInt ${1})"
  logStart ${idt} "runSource"
  logTarget ${idt} "${RUN_FILE}"

  if [[ ${RUN_FILE} == "" ]]; then
    logError ${idt} "run file is empty"
  elif ! [[ -f ${RUN_FILE} ]]; then
    logError ${idt} "run file not found"
  else
    echo $(chmod +x ${RUN_FILE})&>/dev/null
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
  NEW_DIR="${2}"
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
  TARGET="${2}"
  DIR="${3}"
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
  MAKE_DIR="${2}"
  MAKE_PERMISSION="${3}"

  logTarget ${idt} ${MAKE_DIR}
  logInfo ${idt} "permission" ${MAKE_PERMISSION}

  if [[ ${MAKE_DIR} == "" || ${MAKE_PERMISSION} == "" ]]; then
    logError ${idt} "Invalid-parameters:MAKE_DIR==${MAKE_DIR},MAKE_PERMISSION==${MAKE_PERMISSION}"
    return 0;
  fi

  if [[ ${MAKE_DIR} == "" ]]; then
    MSG="dir-is-empty"
    logError ${idt} "${MSG}"
    return 0;
  fi

  if ! [[ -d ${MAKE_DIR}  ]]; then
    mkdir -p ${MAKE_DIR}
    if ! [[ -d ${MAKE_DIR}  ]]; then
      logError ${idt} "no-create-dir:${MSG}"
      return 0
    fi
  fi  

  if [[ ${MAKE_PERMISSION} != "" ]]; then
    #echo "chmod ${MAKE_PERMISSION} ${MAKE_DIR})>/dev/null 2>&1"
    __makeDirUser=$(echo $(ls -l ${MAKE_DIR}) | awk '{print $5}')
    if [[ ${__makeDirUser} == ${USER} ]]; then
      echo $(chmod ${MAKE_PERMISSION} ${MAKE_DIR})>/dev/null 2>&1
    fi
  fi

  logSuccess ${idt}
  logFinished ${idt} "makeDir"
  return 1;
}

function copyFile()
{
  idt="$(toInt ${1})"
  logStart ${idt} "copyFile"
  SRC="${2}"
  DST="${3}"

  logTarget ${idt} ${SRC}
  logInfo ${idt} "destine" ${DST}

  logMethod "${1}" "Copying ${SRC} to ${DST}"
  if [[ -f ${SRC} ]]; then
    logError ${idt} "sources-does-not-exists[${SRC}]"
  elif [[ -f ${DST} ]]; then
    logError ${idt} "destine-exists-[${DST}]"
  else
    cp -rf ${SRC} ${DST}
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
  DEDUP_FILENAME="${2}"

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
    if [[ "${line}" == *'/'* ]]; then
      line=$(sed "s/\//$REPLACE_SEPARADOR_250/g" <<< "${line}")
    fi

    if [[ ${line} == "" ]]; then
      echo ${line} > ${TMP_DEDUP_FILENAME} 
    elif ! [[ -f ${TMP_DEDUP_FILENAME} ]]; then
      echo ${line} > ${TMP_DEDUP_FILENAME} 
    elif [[ "${line}" == *'/'* ]]; then
      echo ${line} >> ${TMP_DEDUP_FILENAME}
    else
      #remove existing lines
      echo $(sed -i "/$line/d" ${TMP_DEDUP_FILENAME})&>/dev/null
      echo ${line} >> ${TMP_DEDUP_FILENAME} 
    fi    
  done < "${DEDUP_FILENAME}"

  echo $(sed -i "s/${REPLACE_SEPARADOR_250}/\//g" ${TMP_DEDUP_FILENAME})&>/dev/null


  sort ${TMP_DEDUP_FILENAME} > ${DEDUP_FILENAME}
  rm -rf ${TMP_DEDUP_FILENAME}
 

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
    cp -rf ${SRC} ${DST}
    if [[ -d ${DST} ]]; then
      logSuccess ${idt}
    fi
  fi
  logFinished ${idt} "copyFileIfNotExists"
}

function utilInitialize()
{
  export PUBLIC_LOG_LEVEL=false
  export STACK_LOG=0            
  export STACK_LOG_VERBOSE=0            
  export STACK_LOG_VERBOSE_SUPER=0
  export PUBLIC_RUNNER_MODE=runner
  export PUBLIC_RUNNER_TEST=false

  for PARAM in "$@"
  do
    if [[ ${PARAM} == "-d" || ${PARAM} == "--debug" ]]; then
      export PUBLIC_LOG_LEVEL=true
      export STACK_LOG=1            
      export STACK_LOG_VERBOSE=1    
      export STACK_LOG_VERBOSE_SUPER=1
    elif [[ ${PARAM} == "-t" || ${PARAM} == "--test" ]]; then

      export PUBLIC_RUNNER_MODE=test
      export PUBLIC_RUNNER_TEST=true
    elif [[ ${PARAM} == "-l" ]]; then
      export STACK_LOG=1            
    elif [[ ${PARAM} == "-lv" ]]; then
      export STACK_LOG=1            
      export STACK_LOG_VERBOSE=1            
    elif [[ ${PARAM} == "-lvs" ]]; then
      export STACK_LOG=1            
      export STACK_LOG_VERBOSE=1            
      export STACK_LOG_VERBOSE_SUPER=1
    fi
  done

  __utilInitialize_envs=()
  __utilInitialize_envs+=("..information")
  if [[ ${PUBLIC_LOG_LEVEL} == true ]]; then
    __utilInitialize_envs+=("....Debug mode is enabled")
  fi
  if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
    __utilInitialize_envs+=("....Log verbose is enabled")
  fi
  if [[ ${STACK_LOG} == 1 ]]; then
    __utilInitialize_envs+=("....-Log is enabled")
  fi
  if [[ ${PUBLIC_RUNNER_TEST} == true ]]; then
    __utilInitialize_envs+=("....-Runner mode: ${PUBLIC_RUNNER_MODE}")
  fi
  __utilInitialize_envs+=("..args:")
  export DOCKER_ARGS_DEFAULT="--quiet --log-level ERROR"
  __utilInitialize_envs+=("....-docker: ${DOCKER_ARGS_DEFAULT}")
  export MAVEN_ARGS_DEFAULT="--quiet"
  __utilInitialize_envs+=("....-maven: ${MAVEN_ARGS_DEFAULT}")
  if [[ ${STACK_LOG} == 0 ]]; then    
    export GIT_ARGS_DEFAULT="--quiet"
    __utilInitialize_envs+=("....-git: ${GIT_ARGS_DEFAULT}")
  fi

  if [[ ${__utilInitialize_envs} != "" ]]; then
    echG "Initialization"
    for __utilInitialize_env in "${__utilInitialize_envs[@]}"
    do
      __utilInitialize_msg=$(echo ${__utilInitialize_env} | sed 's/\./ /g')
      if [[ ${__utilInitialize_env} == "......"*  ]]; then
        echY "${__utilInitialize_msg}"
      elif [[ ${__utilInitialize_env} == "...."*  ]]; then
        echC "${__utilInitialize_msg}"
      elif [[ ${__utilInitialize_env} == ".."*  ]]; then
        echM "${__utilInitialize_msg}"
      else
        echR "${__utilInitialize_msg}"
      fi
    done
    sleep 1
  fi

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
    cp -rf ${FILE} ${FILE_BACK}

    for ENV in "${ENVSLIST[@]}"
    do
      ENV=(${ENV//=/ })
      replace="\${${ENV[0]}}"
      replacewith=$(sed "s/\//$REPLACE_SEPARADOR_250/g" <<< "${ENV[1]}")

      if [[ "$replacewith" == *"/"* ]]; then
        continue;
      else
        echo $(sed -i s/${replace}/${replacewith}/g ${FILE})&>/dev/null
      fi
    done

    echo $(sed -i s/$REPLACE_SEPARADOR_250/\//g ${FILE})&>/dev/null

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
    cp -rf ${FILE} ${FILE_BACK}

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
  export DIR="${2}"
  export EXT="${3}"

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

function clearTerm()
{
  export __selector=
  if [[ ${PUBLIC_LOG_LEVEL} != true ]]; then
    clear
  fi
}

function strExtractFilePath()
{
  __str_file="${1}"
  __func_return=
  if [[ ${__str_file} == "" ]]; then
    return 0
  fi
  __func_return=$(dirname ${__str_file})
  echo ${__func_return}
  return 1;  
}

function strExtractFileName()
{
  __str_file="${1}"
  __func_return=
  if [[ ${__str_file} == "" ]]; then
    return 0
  fi
  __func_return=$(basename ${__str_file})
  echo ${__func_return}
  return 1;
}

function strExtractFileExtension()
{
  __str_file="${1}"
  __func_return=
  if [[ ${__str_file} == "" ]]; then
    return 0
  fi
  __str_file_splitted=$(strSplit ${__str_file} ".")
  if [[ ${__str_file_splitted} == "" ]]; then
    return 0
  fi
  __str_file_splitted=(${__str_file_splitted})
  __str_file_last_index=$((${#__str_file_splitted[@]} - 1))
  __func_return=${__str_file_splitted[$__str_file_last_index]}
  echo ${__func_return}
  return 1;
}

function strSplit()
{
  __strSplitText="${1}"
  __strSplitSepatator="${2}"
  __func_return=

  if [[ ${__strSplitText} == ""  ]]; then
    return 0
  fi

  # Defina o IFS para o caractere de espaço em branco
  if [[ "${__strSplitSepatator}" == ""  ]]; then
    __strSplitSepatator=' '
  fi

  #cache old IFS
  OLD_IFS=${IFS}
  #new char split
  IFS=${__strSplitSepatator}
  __strSplitArray=($__strSplitText)

  # restore IFS
  IFS=${OLD_IFS}
  for env in "${__strSplitArray[@]}"; do
      echo "${env}"
      __func_return="${__func_return} ${env}"
  done
  echo "${__func_return}"
  
}

function strAlign()
{
  __s_j_align="${1}"
  __s_j_count=$(toInt "${2}")
  __s_j_return="${3}"
  __s_j_char="${4}"

  if [[ 0 -eq ${__s_j_count} ]]; then
    echo ${__s_j_return}
    return 1;
  fi
  if [[ ${__s_j_char} == "" ]]; then 
    __s_j_char=" ";
  fi
  if [[ ${__s_j_return} == "" ]]; then
    __s_j_return=${__s_j_char};
  fi

  __s_j_left=1
  for i in $(seq 1 ${__s_j_count});
  do
    __s_j_len=$(expr length "${__s_j_return}")
    if [[ ${__s_j_len} -ge ${__s_j_count} ]]; then
      break
    fi

    if [[ ${__s_j_align} == "left" ]]; then
      __s_j_return="${__s_j_return}${__s_j_char}"
    elif [[ ${__s_j_align} == "right" ]]; then
      __s_j_return="${__s_j_char}${__s_j_return}"
    elif [[ ${__s_j_align} == "center" ]]; then
      if [[ ${__s_j_left} == 0 ]]; then
        __s_j_return="${__s_j_return}${__s_j_char}"
        __s_j_left=1
      else
        __s_j_return="${__s_j_char}${__s_j_return}"
        __s_j_left=0
      fi
    else
      __s_j_align=
      __s_j_count=
      __s_j_char=
      return 0
    fi
  done
  __s_j_align=
  __s_j_count=
  __s_j_char=
  echo "${__s_j_return}"
  return 1
}

function strLeftJustified()
{
  strAlign "left" "${1}" "${2}" "${3}" " "
}

function strRightJustified()
{
  strAlign "right" "${1}" "${2}" "${3}" " "
}

function strCenterJustified()
{
  strAlign "center" "${1}" "${2}" "${3}" " "
}

function replaceString()
{
  SOURCE="${1}"
  TARGET="${2}"
  REPLAC="${3}"

  if [[ "${SOURCE}" == "" ]]; then
    return 0;
  fi

  if [[ "${TARGET}" == "${REPLAC}" ]]; then
    echo ${SOURCE} 
    return 0;
  fi

  OUTPUT=${SOURCE}
  while :
  do
    LAST_OUTPUT=${OUTPUT}
    OUTPUT=$(echo ${LAST_OUTPUT} | sed "s/${TARGET}/${REPLAC}/g")
    if [[ "${OUTPUT}" == "${LAST_OUTPUT}" ]]; then
      break
    fi
    break;
  done
  echo ${OUTPUT}
  return 1
}

function echoColor()
{
  echo -e "${1}${2}\e[0m"
}

function echR()
{
  echoColor ${COLOR_RED} "$@"
}

function echG()
{
  echoColor ${COLOR_GREEN} "$@"
}

function echY()
{
  echoColor ${COLOR_YELLOW} "$@"
}

function echB()
{
  echoColor ${COLOR_BLUE} "$@"
}

function echM()
{
  echoColor ${COLOR_MAGENTA} "$@"
}

function echC()
{
  echoColor ${COLOR_CIANO} "$@"
}

function echIdent()
{
  __e_i_level=$(toInt ${1})
  __e_i_step=$(toInt "${2}")
  let "__e_i_step=${__e_i_step}"

  #echo "    __e_i_level=${__e_i_level}, __e_i_step==${__e_i_step}"

  __e_i_out=
  __e_i_spacer="  "
  for i in $(seq 1 ${__e_i_step});
  do
    __e_i_out="${__e_i_out}${__e_i_spacer}"
  done

  for __e_i_level_i in $(seq 1 ${__e_i_level});
  do
    if [[ ${__e_i_level_i} == 5 ]]; then
      __e_i_spacer=" ."
    else
      __e_i_spacer="  "
    fi
    __e_i_out="${__e_i_out}${__e_i_spacer}"
  done

  echo "${__e_i_out}"

  #__e_i_out=$(strAlign right "${__e_i_step}" " " " ")
  #echo "${__e_i_out}"
}

function echText()
{
  __e_s_lev=${1}
  __e_s_inc=${2}
  __e_s_spa="$(echIdent "${__e_s_lev}" "${__e_s_inc}")"
  __e_s_txt="${3}"
  __e_s_log="${4}"

  if [[ ${PUBLIC_LOG_LEVEL} == true && ${__e_s_log} != "" ]]; then
    echo "${__e_s_spa} ${__e_s_txt} - [ ${__e_s_log} ]"
  else
    echo "${__e_s_spa} ${__e_s_txt}"
  fi
}

function __private_echStart()
{
  echo "$(echText 1 "${1}" "${2}" "${3}")"
}

function __private_echFinished()
{
  __e_a_f_identity="${1}"
  __e_a_f_return="${2}"
  __e_a_f_message="${3}"
  __e_a_f_output="${4}"

  if [[ ${__e_a_f_return} != "" && ${__e_a_f_return} != 1 ]]; then
    if [[ ${__e_a_f_return} == 2 ]]; then
      echWarning "${__e_a_f_identity}" "${__e_a_f_message}" "${__e_a_f_output}"
    else
      echFail "${__e_a_f_identity}" "${__e_a_f_message}" "${__e_a_f_output}"
    fi
  fi
  echG "$(echText 1 "${__e_a_f_identity}" "Finished" "${3}")"
  export __e_a_f_output=
}

function __private_echAttibute()
{
  __e_p_identity="${1}" 
  __e_p_key="${2}"
  __e_p_value="${3}"
  if [[ ${__e_p_key} != "" && ${__e_p_value} != "" ]]; then
    __e_p_value="- ${__e_p_key}: ${__e_p_value}"
  else
    __e_p_value="- ${__e_p_key}${__e_p_value}"
  fi

  echo "$(echText 2 "${__e_p_identity}" "${__e_p_value}")"
}

function echStart()
{
  echM "$(__private_echStart "${1}" "${2}" "${3}")"
}

function echContinue()
{
  echG
  echG "$(echText "${1}" "${1}" "[ENTER] to continue")"
  echG
  read
}

function echTitle()
{
  echB "$(__private_echStart "${1}" "${2}" "${3}")"
}

function echTopic()
{
  echM "$(__private_echStart "${1}" "${2}" "${3}")"
}

function echProperty()
{
  echC "$(__private_echAttibute "${1}" "${2}" "${3}")"
}

function echAction()
{
  echY "$(__private_echStart "${1}" "${2}" "${3}")"
}

function echFinished()
{
  __private_echFinished "${1}" "${2}" "${3}"
}

function echCommand()
{
  __e_c_env_i=1
  __e_c_command=
  export __echCommand=
  for __e_c_env in "$@"
  do
    if [[ ${__e_c_env_i} == "" ]]; then
      __e_c_command="${__e_c_command} ${__e_c_env}"
    fi
    __e_c_env_i=
  done

  __e_c_out=$(echText 2 "${1}" "-${__e_c_command}")

  echY "${__e_c_out}"
  if [[ ${__e_c_command} != "" ]]; then
    if [[ -f ${__e_c_command} ]]; then
      export __echCommand=$(source ${__e_c_command})
    else
      export __echCommand=$(exec ${__e_c_command})
    fi
    return "$?"
  fi
  return 0
}

function echStep()
{
  echC "$(__private_echStart "${1}" "${2}" "${3}")"
}

function echInfo()
{
  echo "$(__private_echAttibute "${1}" "${2}" "${3}")"
}

function echWarning()
{
  __e_f_txt=" ${2} "
  __e_f_out=" ${3} "
  if [[ ${__e_f_out} == "" ]]; then
    __e_f_out=${__echCommand}
  fi
  export __echCommand=
  __e_f_len=$(expr length "${__e_f_txt}")
  let "__e_f_len_inc=${__e_f_len} + 4"

  lnContinuoEQU=$(strCenterJustified ${__e_f_len_inc} "=" "=")
  lnContinuoMSG=$(strCenterJustified ${__e_f_len_inc} "${__e_f_txt}" "*")
  lnContinuoSPC=$(strCenterJustified ${__e_f_len} "" "*")
  lnContinuoSPC=$(strCenterJustified ${__e_f_len_inc} "${lnContinuoSPC}" " ")  

  
  lnContinuoEQU="+${lnContinuoEQU}+"
  lnContinuoSPC="+${lnContinuoSPC}+"
  lnContinuoMSG="+${lnContinuoMSG}+"

 
  echY "$(echText 2 "${1}" "")"
  echY "$(echText 2 "${1}" "${lnContinuoEQU}")"
  echY "$(echText 2 "${1}" "${lnContinuoSPC}")"
  echY "$(echText 2 "${1}" "${lnContinuoMSG}")"
  echY "$(echText 2 "${1}" "${lnContinuoSPC}")"
  echY "$(echText 2 "${1}" "${lnContinuoEQU}")"

  if [[ ${__e_f_out} != "" ]]; then
    echY "$(echText 2 "${1}" "")"
    printf "${__e_f_out}"
  fi
  echY "$(echText 2 "${1}" "")"
  export __e_f_out=
  return 1
}

function echFail()
{
  __e_f_txt=" ${2} "
  __e_f_out=" ${3} "
  if [[ ${__e_f_out} == "" ]]; then
    __e_f_out=${__echCommand}
  fi
  export __echCommand=

  __e_f_len=$(expr length "${__e_f_txt}")
  let "__e_f_len_inc=${__e_f_len} + 8"

  lnContinuoEQU=$(strCenterJustified ${__e_f_len_inc} "=" "=")
  lnContinuoMSG=$(strCenterJustified ${__e_f_len_inc} "${__e_f_txt}" "*")
  lnContinuoSPC=$(strCenterJustified ${__e_f_len} "" "*")
  lnContinuoSPC=$(strCenterJustified ${__e_f_len_inc} "${lnContinuoSPC}" " ")  
  
  lnContinuoEQU="+${lnContinuoEQU}+"
  lnContinuoSPC="+${lnContinuoSPC}+"
  lnContinuoMSG="+${lnContinuoMSG}+"

 
  echR "$(echText 2 "${1}" "")"
  echR "$(echText 2 "${1}" "${lnContinuoEQU}")"
  echR "$(echText 2 "${1}" "${lnContinuoSPC}")"
  echR "$(echText 2 "${1}" "${lnContinuoMSG}")"
  echR "$(echText 2 "${1}" "${lnContinuoSPC}")"
  echR "$(echText 2 "${1}" "${lnContinuoEQU}")"

  if [[ ${__e_f_out} != "" ]]; then
    echR "$(echText 2 "${1}" "")"
    echo "${__e_f_out}"
  fi
  export __e_f_out=  
  return 1
}



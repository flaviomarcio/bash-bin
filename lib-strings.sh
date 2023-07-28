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


# function makeDir()
# {
#   idt="$(toInt ${1})"
#   logStart ${idt} "makeDir"
#   MAKE_DIR="${2}"
#   MAKE_PERMISSION="${3}"

#   logTarget ${idt} ${MAKE_DIR}
#   logInfo ${idt} "permission" ${MAKE_PERMISSION}

#   if [[ ${MAKE_DIR} == "" || ${MAKE_PERMISSION} == "" ]]; then
#     logError ${idt} "Invalid-parameters:MAKE_DIR==${MAKE_DIR},MAKE_PERMISSION==${MAKE_PERMISSION}"
#     return 0;
#   fi

#   if [[ ${MAKE_DIR} == "" ]]; then
#     MSG="dir-is-empty"
#     logError ${idt} "${MSG}"
#     return 0;
#   fi

#   if ! [[ -d ${MAKE_DIR}  ]]; then
#     mkdir -p ${MAKE_DIR}
#     if ! [[ -d ${MAKE_DIR}  ]]; then
#       logError ${idt} "no-create-dir:${MSG}"
#       return 0
#     fi
#   fi  

#   if [[ ${MAKE_PERMISSION} != "" ]]; then
#     #echo "chmod ${MAKE_PERMISSION} ${MAKE_DIR})>/dev/null 2>&1"
#     __makeDirUser=$(echo $(ls -l ${MAKE_DIR}) | awk '{print $5}')
#     if [[ ${__makeDirUser} == ${USER} ]]; then
#       echo $(chmod ${MAKE_PERMISSION} ${MAKE_DIR})>/dev/null 2>&1
#     fi
#   fi

#   logSuccess ${idt}
#   logFinished ${idt} "makeDir"
#   return 1;
# }

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
  if [[ ${1} == "" ]]; then
    return 0
  fi
  
  __file_deduplice_lines_files=(${1})
  for __file_deduplice_lines_file in "${__file_deduplice_lines_files[@]}"
  do
    if [[ -f ${__file_deduplice_lines_file} ]]; then
      #sort lines
      sort -u ${__file_deduplice_lines_file} -o ${__file_deduplice_lines_file}
      #remove duplicate lines
      sed -i '$!N; /^\(.*\)\n\1$/!P; D' ${__file_deduplice_lines_file}
    fi
  done  

  return 1;
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
  fi

}

function envsOS()
{
  export __func_return=
  __envsOS_destine=${1}
  __envsOS="/tmp/env_file_envsOS_${RANDOM}.env"
  printenv | sort > ${__envsOS}
  __envsOS_Remove=(_ __ CLUTTER_IM_MODULE KUBE LOGNAME KONSOLE GPG SHELL SHLVL GTK HIST S_COLORS XDG printenv shell XCURSOR XCURSOR WINDOWID PWD PATH OLDPWD KDE LD_ LANG COLOR DESKTOP DISPLAY DBUS HOME TERM XAUTHORITY XMODIFIERS USER DOCKER_ARGS_DEFAULT)
  for __envsOS_env in "${__envsOS_Remove[@]}"
  do
    sed -i "/^${__envsOS_env}/d" ${__envsOS}
  done
  if [[ ${__envsOS_destine} != "" ]]; then
    cat ${__envsOS}>${__envsOS_destine}
  else
    export __func_return=$(cat ${__envsOS})
    echo ${__func_return}
  fi
  rm -rf ${__envsOS}
  return 1
}

function envsExtractStatic()
{
  export __func_return=
  __runSourceOnlyStatic_file=${1}
  __runSourceOnlyStatic_file_out=${2}
  if [[ ${__runSourceOnlyStatic_file} == "" ]]; then
    return 0
  fi
  if ! [[ -f ${__runSourceOnlyStatic_file} ]]; then
    return 0
  fi
  if [[ ${__runSourceOnlyStatic_file_out} == "" ]]; then
    __runSourceOnlyStatic_file_out=${__runSourceOnlyStatic_file}
  fi
  __runSourceOnlyStatic_tmp_env="/tmp/env_file_envsExtractStatic_${RANDOM}.env"
  cat ${__runSourceOnlyStatic_file}>>${__runSourceOnlyStatic_tmp_env}
  #replace " ${"
  sed -i 's/ \${/\${/g' ${__runSourceOnlyStatic_tmp_env}
  #remove "=${"
  sed -i '/=\${/d' ${__runSourceOnlyStatic_tmp_env}
  envsFileConvertToExport ${__runSourceOnlyStatic_tmp_env}
  cat ${__runSourceOnlyStatic_tmp_env}>${__runSourceOnlyStatic_file_out}
  rm -rf ${__runSourceOnlyStatic_tmp_env}
  export __func_return=${__runSourceOnlyStatic_file_out}
  return 1
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

function envsPrepareFile()
{
  __envsPrepareFile_target=${1}  
  if ! [[ -f ${__envsPrepareFile_target} ]]; then
    return 0
  fi

  __envsPrepareFile_target_tmp="/tmp/env__envsPrepareFile_target_${RANDOM}.env"
  cat ${__envsPrepareFile_target}>${__envsPrepareFile_target_tmp}
  #trim lines
  sed -i 's/^[[:space:]]*//; s/[[:space:]]*$//' ${__envsPrepareFile_target_tmp}
  #remove empty lines
  sed -i '/^$/d' ${__envsPrepareFile_target_tmp}  
  #remove startWith #
  sed -i '/^#/d' ${__envsPrepareFile_target_tmp}
  #sort lines
  sort -u ${__envsPrepareFile_target_tmp} -o ${__envsPrepareFile_target}
  #remove duplicate lines
  sed -i '$!N; /^\(.*\)\n\1$/!P; D' ${__envsPrepareFile_target}
  rm -rf ${__envsPrepareFile_target_tmp}
  return 1
}

function envsFileConvertToExport()
{
  export __func_return=
  __envsFileConvertToExport_file=${1}
  if [[ ${__envsFileConvertToExport_file} == "" ]]; then
    return 0
  fi

  if ! [[ -f ${__envsFileConvertToExport_file} ]]; then
    return 0
  fi

  __envsFileConvertToExport_file_tmp="/tmp/env_file_envsFileConvertToExport_${RANDOM}.env"
  cat ${__envsFileConvertToExport_file}>${__envsFileConvertToExport_file_tmp}
  echo "">${__envsFileConvertToExport_file}
  envsPrepareFile ${__envsFileConvertToExport_file_tmp}
  sed -i 's/export;//g' ${__envsFileConvertToExport_file_tmp}
  sed -i 's/export //g' ${__envsFileConvertToExport_file_tmp}
  while IFS= read -r line
  do
    line=$(echo ${line} | grep =)
    if [[ ${line} != "" ]]; then
      __args=($(strSplit "${line}" "="))
      __args_key=${__args[0]}
      __args_value=${__args[1]}
      echo "export ${__args_key}=${__args_value}">>${__envsFileConvertToExport_file}
    fi
  done < "${__envsFileConvertToExport_file_tmp}"
  rm -rf ${__envsFileConvertToExport_file_tmp}
  export __func_return=${__envsFileConvertToExport_file} 
  return 1
}

function envsFileConvertToSimpleFile()
{
  export __func_return=
  __envsFileConvertToSimpleFile_file=${1}
  __envsFileConvertToSimpleFile_file_out=${2}
  if [[ ${__envsFileConvertToSimpleFile_file} == "" ]]; then
    return 0
  fi
  if ! [[ -f ${__envsFileConvertToSimpleFile_file} ]]; then
    return 0
  fi
  if [[ ${__envsFileConvertToSimpleFile_file_out} == "" ]]; then
    __envsFileConvertToSimpleFile_file_out=${__envsFileConvertToSimpleFile_file}
  fi

  __envsFileConvertToSimpleFile_file_tmp="/tmp/env_file_envsFileConvertToSimpleFile_${RANDOM}.env"
  cat ${__envsFileConvertToExport_file}>${__envsFileConvertToSimpleFile_file_tmp}
  sed -i '/export ;/d' ${__envsFileConvertToSimpleFile_file}
  sed -i '/export;/d' ${__envsFileConvertToSimpleFile_file}
  sed -i 's/export//g' ${__envsFileConvertToSimpleFile_file}
  envsPrepareFile ${__envsFileConvertToSimpleFile_file}
  cat ${__envsFileConvertToSimpleFile_file_tmp}>${__envsFileConvertToSimpleFile_file_out}
  export __func_return=${__envsFileConvertToSimpleFile_file_out}
  return 1
}

function envsReplaceFile()
{
  __envsReplaceFile_file=${1}  
  if ! [[ -f ${__envsReplaceFile_file} ]]; then
    return 0
  fi

  REPLACE_SEPARADOR_250="%REPLACE-250"
  __envsReplaceFile_envs="/tmp/env_file_envsReplaceFile_${RANDOM}.env"

  __envsReplaceFile_envs=($(envsOS))
  sed -i 's/\${/\[\#\#\]{/g' ${__envsReplaceFile_file}  
  for __envsReplaceFile_env in "${__envsReplaceFile_envs[@]}"
  do
    __envsReplaceFile_env=(${__envsReplaceFile_env//=/ })
    replace="\[\#\#\]{${__envsReplaceFile_env[0]}}"
    replacewith=$(sed "s/\//$REPLACE_SEPARADOR_250/g" <<< "${__envsReplaceFile_env[1]}")

    if [[ ${replace} == "_" ]]; then
      continue;
    fi
    if [[ "$replacewith" == *"/"* ]]; then
      continue;
    fi
    sed -i "s/${replace}/${replacewith}/g" ${__envsReplaceFile_file}
  done
  sed -i 's/\[\#\#\]{/\${/g' ${__envsReplaceFile_file}
  echo $(sed -i "s/$REPLACE_SEPARADOR_250/\//g" ${__envsReplaceFile_file})&>/dev/null
  return 1;
}

function envsParserFile()
{
  __envsParserFile_file=${1}  
  if ! [[ -f ${__envsParserFile_file} ]]; then
    return 0
  fi

  __envsParserFile_file_tmp="/tmp/env_file___envsParserFile_file_tmp_${RANDOM}.env"

  cat ${__envsParserFile_file}>${__envsParserFile_file_tmp}

  envsPrepareFile ${__envsParserFile_file_tmp}
  envsReplaceFile ${__envsParserFile_file_tmp}
  #sort lines
  sort -u ${__envsParserFile_file_tmp} -o ${__envsParserFile_file}
  sed -i '$!N; /^\(.*\)\n\1$/!P; D' ${__envsParserFile_file}
  rm -rf ${__envsParserFile_file_tmp}
  return 1;
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

function strArg()
{
  export __func_return=
  __strArg_index="${1}"
  __strArg_args="${2}"
  __strArg_ifs="${3}"
  if [[ ${__strArg_index} == "" ]]; then
    export __func_return="$@"
    echo "$@"
    return 0
  fi
  if [[ ${__strArg_args} == "" ]]; then
    return 0
  fi
  __strArg_ifs_old=${IFS}
  if [[ ${__strArg_ifs} == "" ]]; then
    __strArg_ifs=' '
  fi
  IFS=${__strArg_ifs}
  __strArg_args=(${__strArg_args})
  export __func_return=${__strArg_args[${__strArg_index}]}
  echo "${__func_return}"
  IFS=${__strArg_ifs_old}
  return 1
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
  for env in "${__strSplitArray[@]}";
  do
    __func_return="${__func_return} ${env}"
  done
  echo ${__func_return}
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


function jsonGet()
{
  export __func_return=
  __json_get_body=${1}
  __json_get_tags=${2}

  if [[ ${__json_get_body} == "" ]]; then
    return 0
  fi
  if [[ -f ${__json_get_body} ]]; then
    __json_get_body=$(cat ${__json_get_body})
  fi

  __json_get_tag_names=$(strSplit "${__json_get_tags}" ".")
  if [[ ${__json_get_tag_names} == "" ]]; then
    return 0
  fi

  __json_get_tag_names=(${__json_get_tag_names})
  __json_get_tag_name=
  for __json_get_tag in "${__json_get_tag_names[@]}"
  do
    __json_get_tag_name="${__json_get_tag_name}.${__json_get_tag}"
    __json_get_check=$(echo ${__json_get_body} | jq "${__json_get_tag_name}")
    if [[ ${__json_get_check} == "" || ${__json_get_check} == "null" ]]; then
      return 0
    fi
  done
  __func_return=$(echo ${__json_get_body} | jq "${__json_get_tag_name}" | jq '.[]')
  echo ${__func_return}
  return 1
}


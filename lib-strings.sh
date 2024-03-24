#!/bin/bash

    # coff='\e[0m'
    # black='\e[0;30m'
    # red='\e[0;31m'
    # green='\e[0;32m'
    # yellow='\e[0;33m'
    # blue='\e[0;34m'
    # purple='\e[0;35m'
    # cyan='\e[0;36m'
    # white='\e[0;37m'
    # bblack='\e[1;30m'
    # bred='\e[1;31m'
    # bgreen='\e[1;32m'
    # byellow='\e[1;33m'
    # bblue='\e[1;34m'
    # bpurple='\e[1;35m'
    # bcyan='\e[1;36m'
    # bwhite='\e[1;37m'

export COLOR_OFF='\e[0m'
export COLOR_BACK='\e[0;30m'
export COLOR_BACK_B='\e[1;30m'
export COLOR_RED='\e[0;31m'
export COLOR_RED_B='\e[0;31m'
export COLOR_GREEN='\e[0;32m'
export COLOR_GREEN_B='\e[1;32m'
export COLOR_YELLOW='\e[0;33m'
export COLOR_YELLOW_B='\e[2;33m'
export COLOR_BLUE='\e[0;34m'
export COLOR_BLUE_B='\e[1;34m'
export COLOR_MAGENTA='\e[0;35m'
export COLOR_MAGENTA_B='\e[1;35m'
export COLOR_CIANO='\e[0;36m'
export COLOR_CIANO_B='\e[1;36m'
export COLOR_WHITE='\e[0;37m'
export COLOR_WHITE_B='\e[1;37m'

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
  local v="${1}"
  if [[ ${v} == "" ]]; then
    v=0
  fi
  [ ! -z "${v##*[!0-9]*}" ] && echo -n ${v} || echo 0;
}

function incInt()
{
  local v=$(toInt ${1})
  local i=$(toInt ${2})
  if [[ ${i} == 0 ]]; then
    i=1
  fi
  let "v=${v} + ${i}"
  echo ${v}
}

function logIdent()
{
  local __identity=$(toInt ${1})
  local __char="${2}"

  if [[ ${__char} == "" ]]; then
    local __char="."
  fi

  if [[ ${__identity} == "" ]]; then
    echo -n ${__char}
    return 0;
  fi

  echo $(strRightJustified 4 ${__identity} ${__char} )
  return 1
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
      local __log="${2}: ${3}"
    else
      local __log="${2}"
    fi
    if [[ ${__log} != "" ]]; then
      logMethod "${1}" "-${__log}"
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
  local __NEW_DIR="${1}"
  if ! [[ -d ${__NEW_DIR} ]]; then
    return 0;
  fi
  cd ${__NEW_DIR}
  if [[ ${PWD} != ${__NEW_DIR} ]]; then
    return 0;
  fi
  return 1;
}

function copyFile()
{
  local __SRC="${1}"
  local __DST="${2}"

  if [[ -f ${__SRC} ]]; then
    return 0;
  fi
  if [[ -f ${__DST} ]]; then
    return 0
  fi
  cp -rf ${__SRC} ${__DST}
  if [[ -f ${__DST} ]]; then
    return 1
  fi
  return 0
}

function fileDedupliceLines()
{
  if [[ ${1} == "" ]]; then
    return 0
  fi
  
  local __files=(${1})
  local __file=
  for __file in "${__files[@]}"
  do
    if [[ -f ${__file} ]]; then
      #sort lines
      sort -u ${__file} -o ${__file}
      #remove duplicate lines
      sed -i '$!N; /^\(.*\)\n\1$/!P; D' ${__file}
    fi
  done  

  return 1;
}

function copyFileIfNotExists()
{
  local __file_src=${1}
  local __file_dst=${2}
  
  if ! [[ -f ${__file_src} ]]; then
    return 0
  fi

  if [[ -d ${__file_dst} ]]; then
    rm -rf ${__file_dst}
    logInfo ${idt} "remove" ${__file_dst}
  fi
  cp -rf ${__file_src} ${__file_dst}
  if [[ -d ${__file_dst} ]]; then
    return 1
  fi
  return 0
}

function utilInitialize()
{
  export STACK_LOG=0            
  export STACK_LOG_VERBOSE=0            
  export STACK_LOG_VERBOSE_SUPER=0

  export PUBLIC_LOG_LEVEL=false
  export PUBLIC_RUNNER_MODE=runner
  export PUBLIC_RUNNER_TEST=false
  local PARAM=
  for PARAM in "$@"
  do
    if [[ ${PARAM} == "-d" || ${PARAM} == "--debug" ]]; then
      export PUBLIC_RUNNER_MODE=debug
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

  # local __utilInitialize_envs=()
  # local __utilInitialize_envs+=("..information")
  # if [[ ${PUBLIC_LOG_LEVEL} == true ]]; then
  #   local __utilInitialize_envs+=("....Debug mode is enabled")
  # fi
  # if [[ ${STACK_LOG_VERBOSE} == 1 ]]; then
  #   local __utilInitialize_envs+=("....Log verbose is enabled")
  # fi
  # if [[ ${STACK_LOG} == 1 ]]; then
  #   local __utilInitialize_envs+=("....Log is enabled")
  # fi
  # if [[ ${PUBLIC_RUNNER_TEST} == true ]]; then
  #   local __utilInitialize_envs+=("....-Runner mode: ${PUBLIC_RUNNER_MODE}")
  # fi
  # local __utilInitialize_envs+=("..args:")
  # export DOCKER_ARGS_DEFAULT="--quiet --log-level ERROR"
  # local __utilInitialize_envs+=("....-docker: ${DOCKER_ARGS_DEFAULT}")
  # export MAVEN_ARGS_DEFAULT="--quiet"
  # local __utilInitialize_envs+=("....-maven: ${MAVEN_ARGS_DEFAULT}")
  # if [[ ${STACK_LOG} == 0 ]]; then    
  #   export GIT_ARGS_DEFAULT="--quiet"
  #   local __utilInitialize_envs+=("....-git: ${GIT_ARGS_DEFAULT}")
  # fi

  # if [[ ${__utilInitialize_envs} != "" ]]; then
  #   echG "Initialization"
  #   for __utilInitialize_env in "${__utilInitialize_envs[@]}"
  #   do
  #     local __utilInitialize_msg=$(echo ${__utilInitialize_env} | sed 's/\./ /g')
  #     if [[ ${__utilInitialize_env} == "......"*  ]]; then
  #       echY "${__utilInitialize_msg}"
  #     elif [[ ${__utilInitialize_env} == "...."*  ]]; then
  #       echC "${__utilInitialize_msg}"
  #     elif [[ ${__utilInitialize_env} == ".."*  ]]; then
  #       echM "${__utilInitialize_msg}"
  #     else
  #       echR "${__utilInitialize_msg}"
  #     fi
  #   done
  # fi

}

function envsOS()
{
  unset __func_return
  local __destine=${1}
  local __envsOS="/tmp/env_file_envsOS_${RANDOM}.env"
  printenv | sort > ${__envsOS}
  local __Remove=(_ __ CLUTTER_IM_MODULE KUBE LOGNAME KONSOLE GPG SHELL SHLVL GTK HIST S_COLORS XDG printenv shell XCURSOR XCURSOR WINDOWID PWD PATH OLDPWD KDE LD_ LANG COLOR DESKTOP DISPLAY DBUS HOME TERM XAUTHORITY XMODIFIERS USER DOCKER_ARGS_DEFAULT)
  local __env=
  for __env in "${__Remove[@]}"
  do
    sed -i "/^${__env}/d" ${__envsOS}
  done
  if [[ ${__destine} != "" ]]; then
    cat ${__envsOS}>${__destine}
  else
    export __func_return=$(cat ${__envsOS})
    echo ${__func_return}
  fi
  rm -rf ${__envsOS}
  return 1
}

function envsSetIfIsEmpty()
{
  local __env_name=${1}
  local __env_value=${2}
  local __check=${!__env_name}
  if [[ ${__check} == "" ]]; then
    __check=$(echo ${__env_value} | grep ' ')
    if [[ ${__check} != "" ]]; then
      __env_value=$(echo "${__env_value}" | sed 's/"//g' )
      export ${__env_name}="\"${__env_value}\""
    else
      export ${__env_name}=${__env_value}
    fi    
  fi
  return 1;  
}

function envsFileAddIfNotExists()
{
  unset __env_file
  local __env_file_names=

  local __i=0
  local __arg=
  for __arg in "$@"
  do
    if [[ ${__i} == 0 ]]; then
      local __env_file=${__arg}
    else
      __env_file_names="${__env_file_names} ${__arg}"
    fi
    local __i=1
  done
  local __env_file_names=(${__env_file_names})

  if [[ ${__env_file} == "" ]]; then
    return 0
  fi

  if ! [[ -f ${__env_file} ]]; then
    local __env_file_dir=$(dirname ${__env_file})
    mkdir -p ${__env_file_dir}
    if ! [[ -d ${__env_file_dir} ]];then
      echR "No create env dir: ${__env_file_dir}"
      echR "No create env file: ${__env_file}"
      return 0
    fi
    echo "#!/bin/bash">${__env_file}
  fi


  local __env_file_temp="/tmp/envsFileAddIfNotExists_${RANDOM}.env"
  cat ${__env_file}>${__env_file_temp}
  sed -i "/${__env_file_name}=/d" ${__env_file_temp}
  #remover apenas linhas com apenas "export"
  sed -i '/^\s*export\s*$/d' ${__env_file_temp}

  local __env_file_name=
  for __env_file_name in "${__env_file_names[@]}"
  do
    if [[ ${__env_file_name} == "" ]]; then
      continue
    fi
    local __env_file_value=$(echo ${!__env_file_name} | sed 's/\\$/\\$/g')

    local __check=$(echo ${__env_file_value} | grep ' ')
    if [[ ${__check} == "" ]]; then
      local __env_final="${__env_file_name}=${__env_file_value}"
    else
      local __env_file_value=$(echo "${__env_file_value}" | sed 's/"//g' )
      local __env_final="${__env_file_name}=\"${__env_file_value}\""
    fi

    local __check_value=$(echo ${__env_final} | sed 's/\*/\\\*/g')
    local __check=$(cat ${__env_file} | grep "${__check_value}")
    if [[ ${__check} != "" ]]; then
      return 1;
    fi

    echo "export ${__env_final}">>${__env_file_temp}
  done

  sort -u ${__env_file_temp} -o ${__env_file}
  rm -rf ${__env_file_temp}
  return 1;

}

function envsExtractStatic()
{
  unset __func_return
  local __file=${1}
  local __file_out=${2}
  if [[ ${__file} == "" ]]; then
    return 0
  fi
  if ! [[ -f ${__file} ]]; then
    return 0
  fi
  if [[ ${__file_out} == "" ]]; then
    local __file_out=${__file}
  fi
  local __file_temp="/tmp/env_file_envsExtractStatic_${RANDOM}.env"
  cat ${__file}>>${__file_temp}
  #replace " ${"
  sed -i 's/ \${/\${/g' ${__file_temp}
  #remove "=${"
  sed -i '/=\${/d' ${__file_temp}
  envsFileConvertToExport ${__file_temp}
  cat ${__file_temp}>${__file_out}
  rm -rf ${__file_temp}
  export __func_return=${__file_out}
  return 1
}

function runSource()
{
  unset __func_return
  local __file_name="${1}"
  local __file_params="${2}"
  if [[ ${__file_name} == "" ]]; then
    return 0
  fi

  if ! [[ -f ${__file_name} ]]; then
    return 0
  fi

  echo $(chmod +x ${__file_name})&>/dev/null
  source ${__file_name} ${__file_params}
  return 0
}

function envsPrepareFile()
{
  unset __func_return
  local __target=${1}
  local __target_output=${2}
  if ! [[ -f ${__target} ]]; then
    return 0
  fi

  local __target_tmp_1="/tmp/env__target_1_${RANDOM}.env"
  local __target_tmp_2="/tmp/env__target_2_${RANDOM}.env"
  cat ${__target}>${__target_tmp_1}
  #trim lines
  sed -i 's/^[[:space:]]*//; s/[[:space:]]*$//' ${__target_tmp_1}
  #remove empty lines
  sed -i '/^$/d' ${__target_tmp_1}  
  #remove startWith #
  sed -i '/^#/d' ${__target_tmp_1}
  #remove exports
  sed -i 's/export;//g' ${__target_tmp_1}
  sed -i 's/export //g' ${__target_tmp_1}
  #sort lines
  sort -u ${__target_tmp_1} -o ${__target_tmp_2}
  #after sort remove duplicate lines
  sed -i '$!N; /^\(.*\)\n\1$/!P; D' ${__target_tmp_2}


  rm -rf ${__target_tmp_1}

  #tratando nomes das variaveis
  while IFS= read -r line
  do
    local line=$(echo ${line} | grep =)
    if [[ ${line} != "" ]]; then
      line=$(echo ${line} | sed 's/ /__xSPC__/g')
      #separando nome da env e dos valores
      __args=($(strSplit "${line}" "="))
      #nome da env
      __args_key="${__args[0]}"
      #extracao do nome da env
      __args_value=$(echo ${line} | sed "s/${__args_key}=//")
      #trocar caractores que não sejam numeros letras e o [_] por _
      __args_key=$(echo ${__args_key} | sed 's/[^[:alnum:]_]/_/g' | sed 's/__xSPC__/_/g')
      line="${__args_key}=${__args_value}"
      line=$(echo ${line} | sed 's/__xSPC__/ /g')
      
      #exportando para arquivo final
      if [[ -f ${__target_tmp_1} ]]; then
        echo "${line}">>${__target_tmp_1}
      else
        echo "${line}">${__target_tmp_1}
      fi
    fi
  done < "${__target_tmp_2}"

  if ! [[ -f ${__target_tmp_1} ]]; then
    return 0
  fi

  if [[ ${__target_output} == "" ]]; then
    local __target_output=${__target}
  fi
  cat ${__target_tmp_1}>${__target_output}
  rm -rf ${__target_tmp_1}
  rm -rf ${__target_tmp_2}
  export __func_return=${__target_output}
  return 1
}

function envsFileConvertToExport()
{
  unset __func_return
  local __file="${1}"
  local __file_out="${2}"

  if [[ ${__file} == "" ]]; then
    return 0
  fi

  if ! [[ -f ${__file} ]]; then
    return 0
  fi

  if [[ ${__file_out} == "" ]]; then
    local __file_out=${__file}
  else
    cat ${__file}>${__file_out}
  fi

  envsPrepareFile ${__file_out}

  unset __func_return
  #incluindo prefixo no artquivo
  sed -i 's/^/export /' ${__file_out}
  export __func_return=${__file_out} 
  return 1
}

function envsReplaceFile()
{
  local __file=${1}  
  if ! [[ -f ${__file} ]]; then
    return 0
  fi

  local __char_250="%REPLACE-250"
  local __file_envs="/tmp/env_file_envsReplaceFile_${RANDOM}.env"

  local __file_envs=($(envsOS))
  sed -i 's/\${/\[\#\#\]{/g' ${__file}  
  local __file_env=
  for __file_env in "${__file_envs[@]}"
  do
    local __file_env=(${__file_env//=/ })
    local replace="\[\#\#\]{${__file_env[0]}}"
    local replacewith=$(sed "s/\//$__char_250/g" <<< "${__file_env[1]}")

    if [[ ${replace} == "_" ]]; then
      continue;
    fi
    if [[ "$replacewith" == *"/"* ]]; then
      continue;
    fi
    sed -i "s/${replace}/${replacewith}/g" ${__file}
  done
  sed -i 's/\[\#\#\]{/\${/g' ${__file}
  echo $(sed -i "s/$__char_250/\//g" ${__file})&>/dev/null
  return 1;
}

function envsParserFile()
{
  local __file=${1}  
  if ! [[ -f ${__file} ]]; then
    return 0
  fi

  local __file_tmp="/tmp/env_file___file_tmp_${RANDOM}.env"

  cat ${__file}>${__file_tmp}

  envsPrepareFile ${__file_tmp}
  envsReplaceFile ${__file_tmp}
  #sort lines
  sort -u ${__file_tmp} -o ${__file}
  sed -i '$!N; /^\(.*\)\n\1$/!P; D' ${__file}
  rm -rf ${__file_tmp}
  return 1;
}

function envsParserDir()
{
  export __DIR="${2}"
  export __EXT="${3}"

  if [[ ${__DIR} == "" || ${__EXT} == "" ]]; then
    if [[ -d ${__DIR} ]]; then
      local __TARGETS=($(find ${__DIR} -name ${__EXT}))
      local __TARGET=
      for __TARGET in "${__TARGETS[@]}"
      do
        envsParserFile ${__TARGET}
      done
    fi
  fi
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
  unset __func_return
  local __str_file="${1}"
  if [[ ${__str_file} == "" ]]; then
    return 0
  fi
  export __func_return=$(dirname ${__str_file})
  echo ${__func_return}
  return 1;  
}

function strExtractFileName()
{
  local __str_file="${1}"
  local __func_return=
  if [[ ${__str_file} == "" ]]; then
    return 0
  fi
  local __func_return=$(basename ${__str_file})
  echo ${__func_return}
  return 1;
}

function strExtractFileExtension()
{
  local __str_file="${1}"
  local __func_return=
  if [[ ${__str_file} == "" ]]; then
    return 0
  fi
  local __str_file_splitted=$(strSplit ${__str_file} ".")
  if [[ ${__str_file_splitted} == "" ]]; then
    return 0
  fi
  local __str_file_splitted=(${__str_file_splitted})
  local __str_file_last_index=$((${#__str_file_splitted[@]} - 1))
  export __func_return=${__str_file_splitted[$__str_file_last_index]}
  echo ${__func_return}
  return 1;
}

function strArg()
{
  unset __func_return
  local __strArg_index="${1}"
  local __strArg_args="${2}"
  local __strArg_ifs="${3}"
  if [[ ${__strArg_index} == "" ]]; then
    export __func_return="$@"
    echo "$@"
    return 0
  fi
  if [[ ${__strArg_args} == "" ]]; then
    return 0
  fi
  local __strArg_ifs_old=${IFS}
  if [[ ${__strArg_ifs} == "" ]]; then
    local __strArg_ifs=' '
  fi
  IFS=${__strArg_ifs}
  local __strArg_args=(${__strArg_args})
  export __func_return=${__strArg_args[${__strArg_index}]}
  echo "${__func_return}"
  IFS=${__strArg_ifs_old}
  return 1
}

function strSplit()
{
  local __strSplitText="${1}"
  local __strSplitSepatator="${2}"
  unset __func_return

  if [[ ${__strSplitText} == ""  ]]; then
    return 0
  fi

  # Defina o IFS para o caractere de espaço em branco
  if [[ "${__strSplitSepatator}" == ""  ]]; then
    local __strSplitSepatator=' '
  fi

  #cache old IFS
  OLD_IFS=${IFS}
  #new char split
  IFS=${__strSplitSepatator}
  local __strSplitArray=($__strSplitText)

  # restore IFS
  IFS=${OLD_IFS}
  local __env=
  for __env in "${__strSplitArray[@]}";
  do
    export __func_return="${__func_return} ${__env}"
  done
  echo ${__func_return}
}

function strAlign()
{
  local __s_j_align="${1}"
  local __s_j_count=$(toInt "${2}")
  local __s_j_return="${3}"
  local __s_j_char="${4}"

  if [[ 0 -eq ${__s_j_count} ]]; then
    echo ${__s_j_return}
    return 1;
  fi
  if [[ ${__s_j_char} == "" ]]; then 
    local __s_j_char=" ";
  fi
  if [[ ${__s_j_return} == "" ]]; then
    local __s_j_return=${__s_j_char};
  fi

  local __s_j_left=1
  local i=
  for i in $(seq 1 ${__s_j_count});
  do
    local __s_j_len=$(expr length "${__s_j_return}")
    if [[ ${__s_j_len} -ge ${__s_j_count} ]]; then
      break
    fi

    if [[ ${__s_j_align} == "left" ]]; then
      local __s_j_return="${__s_j_return}${__s_j_char}"
    elif [[ ${__s_j_align} == "right" ]]; then
      local __s_j_return="${__s_j_char}${__s_j_return}"
    elif [[ ${__s_j_align} == "center" ]]; then
      if [[ ${__s_j_left} == 0 ]]; then
        local __s_j_return="${__s_j_return}${__s_j_char}"
        local __s_j_left=1
      else
        local __s_j_return="${__s_j_char}${__s_j_return}"
        local __s_j_left=0
      fi
    else
      local __s_j_align=
      local __s_j_count=
      local __s_j_char=
      return 0
    fi
  done
  local __s_j_align=
  local __s_j_count=
  local __s_j_char=
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
  local __replaceString_SOURCE="${1}"
  local __replaceString_TARGET="${2}"
  local __replaceString_REPLAC="${3}"

  if [[ "${__replaceString_SOURCE}" == "" ]]; then
    return 0;
  fi

  if [[ "${__replaceString_TARGET}" == "${__replaceString_REPLAC}" ]]; then
    echo ${__replaceString_SOURCE} 
    return 0;
  fi

  OUTPUT=${__replaceString_SOURCE}
  while :
  do
    local __replaceString_LAST_OUTPUT=${__replaceString_OUTPUT}
    local __replaceString_OUTPUT=$(echo ${LAST_OUTPUT} | sed "s/${__replaceString_TARGET}/${__replaceString_REPLAC}/g")
    if [[ "${__replaceString_OUTPUT}" == "${__replaceString_LAST_OUTPUT}" ]]; then
      break
    fi
    break;
  done
  echo ${__replaceString_OUTPUT}
  return 1
}

function echoColor()
{
  echo -e "${1}${2}${COLOR_OFF}"
}

function echR()
{
  echoColor ${COLOR_RED} "$@"
}


function echE()
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
  local __e_i_level=$(toInt ${1})
  local __e_i_step=$(toInt "${2}")
  let "__e_i_step=${__e_i_step}"

  #echo "    __e_i_level=${__e_i_level}, __e_i_step==${__e_i_step}"

  local __e_i_out=
  local __e_i_spacer="  "
  local i=
  for i in $(seq 1 ${__e_i_step});
  do
    local __e_i_out="${__e_i_out}${__e_i_spacer}"
  done

  local __e_i_level_i=
  for __e_i_level_i in $(seq 1 ${__e_i_level});
  do
    if [[ ${__e_i_level_i} == 5 ]]; then
      local __e_i_spacer=" ."
    else
      local __e_i_spacer="  "
    fi
    local __e_i_out="${__e_i_out}${__e_i_spacer}"
  done

  echo "${__e_i_out}"
}

function echText()
{
  local __e_s_lev=${1}
  local __e_s_inc=${2}
  local __e_s_spa="$(echIdent "${__e_s_lev}" "${__e_s_inc}")"
  local __e_s_txt="${3}"
  local __e_s_log="${4}"

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
  local __e_a_f_identity="${1}"
  local __e_a_f_return="${2}"
  local __e_a_f_message="${3}"
  local __e_a_f_output="${4}"

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
  local __e_p_identity="${1}" 
  local __e_p_key="${2}"
  local __e_p_value="${3}"
  if [[ ${__e_p_key} != "" && ${__e_p_value} != "" ]]; then
    local __e_p_value="- ${__e_p_key}: ${__e_p_value}"
  else
    local __e_p_value="- ${__e_p_key}${__e_p_value}"
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
  local __e_c_env_i=1
  local __e_c_command=
  local __e_c_command_ignore=
  export __echCommand=
  local __e_c_env=
  for __e_c_env in "$@"
  do
    if [[ ${__e_c_env} == "--ignore" ]]; then
      local __e_c_command_ignore=true
    else
      if [[ ${__e_c_env_i} == "" ]]; then
        local __e_c_command="${__e_c_command} ${__e_c_env}"
      fi
      local __e_c_env_i=
    fi
  done

  __e_c_out=$(echText 2 "${1}" "-${__e_c_command}")

  echY "${__e_c_out}"
  if [[ ${__e_c_command_ignore} != "" ]]; then
    return 1
  fi

  if [[ ${__e_c_command} == "" ]]; then
    return 0
  fi

  if [[ -f ${__e_c_command} ]]; then
    export __echCommand=$(source ${__e_c_command})
  else
    export __echCommand=$(exec ${__e_c_command})
  fi
  return "$?"
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
  local __e_f_txt=" ${2} "
  local __e_f_out=" ${3} "
  if [[ ${__e_f_out} == "" ]]; then
    __e_f_out=${__echCommand}
  fi
  export __echCommand=
  local __e_f_len=$(expr length "${__e_f_txt}")
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
  local __e_f_txt=" ${2} "
  local __e_f_out=" ${3} "
  if [[ ${__e_f_out} == "" ]]; then
    __e_f_out=${__echCommand}
  fi
  export __echCommand=

  __e_f_len=$(expr length "${__e_f_txt}")
  let "__e_f_len_inc=${__e_f_len} + 8"

  local lnContinuoEQU=$(strCenterJustified ${__e_f_len_inc} "=" "=")
  local lnContinuoMSG=$(strCenterJustified ${__e_f_len_inc} "${__e_f_txt}" "*")
  local lnContinuoSPC=$(strCenterJustified ${__e_f_len} "" "*")
  local lnContinuoSPC=$(strCenterJustified ${__e_f_len_inc} "${lnContinuoSPC}" " ")  
  
  local lnContinuoEQU="+${lnContinuoEQU}+"
  local lnContinuoSPC="+${lnContinuoSPC}+"
  local lnContinuoMSG="+${lnContinuoMSG}+"

 
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
  unset __func_return
  local __json_get_body=${1}
  local __json_get_tags=${2}

  if [[ ${__json_get_body} == "" ]]; then
    return 0
  fi
  if [[ -f ${__json_get_body} ]]; then
    local __json_get_body=$(cat ${__json_get_body})
  fi

  local __json_get_tag_names=$(strSplit "${__json_get_tags}" ".")
  if [[ ${__json_get_tag_names} == "" ]]; then
    return 0
  fi

  local __json_get_tag_names=(${__json_get_tag_names})
  local __json_get_tag_name=
  local __json_get_tag=
  for __json_get_tag in "${__json_get_tag_names[@]}"
  do
    local __json_get_tag_name="${__json_get_tag_name}.${__json_get_tag}"
    local __json_get_check=$(echo ${__json_get_body} | jq "${__json_get_tag_name}")
    if [[ ${__json_get_check} == "" || ${__json_get_check} == "null" ]]; then
      return 0
    fi
  done
  export __func_return=$(echo ${__json_get_body} | jq "${__json_get_tag_name}" | jq '.[]')
  echo ${__func_return}
  return 1
}

function arrayContains()
{
  local __inArray_array=(${1})
  local __inArray_arg=${2}
  local __inArray_item=
  for __inArray_item in "${__inArray_array[@]}"
  do
    if [[ ${__inArray_arg} == ${__inArray_item} ]]; then
      return 1
    fi
  done
  return 0
}

function toUpper()
{
  echo $(echo "$@" | tr '[:lower:]' '[:upper:]')  
  return 1;  
}

function toLower()
{
  echo $(echo "$@" | tr '[:upper:]' '[:lower:]')  
  return 1;
}

function nameFormat()
{
  local __nameFormat_args=($@)
  local __nameFormat_output=
  local __nameFormat_arg=
  for __nameFormat_arg in "${__nameFormat_args[@]}"
  do
    local __nameFormat_first=$(toUpper ${__nameFormat_arg:0:1})
    local __nameFormat_body=$(toLower ${__nameFormat_arg:1})
    local __nameFormat_output="${__nameFormat_output} ${__nameFormat_first}${__nameFormat_body}"
  done
  export __func_return=${__nameFormat_output}
  echo ${__nameFormat_output}
  return 1;
}
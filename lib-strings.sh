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
  __cdDir_NEW_DIR="${1}"
  if ! [[ -d ${__cdDir_NEW_DIR} ]]; then
    return 0;
  fi
  cd ${__cdDir_NEW_DIR}
  if [[ ${PWD} != ${__cdDir_NEW_DIR} ]]; then
    return 0;
  fi
  return 1;
}

function copyFile()
{
  __copyFile_SRC="${1}"
  __copyFile_DST="${2}"

  if [[ -f ${__copyFile_SRC} ]]; then
    return 0;
  fi
  if [[ -f ${__copyFile_DST} ]]; then
    return 0
  fi
  cp -rf ${__copyFile_SRC} ${__copyFile_DST}
  if [[ -f ${__copyFile_DST} ]]; then
    return 1
  fi
  return 0
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
  __copyFileIfNotExists_SRC=${1}
  __copyFileIfNotExists_DST=${2}
  
  if ! [[ -f ${__copyFileIfNotExists_SRC} ]]; then
    return 0
  fi

  if [[ -d ${__copyFileIfNotExists_DST} ]]; then
    rm -rf ${__copyFileIfNotExists_DST}
    logInfo ${idt} "remove" ${__copyFileIfNotExists_DST}
  fi
  cp -rf ${__copyFileIfNotExists_SRC} ${__copyFileIfNotExists_DST}
  if [[ -d ${__copyFileIfNotExists_DST} ]]; then
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

function envsSetIfIsEmpty()
{
  __envsSetIfIsEmpty_name=${1}
  __envsSetIfIsEmpty_default_value=${2}
  __envsSetIfIsEmpty_check=${!__envsSetIfIsEmpty_name}
  if [[ ${__envsSetIfIsEmpty_check} == "" ]]; then
    __envsSetIfIsEmpty_check=$(echo ${__envsSetIfIsEmpty_default_value} | grep ' ')
    if [[ ${__envsSetIfIsEmpty_check} != "" ]]; then
      __envsSetIfIsEmpty_default_value=$(echo "${__envsSetIfIsEmpty_default_value}" | sed 's/"//g' )
      export ${__envsSetIfIsEmpty_name}="\"${__envsSetIfIsEmpty_default_value}\""
    else
      export ${__envsSetIfIsEmpty_name}=${__envsSetIfIsEmpty_default_value}
    fi    
  fi
  return 1;  
}

function envsFileAddIfNotExists()
{
  __envsFileAddIfNotExists_file=${1}
  __envsFileAddIfNotExists_name=${2}
  __envsFileAddIfNotExists_value=${3}


  if [[ ${__envsFileAddIfNotExists_file} == "" || ${__envsFileAddIfNotExists_name} == "" ]]; then
    return 0
  fi

  if ! [[ -f ${__envsFileAddIfNotExists_file} ]]; then
    __envsFileAddIfNotExists_file_dir=$(dirname ${__envsFileAddIfNotExists_file})
    mkdir -p ${__envsFileAddIfNotExists_file_dir}
    if ! [[ -d ${__envsFileAddIfNotExists_file_dir} ]];then
      echR "No create env dir: ${__envsFileAddIfNotExists_file_dir}"
      echR "No create env file: ${__envsFileAddIfNotExists_file}"
      return 0
    fi
    echo "#!/bin/bash">${__envsFileAddIfNotExists_file}
  fi

  __envsFileAddIfNotExists_check=$(cat ${__envsFileAddIfNotExists_file} | grep ${__envsFileAddIfNotExists_name} )
  if [[ ${__envsFileAddIfNotExists_check} != "" ]]; then
    return 1
  fi
  #se nao for informado o valor da variavel recuperaremos seu valor pelo nome indicado
  if [[ ${__envsFileAddIfNotExists_value} == "" ]]; then
    __envsFileAddIfNotExists_value=${!__envsFileAddIfNotExists_name}
  fi

  __envsFileAddIfNotExists_file_temp="/tmp/envsFileAddIfNotExists_${RANDOM}.env"
  cat ${__envsFileAddIfNotExists_file}>${__envsFileAddIfNotExists_file_temp}

  __envsFileAddIfNotExists_check=$(echo ${__envsFileAddIfNotExists_value} | grep ' ')
  if [[ ${__envsFileAddIfNotExists_check} == "" ]]; then
    echo "export ${__envsFileAddIfNotExists_name}=${__envsFileAddIfNotExists_value}">>${__envsFileAddIfNotExists_file_temp}
  else
    __envsFileAddIfNotExists_value=$(echo "${__envsFileAddIfNotExists_value}" | sed 's/"//g' )
    echo "export ${__envsFileAddIfNotExists_name}=\"${__envsFileAddIfNotExists_value}\"">>${__envsFileAddIfNotExists_file_temp}
  fi

  #sort lines
  sort -u ${__envsFileAddIfNotExists_file_temp} -o ${__envsFileAddIfNotExists_file}
  rm -rf ${__envsFileAddIfNotExists_file_temp}

  return 1;

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
  export __func_return=
  __runSource_RUN_FILE="${1}"
  __runSource_RUN_PARAMS="${2}"
  if [[ ${__runSource_RUN_FILE} == "" ]]; then
    return 0
  fi

  if ! [[ -f ${__runSource_RUN_FILE} ]]; then
    return 0
  fi

  echo $(chmod +x ${__runSource_RUN_FILE})&>/dev/null
  source ${__runSource_RUN_FILE} ${__runSource_RUN_PARAMS}
  return 0
}

function envsPrepareFile()
{
  export __func_return=
  __envsPrepareFile_target=${1}
  __envsPrepareFile_target_output=${2}
  if ! [[ -f ${__envsPrepareFile_target} ]]; then
    return 0
  fi

  __envsPrepareFile_target_tmp_1="/tmp/env__envsPrepareFile_target_1_${RANDOM}.env"
  __envsPrepareFile_target_tmp_2="/tmp/env__envsPrepareFile_target_2_${RANDOM}.env"
  cat ${__envsPrepareFile_target}>${__envsPrepareFile_target_tmp_1}
  #trim lines
  sed -i 's/^[[:space:]]*//; s/[[:space:]]*$//' ${__envsPrepareFile_target_tmp_1}
  #remove empty lines
  sed -i '/^$/d' ${__envsPrepareFile_target_tmp_1}  
  #remove startWith #
  sed -i '/^#/d' ${__envsPrepareFile_target_tmp_1}
  #remove exports
  sed -i 's/export;//g' ${__envsPrepareFile_target_tmp_1}
  sed -i 's/export //g' ${__envsPrepareFile_target_tmp_1}
  #sort lines
  sort -u ${__envsPrepareFile_target_tmp_1} -o ${__envsPrepareFile_target_tmp_2}
  #after sort remove duplicate lines
  sed -i '$!N; /^\(.*\)\n\1$/!P; D' ${__envsPrepareFile_target_tmp_2}


  rm -rf ${__envsPrepareFile_target_tmp_1}

  #tratando nomes das variaveis
  while IFS= read -r line
  do
    line=$(echo ${line} | grep =)
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
      if [[ -f ${__envsPrepareFile_target_tmp_1} ]]; then
        echo "${line}">>${__envsPrepareFile_target_tmp_1}
      else
        echo "${line}">${__envsPrepareFile_target_tmp_1}
      fi
    fi
  done < "${__envsPrepareFile_target_tmp_2}"

  if ! [[ -f ${__envsPrepareFile_target_tmp_1} ]]; then
    return 0
  fi

  if [[ ${__envsPrepareFile_target_output} == "" ]]; then
    __envsPrepareFile_target_output=${__envsPrepareFile_target}
  fi
  cat ${__envsPrepareFile_target_tmp_1}>${__envsPrepareFile_target_output}
  rm -rf ${__envsPrepareFile_target_tmp_1}
  rm -rf ${__envsPrepareFile_target_tmp_2}
  __func_return=${__envsPrepareFile_target_output}
  return 1
}

function envsFileConvertToExport()
{
  export __func_return=
  __envsFileConvertToExport_file="${1}"
  __envsFileConvertToExport_output="${2}"


  if [[ ${__envsFileConvertToExport_file} == "" ]]; then
    return 0
  fi

  if ! [[ -f ${__envsFileConvertToExport_file} ]]; then
    return 0
  fi

  if [[ ${__envsFileConvertToExport_output} == "" ]]; then
    __envsFileConvertToExport_output=${__envsFileConvertToExport_file}
  else
    cat ${__envsFileConvertToExport_file}>${__envsFileConvertToExport_output}
  fi

  envsPrepareFile ${__envsFileConvertToExport_output}

  export __func_return=
  #incluindo prefixo no artquivo
  sed -i 's/^/export /' ${__envsFileConvertToExport_output}
  export __func_return=${__envsFileConvertToExport_output} 
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
  export __envsParserDir_DIR="${2}"
  export __envsParserDir_EXT="${3}"

  if [[ ${__envsParserDir_DIR} == "" || ${__envsParserDir_EXT} == "" ]]; then
    if [[ -d ${__envsParserDir_DIR} ]]; then
      __envsParserDir_TARGETS=($(find ${__envsParserDir_DIR} -name ${__envsParserDir_EXT}))
      for __envsParserDir_TARGET in "${__envsParserDir_TARGETS[@]}"
      do
        envsParserFile ${__envsParserDir_TARGET}
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
  export __func_return=
  __str_file="${1}"
  if [[ ${__str_file} == "" ]]; then
    return 0
  fi
  export __func_return=$(dirname ${__str_file})
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

# function strArg(){
#   local __args=(${1})
#   local __arg="${2}"
#   local __return=
#   for arg in "${__args[@]}"
#   do
#     local key=$(echo "$arg" | cut -d '=' -f1)
#     if ! [[ ${arg} == "--"* ]]; then
#       continue;
#     fi

#     echo "if [[ "${arg}" == "--${arg}="* ]]; then"

#     if [[ "${arg}" == "--${arg}="* ]]; then
#       continue;
#     fi

#     echo $(echo "$arg" | cut -d '=' -f2)


#   done
#   return 0;
# }

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
  __replaceString_SOURCE="${1}"
  __replaceString_TARGET="${2}"
  __replaceString_REPLAC="${3}"

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
    __replaceString_LAST_OUTPUT=${__replaceString_OUTPUT}
    __replaceString_OUTPUT=$(echo ${LAST_OUTPUT} | sed "s/${__replaceString_TARGET}/${__replaceString_REPLAC}/g")
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
  __e_c_command_ignore=
  export __echCommand=
  for __e_c_env in "$@"
  do
    if [[ ${__e_c_env} == "--ignore" ]]; then
      __e_c_command_ignore=true
    else
      if [[ ${__e_c_env_i} == "" ]]; then
        __e_c_command="${__e_c_command} ${__e_c_env}"
      fi
      __e_c_env_i=
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

function arrayContains()
{
  __inArray_array=(${1})
  __inArray_arg=${2}

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
  for __nameFormat_arg in "${__nameFormat_args[@]}"
  do
    local __nameFormat_first=$(toUpper ${__nameFormat_arg:0:1})
    local __nameFormat_body=$(toLower ${__nameFormat_arg:1})
    __nameFormat_output="${__nameFormat_output} ${__nameFormat_first}${__nameFormat_body}"
  done
  echo ${__nameFormat_output}
  return 1;
}
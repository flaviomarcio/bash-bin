#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-git.sh
. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh
. ${BASH_BIN}/lib-build.sh
. ${BASH_BIN}/lib-docker.sh

function __private_deploy_envsubst()
{
  if [[ ${1} == "" ]]; then
    return 0
  fi
  local __files=(${1})
  local __file_src=
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

function deployPrepareEnvFile()
{
  unset __func_return
  local __src_json_file=${1}
  local __dst_dir=${2} 
  local __tag_envs=${3}

  if ! [[ -f ${__src_json_file} ]]; then
    return 1
  fi

  mkdir -p ${__dst_dir}

  if ! [[ -d ${__dst_dir} ]]; then
    ls -l 
    return 0
  fi
  cd ${__dst_dir}
  if [[ ${PWD} != ${__dst_dir} ]]; then
    return 0
  fi

  local __dst_json_file="${__dst_dir}/env.json"
  cat ${__src_json_file}>${__dst_json_file}

  local __tag_envs=($(echo ${__tag_envs} | sed 's/-/_/g'))

  local __party_tag_files=()
  local __tag=
  for __tag in "${__tag_envs[@]}"
  do
    #echo "__tag==${__tag}"
    local __tag_ext=$(strArg 0 "$(strSplit ${__tag})" '.')
    if [[ ${__tag_ext} == "" ]]; then
      continue;
    fi

    #Env file
    local __tag_envs=$(jsonGet "${__src_json_file}" "${__tag}" )
    if [[ ${__tag_envs} == "" ]]; then
      continue;
    fi

    local __party_tag_file=${__dst_dir}/tag.${__tag}.env
    echo "">${__party_tag_file}
    local __tag_envs=(${__tag_envs})
    for __tag_env in "${__tag_envs[@]}"
    do
      local __tag_env=$(echo ${__tag_env} | sed 's/\"//g')
      echo ${__tag_env}>>${__party_tag_file}
    done
    fileDedupliceLines ${__party_tag_file}
    local __party_tag_files+=(${__party_tag_file})
  done


  local __files=()
  local __party_tag_file=
  for __party_tag_file in "${__party_tag_files[@]}"
  do
    local __tag_ext=$(basename ${__party_tag_file})
    local __tag_ext=$(strArg 1 "$(strSplit ${__tag_ext})" '.')
    local __tag_file_ext=${__dst_dir}/env_file.${__tag_ext}.env

    if ! [[ -f ${__tag_file_ext} ]]; then
      cat ${__party_tag_file}>${__tag_file_ext}
      __files+=(${__tag_file_ext})
    else
      cat ${__party_tag_file}>>${__tag_file_ext}
    fi    
  done

  local __file_static=${__dst_dir}/env_file-static.env
  echo "">${__file_static}
  local __file=
  for __file in "${__files[@]}"
  do
    local __file_ext=$(basename ${__file})
    local __file_ext=$(strArg 1 "$(strSplit ${__file_ext})" '.')
    if [[ ${__file_ext} == "env" ]]; then
      envsFileConvertToExport ${__file}
      cat ${__func_return}>>${__file_static}
      source ${__func_return}
    fi
  done
  local __file=
  for __file in "${__files[@]}"
  do
    local __file_ext=$(basename ${__file})
    local __file_ext=$(strArg 1 "$(strSplit ${__file_ext})" '.')
    if [[ ${__file_ext} == "env" ]]; then      
      __private_deploy_envsubst ${__file}
    fi
  done

  local __file_deploy=${__dst_dir}/env_file-deploy.env
  echo "">${__file_deploy}
  local __file=
  for __file in "${__files[@]}"
  do
    local __file_ext=$(basename ${__file})
    local __file_ext=$(strArg 1 "$(strSplit ${__file_ext})" '.')
    if [[ ${__file_ext} != "env" ]]; then
      cat ${__file}>>${__file_deploy}
    fi
  done

  __private_deploy_envsubst ${__file_static}
  fileDedupliceLines ${__file_static}
  source ${__file_static}

  __private_deploy_envsubst ${__file_deploy}
  fileDedupliceLines ${__file_deploy}

  # #clean dir
  # rm -rf *.env.ori
  # rm -rf tag*.env
  # rm -rf env_file.*.env
  # rm -rf env.json

  export __func_return=${__file_deploy}
  return 1
}


function deploy()
{
  clearTerm
  __private_print_os_information
  echM "  Deploy"
  local __deploy_environment=${1}
  local __deploy_target=${2}
  local __deploy_name=${3}
  local __deploy_builder_dir=${4}
  local __deploy_build_option=${5}
  local __deploy_git_repository=${6}
  local __deploy_git_branch=${7}
  local __deploy_git_project_file=${8}
  local __deploy_dck_image=${9}
  local __deploy_dck_file=${10}
  local __deploy_dck_compose=${11}
  local __deploy_dck_env_file=${12}
  local __deploy_bin_dir=${13}
  local __deploy_binary_application=${14}
  local __deploy_dependency_dir=(${15})

  local __deploy_dck_env_tags=
  local __deploy_check_build=false
  local __deploy_check_deploy=false
  if [[ ${APPLICATION_ACTION} == "script" ]]; then
    local __deploy_check_build=true
    local __deploy_check_deploy=false
  elif [[ ${__deploy_build_option} == "build" ]]; then
    local __deploy_check_build=false
    local __deploy_check_deploy=false
  elif [[ ${__deploy_build_option} == "deploy" ]]; then
    local __deploy_check_build=false
    local __deploy_check_deploy=true
  else
    local __deploy_check_build=true
    local __deploy_check_deploy=true
  fi

  if [[ ${__deploy_environment} == "" || ${__deploy_target} == "" || ${__deploy_name} == "" || ${__deploy_builder_dir} == "" ]]; then
    echB "  target: $@"
    echR "    ===============================  "
    echR "             ************            "
    echR "    *********Invalid args*********   "
    echR "             ************            "
    echR "    ===============================  "
    return 0
  fi

  dockerSwarmIsActive
  if ! [ "$?" -eq 1 ]; then
    echB "  Docker swarm verify"
    echC "    - state: $(dockerSwarmState)"
    echR "    ===============================  "
    echR "         **********************      "
    echR "    *****DockerSwarm no active*****  "
    echR "         **********************      "
    echR "    ===============================  "
    return 0
  fi

  local __deploy_service_name=${__deploy_environment}-${__deploy_target}-${__deploy_name}
  local __deploy_host_name="${STACK_PREFIX_HOST}${__deploy_name}"

  mkdir -p ${__deploy_builder_dir}
  local __deploy_dependency=
  for __deploy_dependency in "${__deploy_dependency_dir[@]}"
  do
    if [[ -d ${__deploy_dependency} ]]; then
      cp -rf ${__deploy_dependency}/* ${__deploy_builder_dir}
    fi
  done

  if [[ -f ${__deploy_dck_file} ]]; then
    local __deploy_dck_file_src=$(echo ${__deploy_dck_file} | sed 's/\.yml/\.*/g')
    cp -rf ${__deploy_dck_file_src} ${__deploy_builder_dir}
    local __deploy_dck_file=${__deploy_builder_dir}/$(basename ${__deploy_dck_file})
  fi

  if [[ -f ${__deploy_dck_compose} ]]; then
    local __deploy_dck_compose_src=$(echo ${__deploy_dck_compose} | sed 's/\.yml/\.*/g')
    cp -rf ${__deploy_dck_compose_src} ${__deploy_builder_dir}
    local __deploy_dck_compose=${__deploy_builder_dir}/$(basename ${__deploy_dck_compose})
  fi

  #format config files 
  # -embora legal ele gera problemas pois os arquivos conf tem as proprias envs 
  #  com $ e o env simplesmente faz replace delas gerando assim problemas
  # 
  # -alternativa é utilizar o metodo fileEnvreplace que apenas dará replace 
  #  nas envs carregadas no ambiente
  #
  #__private_deploy_envsubst "$(find ${__deploy_builder_dir} -name '*.conf')"

  if [[ ${__deploy_check_build} == true ]]; then
    if [[ ${__deploy_git_repository} != "" ]]; then
      gitClone "${__deploy_git_repository}" "${__deploy_git_branch}" "${__deploy_builder_dir}" "src"
      if ! [ "$?" -eq 1 ]; then
        return 0
      fi
      local __deploy_git_dir=${__func_return}

      buildCompilerCheck ${__deploy_git_dir}
      if ! [ "$?" -eq 1 ]; then
        echB "    target: ${__deploy_git_dir}"
        echR "    ===============================  "
        echR "           ******************        "
        echR "    *******Invalid compiler*******   "
        echR "           ******************        "
        echR "    ===============================  "
        return 0
      fi

      if [[ ${__func_return} == "script"  ]]; then
        execScript "${__deploy_git_dir}" "${APPLICATION_ACTION_SCRIPT}"
        if ! [ "$?" -eq 1 ]; then
          export __func_return="fail on calling execScript: ${__func_return}"
          return 0
        fi
      elif [[ ${__func_return} == "maven"  ]]; then
        local __deploy_git_project_file="app*.jar"
        mavenBuild ${__deploy_git_dir} ${__deploy_git_project_file}
        if ! [ "$?" -eq 1 ]; then
          export __func_return="fail on calling mavenBuild: ${__func_return}"
          return 0
        fi
        local __deploy_binary_application=${__deploy_builder_dir}/${__deploy_binary_application}
        cp -rf ${__func_return} ${__deploy_binary_application}
      elif [[ ${__func_return} == "qmake"  ]]; then
        qtBuild ${__deploy_git_dir} ${__deploy_git_project_file}
        if ! [ "$?" -eq 1 ]; then
          export __func_return="fail on calling qtBuild: ${__func_return}"
          return 0
        fi
        local __deploy_binary_application=${__deploy_builder_dir}/${__deploy_binary_application}
        cp -rf ${__func_return} ${__deploy_binary_application}
      fi
    fi
  fi

  if [[ ${__deploy_check_deploy} == true ]]; then

    dockerCleanup ${__deploy_service_name}
    if ! [ "$?" -eq 1 ]; then
      echB "    target: ${__deploy_git_dir}"
      echR "    ===============================   "
      echR "             ************             "
      echR "    *********Cleanup fail**********   "
      echR "             ************             "
      echR "    ===============================   "
      return 0;
    fi

    local __deploy_network_name=${__deploy_environment}-${__deploy_target}-inbound
    dockerNetworkCreate ${__deploy_network_name}
    if ! [ "$?" -eq 1 ]; then
      echB "    target: ${__deploy_git_dir}"
      echR "    ===============================  "
      echR "           ******************        "
      echR "    ******network create fail******  "
      echR "           ******************        "
      echR "    ===============================  "
      return 0;
    fi

    dockerBuildCompose \
        "${__deploy_service_name}" \
        "${__deploy_dck_image}" \
        "${__deploy_dck_file}" \
        "${__deploy_dck_compose}" \
        "${__deploy_dck_env_file}" \
        "${__deploy_builder_dir}" \
        "${__deploy_binary_application}" \
        "${__deploy_host_name}" \
        "${__deploy_network_name}"

    if ! [ "$?" -eq 1 ]; then
      return 0
    fi
  fi
  echG "  Finished"
  return 1
}

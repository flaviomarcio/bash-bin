#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
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
  __private_deploy_envsubst_files=(${1})
  for __private_deploy_envsubst_file_src in "${__private_deploy_envsubst_files[@]}"
  do
    if [[ -f ${__private_deploy_envsubst_file_src} ]]; then
      __private_deploy_envsubst_file_ori=${__private_deploy_envsubst_file_src}.ori
      cat ${__private_deploy_envsubst_file_src}>${__private_deploy_envsubst_file_ori}
      envsubst < ${__private_deploy_envsubst_file_ori} > ${__private_deploy_envsubst_file_src}
    fi
  done  

  return 1;
}

function deployPrepareEnvFile()
{
  export __func_return=
  __deploy_prepare_env_src_json_file=${1}
  __deploy_prepare_env_dst_dir=${2} 
  __deploy_prepare_env_tag_envs=${3}

  if ! [[ -f ${__deploy_prepare_env_src_json_file} ]]; then
    return 1
  fi

  mkdir -p ${__deploy_prepare_env_dst_dir}

  if ! [[ -d ${__deploy_prepare_env_dst_dir} ]]; then
    ls -l 
    return 0
  fi
  cd ${__deploy_prepare_env_dst_dir}
  if [[ ${PWD} != ${__deploy_prepare_env_dst_dir} ]]; then
    return 0
  fi

  __deploy_prepare_env_dst_json_file="${__deploy_prepare_env_dst_dir}/env.json"
  cat ${__deploy_prepare_env_src_json_file}>${__deploy_prepare_env_dst_json_file}

  __deploy_prepare_env_tag_envs=($(echo ${__deploy_prepare_env_tag_envs} | sed 's/-/_/g'))

  __deploy_prepare_env_party_tag_files=()
  for __deploy_prepare_env_tag in "${__deploy_prepare_env_tag_envs[@]}"
  do
    #echo "__deploy_prepare_env_tag==${__deploy_prepare_env_tag}"
    __deploy_prepare_env_tag_ext=$(strArg 0 "$(strSplit ${__deploy_prepare_env_tag})" '.')
    if [[ ${__deploy_prepare_env_tag_ext} == "" ]]; then
      continue;
    fi

    #Env file
    __deploy_prepare_env_tag_envs=$(jsonGet "${__deploy_prepare_env_src_json_file}" "${__deploy_prepare_env_tag}" )
    if [[ ${__deploy_prepare_env_tag_envs} == "" ]]; then
      continue;
    fi

    __deploy_prepare_env_party_tag_file=${__deploy_prepare_env_dst_dir}/tag.${__deploy_prepare_env_tag}.env
    echo "">${__deploy_prepare_env_party_tag_file}
    __deploy_prepare_env_tag_envs=(${__deploy_prepare_env_tag_envs})
    for __deploy_prepare_env_tag_env in "${__deploy_prepare_env_tag_envs[@]}"
    do
      __deploy_prepare_env_tag_env=$(echo ${__deploy_prepare_env_tag_env} | sed 's/\"//g')
      echo ${__deploy_prepare_env_tag_env}>>${__deploy_prepare_env_party_tag_file}
    done
    fileDedupliceLines ${__deploy_prepare_env_party_tag_file}
    __deploy_prepare_env_party_tag_files+=(${__deploy_prepare_env_party_tag_file})
  done


  __deploy_prepare_env_files=()
  for __deploy_prepare_env_party_tag_file in "${__deploy_prepare_env_party_tag_files[@]}"
  do
    __deploy_prepare_env_tag_ext=$(basename ${__deploy_prepare_env_party_tag_file})
    __deploy_prepare_env_tag_ext=$(strArg 1 "$(strSplit ${__deploy_prepare_env_tag_ext})" '.')
    __deploy_prepare_env_tag_file_ext=${__deploy_prepare_env_dst_dir}/env_file.${__deploy_prepare_env_tag_ext}.env

    if ! [[ -f ${__deploy_prepare_env_tag_file_ext} ]]; then
      cat ${__deploy_prepare_env_party_tag_file}>${__deploy_prepare_env_tag_file_ext}
      __deploy_prepare_env_files+=(${__deploy_prepare_env_tag_file_ext})
    else
      cat ${__deploy_prepare_env_party_tag_file}>>${__deploy_prepare_env_tag_file_ext}
    fi    
  done

  __deploy_prepare_env_file_static=${__deploy_prepare_env_dst_dir}/env_file-static.env
  echo "">${__deploy_prepare_env_file_static}

  for __deploy_prepare_env_file in "${__deploy_prepare_env_files[@]}"
  do
    __deploy_prepare_env_file_ext=$(basename ${__deploy_prepare_env_file})
    __deploy_prepare_env_file_ext=$(strArg 1 "$(strSplit ${__deploy_prepare_env_file_ext})" '.')
    if [[ ${__deploy_prepare_env_file_ext} == "env" ]]; then
      envsFileConvertToExport ${__deploy_prepare_env_file}
      cat ${__deploy_prepare_env_file}>>${__deploy_prepare_env_file_static}
      source ${__deploy_prepare_env_file}
    fi
  done

  for __deploy_prepare_env_file in "${__deploy_prepare_env_files[@]}"
  do
    __deploy_prepare_env_file_ext=$(basename ${__deploy_prepare_env_file})
    __deploy_prepare_env_file_ext=$(strArg 1 "$(strSplit ${__deploy_prepare_env_file_ext})" '.')
    if [[ ${__deploy_prepare_env_file_ext} == "env" ]]; then      
      __private_deploy_envsubst ${__deploy_prepare_env_file}
    fi
  done

  __deploy_prepare_env_file_deploy=${__deploy_prepare_env_dst_dir}/env_file-deploy.env
  echo "">${__deploy_prepare_env_file_deploy}
  for __deploy_prepare_env_file in "${__deploy_prepare_env_files[@]}"
  do
    __deploy_prepare_env_file_ext=$(basename ${__deploy_prepare_env_file})
    __deploy_prepare_env_file_ext=$(strArg 1 "$(strSplit ${__deploy_prepare_env_file_ext})" '.')
    if [[ ${__deploy_prepare_env_file_ext} != "env" ]]; then
      cat ${__deploy_prepare_env_file}>>${__deploy_prepare_env_file_deploy}
    fi
  done

  __private_deploy_envsubst ${__deploy_prepare_env_file_static}
  fileDedupliceLines ${__deploy_prepare_env_file_static}
  source ${__deploy_prepare_env_file_static}

  __private_deploy_envsubst ${__deploy_prepare_env_file_deploy}
  fileDedupliceLines ${__deploy_prepare_env_file_deploy}

  #clean dir
  rm -rf *.env.ori
  rm -rf tag*.env
  rm -rf env_file.*.env
  rm -rf env.json

  export __func_return=${__deploy_prepare_env_file_deploy}
  return 1
}


function deploy()
{
  __deploy_binary_file=

  clearTerm
  __private_print_os_information
  echM "  Deploy"
  __deploy_environment=${1}
  __deploy_target=${2}
  __deploy_name=${3}
  __deploy_builder_dir=${4}
  __deploy_build_option=${5}
  __deploy_git_repository=${6}
  __deploy_git_branch=${7}
  __deploy_git_project_file=${8}
  __deploy_dck_image=${9}
  __deploy_dck_file=${10}
  __deploy_dck_compose=${11}
  __deploy_dck_env_file=${12}
  __deploy_bin_dir=${13}
  __deploy_dependency_dir=(${14})

  __deploy_dck_env_tags=
  __deploy_check_build=false
  __deploy_check_deploy=false
  if [[ ${__deploy_build_option} == "build" ]]; then
    __deploy_check_build=false
    __deploy_check_deploy=false
  elif [[ ${__deploy_build_option} == "deploy" ]]; then
    __deploy_check_build=false
    __deploy_check_deploy=true
  else
    __deploy_check_build=true
    __deploy_check_deploy=true
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

  __deploy_service_name=${__deploy_environment}-${__deploy_target}-${__deploy_name}

  mkdir -p ${__deploy_builder_dir}
  for __deploy_dependency in "${__deploy_dependency_dir[@]}"
  do
    if [[ -d ${__deploy_dependency} ]]; then
      cp -rf ${__deploy_dependency}/* ${__deploy_builder_dir}
    fi
  done

  if [[ -f ${__deploy_dck_file} ]]; then
    __deploy_dck_file_src=$(echo ${__deploy_dck_file} | sed 's/\.yml/\.*/g')
    cp -rf ${__deploy_dck_file_src} ${__deploy_builder_dir}
    __deploy_dck_file=${__deploy_builder_dir}/$(basename ${__deploy_dck_file})
  fi

  if [[ -f ${__deploy_dck_compose} ]]; then
    __deploy_dck_compose_src=$(echo ${__deploy_dck_compose} | sed 's/\.yml/\.*/g')
    cp -rf ${__deploy_dck_compose_src} ${__deploy_builder_dir}
    __deploy_dck_compose=${__deploy_builder_dir}/$(basename ${__deploy_dck_compose})
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
      __deploy_git_dir=${__func_return}

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

      if [[ ${__func_return} == "maven"  ]]; then
        __deploy_git_project_file="app*.jar"
        mavenBuild ${__deploy_git_dir} ${__deploy_git_project_file}
        if ! [ "$?" -eq 1 ]; then
          return 0
        fi
        __deploy_binary_file=${__deploy_builder_dir}/app.jar
        cp -rf ${__func_return} ${__deploy_binary_file}        
      elif [[ ${__func_return} == "qmake"  ]]; then
        qtBuild ${__deploy_git_dir} ${__deploy_git_project_file}
        if ! [ "$?" -eq 1 ]; then
          return 0
        fi
        __deploy_binary_file=${__deploy_builder_dir}/app
        cp -rf ${__func_return} ${__deploy_binary_file}
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

    __deploy_network_name=${__deploy_environment}-${__deploy_target}-inbound
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
        "${__deploy_bin_dir}" \
        "${__deploy_binary_file}" \
        "${__deploy_network_name}"

    if ! [ "$?" -eq 1 ]; then
      return 0
    fi
  fi
  echG "  Finished"
  return 1
}

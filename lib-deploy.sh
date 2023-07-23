#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-git.sh
. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh
. ${BASH_BIN}/lib-build.sh
. ${BASH_BIN}/lib-docker.sh

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

  rm -rf *.*env
  rm -rf *.*json
  rm -rf *.*bak

  __deploy_prepare_env_dst_json_file="${__deploy_prepare_env_dst_dir}/env.json"
  cat ${__deploy_prepare_env_src_json_file}>${__deploy_prepare_env_dst_json_file}

  __deploy_prepare_env_tag_envs=($(echo ${__deploy_prepare_env_tag_envs} | sed 's/-/_/g'))

  __deploy_prepare_env_party_tag_files=()
  for __deploy_prepare_env_tag in "${__deploy_prepare_env_tag_envs[@]}"
  do
    __deploy_prepare_env_tag_ext=$(strArg 0 "$(strSplit ${__deploy_prepare_env_tag})" '.')
    if [[ ${__deploy_prepare_env_tag_ext} == "" ]]; then
      continue;
    fi

    #Env file
    __deploy_prepare_env_tag_envs=$(jsonGet "${__deploy_prepare_env_src_json_file}" "${__deploy_prepare_env_tag}" )
    if [[ ${__deploy_prepare_env_tag_envs} == "" ]]; then
      continue;
    fi

    __deploy_prepare_env_party_tag_file=${__deploy_prepare_env_dst_dir}/tag-${__deploy_prepare_env_tag}.${__deploy_prepare_env_tag_ext}
    __deploy_prepare_env_party_tag_files+=(${__deploy_prepare_env_party_tag_file})
    echo "">${__deploy_prepare_env_party_tag_file}
    __deploy_prepare_env_tag_envs=(${__deploy_prepare_env_tag_envs})
    for __deploy_prepare_env_tag_env in "${__deploy_prepare_env_tag_envs[@]}"
    do
      __deploy_prepare_env_tag_env=$(echo ${__deploy_prepare_env_tag_env} | sed 's/\"//g')
      echo ${__deploy_prepare_env_tag_env}>>${__deploy_prepare_env_party_tag_file}
    done
  done

  __deploy_prepare_env_file_static=${__deploy_prepare_env_dst_dir}/env_file_static.env
  __deploy_prepare_env_file=${__deploy_prepare_env_dst_dir}/env_file.env
  __deploy_prepare_env_docker=${__deploy_prepare_env_dst_dir}/env_docker.env
  echo "">${__deploy_prepare_env_file}
  echo "">${__deploy_prepare_env_docker}
  for __deploy_prepare_env_party_tag_file in "${__deploy_prepare_env_party_tag_files[@]}"
  do
    __deploy_prepare_env_party_ext=$(strExtractFileExtension ${__deploy_prepare_env_party_tag_file})
    if [[ ${__deploy_prepare_env_party_ext} == "env" ]]; then
      cat ${__deploy_prepare_env_party_tag_file}>>${__deploy_prepare_env_file}
    fi    
    
    cat ${__deploy_prepare_env_party_tag_file}>>${__deploy_prepare_env_docker}
  done

  #load os envs
  envsOS ${__deploy_prepare_env_file_static}
  #parser base envs
  envsParserFile ${__deploy_prepare_env_file}
  #export base envs to static
  cat ${__deploy_prepare_env_file}>>${__deploy_prepare_env_file_static}
  #extract only static envs
  envsExtractStatic ${__deploy_prepare_env_file_static}
  #load static envs
  source ${__deploy_prepare_env_file_static}

  #final parser
  envsParserFile ${__deploy_prepare_env_file}
  envsParserFile ${__deploy_prepare_env_docker}

  #format file
  envsPrepareFile ${__deploy_prepare_env_file_static}
  envsPrepareFile ${__deploy_prepare_env_file}
  envsPrepareFile ${__deploy_prepare_env_docker}
  
  #clean dir
  rm -rf *.bak
  rm -rf tag*.*
  
  export __func_return=${__deploy_prepare_env_docker}
  return 1
}


function deploy()
{
  __deploy_jar_file=

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
  __deploy_dck_image=${8}
  __deploy_dck_file=${9}
  __deploy_dck_compose=${10}
  __deploy_dck_env_file=${11}
  __deploy_bin_dir=${12}
  __deploy_dependency_dir=(${13})


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
        mavenBuild ${__deploy_git_dir} ${__deploy_git_repository} "app*.jar"
        if ! [ "$?" -eq 1 ]; then
          return 0
        fi
        __deploy_jar_file=${__deploy_builder_dir}/app.jar
        cp -rf ${__func_return} ${__deploy_jar_file}
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
        "${__deploy_jar_file}" \
        "${__deploy_network_name}"

    if ! [ "$?" -eq 1 ]; then
      return 0
    fi
  fi
  echG "  Finished"
  return 1
}

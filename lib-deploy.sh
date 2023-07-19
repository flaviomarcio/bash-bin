#!/bin/bash

. lib-strings.sh
. lib-system.sh
. lib-build.sh
. lib-docker.sh

function deploy()
{
  __deploy_jar_file=

  clearTerm
  echM "  Deploy"
  __deploy_environment=${1}
  __deploy_target=${2}
  __deploy_name=${3}
  __deploy_builder_dir=${4}
  __deploy_git_repository=${5}
  __deploy_git_branch=${6}
  __deploy_dck_image=${7}
  __deploy_dck_file=${8}
  __deploy_dck_compose=${9}
  __deploy_dck_env_file=${10}
  __deploy_bin_dir=${11}
  __deploy_dependency_dir=(${12})

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

  __deploy_builder_dir=${__deploy_builder_dir}/${__deploy_service_name}
  if [[ ${__deploy_builder_dir} != "" ]]; then
    if [[ -d ${__deploy_builder_dir} ]]; then
      rm -rf ${__deploy_builder_dir}
    fi    
  fi

  mkdir -p ${__deploy_builder_dir}
  for __deploy_dependency in "${__deploy_dependency_dir[@]}"
  do
    cp -rf ${__deploy_dependency}/* ${__deploy_builder_dir}
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
  

  if [[ ${__deploy_dck_env_file} != "" ]]; then
    __deploy_dck_env_tmp=$(echo ${__deploy_dck_compose} | sed 's/\.yml/\.env/g')
    __deploy_dck_env_tmp="/tmp/$(basename ${__deploy_dck_env_tmp})"
    __deploy_dck_file_env=$(echo ${__deploy_dck_compose} | sed 's/\.yml/\.env/g')
    __deploy_dck_compose_env=$(echo ${__deploy_dck_compose} | sed 's/\.yml/\.env/g')
    __deploy_dck_env_files=(${APPLICATION_DEPLOY_ENV_FILE} ${__deploy_dck_file_env} ${__deploy_dck_compose_env} ${__deploy_dck_env_file})
    echo " " >${__deploy_dck_env_tmp}
    for __deploy_tmp_file in "${__deploy_dck_env_files[@]}"
    do
      cat ${__deploy_tmp_file}>>${__deploy_dck_env_tmp}
      echo " ">>${__deploy_dck_env_tmp}
    done
    cat ${__deploy_dck_env_tmp}>${__deploy_dck_env_file}

    __deploy_dck_env_file_src=${__deploy_dck_env_file}
    __deploy_dck_env_file=$(echo ${__deploy_dck_compose} | sed 's/\.yml/\.env/g')
    if [[ -f ${__deploy_dck_env_file_src} ]]; then
      cp -rf ${__deploy_dck_env_file_src} ${__deploy_dck_env_file}
    else
      echo " ">${__deploy_dck_env_file}
    fi
  fi
  
  if [[ ${__deploy_git_repository} != "" ]]; then
    __deploy_git_dir=${__deploy_builder_dir}/src
    gitClone ${__deploy_git_repository} ${__deploy_git_branch} ${__deploy_git_dir} ${__deploy_name}
    if [ "$?" -eq 1 ]; then
      return 0
    fi

    mavenBuild ${__deploy_git_dir} ${__deploy_git_repository} "app.jar"
    if [ "$?" -eq 1 ]; then
      return 0
    fi
    __deploy_jar_file=${__deploy_builder_dir}/${__deploy_service_name}.jar
    cp -rf ${__mvn_jar_file} ${__deploy_jar_file}
  fi

  dockerCleanup ${__deploy_service_name}
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi

  __deploy_network_name=${__deploy_environment}-${__deploy_target}-inbound
  dockerNetworkCreate ${__deploy_network_name}
  if ! [ "$?" -eq 1 ]; then
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

  if [ "$?" -eq 1 ]; then
    return 0
  fi
  echG "  Finished"

}

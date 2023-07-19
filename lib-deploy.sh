#!/bin/bash

. lib-git.sh
. lib-strings.sh
. lib-system.sh
. lib-build.sh
. lib-docker.sh

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
  __deploy_dck_env_file=${1110}
  __deploy_bin_dir=${12}
  __deploy_dependency_dir=(${13})


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

  __deploy_builder_dir=${__deploy_builder_dir}/${__deploy_service_name}
  if [[ ${__deploy_builder_dir} != "" ]]; then
    if [[ -d ${__deploy_builder_dir} ]]; then
      rm -rf ${__deploy_builder_dir}
    fi    
  fi

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
        if [ "$?" -eq 1 ]; then
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
  fi
  echG "  Finished"
  return 1
}

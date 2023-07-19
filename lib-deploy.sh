#!/bin/bash

. lib-strings.sh
. lib-system.sh
. lib-build.sh
. lib-docker.sh

function deploy()
{
  clearTerm
  echM "  Deploy"
  __deploy_environment=${1}
  __deploy_target=${2}
  __deploy_stack_type=${3}  
  __deploy_stack_name=${4}
  __deploy_git_dir=${4}
  __deploy_git_repository=${4}
  __deploy_git_branch=${4}
  __deploy_docker_dir=${5}
  __deploy_bin_dir=${6}

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

  if [[ ${__deploy_stack_name} == "" ]]; then
    __deploy_name=${__deploy_stack_type}
  else
    __deploy_name=${__deploy_stack_type}_${__deploy_stack_name}
  fi

  if [[ ${__deploy_git_repository} != "" ]]; then
    gitClone ${__deploy_git_repository} ${__deploy_git_branch} ${__deploy_git_dir} ${__deploy_name}
    if [ "$?" -eq 1 ]; then
      return 0
    fi

    mavenBuild ${__deploy_git_dir} ${__deploy_git_repository} "app.jar"
    if [ "$?" -eq 1 ]; then
      return 0
    fi
  fi

  dockerCleanup ${__deploy_name}
  if [ "$?" -eq 1 ]; then
    return 0;
  fi

  __docker_build_network_name=${__deploy_environment}-${__deploy_target}-inbound
  dockerNetworkCreate ${__docker_build_network_name}
  if [ "$?" -eq 1 ]; then
    return 0;
  fi

  # export __docker_build_compose_file=${__docker_build_init_dir}/${__docker_build_stack_name}.yml
  dockerBuildCompose ${__deploy_name} ${__docker_build_compose_file} ${__deploy_docker_dir} ${__deploy_bin_dir} ${__mvn_jar_file} 
  if [ "$?" -eq 1 ]; then
    return 0
  fi
  echG "  Finished"

}

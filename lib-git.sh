#!/bin/bash

. lib-strings.sh

function gitClone()
{
  echM "  Git cloning repository"

  __git_clone_repository=${1}
  __git_clone_branch=${2}
  __git_clone_dir=${3}
  __git_clone_name=${4}

  if [[ ${__git_clone_name} == "" ]]; then
    __git_clone_name="src"
  fi

  mkdir -p ${__git_clone_dir}
  if ! [[ -d ${__git_clone_dir} ]]; then
    echY "  target: ${__git_clone_dir}"  
    echR "  ===============================  "
    echR "         *****************         "
    echR "  *******Invalid clone dir*******  "
    echR "         *****************         "
    echR "  ===============================  "
    return 0;
  fi
  
  if [[ ${__git_clone_branch} = "" ]]; then
    echY "  target: ${__git_clone_branch}"  
    echR "  =============================== "
    echR "        *******************       "
    echR "  ******Invalid branch name****** "
    echR "        *******************       "
    echR "  =============================== "
    return 0;
  fi

  cd ${__git_clone_dir}
  __git_clone_src_dir=${__git_clone_dir}/${__git_clone_name}
  rm -rf ${__git_clone_src_dir};
  __git_clone_src_cmd="git clone -q ${__git_clone_repository} ${__git_clone_name}"
  echC "    - ${__git_clone_repository}"
  echC "    - Branch: ${__git_clone_branch}"
  echC "    - Source dir: ${__git_clone_src_dir}"
  echY "    - ${__git_clone_src_cmd}"
  echo $(${__git_clone_src_cmd})>/dev/null 2>&1
  if ! [[ -d ${__git_clone_src_dir} ]]; then
    echY "    target: ${__git_clone_src_dir}"  
    echR "    =============================== "
    echR "         ********************       "
    echR "    *****Repository not found****** "
    echR "         ********************       "
    echR "    =============================== "
    return 0
  fi
  cd ${__git_clone_src_dir}
  __git_clone_src_cmd="git checkout ${__git_clone_branch} -q"
  echY "    - ${__git_clone_src_cmd}"
  echo $(${__git_clone_src_cmd})>/dev/null 2>&1
  echG "  Finished"
  __func_return=${__git_clone_src_dir}
  return 1
}
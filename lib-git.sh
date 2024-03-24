#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh

function gitIsValid()
{
  unset __func_return
  local __gitIsValidPWD=${PWD}
  local __gitIsValid=${1}
  if [[ ${__gitIsValid} != "" ]]; then
    if ! [[ -d ${__gitIsValid} ]]; then
      return 0;
    fi
    cd ${__gitIsValid}
  fi
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    cd ${__gitIsValidPWD}
    return 1;
  fi
  cd ${__gitIsValidPWD}
  return 0;
}

function gitBranch()
{
  unset __func_return
  gitIsValid
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  export __func_return=$(git rev-parse --abbrev-ref HEAD)
  echo ${__func_return}
  return 1
}

function gitBranchList()
{
  unset __func_return
  gitIsValid
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  export __func_return=$(echo "$(git branch --list)" | sed 's/*//g' | sed 's/ //g' | sort)
  echo ${__func_return}
  return 1
}

function gitBranchExists()
{
  gitIsValid
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  local __git_branch_exists_name=${1}
  if [[ ${__git_branch_exists_name} == "" ]]; then
    return 0
  fi
  
  local __git_branch_exists_name=$( echo "$(git branch -a --list)" | sed 's/remotes\/origin\///g' | sed 's/*//g' | sed 's/ //g' | grep ${__git_branch_exists_name})
  if [[ ${__git_branch_exists_name} == "" ]]; then
    return 0
  fi
  return 1
}

function gitCheckOut()
{
  local __git_check_branch=${1}
  gitBranchExists ${__git_check_branch}
  if ! [ "$?" -eq 1 ]; then
    return 0
  fi
  git checkout ${__git_check_branch} --quiet
  return 1
}

function gitClone()
{
  unset __func_return
  echM "  Git cloning repository"

  local __git_check=$(which git)
  if [[ ${__git_check} == ""  ]]; then
    echR "  ==============================  "
    echR "      **********************      "
    echR "  ****GIT não está instalado****  "
    echR "      **********************      "
    echR "  ==============================  "
    return 0
  fi

  local __git_clone_repository=${1}
  local __git_clone_branch=${2}
  local __git_clone_dir=${3}
  local __git_clone_name=${4}

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
  local __git_clone_src_dir=${__git_clone_dir}/${__git_clone_name}
  rm -rf ${__git_clone_src_dir};
  local __git_clone_src_cmd="git clone -q ${__git_clone_repository} ${__git_clone_name}"
  echC "    - ${__git_clone_repository}"
  echC "    - Branch: ${__git_clone_branch}"
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
  echB "    - Source dir: ${__git_clone_src_dir}"
  gitBranchExists ${__git_clone_branch}
  if ! [ "$?" -eq 1 ]; then
    echR "      branch not found"
  else
    echG "      - branch"  
    echC "          requested: ${__git_clone_branch}"  
    echC "          current: $(gitBranch)"
    gitCheckOut ${__git_clone_branch}
    if ! [ "$?" -eq 1 ]; then
    echR "          branch not found"
    fi
    echY "          now: $(gitBranch)"
  fi
  echG "  Finished"
  export __func_return=${__git_clone_src_dir}
  return 1
}
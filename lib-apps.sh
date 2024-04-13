#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh

export APP_REQUIRED_NAMES="ip ping telnet curl wget jq mc mcedit zip 7zz tmux git awk"
export APP_REQUIRED_PACKAGES_APT="coreutils inetutils-ping iputils-ping telnet curl wget jq mc mcedit zip 7zip tmux git nfs-kernel-server nfs-common"

export APP_SERVER_NAMES="htop atop ufw libyaml-cpp-dev"
export APP_SERVER_PACKAGES_APT="htop atop ufw libyaml-cpp-dev"

export APP_DEVELOPMENT_NAMES="yarnpkg meld sdkmanager"
export APP_DEVELOPMENT_PACKAGES_APT="yarnpkg meld sdkmanager"

export APP_NAMES="${APP_REQUIRED_NAMES} ${APP_DEVELOPMENT_NAMES} ${APP_SERVER_NAMES}"
export APP_NAMES_PACKAGES_APT="${APP_REQUIRED_PACKAGES_APT} ${APP_SERVER_PACKAGES_APT} ${APP_DEVELOPMENT_PACKAGES_APT}"

function __app_install()
{
  unset __func_return
  local __extra_apps=($(echo "$@" | sed 's/ /\n/g'  | sort --unique))
  if [[ "${__extra_apps[@]}" == "" ]]; then
    return 1;
  elif [[ "$(which apt)" == "" ]]; then
    export __func_return="APT: no found"
    return 0;
  else
    echB "  SUDO request"
    echY "  +===========================+"
    echY "  +          *******          +"
    echY "  +***********Alert***********+"
    echY "  +          *******          +"
    echY "  +===========================+"
    echo ""
    echG "  [ENTER] to continue"
    echo ""
    sudoSet
    if ! [ "$?" -eq 1 ]; then
      echR "  +===========================+"
      echR "  +         *********         +"
      echR "  +*********SUDO Fail*********+"
      echR "  +         *********         +"
      echR "  +===========================+"
      echo ""
      return 0
    fi

    local __app=
    for __app in "${__extra_apps[@]}"
    do
      local __cmd="sudo apt install -y ${__app}"
      echY "  ${__cmd}"
      ${__cmd}
    done
    return 1;  
  fi
}

function __app_installed_check()
{
  unset __func_return
  echM "Applications verify"
  local __apps=($(echo "$@" | sed 's/ /\n/g'  | sort --unique))
  local __app=
  for __app in "${__apps[@]}"
  do
    if [[ $(which ${__app}) == "" ]]; then
      echC "  - ${__app}: ${COLOR_RED}Not found"
      export __func_return="${__func_return} ${__app}"
    else
      echC "  - ${__app}: ${COLOR_GREEN}Installed"
    fi
  done
  if [[ ${__func_return} != "" ]]; then
    echG "Finished"
    return 0;
  fi
  echG "Finished"
  return 1;
  
}

function appInstallRequired()
{
  __app_install "${APP_REQUIRED_PACKAGES_APT}"
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  return 1;
}

function appInstallForServer()
{
  __app_install "${APP_SERVER_PACKAGES_APT}"
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  return 1;
}

function appInstallForDevelop()
{
  __app_install "${APP_DEVELOPMENT_PACKAGES_APT}"
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  return 1;
}

function appInstallRequiredVerify()
{
  __app_installed_check "${APP_REQUIRED_NAMES}"
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  return 1;
}

function appInstallMain()
{
  local __options=(Quit)
  local __options+=(Required)
  local __options+=(For-Servers)
  local __options+=(For-Development)
  local __options+=(Docker)
  while :
  do
    unset __func_return
    clearTerm
    echM $'\n'"Applications menu"$'\n'
    local __apps=(${APP_NAMES})
    local __app=
    for __app in "${__apps[@]}"
    do
      if [[ $(which ${__app}) == "" ]]; then
        echC "  - ${__app}: ${COLOR_RED}Not found"
      fi
    done
    echM ""

    PS3=$'\n'"Choose option:"
    local __opt
    select __opt in "${__options[@]}"
    do
      if [[ ${__opt} == "Quit" ]]; then
        return 1
      fi
      echo ""
      echM "Action selected: ${COLOR_YELLOW}[${__opt}]"
      echo ""

      if [[ ${__opt} == "Required" ]]; then
        appInstallRequired
      elif [[ ${__opt} == "For-Servers" ]]; then
        appInstallForServer
      elif [[ ${__opt} == "For-Development" ]]; then
        appInstallForDevelop
      else
        echR "Invalid __option ${__opt}"
      fi
      if ! [ "$?" -eq 1 ]; then
        echR "Fail on calling option: [${__opt}], ${__func_return}"
      fi
      echB
      echG "[ENTER] to continue"
      echG
      read
      break
    done
  done

}

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
. ${BASH_BIN}/lib-selector.sh

__private_default_storage_inited=false
__private_default_storage_path=/mnt/stack-storage

function __private_sudo_check()
{
  if [[ ${__sudoed} != true ]]; then
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
  fi
  __sudoed=true
  return 1;
}

function __private_storage_is_valid()
{
  unset __func_return
  if [[ ${STACK_STORAGE_PATH} == "" ]]; then
    export __func_return="Invalid env \${STACK_STORAGE_PATH}"
    return 0
  elif [[ ${STACK_STORAGE_PATH} == "" ]]; then
    export __func_return="No exists: \${STACK_STORAGE_PATH}: ${STACK_STORAGE_PATH}"
    return 0
  elif ! [[ -d ${STACK_STORAGE_PATH} ]]; then
    export __func_return="No exists: \${STACK_STORAGE_PATH}: ${STACK_STORAGE_PATH}"
    return 0
  else
    return 1;
  fi
}

function __private_storage_remove()
{
  return 1;
}

function __private_storage_reset()
{
  return 1;
}

function storageInit()
{
  unset __func_return
  export __path=${1}
  if [[ ${__path} == "" ]]; then
    local __path=${__private_default_storage_path}
  fi

  export STACK_STORAGE_PATH=${__path}

  if [[ ${STACK_STORAGE_PATH} == "" ]]; then
    export __func_return="Storage: invalid storage init, \${__path} is empty"
    return 0
  fi

  return 1;
}

function __private_storage_delete()
{
  __private_sudo_check
  if ! [ "$?" -eq 1 ]; then
    return 1;
  fi

  __private_storage_is_valid
  if ! [ "$?" -eq 1 ]; then
    echR "\${__func_return}"
    export __func_return="Storage: ${__func_return}"
    return 0;
  else
    clearTerm
    __private_print_os_information
    local __runner_menu_environment=${1} 
    local __runner_menu_target=${2}

    cd ${STACK_STORAGE_PATH}

    local __options="Back $(ls)"
    local __options=(${__options})
    echM $'\n'"Storage delete options"$'\n'
    PS3=$'\n'"Choose option:"
    local __opt=
    select __opt in "${__options[@]}"
    do
      if [[ ${__opt} == "Back" ]]; then
        return 1;
      else
        local __path_to_remove=${STACK_STORAGE_PATH}/${__opt}
        selectorYesNo " Confirme delete storage path: ${__path_to_remove}"
        if ! [ "$?" -eq 1 ]; then
          continue;
        fi
        sudo rm -rf ${__path_to_remove}
      fi
      return 1
    done
    echG
    echG "Finished"
    echG ""
    echG "[ENTER] to continue"
    echG
    read
  fi
  return 1;
}

function storageMainMenu()
{
  unset __sudoed
  unset __func_return
  __private_storage_is_valid
  if ! [ "$?" -eq 1 ]; then
    export __func_return="Storage: ${__func_return}"
    return 0;
  fi
  clearTerm
  __private_print_os_information
  local __runner_menu_environment=${1} 
  local __runner_menu_target=${2}

  local __options=(Back Storage-Reset Storage-Delete)
  echM $'\n'"Storage Meno"$'\n'
  PS3=$'\n'"Choose option:"
  local __opt=
  select __opt in "${__options[@]}"
  do
    if [[ ${__opt} == "Back" ]]; then
      return 1;
    elif [[ ${__opt} == "Storage-Reset" ]]; then
      __private_storage_reset
    elif [[ ${__opt} == "Storage-Delete" ]]; then
      __private_storage_delete      
    else
      echR "Invalid option ${__opt}"
    fi
    echB
    echG "[ENTER] to continue"
    echG
    read
    break
  done
  return 1
}

storageInit ${__private_default_storage_path}
storageMainMenu
echB "${__func_return}"
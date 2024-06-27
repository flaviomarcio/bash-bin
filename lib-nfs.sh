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
. ${BASH_BIN}/lib-util-date.sh

function __nfs_env_check()
{
  unset __func_return  
  if [[ ${STACK_NFS_ENABLED} != true ]]; then
    export __func_return="NFS is not enabled, check env \${STACK_NFS_ENABLED}"  
  elif [[ ${STACK_NFS_SERVER} == "" ]]; then
    export __func_return="Invalid env \${STACK_NFS_SERVER}"    
  elif [[ ${STACK_NFS_MOUNT_DIR} == "" ]]; then
    export __func_return="Invalid env \${STACK_NFS_MOUNT_DIR}"  
  elif [[ ${STACK_NFS_REMOTE_DATA_DIR} == "" ]]; then
    export __func_return="Invalid env \${STACK_NFS_REMOTE_DATA_DIR}"
  else
    return 1;
  fi
  return 0;
}

function nfsIsMounted()
{
  __nfs_env_check
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  echo "mount | grep "${STACK_NFS_MOUNT_DIR}""
  local __check=$(mount | grep "${STACK_NFS_MOUNT_DIR}")
  if [[ ${__check} == "" ]]; then
    return 0;
  fi
  return 1;
}

function nfsMount()
{
  __nfs_env_check
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  unset __func_return
  nfsIsMounted
  if ! [ "$?" -eq 1 ]; then
    mkdir -p ${STACK_NFS_MOUNT_DIR}
    sudo mount -t nfs ${STACK_NFS_SERVER}:${STACK_NFS_REMOTE_DATA_DIR} ${STACK_NFS_MOUNT_DIR} -o rw,sync
    nfsIsMounted
    if ! [ "$?" -eq 1 ]; then
        export __func_return="NFS unmounted: ${__func_return}, mount -t nfs ${STACK_NFS_SERVER}:${STACK_NFS_REMOTE_DATA_DIR} ${STACK_NFS_MOUNT_DIR} -o rw,sync"
        return 0;
    fi
  fi
  return 1;
}

function nfsMountPoint()
{
  __nfs_env_check
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  return 1;
}

function nfsVerify()
{
 
  unset __func_return
  if [[ ${STACK_NFS_ENABLED} != true ]]; then
    return 1;
  fi

  echM ""
  echM "NFS verify"
  __nfs_env_check
  if ! [ "$?" -eq 1 ]; then
    echR "fail on calling __nfs_env_check: ${__func_return}"
    return 0;
  fi

  nfsIsMounted
  if ! [ "$?" -eq 1 ]; then
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
      return 0;
    else
      echB "  Mounting"
      echB "    NFS:"
      echC "      - server......: ${COLOR_YELLOW}${STACK_NFS_SERVER}"
      echC "      - remote-dir..: ${COLOR_YELLOW}${STACK_NFS_REMOTE_DATA_DIR}"
      echC "      - mount-point.: ${COLOR_YELLOW}${STACK_NFS_MOUNT_DIR}"
      echY "      - Executing:"
      echC "        - ${COLOR_BLUE}mount ${COLOR_CIANO}-t nfs ${COLOR_YELLOW}${STACK_NFS_SERVER}${COLOR_CIANO}:${COLOR_YELLOW}${STACK_NFS_REMOTE_DATA_DIR} ${STACK_NFS_MOUNT_DIR}"
      nfsMount
      if ! [ "$?" -eq 1 ]; then
        echR "  fail on calling nfsMount: ${__func_return}"
        return 0;
      else
        echG "        Successful"
      fi
    fi
  fi
  echC "  - NFS ${COLOR_GREEN}OK"
  echG "Finished"
  return 1;
}
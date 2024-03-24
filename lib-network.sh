#!/bin/bash

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh

function dnsToAddress()
{
  echo $(ping -c 1 localhost | grep PING | awk '{print $3}' | tr -d '()')
}


function hostIsAvailable()
{
  local __host=${1}
  local __port=${2}
  if [[ ${__host} == "" ]] ; then
    echo "Invalid \${__host}";
    return 0;
  fi

  if [[ ${__port} == "" ]] ; then
    echo "Invalid \${__port}";
    return 0;
  fi

  local __host_address=$(dnsToAddress ${__host})
  local __check=$(nc -zv ${__host_address} ${__port} 2>&1)
  if [[ $(echo ${__check} | grep 'succeeded') == "" ]]; then
    return 0;
  fi

  return 1;  
}

function hostWaitAvailable()
{
  local __host=${1}
  local __port=${2}
  local __seconds=${3}
  local __message="${4}"

  if [[ ${__host} == "" ]] ; then
    echR "Invalid \${__host}";
    return 0;
  fi

  if [[ ${__port} == "" ]] ; then
    echR "Invalid \${__port}";
    return 0;
  fi

  local __host_address=$(dnsToAddress ${__host})
  if [[ ${__host_address} == "" ]]; then
    echR "No address for host:[${__host}]";
    return 0;
  fi

  if [[ ${__seconds} == "" ]]; then
    local __seconds=0;
  fi

  if [ "$__seconds" -lt 0 ]; then
    hostIsAvailable "${__host}" "${__port}"
    if ! [ "$?" -eq 1 ]; then
      return 0;
    fi   
    return 1;
  fi
  
  i=1
  while :
  do 
    hostIsAvailable "${__host}" "${__port}"
    if ! [ "$?" -eq 1 ]; then
      if [[ ${__message} != "" ]]; then
        echY "${__message}, [${__host}]:[${__port}] [${i}s]/[${__seconds}s]"
      fi
      sleep 1
    else
      return 1;
    fi

    if [ "${i}" -lt ${__seconds} ]; then
      let "i=${i} + 1"
    else
      break      
    fi
    
  done

  return 0;  
}
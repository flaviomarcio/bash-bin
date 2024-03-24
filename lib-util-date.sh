#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh


function parserTime()
{
  local __args=($@)
  local __out=
  local __arg=
  for __arg in "${__args[@]}"
  do
    __arg=$(toLower ${__arg})
    local __type=${__arg: -1}
    if [[ ${__type} == "s" || ${__type} == "m" || ${__type} == "h" || ${__type} == "d" || ${__type} == "m" || ${__type} == "y" ]]; then
      local __time=${__arg:0:-1}
    else
      local __time=${__arg}
    fi
    local __time=$((${__time} * 1)) #check error

    if [[ ${__type} == "s" ]]; then
      __time=$((1000 * ${__time}))
    elif [[ ${__type} == "m" ]]; then
      __time=$((1000 * ${__time} * 60 ))
    elif [[ ${__type} == "h" ]]; then
      __time=$((1000 * ${__time} * 60 * 60 ))
    elif [[ ${__type} == "d" ]]; then
      __time=$((1000 * ${__time} * 60 * 60 * 24))
    elif [[ ${__type} == "y" ]]; then
      __time=$((1000 * ${__time} * 60 * 60 * 24 * 365))
    else
      __time=${__time}
    fi
    local __out="${__out} ${__time}"

  done

  echo ${__out}
}
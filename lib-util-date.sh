#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh


function parserTime()
{
  local __parserTime_args=($@)
  local __parserTime_out=
  for __parserTime_arg in "${__parserTime_args[@]}"
  do
    __parserTime_arg=$(toLower ${__parserTime_arg})
    local __parserTime_type=${__parserTime_arg: -1}
    if [[ ${__parserTime_type} == "s" || ${__parserTime_type} == "m" || ${__parserTime_type} == "h" || ${__parserTime_type} == "d" || ${__parserTime_type} == "m" || ${__parserTime_type} == "y" ]]; then
      local __parserTime_time=${__parserTime_arg:0:-1}
    else
      local __parserTime_time=${__parserTime_arg}
    fi
    local __parserTime_time=$((${__parserTime_time} * 1)) #check error

    if [[ ${__parserTime_type} == "s" ]]; then
      __parserTime_time=$((1000 * ${__parserTime_time}))
    elif [[ ${__parserTime_type} == "m" ]]; then
      __parserTime_time=$((1000 * ${__parserTime_time} * 60 ))
    elif [[ ${__parserTime_type} == "h" ]]; then
      __parserTime_time=$((1000 * ${__parserTime_time} * 60 * 60 ))
    elif [[ ${__parserTime_type} == "d" ]]; then
      __parserTime_time=$((1000 * ${__parserTime_time} * 60 * 60 * 24))
    elif [[ ${__parserTime_type} == "y" ]]; then
      __parserTime_time=$((1000 * ${__parserTime_time} * 60 * 60 * 24 * 365))
    else
      __parserTime_time=${__parserTime_time}
    fi
    __parserTime_out="${__parserTime_out} ${__parserTime_time}"

  done

  echo ${__parserTime_out}
}
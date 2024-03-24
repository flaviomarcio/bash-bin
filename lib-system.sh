#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh

function sudoSet()
{
  __sudo_set_out=$(sudo id -u)
  if [[ ${__sudo_set_out} == 0 ]]; then
    return 1
  fi
  return 0
}

function systemIPvPrepare()
{
  export HOST_IP="127.0.0.1"
  if [[ -d /mnt ]]; then
      export PUBLIC_HOST_IPv4=$(ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')
  else
      export PUBLIC_HOST_IPv4=$(ipconfig.exe | grep -a IPv4 | grep -a 192 | sed 's/ //g' | sed 's/Endere□oIPv4//g' | awk -F ':' '{print $2}')
  fi
}

function systemDNSEssentialList()
{
  unset __func_return
  local __func_return="${__func_return} activemq"
  local __func_return="${__func_return} admin"
  local __func_return="${__func_return} cadvisor"
  local __func_return="${__func_return} cadvisorZFS"
  local __func_return="${__func_return} grafana"
  local __func_return="${__func_return} haproxy"
  local __func_return="${__func_return} jenkins"
  local __func_return="${__func_return} keycloak"
  local __func_return="${__func_return} loki"
  local __func_return="${__func_return} minio"
  local __func_return="${__func_return} mysql"
  local __func_return="${__func_return} nexus"
  local __func_return="${__func_return} opentelemetry"
  local __func_return="${__func_return} portainer"
  local __func_return="${__func_return} postgres-admin"
  local __func_return="${__func_return} postgres"
  local __func_return="${__func_return} prometheus"
  local __func_return="${__func_return} promtail"
  local __func_return="${__func_return} rabbitmq"
  local __func_return="${__func_return} redis"
  local __func_return="${__func_return} registry"
  local __func_return="${__func_return} tempo"
  local __func_return="${__func_return} traefik"
  local __func_return="${__func_return} vault"
  local __func_return="${__func_return} wikijs"
  local __func_return="${__func_return} wireguard"
  echo ${__func_return}
  return 1

}

function systemDNSList()
{
  local __inc_pub=${1}
  if [[ ${STACK_PREFIX} == "" ]]; then
    return 0
  fi
  local __dns_list=" $(systemDNSEssentialList) ${STACK_DNS_LIST} "
  local __dns_list=$(echo ${__dns_list} | sort)
  local __dns_list=(${__dns_list})
  local __dns_out=
  local __dns=
  for __dns in "${__dns_list[@]}"
  do
    local __dns_out="${__dns_out} ${STACK_PREFIX_HOST}${__dns}"
    if [[ ${__inc_pub} == true ]]; then
      local __dns_out="${__dns_out} ${STACK_PREFIX_HOST}${__dns}.${STACK_DOMAIN}"
    fi
  done
  echo ${__dns_out}
  return 1
}

function systemETCHostApply()
{
  return 1
  local ____tag=${1}
  if [[ ${ROOT_APPLICATIONS_DIR} == "" ]]; then
    return 0;
  fi
  if [[ ${____tag} == "" ]]; then
    return 0;
  fi
  local ____dns_list=( $(systemDNSList true) )
  export ____hosts=/etc/hosts
  export ____hosts_BKP=${ROOT_APPLICATIONS_DIR}/hosts.backup
  export ____hosts_TMP=${ROOT_APPLICATIONS_DIR}/hosts.temp

  cp -rf ${____hosts} ${____hosts_BKP}
  cp -rf ${____hosts} ${____hosts_TMP}
  sed -i '/^\s*$/d' ${____hosts_TMP}
  sed -i '/srv-/d' ${____hosts_TMP}
  sed -i '/mcs-/d' ${____hosts_TMP}
  sed -i "/${____tag}/d" ${____hosts_TMP}

  if ! [[ -f ${____hosts_BKP} ]]; then
    echR "    +===========================+"
    echR "    +        ***********        +"
    echR "    +********Backup Fail********+"
    echR "    +        ***********        +"
    echR "    +===========================+"
    echo ""
    return 0
  fi

  echM "  DNS inserting"
  echC "    - Target: ${____hosts_TMP}"
  echC "    - Backup: ${____hosts_BKP}"
  echB "    Prepare"
  echY "      - cp -rf ${____hosts} ${____hosts_TMP}"
  echY "      - cp -rf ${____hosts} ${____hosts_BKP}"
  echB "    Cleanup"
  echY "      - sed -i '/^\s*$/d' ${____hosts_TMP}"
  echY "      - sed -i '/^\s*$/d' ${____hosts_TMP}"
  echY "      - sed -i '/srv-/d' ${____hosts_TMP}"
  echY "      - sed -i '/mcs-/d' ${____hosts_TMP}"
  echY "      - sed -i '/adm-/d' ${____hosts_TMP}"
  echG "    Finished"
  echo ""
  echB "    SUDO request"
  echY "    +===========================+"
  echY "    +          *******          +"
  echY "    +***********Alert***********+"
  echY "    +          *******          +"
  echY "    +===========================+"
  echo ""
  echG "       [ENTER] para continuar"
  echo ""
  read
  sudoSet
  if ! [ "$?" -eq 1 ]; then
    echR "    +===========================+"
    echR "    +         *********         +"
    echR "    +*********SUDO Fail*********+"
    echR "    +         *********         +"
    echR "    +===========================+"
    echo ""
    return 0
  fi

  echB "    DNS Change"
  echC "      - Target: ${____hosts_TMP}"
  echB "      Actions"

  echo "">>${____hosts_TMP}
  local __dns=
  for __dns in "${____dns_list[@]}"
  do
    local __cmd="echo \"127.0.0.1 ${__dns}\">>${____hosts_TMP}"
    echY "          ${__cmd}"
    echo "127.0.0.1 ${__dns}">>${____hosts_TMP}
  done

  echB "    DNS Apply"
  echC "      - Target: ${____hosts}"
  echC "      - Source: ${____hosts_TMP}"
  echC "      - Backup: ${____hosts_BKP}"
  echC "      Action"
  echY "        - sudo cp -rf ${____hosts_TMP} ${____hosts}"
  sudo cp -rf ${____hosts_TMP} ${____hosts}
  echG "    Finished"

  echo ""
  echG "  Finished"
  echo ""
  return 1
}

function systemETCHostRemove()
{
  local __tag=${1}
  if [[ ${ROOT_APPLICATIONS_DIR} == "" ]]; then
    return 0;
  fi
  if [[ ${__tag} == "" ]]; then
    return 0;
  fi
  local __dns_list=( $(systemDNSList) )
  export __hosts=/etc/hosts
  export __hosts_BKP=${ROOT_APPLICATIONS_DIR}/hosts.backup
  export __hosts_TMP=${ROOT_APPLICATIONS_DIR}/hosts.temp

  cp -rf ${__hosts} ${__hosts_BKP}
  cp -rf ${__hosts} ${__hosts_TMP}

  sed -i "/${__tag}/d" ${__hosts_TMP}

  if ! [[ -f ${__hosts_BKP} ]]; then
    echR "    +===========================+"
    echR "    +        ***********        +"
    echR "    +********Backup Fail********+"
    echR "    +        ***********        +"
    echR "    +===========================+"
    echo ""
    return 0
  fi

  echM "  DNS inserting"
  echC "    - Target: ${__hosts_TMP}"
  echC "    - Backup: ${__hosts_BKP}"
  echB "    Prepare"
  echY "      - cp -rf ${__hosts} ${__hosts_TMP}"
  echY "      - cp -rf ${__hosts} ${__hosts_BKP}"
  echG "    Finished"
  echo ""
  echB "    SUDO request"
  echY "    +===========================+"
  echY "    +          *******          +"
  echY "    +***********Alert***********+"
  echY "    +          *******          +"
  echY "    +===========================+"
  echo ""
  echG "       [ENTER] para continuar"
  echo ""
  read
  sudoSet
  if ! [ "$?" -eq 1 ]; then
    echR "    +===========================+"
    echR "    +         *********         +"
    echR "    +*********SUDO Fail*********+"
    echR "    +         *********         +"
    echR "    +===========================+"
    echo ""
    return 0
  fi

  echB "    DNS Change"
  echC "      - Target: ${__hosts_TMP}"
  echB "      Cleanup"
  echY "        - sed -i '/${__tag}/d' ${__hosts_TMP}"
  echB "    DNS Apply"
  echC "      - Target: ${__hosts}"
  echC "      - Source: ${__hosts_TMP}"
  echC "      - Backup: ${__hosts_BKP}"
  echC "      Action"
  echY "        - sudo cp -rf ${__hosts_TMP} ${__hosts}"
  sudo cp -rf ${__hosts_TMP} ${__hosts}
  echG "    Finished"

  echo ""
  echG "  Finished"
  echo ""
  return 1
}

function systemETCHostPrint()
{
  export ____hosts=/etc/hosts
  local __dns_list=$(systemDNSList)
  local __dns_list=(${__dns_list})
  echM "  DNS Print"
  echB "    DNS list"
  local __dns=
  for __dns in "${__dns_list[@]}"
  do
    echC "      ${__dns}" 
  done
  echo ""
  echB "    ${____hosts} list"
  local __dns=
  for __dns in "${__dns_list[@]}"
  do
    echY "      127.0.0.1 ${__dns}"
  done
  echo ""
  echG "  Finished"
  echo ""
  echo
}

function main()
{
  systemIPvPrepare
}

main
#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  BASH_BIN=${PWD}
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
  __func_return=
  __func_return="${__func_return} activemq"
  __func_return="${__func_return} admin"
  __func_return="${__func_return} cadvisor"
  __func_return="${__func_return} cadvisorZFS"
  __func_return="${__func_return} grafana"
  __func_return="${__func_return} haproxy"
  __func_return="${__func_return} jenkins"
  __func_return="${__func_return} keycloak"
  __func_return="${__func_return} loki"
  __func_return="${__func_return} minio"
  __func_return="${__func_return} mysql"
  __func_return="${__func_return} nexus"
  __func_return="${__func_return} opentelemetry"
  __func_return="${__func_return} portainer"
  __func_return="${__func_return} postgres-admin"
  __func_return="${__func_return} postgres"
  __func_return="${__func_return} prometheus"
  __func_return="${__func_return} promtail"
  __func_return="${__func_return} rabbitmq"
  __func_return="${__func_return} redis"
  __func_return="${__func_return} registry"
  __func_return="${__func_return} tempo"
  __func_return="${__func_return} traefik"
  __func_return="${__func_return} vault"
  __func_return="${__func_return} wikijs"
  __func_return="${__func_return} wireguard"
  echo ${__func_return}
  return 1

}

function systemDNSList()
{
  if [[ ${STACK_PREFIX} == "" ]]; then
    return 0
  fi
  __systemDNSList_dns_list=" $(systemDNSEssentialList) ${STACK_DNS_LIST} "
  __systemDNSList_dns_list=$(echo ${__systemDNSList_dns_list} | sort)
  __systemDNSList_dns_list=(${__systemDNSList_dns_list})
  __systemDNSList_dns_out=
  for __systemDNSList_dns in "${__systemDNSList_dns_list[@]}"
  do
    __systemDNSList_dns_out="${__systemDNSList_dns_out} ${STACK_PREFIX}-${__systemDNSList_dns}"
  done
  echo ${__systemDNSList_dns_out}
  return 1
}

function systemETCHostApply()
{
  if [[ ${ROOT_APPLICATIONS_DIR} == "" ]]; then
    return 1;
  fi
  __systemETCHostApply_dns_list=( $(systemDNSList) )
  export __systemETCHostApply_hosts=/etc/hosts
  export __systemETCHostApply_hosts_BKP=${ROOT_APPLICATIONS_DIR}/hosts.backup
  export __systemETCHostApply_hosts_TMP=${ROOT_APPLICATIONS_DIR}/hosts.temp

  cp -rf ${__systemETCHostApply_hosts} ${__systemETCHostApply_hosts_BKP}
  cp -rf ${__systemETCHostApply_hosts} ${__systemETCHostApply_hosts_TMP}
  sed -i '/^\s*$/d' ${__systemETCHostApply_hosts_TMP}
  sed -i '/srv-/d' ${__systemETCHostApply_hosts_TMP}
  sed -i '/mcs-/d' ${__systemETCHostApply_hosts_TMP}

  if ! [[ -f ${__systemETCHostApply_hosts_BKP} ]]; then
    echR "    +===========================+"
    echR "    +        ***********        +"
    echR "    +********Backup Fail********+"
    echR "    +        ***********        +"
    echR "    +===========================+"
    echo ""
    return 0
  fi

  echM "  DNS inserting"
  echC "    - Target: ${__systemETCHostApply_hosts_TMP}"
  echC "    - Backup: ${__systemETCHostApply_hosts_BKP}"
  echB "    Prepare"
  echY "      - cp -rf ${__systemETCHostApply_hosts} ${__systemETCHostApply_hosts_TMP}"
  echY "      - cp -rf ${__systemETCHostApply_hosts} ${__systemETCHostApply_hosts_BKP}"
  echB "    Cleanup"
  echY "      - sed -i '/^\s*$/d' ${__systemETCHostApply_hosts_TMP}"
  echY "      - sed -i '/srv-/d' ${__systemETCHostApply_hosts_TMP}"
  echY "      - sed -i '/mcs-/d' ${__systemETCHostApply_hosts_TMP}"
  echY "      - sed -i '/adm-/d' ${__systemETCHostApply_hosts_TMP}"
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
  echC "      - Target: ${__systemETCHostApply_hosts_TMP}"
  echB "      Actions"

  echo "">>${__systemETCHostApply_hosts_TMP}
  for systemETCHostApply_dns in "${__systemETCHostApply_dns_list[@]}"
  do
    CMD="echo \"127.0.0.1 ${systemETCHostApply_dns}\">>${__systemETCHostApply_hosts_TMP}"
    echY "          - ${CMD}"
    echo "127.0.0.1 ${systemETCHostApply_dns}">>${__systemETCHostApply_hosts_TMP}
  done

  echB "    DNS Apply"
  echC "      - Target: ${__systemETCHostApply_hosts}"
  echC "      - Source: ${__systemETCHostApply_hosts_TMP}"
  echC "      - Backup: ${__systemETCHostApply_hosts_BKP}"
  echC "      Action"
  echY "        - sudo cp -rf ${__systemETCHostApply_hosts_TMP} ${__systemETCHostApply_hosts}"
  sudo cp -rf ${__systemETCHostApply_hosts_TMP} ${__systemETCHostApply_hosts}
  echG "    Finished"

  echo ""
  echG "  Finished"
  echo ""
  return 1
}

function systemETCHostRemove()
{
  __systemETCHostRemove_tag=${1}
  if [[ ${ROOT_APPLICATIONS_DIR} == "" ]]; then
    return 0;
  fi
  if [[ ${__systemETCHostRemove_tag} == "" ]]; then
    return 0;
  fi
  __systemETCHostRemove_dns_list=( $(systemDNSList) )
  export __systemETCHostRemove_hosts=/etc/hosts
  export __systemETCHostRemove_hosts_BKP=${ROOT_APPLICATIONS_DIR}/hosts.backup
  export __systemETCHostRemove_hosts_TMP=${ROOT_APPLICATIONS_DIR}/hosts.temp

  cp -rf ${__systemETCHostRemove_hosts} ${__systemETCHostRemove_hosts_BKP}
  cp -rf ${__systemETCHostRemove_hosts} ${__systemETCHostRemove_hosts_TMP}

  sed -i '/${__systemETCHostRemove_tag}/d' ${__systemETCHostRemove_hosts_TMP}

  if ! [[ -f ${__systemETCHostRemove_hosts_BKP} ]]; then
    echR "    +===========================+"
    echR "    +        ***********        +"
    echR "    +********Backup Fail********+"
    echR "    +        ***********        +"
    echR "    +===========================+"
    echo ""
    return 0
  fi

  echM "  DNS inserting"
  echC "    - Target: ${__systemETCHostRemove_hosts_TMP}"
  echC "    - Backup: ${__systemETCHostRemove_hosts_BKP}"
  echB "    Prepare"
  echY "      - cp -rf ${__systemETCHostRemove_hosts} ${__systemETCHostRemove_hosts_TMP}"
  echY "      - cp -rf ${__systemETCHostRemove_hosts} ${__systemETCHostRemove_hosts_BKP}"
  echB "    Cleanup"
  echY "      - sed -i '/${__systemETCHostRemove_tag}/d' ${__systemETCHostRemove_hosts_TMP}"
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
  echC "      - Target: ${__systemETCHostRemove_hosts_TMP}"
  echB "      Actions"

  echo "">>${__systemETCHostRemove_hosts_TMP}
  for systemETCHostRemove_dns in "${__systemETCHostRemove_dns_list[@]}"
  do
    CMD="echo \"127.0.0.1 ${systemETCHostRemove_dns}\">>${__systemETCHostRemove_hosts_TMP}"
    echY "          - ${CMD}"
    echo "127.0.0.1 ${systemETCHostRemove_dns}">>${__systemETCHostRemove_hosts_TMP}
  done

  echB "    DNS Apply"
  echC "      - Target: ${__systemETCHostRemove_hosts}"
  echC "      - Source: ${__systemETCHostRemove_hosts_TMP}"
  echC "      - Backup: ${__systemETCHostRemove_hosts_BKP}"
  echC "      Action"
  echY "        - sudo cp -rf ${__systemETCHostRemove_hosts_TMP} ${__systemETCHostRemove_hosts}"
  sudo cp -rf ${__systemETCHostRemove_hosts_TMP} ${__systemETCHostRemove_hosts}
  echG "    Finished"

  echo ""
  echG "  Finished"
  echo ""
  return 1
}

function systemETCHostPrint()
{
  export __systemETCHostApply_hosts=/etc/hosts
  __systemETCHostPrint_dns_list=$(systemDNSList)
  __systemETCHostPrint_dns_list=(${__systemETCHostPrint_dns_list})
  echM "  DNS Print"
  echB "    DNS list"
  for __systemETCHostPrint_dns in "${__systemETCHostPrint_dns_list[@]}"
  do
    echC "      ${__systemETCHostPrint_dns}" 
  done
  echo ""
  echB "    ${__systemETCHostApply_hosts} list"
  for __systemETCHostPrint_dns in "${__systemETCHostPrint_dns_list[@]}"
  do
    echY "      127.0.0.1 ${__systemETCHostPrint_dns}"
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
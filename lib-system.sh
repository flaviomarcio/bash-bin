#!/bin/bash

. lib-strings.sh

function systemIPvPrepare()
{
  export HOST_IP="127.0.0.1"
  if [[ -d /mnt ]]; then
      export PUBLIC_HOST_IPv4=$(ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')
  else
      export PUBLIC_HOST_IPv4=$(ipconfig.exe | grep -a IPv4 | grep -a 192 | sed 's/ //g' | sed 's/Endere□oIPv4//g' | awk -F ':' '{print $2}')
  fi
}

function systemDNSList()
{
  if [[ ${PUBLIC_SERVICES_PREFIX} == "" ]]; then
    return 0
  fi
  if [[ ${PUBLIC_SERVICES_NAME} == "" ]]; then
    return 0
  fi

  DNSList=(${PUBLIC_SERVICES_NAME})
  DNSOut=
  for DNS in "${DNSList[@]}"
  do
    DNSOut="${DNSOut} ${PUBLIC_SERVICES_PREFIX}-${DNS}"
  done
  echo ${DNSOut}
  return 1
}

function systemETCHostApply()
{
  DNSList=( $(systemDNSList) )
  export ETC_HOST=/etc/hosts
  export ETC_HOST_BKP=${PUBLIC_DIR_DATA}/hosts.backup
  export ETC_HOST_TMP=${PUBLIC_DIR_DATA}/hosts.temp

  cp -rf ${ETC_HOST} ${ETC_HOST_BKP}
  cp -rf ${ETC_HOST} ${ETC_HOST_TMP}
  sed -i '/^\s*$/d' ${ETC_HOST_TMP}
  sed -i '/srv-/d' ${ETC_HOST_TMP}
  sed -i '/mcs-/d' ${ETC_HOST_TMP}

  if ! [[ -f ${ETC_HOST_BKP} ]]; then
    echR "    +===========================+"
    echR "    +        ***********        +"
    echR "    +********Backup Fail********+"
    echR "    +        ***********        +"
    echR "    +===========================+"
    echo ""
    return 0
  fi

  echM "    DNS inserting"
  echC "      - Target: ${ETC_HOST_TMP}"
  echC "      - Backup: ${ETC_HOST_BKP}"
  echB "      Prepare"
  echY "        - cp -rf ${ETC_HOST} ${ETC_HOST_TMP}"
  echY "        - cp -rf ${ETC_HOST} ${ETC_HOST_BKP}"
  echB "      Cleanup"
  echY "        - sed -i '/^\s*$/d' ${ETC_HOST_TMP}"
  echY "        - sed -i '/srv-/d' ${ETC_HOST_TMP}"
  echY "        - sed -i '/mcs-/d' ${ETC_HOST_TMP}"
  echY "        - sed -i '/adm-/d' ${ETC_HOST_TMP}"
  echG "      Finished"
  echo ""
  echB "      SUDO request"
  echY "      +===========================+"
  echY "      +          *******          +"
  echY "      +**********Atenção**********+"
  echY "      +          *******          +"
  echY "      +===========================+"
  echo ""
  echG "         [ENTER] para continuar"
  echo ""
  read
  sudoSet
  if ! [ "$?" -eq 1 ]; then
    echR "      +===========================+"
    echR "      +         *********         +"
    echR "      +*********SUDO Fail*********+"
    echR "      +         *********         +"
    echR "      +===========================+"
    echo ""
    return 0
  fi

  echB "      DNS Change"
  echC "        - Target: ${ETC_HOST_TMP}"
  echB "        Actions"

  echo "">>${ETC_HOST_TMP}
  for DNS in "${DNSList[@]}"
  do
    CMD="echo \"127.0.0.1 ${DNS}\">>${ETC_HOST_TMP}"
    echY "          - ${CMD}"
    echo "127.0.0.1 ${DNS}">>${ETC_HOST_TMP}
  done

  echB "      DNS Apply"
  echC "        - Target: ${ETC_HOST}"
  echC "        - Source: ${ETC_HOST_TMP}"
  echC "        - Backup: ${ETC_HOST_BKP}"
  echC "        Action"
  echY "          - sudo cp -rf ${ETC_HOST_TMP} ${ETC_HOST}"
  sudo cp -rf ${ETC_HOST_TMP} ${ETC_HOST}
  echG "      Finished"

  echo ""
  echG "    Finished"
  echo ""
  return 1
}

function systemETCHostPrint()
{
  export ETC_HOST=/etc/hosts
  DNSList=( $(systemDNSList) )
  echM "    DNS Print"
  echB "      DNS list"
  for DNS in "${DNSList[@]}"
  do
    echC "        - ${DNS}" 
  done
  echo ""
  echB "      ${ETC_HOST} list"
  for DNS in "${DNSList[@]}"
  do
    echY "        127.0.0.1 ${DNS}"
  done
  echo ""
  echG "    Finished"
  echo ""
  echG
}

function main()
{
  systemIPvPrepare
}

main
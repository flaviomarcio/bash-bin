#!/bin/bash

. lib-bash.sh

function __private_project_tags()
{
  __private_project_tags=
  if ! [[ ${PUBLIC_SERVICES_NAME} == "" ]]; then
    __private_project_tags=$(echo ${PUBLIC_SERVICES_NAME} | sed 's/-/ /g' | sort)
    __private_project_tags=$(echo ${PUBLIC_SERVICES_NAME} | sed 's/_/ /g' | sort)
  fi
  GIT_TAGS="${GIT_TAGS} ${__private_project_tags}"
  GIT_TAGS="${GIT_TAGS} testing development staging production"
  echo ${__private_project_tags}
  return 1
}



# return all all list
function __private_project_names()
{
  __pvt_project_filter=${1}
  __pvt_project_target=
  if [[ ${PUBLIC_SERVICES_PREFIX} != "" ]]; then
    __pvt_project_list=(${PUBLIC_SERVICES_PREFIX})
    __pvt_project_target=
    for __pvt_project_name in "${__pvt_project_list[@]}"
    do
      CHECK=$(echo ${__pvt_project_name} | grep ${__pvt_project_filter});
      if [[ ${CHECK} != "" ]]; then
        __pvt_project_target="${__pvt_project_target} ${__pvt_project_name}" 
      fi
    done
    __pvt_project_list=
  fi

  echo ${__pvt_project_target}
  return 1
}

function selectorProjectTags()
{
  while :
  do
    options=(Back $(__private_project_tags))
    PS3="Stack project menu"$'\n'"Choose option: "
    select opt in "${options[@]}"
    do
      if [[ ${opt} == "Back" ]]; then
        return 0
      elif [[ ${opt} != "" ]]; then
        echo $(__private_project_names ${opt})
        return 1
      else
        break
      fi
    done
  done
  return 0
}

function selectorProjects()
{
  while :
  do
    options=(Back All Tag $(__private_project_names))
    PS3="Stack project menu"$'\n'"Choose option: "
    select opt in "${options[@]}"
    do
      if [[ ${opt} == "Back" ]]; then
        return 0;
      elif [[ ${opt} == "All" ]]; then
        echo $(__private_project_names)
        return 1
      elif [[ ${opt} != "" ]]; then
        echo ${opt}
        return 1
      else
        #echR "Invalid option ${opt}"
        break
      fi
    done
  done
  return 0
}

# show System commands
function selectorCommands()
{
  clearTerm
  echM "  Docker"
  echB "    Configurando e desconfigurando o docker swarm"
  echC "      - docker swarm init --advertise-addr ${PUBLIC_HOST_IPv4}"
  echC "      - docker swarm leave --force"
  echB "    Acessando uma image/container"
  echG "      Imagem" 
  echC "        - docker run -it debian /bin/bash"
  echC "        - docker run -it debian /bin/sh"
  echR "      Observação"
  echC "        - Nem todas as imagens vem com o bash e sh algumas vem apenas com sistemas basicos" 
  echG "      Container" 
  echB "        Informando o nome" 
  echC "          - docker exec -it CONTAINER_NAME /bin/bash"
  echC "          - docker exec -it CONTAINER_NAME /bin/sh"
  echR "        Observação"
  echC "          - Nem todas as imagens vem com o bash e sh algumas vem apenas com sistemas basicos" 
  echR "        Dica"
  echC "          - Digite parte do nome e use a tecla[TAB] para completar o nome do container ou imagem"
  echG "        Pesquisando com script" 
  echC "          - export CONTAINER_NAME=debian"
  echC "          - export CONTAINER_ID=\$(docker container ls --filter "name=\${CONTAINER_NAME}" | grep \${CONTAINER_NAME} | awk '{print \$1}')"
  echC "          - docker exec -it \${CONTAINER_ID} /bin/bash"
  echC "          - docker exec -it \${CONTAINER_ID} /bin/sh"
  echB "    Inspecionando as configurações do serviço"
  echC "      - docker service inspect \${SERVICE_NAME}"
  echC "      - docker inspect \${CONTAINER_NAME}"
  echB "    Removendo um serviço ou container"
  echC "      - docker service rm \${SERVICE_NAME}"
  echC "      - docker rm \${CONTAINER_NAME}"
  echB "    Removendo serviços ou containers"
  echC "      - docker service rm \$(docker service ls | awk '{print \$1}') "
  echC "      - docker container rm \$(docker container ls | awk '{print \$1}') "
  echB "    Reiniciando toda a configuração do docker"
  echC "      - docker system prune --all --force"
  echM "  Redis"
  echB "    Requirements"
  echC "      - sudo apt install -y redis-tools"
  echB "    Client"
  echC "      - execute: [redis-cli] or [redis-cli -h sro-redis.local]"
  echR "  Dica"
  echB "    Acesse o container [adm]"
  echG "      Nele você terá todos os recursos de um linux"
  echG "      Poderá instalar outros aplicativos"
  echG "      Já conterá os aplicativos"
  echC "        - bash-completion"
  echC "        - telnet curl atop tar wget zip mc mcedit"
  echC "        - iproute2 iputils-ping"
  echC "        - postgresql-client"
  echC "        - postgresql-common"
  echC "        - redis-tools"
  echB "    Sua pastas [application] e [HOME] estarão mapeadas em :"
  echC "      - [/app/home]"
  echC "      - [/app/data]"
}

function selectorPGPass()
{
  clearTerm
  echM "Postgres password file configure"
  echB "  Linux script:"
  echC ""
  echG "    # env's to append"
  echC "      export PG_PASS=\${HOME}/.pgpass"
  echC "      export PUBLIC_LOCALHOST=localhost"
  echC "      export PUBLIC_HOST_NAME=${PUBLIC_HOST_IPv4}"
  echC "      export PUBLIC_HOST_LOCA=${PUBLIC_HOST_IP}"
  echC "      export PUBLIC_HOST_IPv4=${PUBLIC_HOST_IPv4}"
  echC "      export POSTGRESS_CONFIG='5432:postgres:postgres:postgres'"
  echC ""
  echG "    # append to file"
  echC "      echo \"\">\${PG_PASS}"
  echC "      echo \"\${PUBLIC_LOCALHOST}:\${POSTGRESS_CONFIG}\">>\${PG_PASS}"
  echC "      echo \"\${PUBLIC_HOST_NAME}:\${POSTGRESS_CONFIG}\">>\${PG_PASS}"
  echC "      echo \"\${PUBLIC_HOST_LOCA}:\${POSTGRESS_CONFIG}\">>\${PG_PASS}"
  echC "      echo \"\${PUBLIC_HOST_IPv4}:\${POSTGRESS_CONFIG}\">>\${PG_PASS}"
  echC ""
  echG "    # change permission"
  echC "      chmod 0600 \${PG_PASS};"
  echC ""
  echG "    # .pgpass file show"
  echC "      cat ${HOME}/.pgpass"
}

# show System DNSs
function selectorDNS()
{
  clearTerm
  echM "DNS List"
  echB "  Linux script:"
  echC ""
  echG "    # envs to append"
  echC "      export ETC_HOST=/etc/hosts"
  echC "      export PUBLIC_HOST_IP=${PUBLIC_HOST_IP}"
  echC "      export PUBLIC_HOST_IPv4=${PUBLIC_HOST_IPv4}"
  echC ""
  echG "    # append dns for debian admin"
  echC "      sudo echo \"${PUBLIC_HOST_IP} adm-debian.local\">>\${ETC_HOST}"
  echC ""
  echG "    # append dns for services"
  echC "      sudo echo \"${PUBLIC_HOST_IP} srv-activemq.local\">>\${ETC_HOST}"
  echC "      sudo echo \"${PUBLIC_HOST_IP} srv-auth.local\">>\${ETC_HOST}"
  echC "      sudo echo \"${PUBLIC_HOST_IP} srv-postgres.local\">>\${ETC_HOST}"
  echC "      sudo echo \"${PUBLIC_HOST_IP} srv-redis.local\">>\${ETC_HOST}"
  echC "      sudo echo \"${PUBLIC_HOST_IP} srv-traefik.local\">>\${ETC_HOST}"
  echC "      sudo echo \"${PUBLIC_HOST_IP} srv-vault.local\">>\${ETC_HOST}"
  echC ""
  echG "    # append dns for micro services"
  LST=( $(__private_project_names) )
  for ENV in "${LST[@]}"
  do
  echC "      sudo echo \"${PUBLIC_HOST_IP} mcs-${ENV}.local\">>\${ETC_HOST}"
  done
  echC ""
  echG "    # /etc/hosts file show"
  echC "      cat /etc/hosts | grep adm"
  echC "      cat /etc/hosts | grep srv"
  echC "      cat /etc/hosts | grep mcs"
}

#check docker mode [Docker Swarm|Docker Compose]
function selectorDockerOption()
{
  echo "Docker-Stack"
  return 1
  PS3="Stack build option menu"$'\n'"Choose option: "
  options=(Back Docker-Stack Docker-Compose)
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "Back" ]]; then
      break
    elif [[ ${opt} == "Docker-Stack" ]]; then
      echo ${opt}
      return 1;
    elif [[ ${opt} == "Docker-Compose" ]]; then
      echo ${opt}
      return 1;
    else
      echR "Invalid option ${opt}"
    fi
  done
  return 0;
}

function selectorBuildOption()
{
  while :
  do
    options=(Back build-and-deploy build deploy)
    PS3="Stack repository menu"$'\n'"Choose option: "
    select opt in "${options[@]}"
    do
      if [[ ${opt} == "Back" ]]; then
        return 0;
      elif [[ ${opt} != "" ]]; then
        echo ${opt}
        return 1
      else
        echR "Invalid option ${opt}"
      fi
    done
  done
  return 0;
}


function selectorDNSOption()
{
  while :
  do
    options=(Back etc-hosts print)
    PS3="DNS options"$'\n'"Choose option: "
    select opt in "${options[@]}"
    do
      if [[ ${opt} == "Back" ]]; then
        return 0;
      elif [[ ${opt} != "" ]]; then
        echo ${opt}
        return 1
      else
        break
      fi
    done
  done
  return 0
}
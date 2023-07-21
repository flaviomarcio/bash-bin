#!/bin/bash

. lib-strings.sh
. lib-system.sh
. lib-docker.sh

__selector_environments="testing development staging production"

function __private_print_os_information()
{
  echG "OS informations"
  echC "  - $(uname -a)"
  echC "  - $(docker --version), IPv4: ${PUBLIC_HOST_IPv4}"
  echC "  - Target:${__public_target}, Enviroment:${__public_enviroment}"
}

function __private_project_tags()
{
  __private_project_tags=
  if ! [[ ${PUBLIC_SERVICES_NAME} == "" ]]; then
    __private_project_tags=$(echo ${PUBLIC_SERVICES_NAME} | sed 's/-/ /g' | sort)
    __private_project_tags=$(echo ${PUBLIC_SERVICES_NAME} | sed 's/_/ /g' | sort)
  fi
  GIT_TAGS="${GIT_TAGS} ${__private_project_tags}"
  GIT_TAGS="${GIT_TAGS} ${__selector_environments}"
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
      __pvt_project_check=$(echo ${__pvt_project_name} | grep ${__pvt_project_filter});
      if [[ ${__pvt_project_check} != "" ]]; then
        __pvt_project_target="${__pvt_project_target} ${__pvt_project_name}" 
      fi
    done
    __pvt_project_list=
  fi

  echo ${__pvt_project_target}
  return 1
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

function selectorProjectTags()
{
  export __selector=
  options=(Back $(__private_project_tags))
  clearTerm
  __private_print_os_information
  echG $'\n'"Stack project tags menu"$'\n'
  PS3=$'\n'"Choose option: "
  select opt in "${options[@]}"
  do
    export __selector=${opt}
    if [[ ${opt} == "Back" ]]; then
      return 0
    elif [[ ${opt} != "" ]]; then
      echo $(__private_project_names ${opt})
      return 1
    else
      break
    fi
  done
  return 0
}

function selectorProjects()
{
  export __selector=
  clearTerm
  __private_print_os_information
  options=(Back All Tag $(__private_project_names))
  echG $'\n'"Project menu"$'\n'
  PS3=$'\n'"Choose option: "
  select opt in "${options[@]}"
  do
    export __selector=${opt}
    if [[ ${opt} == "Back" ]]; then
      return 0;
    elif [[ ${opt} == "All" ]]; then
      echo $(__private_project_names)
      return 1
    elif [[ ${opt} != "" ]]; then
      echo ${opt}
      return 1
    else
      break
    fi
  done
  return 0
}

function selectorDockerOption()
{
  export __selector=Docker-Stack
  return 1
  echG $'\n'"Docker option menu"$'\n'
  PS3=$'\n'"Choose option: "
  options=(Back Docker-Stack Docker-Compose)
  select opt in "${options[@]}"
  do
    export __selector=${opt}
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
  export __selector=
  options=(Back build-and-deploy build deploy)
  echG $'\n'"Docker build option menu"$'\n'
  PS3=$'\n'"Choose option: "
  select opt in "${options[@]}"
  do
    export __selector=${opt}
    if [[ ${opt} == "Back" ]]; then
      return 0;
    elif [[ ${opt} != "" ]]; then
      echo ${opt}
      return 1
    else
      echR "Invalid option ${opt}"
    fi
  done
  return 0;
}

function selectorDNSOption()
{
  export __selector=
  clearTerm
  options=(Back etc-hosts print)
  echG $'\n'"DNS options"$'\n'
  PS3=$'\n'"Choose option: "
  select opt in "${options[@]}"
  do
    export __selector=${opt}
    if [[ ${opt} == "Back" ]]; then
      return 0;
    elif [[ ${opt} != "" ]]; then
      echo ${opt}
      return 1
    else
      break
    fi
  done
  return 0
}

function selectorCustomer()
{
  export __selector=
  export PUBLIC_STACK_TARGET_FILE=${HOME}/applications/stack_targets.env
  if [[ -f ${PUBLIC_STACK_TARGET_FILE} ]]; then
    options=$(cat ${PUBLIC_STACK_TARGET_FILE})
    options="quit company ${options}"
  else
    options="quit company"
  fi
  options=(${options})

  clearTerm
  __private_print_os_information
  echM $'\n'"Customer menu"$'\n'
  PS3=$'\n'"Choose a option: "
  select opt in "${options[@]}"
  do
    export __selector=${opt}
    if [[ ${opt} == "quit" ]]; then
      return 0
    fi
    export STACK_TARGET=${opt}
    break;
  done
  return 1;
}

function selectorEnvironment()
{
  export __selector=
  clearTerm
  __private_print_os_information
  echM $'\n'"Environment menu"$'\n'
  PS3=$'\n'"Choose a option: "
  
  options=(${__selector_environments})

  select opt in "${options[@]}"
  do
    export __selector=${opt}
    export STACK_ENVIRONMENT=${opt}
    case $opt in
        "development")
          break
            ;;
        "testing")
          break
            ;;
        "stating")
          break
            ;;
        "production")
          break
            ;;
        "quit")
          return 0
            ;;
        *) echo "invalid option $opt";
    esac
  done
  return 1
}

function selectorDeployOption()
{
  export __selector=
  clearTerm
  echM $'\n'"Stack deploy mode"$'\n'
  PS3=$'\n'"Choose a option: "

  options=(Back all build deploy)

  select opt in "${options[@]}"
  do
    export __selector=${opt}
    if [[ ${opt} == "Back" ]]; then
      return 0
    fi
    echo ${opt}
    return 1;
  done

  return 0;
}

function selector()
{
  export __selector=
  __selector_title=${1}
  __selector_args=${2}
  if [[ ${__selector_args} == "" ]]; then
    return 0
  fi
  clearTerm
  __private_print_os_information
  echM $'\n'"${__selector_title}"$'\n'
  PS3=$'\n'"Choose a option: "
  options=(${__selector_args})
  select opt in "${options[@]}"
  do
    export __selector=${opt}
    if [[ ${opt} == "back" ]]; then
      return 0;
    elif [[ ${opt} == "quit" ]]; then
      return 2;
    elif [[ ${opt} == "all" ]]; then
      export __selector=${__selector_args}
    fi
    return 1;
  done
  return 0;
}

function selectorBack()
{
  __selector_title=${1}
  __selector_args=${2} 
  
  if [[ ${__selector_args} == "" ]]; then
    return 0
  fi
  selector "${__selector_title}" "back ${__selector_args}"
  return "$?"
}

function selectorQuit()
{
  __selector_title=${1}
  __selector_args=${2} 
  
  if [[ ${__selector_args} == "" ]]; then
    return 0
  fi
  selector "${__selector_title}" "quit ${__selector_args}"
  return "$?"
}
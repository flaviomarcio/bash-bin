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
. ${BASH_BIN}/lib-docker.sh

__selector_environments="testing development staging production"

function __private_print_os_information()
{
  echG "OS informations"
  echC "  - $(uname -a)"
  echC "  - $(docker --version), IPv4: ${PUBLIC_HOST_IPv4}"
  if [[ ${__public_environment} != "" ]]; then
    echC "  - Target: ${COLOR_YELLOW}${__public_target}${COLOR_CIANO}, Environment: ${COLOR_YELLOW}${__public_environment}"
    echC "  - Prefix: ${COLOR_YELLOW}${__public_environment}-${__public_target}"
  fi
}

function __private_project_tags()
{
  unset __private_project_tags
  if ! [[ ${PUBLIC_SERVICES_NAME} == "" ]]; then
    local __private_project_tags=$(echo ${PUBLIC_SERVICES_NAME} | sed 's/-/ /g' | sort)
    local __private_project_tags=$(echo ${PUBLIC_SERVICES_NAME} | sed 's/_/ /g' | sort)
  fi
  # GIT_TAGS="${GIT_TAGS} ${__private_project_tags}"
  # GIT_TAGS="${GIT_TAGS} ${__selector_environments}"
  echo ${__private_project_tags}
  return 1
}



# return all all list
function __private_project_names()
{
  local __pvt_project_filter=${1}
  local __pvt_project_target=
  if [[ ${PUBLIC_SERVICES_PREFIX} != "" ]]; then
    local __pvt_project_list=(${PUBLIC_SERVICES_PREFIX})
    unset __pvt_project_target
    for __pvt_project_name in "${__pvt_project_list[@]}"
    do
      local __pvt_project_check=$(echo ${__pvt_project_name} | grep ${__pvt_project_filter});
      if [[ ${__pvt_project_check} != "" ]]; then
        local __pvt_project_target="${__pvt_project_target} ${__pvt_project_name}" 
      fi
    done
    unset __pvt_project_list
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
  local LST=( $(__private_project_names) )
  local __env=
  for __env in "${LST[@]}"
  do
  echC "      sudo echo \"${PUBLIC_HOST_IP} mcs-${__env}.local\">>\${ETC_HOST}"
  done
  echC ""
  echG "    # /etc/hosts file show"
  echC "      cat /etc/hosts | grep adm"
  echC "      cat /etc/hosts | grep srv"
  echC "      cat /etc/hosts | grep mcs"
}

function selectorProjectTags()
{
  unset __selector
  local options=(Back $(__private_project_tags))
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
  unset __selector
  clearTerm
  __private_print_os_information
  local options=(Back All Tag $(__private_project_names))
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
  local options=(Back Docker-Stack Docker-Compose)
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
  unset __selector
  local options=(Back build-and-deploy build deploy)
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
  unset __selector
  clearTerm
  local options=(Back etc-hosts print)
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

function __private_selectorInitTargets()
{
  unset __func_return
  clearTerm
  export __selector_dir=/data/applications
  mkdir -p ${__selector_dir}
  if [[ -f ${__selector_dir} ]]; then
    echR "No create root dir ${__selector_dir}"
    read
    return 0
  fi

  export __selector_file=${__selector_dir}/stack_targets.env
  if [[ -f ${__selector_file} ]]; then
    export __func_return=${__selector_file}
    return 1
  fi


  while :
  do
    unset __selector_values
    echY "Uninitialized targets"
    echG    "   Target file: ${__selector_values}"
    echG    "   Set target names: ex: name1 name2 name3"
    echo -n "   names: "
    read __selector_values
    if [[ ${__selector_values} == "" ]]; then
      echR "Invalid target names"
    else
      echo ${__selector_values}>${__selector_file}
      export __func_return=${__selector_file}  
      return 1
    fi
  done
  return 0
}

function selectorCustomer()
{
  unset __selector
  __private_selectorInitTargets
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  export __selector_file=${__func_return}
  if ! [[ -f ${__selector_file} ]]; then
    echR "No create root dir ${__selector_dir}"
    read
    return 0;
  fi
  local options=$(cat ${__selector_file})
  local options="quit ${options}"
  local options=(${options})

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
    break;
  done
  return 1;
}

function selectorEnvironment()
{
  unset __selector
  clearTerm
  __private_print_os_information
  echM $'\n'"Environment menu"$'\n'
  PS3=$'\n'"Choose a option: "
  
  local options=(${__selector_environments})

  select opt in "${options[@]}"
  do
    export __selector=${opt}
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
  unset __selector
  clearTerm
  echM $'\n'"Stack deploy mode"$'\n'
  PS3=$'\n'"Choose a option: "

  local options=(Back all build deploy)

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
  unset __selector
  local __selector_title=${1}
  local __selector_args=${2}
  local __selector_clear=${3}
  if [[ ${__selector_args} == "" ]]; then
    return 0
  fi
  if [[ ${__selector_clear} == "" ]]; then
    local __selector_clear=true
  fi

  if [[ ${__selector_clear} == true ]]; then
    clearTerm
    __private_print_os_information
  fi

  while :
  do
    clearTerm
    __private_print_os_information
    echM $'\n'"${__selector_title}"$'\n'
    PS3=$'\n'"Choose a option: "
    local options=(${__selector_args})
    select opt in "${options[@]}"
    do
      arrayContains "${__selector_args}" "${opt}"
      if ! [ "$?" -eq 1 ]; then
        break;
      fi

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
  done
  return 0;
}

function selectorYesNo()
{
  local __selector_title=${1}
  selector "${__selector_title}" "Yes No"
  if [[ ${__selector} == "Yes" ]]; then
    return 1;
  fi
  return 0
}

function selectorWaitSeconds()
{
  local __selectorWaitSeconds_seconds=${1}
  local __selectorWaitSeconds_title=${2}
  local __selectorWaitSeconds_color=${2}

  if [[ ${__selectorWaitSeconds_seconds} == "" ]]; then
    local __selectorWaitSeconds_seconds=10
  fi

  if [[ ${__selectorWaitSeconds_title} == "" ]]; then
    local __selectorWaitSeconds_title="Wainting ${__selectorWaitSeconds_seconds} seconds, use [CTRL+C] to abort..."
  fi

  if [[ ${__selectorWaitSeconds_color} == "" ]]; then
    local __selectorWaitSeconds_color=${COLOR_BLUE_B}
  fi

  echo -e "${__selectorWaitSeconds_color}${__selectorWaitSeconds_title}${COLOR_OFF}"
  for i in $(seq ${__selectorWaitSeconds_seconds} -1 0); do echo -e -n "${i}... "; sleep 1; done; echo -e "\n"

  return 1
}

function selectorBack()
{
  local __selector_title=${1}
  local __selector_args=${2} 
  
  if [[ ${__selector_args} == "" ]]; then
    return 0
  fi
  selector "${__selector_title}" "back ${__selector_args}"
  return "$?"
}

function selectorQuit()
{
  local __selector_title=${1}
  local __selector_args=${2} 
  
  if [[ ${__selector_args} == "" ]]; then
    return 0
  fi
  selector "${__selector_title}" "quit ${__selector_args}"
  return "$?"
}

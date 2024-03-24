#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  export BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh

function __private_db_envs_clear()
{
  export DATABASE_DIR=
}

function __private_db_envs_check()
{
  if [[ ${DATABASE_ENVIRONMENT} == "" ]]; then
    echR "Invalid \${DATABASE_ENVIRONMENT}"
    return 0
  fi

  if [[ ${DATABASE_DIR} == "" ]]; then
    echR "Invalid \${DATABASE_DIR}"
    return 0
  fi
  if ! [[ -d ${DATABASE_DIR} ]]; then
    echR "Invalid database dir: ${DATABASE_DIR}"
    return 0
  fi
  return 1
}

function __private_db_cleanup_sql()
{
  local __file=${1}
  if ! [[ -f ${__file} ]]; then
    return 0;
  fi
  sed -i '/^$/d' ${__file}
  local __envs=(DROP drop TRUNCATE truncate DELETE delete CASCADE cascade)
  for __env in ${__envs[*]}; do 
    sed -i "/${__env}/d" ${__file}
  done
  return 1;
}

function __private_db_scan_files()
{
  unset __func_return
  local DB_SCAN_DIR=${1}
  local __filters="${2}"

  if ! [[ -d ${DB_SCAN_DIR} ]]; then
    return 0;
  fi

  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    local DB_SCAN_FILTERS=$(echo ${__filters} | sed 's/drops//g' | sed 's/drop//g' | sed 's/fakedata//g')
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    local DB_SCAN_FILTERS=${__filters}
  else
    local DB_SCAN_FILTERS=
  fi 

  local DB_SCAN_FILTERS=(${DB_SCAN_FILTERS})
  local DB_SCAN_STEP_DIRS=($(ls ${DB_SCAN_DIR}))
  local DB_SCAN_STEP_DIR=
  for DB_SCAN_STEP_DIR in ${DB_SCAN_STEP_DIRS[*]}; 
  do
    unset DB_SCAN_STEP_FILES
    local DB_SCAN_FILTER=
    for DB_SCAN_FILTER in ${DB_SCAN_FILTERS[*]}; 
    do
      if [[ $(echo ${DB_SCAN_FILTER} | grep sql) == "" ]]; then
        local DB_SCAN_FILTER="${DB_SCAN_FILTER}*.sql"
      fi
      local DB_SCAN_DIR_STEP="${DB_SCAN_DIR}/${DB_SCAN_STEP_DIR}"
      local DB_SCAN_FILES=($(echo $(find ${DB_SCAN_DIR}/${DB_SCAN_STEP_DIR} -iname ${DB_SCAN_FILTER} | sort)))
      local DB_SCAN_FILE=
      for DB_SCAN_FILE in ${DB_SCAN_FILES[*]};
      do
        local DB_SCAN_STEP_FILES="${DB_SCAN_STEP_FILES} ${DB_SCAN_FILE}"
      done
    done
    if [[ ${DB_SCAN_STEP_FILES} != "" ]]; then
      export __func_return="${__func_return} [${DB_SCAN_STEP_DIR}] ${DB_SCAN_STEP_FILES}"
    fi
  done

  echo ${__func_return}
  return 1  
}

function __filters()
{
  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    echo "tables constraints-pk constraints.sql constraints-fk constraints-check indexes initdata view"
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    echo "drops tables constraints-pk constraints.sql constraints-fk constraints-check indexes initdata view fakedata"
  fi  
  return 1
}

function __for_local()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    local __filter="tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view"
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    local __filter="drops tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view fakedata"
  else
    local __filter=
  fi  
  if [[ ${__filter} == "" ]]; then
    return 0;
  fi
  __private_db_scan_files "${1}" "${__filter}"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

function __for_ddl()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    local __filter="tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view"
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    local __filter="tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view fakedata"
  else
    local __filter=
  fi  
  if [[ ${__filter} == "" ]]; then
    return 0;
  fi

  __private_db_scan_files "${1}" "${__filter}"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

function __private_db_ddl_apply_scan()
{
  unset __func_return
  local __target=${1}
  if ! [ -d ${__target} ]; then
    return 0;       
  fi
  local __files=($(__for_local "${__target}"))
  local __file=
  for __file in ${__files[*]};
  do    
    local __func_return="${__func_return} ${__file}"
  done
  echo ${__func_return}
  return 1
}

function __private_pg_envs_check()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi

  envsSetIfIsEmpty POSTGRES_HOST localhost
  envsSetIfIsEmpty POSTGRES_USER services
  envsSetIfIsEmpty POSTGRES_PASSWORD services
  envsSetIfIsEmpty POSTGRES_DATABASE services
  envsSetIfIsEmpty POSTGRES_PORT 5432

  return 1
}

function __private_pg_script_exec()
{
  local __file=${1}
  if ! [[ -f ${__file} ]]; then
    return 0;
  fi

  sed -i '/^$/d' ${__file}
  local __check=$(which qsql)
  if [[ ${__check} != "" ]]; then
    qsql --action=exec --format= --quiet --hostname=${POSTGRES_HOST} --username=${POSTGRES_USER} --password=${POSTGRES_PASSWORD} --port=${POSTGRES_PORT} --database=${POSTGRES_DATABASE} --command=${__file}
  else
    echo $(psql -q -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${POSTGRES_DATABASE} -a -f ${__file})&>/dev/null
  fi
  return 1
}

function __private_pg_pass_apply()
{
  #postgres
  export POSTGRES_PGPASS=${HOME}/.pgpass
  local AUTH="${POSTGRES_HOST}:${POSTGRES_PORT}:${POSTGRES_DATABASE}:${POSTGRES_USER}:${POSTGRES_PASSWORD}">${POSTGRES_PGPASS}
  if [[ -f ${POSTGRES_PGPASS} ]];then
      echo ${AUTH} >> ${POSTGRES_PGPASS}
  else
      echo ${AUTH} > ${POSTGRES_PGPASS}
  fi
  chmod 0600 ${POSTGRES_PGPASS};
  return 1
}

function databaseUpdateExec()
{
  echG "Update databases"
  __private_pg_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;
  fi
  local PG_HOST=${POSTGRES_HOST}
  local PG_DATABASE=${POSTGRES_DATABASE}
  local PG_USER=${POSTGRES_USER}
  local PG_PASSWORD=${POSTGRES_PASSWORD}
  local PG_PORT=${POSTGRES_PORT}

  __private_pg_pass_apply
  echM "    Executing"
  echB "      -Environments"
  echC "        - export PG_HOST=${PG_HOST}"
  echC "        - export PG_DATABASE=${PG_DATABASE}"
  echC "        - export PG_USER=${PG_USER}"
  echC "        - export PG_PASSWORD=${PG_PASSWORD}"
  echC "        - export PG_PORT=${PG_PORT}"
  local __check=$(which qsql)
  if [[ ${__check} != "" ]]; then
  echY "        - qsql --format= --quiet --driver=QPSQL --hostname=\${PG_HOST} --username=\${PG_USER} --password=\${PG_PASSWORD} --port=\${PG_PORT} --database=\${PG_DATABASE} --output=\${PG_SQL_FILE}"
  else
  echC "        - Using password in .pgpass"
  echY "        - psql -q -h \${PG_HOST} -U \${PG_USER} -p \${PG_PORT} -d \${PG_DATABASE} -a -f \${PG_SQL_FILE}"
  fi
  echB "      -Executing"
  
  local EXEC_FILES=$(__private_db_ddl_apply_scan ${DATABASE_DIR})
  if [[ ${EXEC_FILES} == "" ]]; then
    echR "        - No files found"
  else
    local EXEC_FILE=
    for EXEC_FILE in ${EXEC_FILES[*]};
    do
      if [[ ${EXEC_FILE} == "["* ]] ; then
        echG "        -Executing ${EXEC_FILE}"     
      else
        local BASE1=$(basename ${EXEC_FILE})
        local BASE2=$(dirname ${EXEC_FILE})
        local BASE3=$(dirname ${BASE2})
        local BASE2=$(basename ${BASE2})
        local BASE3=$(basename ${BASE3})
        echC "          - ${BASE1} from ${BASE2}"

        local DB_DDL_FILE_TMP="/tmp/ddl_file_$RANDOM.sql"
        echo "set client_min_messages to WARNING; ">${DB_DDL_FILE_TMP};
        cat ${EXEC_FILE} >> ${DB_DDL_FILE_TMP};
        __private_pg_script_exec ${DB_DDL_FILE_TMP}
      fi
    done
  fi
  echB "      Finished"
  echB "    Finished"
  return 1
}

function databaseDDLMakerExec()
{
  local __db_dir=${DATABASE_DIR}
  local __db_ddl_file=${DATABASE_DDL_FILE}
  echG "  DDL Maker"
  echC "    - DDL File: ${DATABASE_DDL_FILE}"  
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi

  local __db_ddl_file_dir=$(dirname ${__db_ddl_file})
  local __db_ddl_files_extra=($(__filters))
  echB "    Cleanup files..."
  echC "      - Local: ${__db_ddl_file_dir}"
  echR "    Removing..."
  local __env=
  for __env in ${__db_ddl_files_extra[*]};
  do
    local __database_file="${__db_ddl_file_dir}/initdb-${__env}*.sql"
    echY "      rm -rf $(basename ${__database_file})"
    rm -rf ${__database_file}
  done
  echG "    Finished"
  echB "    Making..."
  echo "">${__db_ddl_file}
  local __ddl_files=$(__private_db_ddl_apply_scan ${__db_dir})
  local __files=()
  local __ddl_file=
  for __ddl_file in ${__ddl_files[*]};
  do
    if ! [[ -f ${__ddl_file} ]]; then
      echG "      Context: ${__ddl_file}"
      echo "-- ${__ddl_file}">>${__db_ddl_file};
    else
      local BASE1=$(basename ${__ddl_file})
      local BASE2=$(dirname ${__ddl_file})
      local BASE3=$(dirname ${BASE2})
      local BASE2=$(basename ${BASE2})
      local BASE3=$(basename ${BASE3})
      echC "        - ${BASE1} from ${BASE2}"
      cat ${__ddl_file}>>${__db_ddl_file};
    fi
  done
  echB "    Finished"
  echB "    Cleanup maked files..."
  local __files=(${__db_ddl_file})
  local __file=
  for __file in ${__files[*]};
  do
    __private_db_cleanup_sql ${__file}
    echC "      - $(basename ${__file})"    
  done
  echB "    Finished"
  echB "  Finished"  

  echG ""
  echG "Deseja ver o aquivo?"
  echC "  - ${__db_ddl_file}"
  local options=(Back dbeaver code subl kate)
  PS3=$'\n'"Choose option:"
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "Back" ]]; then
      break
    else
      local __cmd="${opt} ${__db_ddl_file}"
      echY "      - ${__cmd}"
      echo $(${__cmd})&>/dev/null
    fi
    break
  done
  echB "Finished"  
  return 1
}

function databasePrepare()
{
  export DATABASE_ENVIRONMENT=${1}
  export DATABASE_DIR=${2}
  export DATABASE_DDL_FILE="${DATABASE_DIR}/initdb.sql"
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    echContinue
    return 0;       
  fi
  return 1
}

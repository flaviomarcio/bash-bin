#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh

# export DATABASE_DIR=

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
  __private_db_cleanup_sql_file=${1}
  if ! [[ -f ${__private_db_cleanup_sql_file} ]]; then
    return 0;
  fi
  sed -i '/^$/d' ${__private_db_cleanup_sql_file}
  __private_db_cleanup_sql_envs=(DROP drop TRUNCATE truncate DELETE delete CASCADE cascade)
  for __private_db_cleanup_sql_env in ${__private_db_cleanup_sql_envs[*]}; do 
    sed -i "/${__private_db_cleanup_sql_env}/d" ${__private_db_cleanup_sql_file}
  done
  return 1;
}

function __private_db_scan_files()
{
  DB_SCAN_RETURN=
  DB_SCAN_DIR=${1}
  __private_db_scan_files_filters="${2}"

  if ! [[ -d ${DB_SCAN_DIR} ]]; then
    return 0;
  fi

  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    DB_SCAN_FILTERS=$(echo ${__private_db_scan_files_filters} | sed 's/drops//g' | sed 's/drop//g' sed 's/fakedata//g')
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    DB_SCAN_FILTERS=${__private_db_scan_files_filters}
  else
    DB_SCAN_FILTERS=
  fi 

  DB_SCAN_FILTERS=(${DB_SCAN_FILTERS})
  DB_SCAN_STEP_DIRS=($(ls ${DB_SCAN_DIR}))
  for DB_SCAN_STEP_DIR in ${DB_SCAN_STEP_DIRS[*]}; 
  do
    DB_SCAN_STEP_FILES=
    for DB_SCAN_FILTER in ${DB_SCAN_FILTERS[*]}; 
    do
      if [[ $(echo ${DB_SCAN_FILTER} | grep sql) == "" ]]; then
        DB_SCAN_FILTER="${DB_SCAN_FILTER}*.sql"
      fi
      DB_SCAN_DIR_STEP="${DB_SCAN_DIR}/${DB_SCAN_STEP_DIR}"
      DB_SCAN_FILES=($(echo $(find ${DB_SCAN_DIR}/${DB_SCAN_STEP_DIR} -iname ${DB_SCAN_FILTER} | sort)))
      for DB_SCAN_FILE in ${DB_SCAN_FILES[*]};
      do
        DB_SCAN_STEP_FILES="${DB_SCAN_STEP_FILES} ${DB_SCAN_FILE}"
      done
    done
    if [[ ${DB_SCAN_STEP_FILES} != "" ]]; then
      DB_SCAN_RETURN="${DB_SCAN_RETURN} [${DB_SCAN_STEP_DIR}] ${DB_SCAN_STEP_FILES}"
    fi
  done

  echo ${DB_SCAN_RETURN}
  return 1  
}

function __private_db_scan_files_filters()
{
  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    echo "tables constraints-pk constraints.sql constraints-fk constraints-check indexes initdata view"
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    echo "drops tables constraints-pk constraints.sql constraints-fk constraints-check indexes initdata view fakedata"
  fi  
  return 1
}

function __private_db_scan_files_for_local()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    __private_db_scan_files_for_local_filter="tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view"
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    __private_db_scan_files_for_local_filter="drops tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view fakedata"
  else
    __private_db_scan_files_for_local_filter=
  fi  
  if [[ ${__private_db_scan_files_for_local_filter} == "" ]]; then
    return 0;
  fi
  __private_db_scan_files "${1}" "${__private_db_scan_files_for_local_filter}"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

function __private_db_scan_files_for_ddl()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    __private_db_scan_files_for_ddl_filter="tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view"
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    __private_db_scan_files_for_ddl_filter="tables constraints.sql constraints-pk constraints-fk constraints-check indexes initdata view fakedata"
  else
    __private_db_scan_files_for_ddl_filter=
  fi  
  if [[ ${__private_db_scan_files_for_ddl_filter} == "" ]]; then
    return 0;
  fi

  __private_db_scan_files "${1}" "${__private_db_scan_files_for_ddl_filter}"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

function __private_db_ddl_apply_scan()
{
  __private_db_ddl_apply_scan_taget=${1}
  if ! [ -d ${__private_db_ddl_apply_scan_taget} ]; then
    return 0;       
  fi
  __private_db_ddl_apply_scan_files=($(__private_db_scan_files_for_local "${__private_db_ddl_apply_scan_taget}"))
  for __private_db_ddl_apply_scan_file in ${__private_db_ddl_apply_scan_files[*]};
  do    
    __private_db_ddl_apply_scan_return="${__private_db_ddl_apply_scan_return} ${__private_db_ddl_apply_scan_file}"
  done
  echo ${__private_db_ddl_apply_scan_return}
  return 1
}

function __private_pg_envs_check()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  if [[ ${POSTGRES_HOST} == "" ]]; then
    export POSTGRES_HOST="localhost"
  fi
  if [[ ${POSTGRES_USER} == "" ]]; then
    export POSTGRES_USER=services
  fi
  if [[ ${POSTGRES_PASS} == "" ]]; then
    export POSTGRES_PASS=services
  fi
  if [[ ${POSTGRES_DB} == "" ]]; then
    export POSTGRES_DB=services
  fi
  if [[ ${POSTGRES_PORT} == "" ]]; then
    export POSTGRES_PORT=5432
  fi

  if [[ ${POSTGRES_HOST} == "" ]]; then 
    echR "Invalid env: POSTGRES_HOST=${POSTGRES_HOST}"
    return 0
  fi
  if [[ ${POSTGRES_USER} == "" ]]; then 
    echR "Invalid env: POSTGRES_USER=${POSTGRES_USER}"
    return 0
  fi
  if [[ ${POSTGRES_PASS} == "" ]]; then 
    echR "Invalid env: POSTGRES_PASS=${POSTGRES_PASS}"
    return 0
  fi
  if [[ ${POSTGRES_DB} == "" ]]; then 
    echR "Invalid env: POSTGRES_DB=${POSTGRES_DB}"
    return 0
  fi
  if [[ ${POSTGRES_PORT} == "" ]]; then 
    echR "Invalid env: POSTGRES_PORT=${POSTGRES_PORT}"
    return 0
  fi
  return 1
}

function __private_pg_script_exec()
{
  __private_pg_script_exec_file=${1}
  if ! [[ -f ${__private_pg_script_exec_file} ]]; then
    return 0;
  fi

  if [[ ${DATABASE_ENVIRONMENT} == "production" ]]; then
    __private_db_cleanup_sql ${__private_pg_script_exec_file}
  elif [[ ${DATABASE_ENVIRONMENT} == "testing" || ${DATABASE_ENVIRONMENT} == "development"  || ${DATABASE_ENVIRONMENT} == "stating" ]]; then
    #remove empty lines
    sed -i '/^$/d' ${__private_pg_script_exec_file}
  else
    return 0;
  fi 

  echo $(psql -q -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${POSTGRES_DB} -a -f ${__private_pg_script_exec_file})&>/dev/null
  return 1
}

function __private_pg_pass_apply()
{
  #postgres
  export POSTGRES_PGPASS=${HOME}/.pgpass
  AUTH="${POSTGRES_HOST}:${POSTGRES_PORT}:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASS}">${POSTGRES_PGPASS}
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
  __private_pg_pass_apply
  echM "    Executing"
  echB "      -Environments"
  echC "        - export POSTGRES_HOST=${POSTGRES_HOST}"
  echC "        - export POSTGRES_DB=${POSTGRES_DB}"
  echC "        - export POSTGRES_USER=${POSTGRES_USER}"
  echC "        - export POSTGRES_PASS=${POSTGRES_PASS}"
  echC "        - export POSTGRES_PORT=${POSTGRES_PORT}"
  echY "        - psql -q -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -p \${POSTGRES_PORT} -d \${POSTGRES_DB} -a -f \${FILE}\""
  echB "      -Executing"
  DB_DDL_FILE_TMP="/tmp/ddl_file.sql"
  EXEC_FILES=$(__private_db_ddl_apply_scan ${DATABASE_DIR})
  if [[ ${EXEC_FILES} == "" ]]; then
    echR "        - No files found"
  else
    for EXEC_FILE in ${EXEC_FILES[*]};
    do
      if [[ ${EXEC_FILE} == "["* ]] ; then
        echG "        -Executing ${EXEC_FILE}"     
      else
        BASE1=$(basename ${EXEC_FILE})
        BASE2=$(dirname ${EXEC_FILE})
        BASE3=$(dirname ${BASE2})
        BASE2=$(basename ${BASE2})
        BASE3=$(basename ${BASE3})
        echC "          - ${BASE1} from ${BASE2}"
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
  echG "  DDL Maker"
  echC "    - DDL File: ${DATABASE_DDL_FILE}"  
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi

  __database_ddl_file_dir=$(dirname ${DATABASE_DDL_FILE})
  __database_ddl_files_extra=($(__private_db_scan_files_filters))
  echB "    Cleanup files..."
  echC "      - Local: ${__database_ddl_file_dir}"
  echR "    Removing..."
  for ENV in ${__database_ddl_files_extra[*]};
  do
    __database_file="${__database_ddl_file_dir}/initdb-${ENV}*.sql"
  echY "      rm -rf $(basename ${__database_file})"
    rm -rf ${__database_file}
  done
  echG "    Finished"
  echB "    Making..."
  echo "">${DATABASE_DDL_FILE}
  DDL_MAKE_FILES=$(__private_db_ddl_apply_scan ${DATABASE_DIR})
  __database_maked_files=()
  for DDL_MAKE_FILE in ${DDL_MAKE_FILES[*]};
  do
    if ! [[ -f ${DDL_MAKE_FILE} ]]; then
      echG "      Context: ${DDL_MAKE_FILE}"
      echo "-- ${DDL_MAKE_FILE}">>${DATABASE_DDL_FILE};
    else
      BASE1=$(basename ${DDL_MAKE_FILE})
      BASE2=$(dirname ${DDL_MAKE_FILE})
      BASE3=$(dirname ${BASE2})
      BASE2=$(basename ${BASE2})
      BASE3=$(basename ${BASE3})
      echC "        - ${BASE1} from ${BASE2}"
      cat ${DDL_MAKE_FILE}>>${DATABASE_DDL_FILE};
    fi
  done
  echB "    Finished"
  __database_maked_files=(${DATABASE_DDL_FILE})
  echB "    Cleanup maked files..."
  for __database_maked_file in ${__database_maked_files[*]};
  do
    __private_db_cleanup_sql ${__database_maked_file}
    echC "      - $(basename ${__database_maked_file})"    
  done
  echB "    Finished"
  echB "  Finished"  

  echG ""
  echG "Deseja ver o aquivo?"
  echC "  - ${DATABASE_DDL_FILE}"
  options=(Back dbeaver code subl kate)
  PS3=$'\n'"Choose option:"
  select opt in "${options[@]}"
  do
    if [[ ${opt} == "Back" ]]; then
      break
    else
      CMD="${opt} ${DATABASE_DDL_FILE}"
      echY "      - ${CMD}"
      echo $(${CMD})&>/dev/null
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

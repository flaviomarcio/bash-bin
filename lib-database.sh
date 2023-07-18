#!/bin/bash

. lib-bash.sh

# export DATABASE_SCOPE=
# export DATABASE_DIR=
# export DATABASE_GIT_BRANCH=

function __private_db_envs_clear()
{
  export DATABASE_DIR=
}

function __private_db_envs_check()
{
  if [[ ${DATABASE_SCOPE} == "" ]]; then
      echo "Invalid \${DATABASE_SCOPE}"
      return 0
  fi
  if [[ ${DATABASE_DIR} == "" ]]; then
      echo "Invalid \${DATABASE_DIR}"
      return 0
  fi
  if ! [[ -d ${DATABASE_DIR} ]]; then
      echo "Invalid database dir: ${DATABASE_DIR}"
      return 0
  fi
  return 1
}

function __private_db_cleanup_sql()
{
  CLEANUP_FILE=${1}
  if ! [[ -f ${CLEANUP_FILE} ]]; then
    return 0;
  fi
  RESERVED_LIST=(DROP drop TRUNCATE truncate DELETE delete CASCADE cascade)
  for RESERVED in ${RESERVED_LIST[*]}; do 
    sed -i "/${RESERVED}/d" ${CLEANUP_FILE}
  done
  return 1;
}

function __private_db_scan_files()
{
  DB_SCAN_RETURN=
  DB_SCAN_DIR=${1}/projects
  DB_SCAN_FILTERS=(${2})

  if ! [[ -d ${DB_SCAN_DIR} ]]; then
    return 0;
  fi
 
  DB_SCAN_STEP_DIRS=($(ls ${DB_SCAN_DIR}))
  for DB_SCAN_STEP_DIR in ${DB_SCAN_STEP_DIRS[*]}; 
  do
    DB_SCAN_STEP_FILES=
    for DB_SCAN_FILTER in ${DB_SCAN_FILTERS[*]}; 
    do 
      DB_SCAN_FILTER="${DB_SCAN_FILTER}*.sql"
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
  echo "drops tables constraints-pk constraints-fk constraints-check indexes initdata view fakedata"
  return 1
}

function __private_db_scan_files_for_local()
{
  __private_db_scan_files "${1}" "drops tables constraints-pk constraints-fk constraints-check indexes initdata view fakedata"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

function __private_db_scan_files_for_ddl()
{
  __private_db_scan_files "${1}" "tables constraints-pk constraints-fk constraints-check indexes initdata view fakedata"
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

function __private_db_ddl_apply_scan()
{
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  DDL_SCAN_FILES=($(__private_db_scan_files_for_local "${DATABASE_DIR}"))
  for DDL_SCAN_FILE in ${DDL_SCAN_FILES[*]};
  do    
    DDL_SCAN_DIR_FILES="${DDL_SCAN_DIR_FILES} ${DDL_SCAN_FILE}"
  done
  echo ${DDL_SCAN_DIR_FILES}
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
    export POSTGRES_USER=postgres
  fi
  if [[ ${POSTGRES_PASS} == "" ]]; then
    export POSTGRES_PASS=postgres
  fi
  if [[ ${POSTGRES_DB} == "" ]]; then
    export POSTGRES_DB=postgres
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
  FILE=${1}
  echo $(psql -q -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${POSTGRES_DB} -a -f ${FILE})&>/dev/null
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
  echY "        - psql -q -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${POSTGRES_DB} -a -f \${FILE}\""
  echB "      -Executing"
  DB_DDL_FILE_TMP="/tmp/ddl_file.sql"
  EXEC_FILES=$(__private_db_ddl_apply_scan ${DATABASE_DIR})
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
  echB "Finished"
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
  export DATABASE_SCOPE=${1}
  export DATABASE_DIR=${2}
  export DATABASE_GIT_BRANCH=${3}
  export DATABASE_DDL_FILE="${DATABASE_DIR}/initdb.sql"
  __private_db_envs_check
  if ! [ "$?" -eq 1 ]; then
    return 0;       
  fi
  return 1
}

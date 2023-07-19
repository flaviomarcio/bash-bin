#!/bin/bash

. lib-strings.sh
. lib-system.sh

function mavenBuild()
{
  __mvn_build_src_dir=${1}
  __mvn_build_bin_dir=${2}
  __mvn_jar_name=${3}

  export __mvn_jar_file=

  echG "  Source building with Maven"
  __mvn_check=$(mvn --version)
  __mvn_check=$(mvn --version | grep Apache)
  if [[ ${__mvn_check} != *"Apache"*  ]]; then
    echR "  ==============================  "
    echR "     ************************     "
    echR "  ***MAVEN não está instalado***  "
    echR "     ************************     "
    echR "  ==============================  "
    return 0
  fi
  if ! [[ -d ${__mvn_build_src_dir} ]]; then
    echR "  ==============================  "
    echR "       ********************       "
    echR "  *****Source dir no exists*****  "
    echR "       ********************       "
    echR "  ==============================  "
    return 0;
  fi
  if ! [[ -f "${__mvn_build_src_dir}/pom.xml" ]]; then
    echR "  ==============================  "
    echR "           *************          "
    echR "  *********POM no exists*******"
    echR "           *************          "
    echR "  ==============================  "
    return 0;
  fi
  mkdir -p ${__mvn_build_bin_dir}
  if ! [[ -d ${__mvn_build_bin_dir} ]]; then
    echR "  ==============================  "
    echR "         *****************        "
    echR "  *******Bin dir no exists******  "
    echR "         *****************        "
    echR "  ==============================  "
    return 0;
  fi

  cd ${__mvn_build_src_dir}

  __mvn_build_src_bin_dir=${__mvn_build_src_dir}/target
  __mvn_jar_destine_file=${__mvn_build_bin_dir}/${__mvn_jar_name}.jar
  rm -rf ${__mvn_jar_destine_file} 

  CMD="mvn install -DskipTests"
  echM "    Maven build"
  echC "      - Source dir: ${__mvn_build_src_dir}"
  echC "      - JAR file: ${__mvn_jar_destine_file}"
  echY "      - ${CMD}"
  __mvn_output=$(${CMD})
  __mvn_check=$(echo ${__mvn_output} | grep ERROR)
  if [[ ${__mvn_check} != "" ]]; then
    echR "    source build fail:"
    echR "    ==============================  "
    echR "    *******Maven build fail*******  "
    echR "    *******Maven build fail*******  "
    echR "    ==============================  "
    printf "${__mvn_output}"
    return 0;
  fi
  echG "    Finished"
  
  echM "    Binaries prepare"
  echC "      - JAR file: ${__mvn_jar_destine_file}"
  export __mvn_jar_source_file=$(find ${__mvn_build_src_bin_dir} -name 'app*.jar')
  cp -r ${__mvn_jar_source_file} ${__mvn_jar_destine_file}

  if ! [[ -f ${__mvn_jar_destine_file} ]]; then
    echR "      ==============================  "
    echR "      ******JAR file not found******  "
    echR "      ******JAR file not found******  "
    echR "      ==============================  "
    return 0;
  fi
  echG "    Finished"
  export __mvn_jar_file=${__mvn_jar_destine_file}
  return 1
}
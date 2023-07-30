#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh

function buildCompilerCheck()
{
  __private_build_compiler_dir=${1}
  export __func_return=
  if [[ -d ${__private_build_compiler_dir}  ]]; then
    if [[ -f ${__private_build_compiler_dir}/pom.xml ]]; then
      __func_return="maven"
      return 1;
    fi

    if [[ -f ${__private_build_compiler_dir}/Makefile.txt ]]; then
      __func_return="cmake"
      return 1;
    fi

    __private_build_compiler_check=$(find ${__private_build_compiler_dir} -name '*.pro')
    if [[ ${__private_build_compiler_check} != ""  ]]; then
      __func_return="qmake"
      return 1;
    fi
  fi

  return 0;

}

function mavenBuild()
{
  export __func_return=
  __mvn_build_src_dir=${1}
  __mvn_build_bin_dir=${2}
  __mvn_jar_filter=${3}

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

  __mvn_cmd="mvn install -DskipTests"
  echM "    Maven build"
  echC "      - Source dir: ${__mvn_build_src_dir}"
  echY "      - ${__mvn_cmd}"
  __mvn_output=$(${__mvn_cmd})
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
  export __mvn_jar_source_file=$(find ${__mvn_build_src_bin_dir} -name ${__mvn_jar_filter})
  echC "      - JAR file: ${__mvn_jar_source_file}"
  if [[ ${__mvn_jar_source_file} == "" ]]; then
    echR "      ==============================  "
    echR "      ******JAR file not found******  "
    echR "      ******JAR file not found******  "
    echR "      ==============================  "
    return 0;
  fi
  echG "    Finished"
  export __func_return=${__mvn_jar_source_file}
  return 1
}
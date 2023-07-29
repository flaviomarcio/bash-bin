#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  export BASH_BIN=${PWD}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh

function buildCompilerCheck()
{
  __private_build_compiler_dir=${1}
  __func_return=
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

function qtBuild()
{
  export __func_return=

  __qtBuild_src_dir=${1}
  __qtBuild_project_filter=${2}
  __qtBuild_qt_version=${QT_VERSION}

  if [[ ${__qtBuild_qt_version} == "" ]]; then
    __qtBuild_qt_version="6.5.1"
  fi

  if [[ ${__qtBuild_qt_root_dir} == "" ]]; then
    __qtBuild_qt_root_dir=${HOME}/Qt
  fi

  #base envs
  __qtBuild_project_file=$(realpath $(find -name ${__qtBuild_project_filter}))
  __qtBuild_build_dir="${HOME}/build/qt-$(basename ${PWD})-$(basename ${__qtBuild_project_file})"
  __qtBuild_build_dir=$(echo ${__qtBuild_build_dir} | sed 's/.pro//g')
  __qtBuild_target_name=app
  __qtBuild_target_file=${__qtBuild_build_dir}/${__qtBuild_target_name}
  __qtBuild_qt_library_path=${__qtBuild_qt_root_dir}/${__qtBuild_qt_version}/gcc_64
  __qtBuild_qt_bin_dir=${__qtBuild_qt_library_path}/bin
  __qtBuild_qt_lib_dir=${__qtBuild_qt_library_path}/lib
  __qtBuild_qt_plugin_dir=${__qtBuild_qt_library_path}/plugins
  __qtBuild_qmake=${__qtBuild_qt_bin_dir}/qmake


  echG "  Source building with Qt/QMake"
  if [[ ${__qtBuild_qt_version} == "" ]]; then
    echR "      - Invalid __Invalid qt version: ${__qtBuild_qt_version}"
  elif [[ ${__qtBuild_src_dir} == "" ]]; then
    echR "      - Invalid __Invalid source dir: ${__qtBuild_src_dir}"
  elif ! [[ -d ${__qtBuild_qt_root_dir} ]]; then
    echR "      - Invalid __qtBuild_qt_root_dir: ${__qtBuild_qt_root_dir}"
  elif ! [[ -d ${__qtBuild_qt_library_path} ]]; then
    echR "      - Invalid __qtBuild_qt_library_path: ${__qtBuild_qt_library_path}"
  elif ! [[ -d ${__qtBuild_qt_bin_dir} ]]; then
    echR "      - Invalid __qtBuild_qt_bin_dir: ${__qtBuild_qt_bin_dir}"
  elif ! [[ -d ${__qtBuild_qt_lib_dir} ]]; then
    echR "      - Invalid __qtBuild_qt_lib_dir: ${__qtBuild_qt_lib_dir}"
  elif ! [[ -d ${__qtBuild_qt_plugin_dir} ]]; then
    echR "      - Invalid __qtBuild_qt_plugin_dir: ${__qtBuild_qt_plugin_dir}"
  elif ! [[ -f ${__qtBuild_qmake} ]]; then
    echR "      - Invalid __qtBuild_qmake: ${__qtBuild_qmake}"
  elif ! [[ -f ${__qtBuild_project_file} ]]; then
    echR "      - Invalid __qtBuild_project_file: ${__qtBuild_project_file}"
  else
    #build
    QT_PLUGIN_PATH=${__qtBuild_qt_plugin_dir}
    QT_QPA_PLATFORM_PLUGIN_PATH=${__qtBuild_qt_lib_dir}:${QT_PLUGIN_PATH}
    LD_LIBRARY_PATH=${__qtBuild_qt_library_path}
    rm -rf ${__qtBuild_build_dir}
    mkdir -p ${__qtBuild_build_dir};

    cd ${__qtBuild_build_dir}
    echM "    QMake running"
    echC "      - source dir: ${__qtBuild_src_dir}"
    echY "      - qmake TARGET=${__qtBuild_target_name} CONFIG+=release $(basename ${__qtBuild_project_file})"
    echo $( \
            ${__qtBuild_qmake} \
            DESTDIR=${__qtBuild_build_dir} \
            TARGET=${__qtBuild_target_name} \
            CONFIG-=debug CONFIG+=release \
            ${__qtBuild_project_file}\
        )&>/dev/null
    echM "    Make running"
    echC "      - build dir: ${__qtBuild_src_dir}"
    echY "      - make --silent --quiet -j12"
    echo $(make --silent --quiet -j12)&>/dev/null
    if ! [[ -f ${__qtBuild_target_file} ]]; then
      echR "      - Invalid__target file: ${__qtBuild_target_file}"
    else
      export __func_return=${__qtBuild_target_file}
    fi
  fi
  echG "    Finished"
  if [[ ${__func_return} == "" ]]; then
    return 0
  fi
  return 1
}

function mavenBuild()
{
  export __func_return=
  __mvn_build_src_dir=${1}
  __mvn_jar_filter=${2}

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

  cd ${__mvn_build_src_dir}
  __mvn_build_base_dir=$(dirname ${__mvn_build_src_dir});
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
  else
    export __mvn_jar_source_files=$(find ${__mvn_build_src_bin_dir} -name ${__mvn_jar_filter})
  
    if [[ ${__mvn_jar_source_files} == "" ]]; then
    echR "      ==============================  "
    echR "      ******JAR file not found******  "
    echR "      ******JAR file not found******  "
    echR "      ==============================  "
    else
      __mvn_jar_source_files=(${__mvn_jar_source_files})
      for __mvn_jar_source_file in "${__mvn_jar_source_files[@]}"
      do
        __mvn_jar_source_file_new=${__mvn_build_base_dir}/$(basename ${__mvn_jar_source_file})
        mv ${__mvn_jar_source_file} ${__mvn_jar_source_file_new}
        export __func_return="${__func_return} ${__mvn_jar_source_file_new}"
        echC "      - JAR file: ${__mvn_jar_source_file_new}"
      done
    fi
  fi
  cd ${__mvn_build_base_dir}
  rm -rf ${__mvn_build_src_dir}

  if [[ ${__func_return} == "" ]]; then
    return 0
  else
    return 1
  fi
  echG "    Finished"
}
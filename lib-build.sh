#!/bin/bash

if [[ ${BASH_BIN} == "" ]]; then
  BASH_BIN=${PWD}
fi

if [[ ${BASH_BIN_BIN} == "" ]]; then
  BASH_BIN_BIN=${BASH_BIN}/bin
  export PATH=${PATH}:${BASH_BIN_BIN}
fi

. ${BASH_BIN}/lib-strings.sh
. ${BASH_BIN}/lib-system.sh


export __upx_binary=${BASH_BIN}/bin/upx


function buildCompilerCheck()
{
  local __private_build_compiler_dir=${1}
  unset __func_return
  if [[ -d ${__private_build_compiler_dir}  ]]; then
    if [[ ${APPLICATION_ACTION} == "script" ]]; then
      export __func_return="script"
      return 1;
    fi


    if [[ -f ${__private_build_compiler_dir}/pom.xml ]]; then
      export __func_return="maven"
      return 1;
    fi

    if [[ -f ${__private_build_compiler_dir}/Makefile.txt ]]; then
      export __func_return="cmake"
      return 1;
    fi

    __private_build_compiler_check=$(find ${__private_build_compiler_dir} -name '*.pro')
    if [[ ${__private_build_compiler_check} != ""  ]]; then
      export __func_return="qmake"
      return 1;
    fi
  fi

  return 0;

}

function qtBuild()
{
  unset __func_return

  local __qtBuild_src_dir=${1}
  local __qtBuild_project_filter=${2}
  local __qtBuild_qt_version=${QT_VERSION}

  if [[ ${__qtBuild_qt_version} == "" ]]; then
    local __qtBuild_qt_version="6.5.2"
  fi

  if [[ ${__qtBuild_qt_root_dir} == "" ]]; then
    local __qtBuild_qt_root_dir=${HOME}/Qt
  fi

  #base envs
  local __qtBuild_base_dir=$(dirname ${__qtBuild_src_dir})
  local __qtBuild_project_file=$(realpath $(find ${__qtBuild_src_dir} -name ${__qtBuild_project_filter}))
  local __qtBuild_build_dir="${HOME}/build/qt-$(basename ${PWD})-$(basename ${__qtBuild_project_file})"
  local __qtBuild_build_dir=$(echo ${__qtBuild_build_dir} | sed 's/.pro//g')
  local __qtBuild_target_name=app
  local __qtBuild_target_file=${__qtBuild_build_dir}/${__qtBuild_target_name}
  local __qtBuild_qt_library_path=${__qtBuild_qt_root_dir}/${__qtBuild_qt_version}/gcc_64
  local __qtBuild_qt_bin_dir=${__qtBuild_qt_library_path}/bin
  local __qtBuild_qt_lib_dir=${__qtBuild_qt_library_path}/lib
  local __qtBuild_qt_plugin_dir=${__qtBuild_qt_library_path}/plugins
  local __qtBuild_qmake=${__qtBuild_qt_bin_dir}/qmake

  echG "  Source building with Qt/QMake"
  if ! [[ -d ${__qtBuild_qt_root_dir} ]]; then
    echR "      - Invalid qt root dir: ${__qtBuild_qt_root_dir}"
  elif [[ ${__qtBuild_qt_version} == "" ]]; then
    echR "      - Invalid qt version: ${__qtBuild_qt_version}"
  elif ! [[ -d ${__qtBuild_qt_library_path} ]]; then
    echR "      - Invalid qt library path: ${__qtBuild_qt_library_path}"
  elif ! [[ -d ${__qtBuild_qt_bin_dir} ]]; then
    echR "      - Invalid qt bin dir: ${__qtBuild_qt_bin_dir}"
  elif ! [[ -d ${__qtBuild_qt_lib_dir} ]]; then
    echR "      - Invalid qt lib dir: ${__qtBuild_qt_lib_dir}"
  elif ! [[ -d ${__qtBuild_qt_plugin_dir} ]]; then
    echR "      - Invalid qt plugin dir: ${__qtBuild_qt_plugin_dir}"
  elif ! [[ -f ${__qtBuild_qmake} ]]; then
    echR "      - Invalid qmake application: ${__qtBuild_qmake}"
  elif [[ ${__qtBuild_src_dir} == "" ]]; then
    echR "      - Invalid source dir: ${__qtBuild_src_dir}"
  elif ! [[ -f ${__qtBuild_project_file} ]]; then
    echR "      - Invalid project file: ${__qtBuild_project_file}"
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
      echR "      - Invalid qt target file: ${__qtBuild_target_file}"
    else
      local __qtBuild_target_file_final=${__qtBuild_base_dir}/${__qtBuild_target_name}
      cp -rf ${__qtBuild_target_file} ${__qtBuild_target_file_final}
      cd ${__qtBuild_base_dir};
      rm -rf ${__qtBuild_src_dir}
      export __func_return=${__qtBuild_target_file_final}
    fi
    echG "    Finished"
    if [[ ${__func_return} != "" ]]; then
      echM "    UPX steps"
      echC "      - target: ${__func_return}"
      echC "      - upx version: $(${__upx_binary} --version | sed -n '1p')"
      echY "        strip (basename ${__func_return})"
      echo $(strip ${__func_return})&>/dev/null
      echY "        upx --best --lzma (basename ${__func_return})"
      echo $(${__upx_binary} --best --lzma ${__func_return})&>/dev/null
      echG "    Finished"
    fi    
  fi
  echG "  Finished"
  if [[ ${__func_return} == "" ]]; then
    return 0
  fi
  return 1
}

function mavenBuild()
{
  unset __func_return
  local __mvn_build_src_dir=${1}
  local __mvn_jar_filter=${2}

  echG "  Source building with Maven"
  local __mvn_check=$(which mvn)
  if [[ ${__mvn_check} == ""  ]]; then
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
  local __mvn_build_base_dir=$(dirname ${__mvn_build_src_dir});
  local __mvn_build_src_bin_dir=${__mvn_build_src_dir}/target

  local __mvn_cmd="mvn install -DskipTests"
  echM "    Maven build"
  echC "      - Source dir: ${__mvn_build_src_dir}"
  echY "      - ${__mvn_cmd}"
  local __mvn_output=$(${__mvn_cmd})
  local __mvn_check=$(echo ${__mvn_output} | grep ERROR)
  if [[ ${__mvn_check} != "" ]]; then
    echR "    source build fail:"
    echR "    ==============================  "
    echR "    *******Maven build fail*******  "
    echR "    *******Maven build fail*******  "
    echR "    ==============================  "
    printf "${__mvn_output}"
  else
    local __mvn_cmd="mvn help:evaluate -Dexpression=project.build.finalName -q -DforceStdout"
    echY "      - ${__mvn_cmd}"
    #__mvn_jar_filter=$(mvn help:evaluate -Dexpression=project.build.finalName -q -DforceStdout)
    local __mvn_jar_filter="app-0.0.1-SNAPSHOT.jar"
    #binary jar file name
    local __mvn_jar_source_file=${__mvn_build_src_bin_dir}/${__mvn_jar_filter}
    echG "      - jar file: ${__mvn_jar_source_file}"
    if ! [[ -f ${__mvn_jar_source_file} ]]; then
      echY "      jar file: ${__mvn_jar_source_file}"
      echR "      ==============================  "
      echR "      ******JAR file not found******  "
      echR "      ******JAR file not found******  "
      echR "      ==============================  "
    else
      local __mvn_jar_source_file_new=${__mvn_build_base_dir}/$(basename ${__mvn_jar_source_file})
      mv ${__mvn_jar_source_file} ${__mvn_jar_source_file_new}
      export __func_return="${__func_return} ${__mvn_jar_source_file_new}"
      echC "      - JAR file: ${__mvn_jar_source_file_new}"
    fi
  fi
  cd ${__mvn_build_base_dir}
  rm -rf ${__mvn_build_src_dir}
  echG "    Finished"
  if [[ ${__func_return} == "" ]]; then
    return 0
  fi
  return 1
}

function execScript()
{
  unset __func_return
  local __src_dir=${1}
  local __src_script=${2}

  echG "  Source building with script"
  if ! [[ -d ${__src_dir} ]]; then
    echY "  source dir: ${__src_dir}"
    echR "  ==============================  "
    echR "       ********************       "
    echR "  *****Source dir not found*****  "
    echR "       ********************       "
    echR "  ==============================  "
    return 0;
  fi

  cd ${__src_dir}
  local __src_script_path="${__src_dir}/${__src_script}"
  if ! [[ -f ${__src_script_path} ]]; then
    echY "  script: ${__src_script_path}"
    echR "  ==============================  "
    echR "     ************************     "
    echR "  *******SCRIPT NOT FOUND*******  "
    echR "     ************************     "
    echR "  ==============================  "
    return 0
  fi

  echG "    - command"
  echY "      - source ./${__src_script_path} --quiet"

  source ${__src_script_path}
  if [[ ${__func_return} == "" || ${__func_return} == "true" ]]; then
    echG "    Finished"
    return 1;
  fi
  echR "    fault on calling ./${__src_script_path}"
  echR "      - ${__func_return}"
  return 0
}

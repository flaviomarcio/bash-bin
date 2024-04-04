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


export __upx_binary=${BASH_BIN}/bin/upx


function buildCompilerCheck()
{
  local __dir=${1}
  unset __func_return
  if [[ -d ${__dir}  ]]; then
    if [[ ${APPLICATION_ACTION} == "script" ]]; then
      export __func_return="script"
      return 1;
    fi

    if [[ -f ${__dir}/pom.xml ]]; then
      export __func_return="maven"
      return 1;
    fi

    if [[ -f ${__dir}/Makefile.txt ]]; then
      export __func_return="cmake"
      return 1;
    fi

    if [[ -f ${__dir}/package.json ]]; then
      export __func_return="node"
      return 1;
    fi

    local __check=$(find ${__dir} -name '*.pro')
    if [[ ${__check} != ""  ]]; then
      export __func_return="qmake"
      return 1;
    fi
  fi

  return 0;

}

function qtBuild()
{
  unset __func_return

  local __src_dir=${1}
  local __project_filter=${2}
  local __version=${QT_VERSION}

  if [[ ${__version} == "" ]]; then
    local __version="6.5.2"
  fi

  if [[ ${__root_dir} == "" ]]; then
    local __root_dir=${HOME}/Qt
  fi

  #base envs
  local __base_dir=$(dirname ${__src_dir})
  local __project_file=$(realpath $(find ${__src_dir} -name ${__project_filter}))
  local __build_dir="${HOME}/build/qt-$(basename ${PWD})-$(basename ${__project_file})"
  local __build_dir=$(echo ${__build_dir} | sed 's/.pro//g')
  local __target_name=app
  local __target_file=${__build_dir}/${__target_name}
  local __library_path=${__root_dir}/${__version}/gcc_64
  local __bin_dir=${__library_path}/bin
  local __lib_dir=${__library_path}/lib
  local __plugin_dir=${__library_path}
  local __qmake=${__bin_dir}/qmake

  echG "  Source building with Qt/QMake"
  if ! [[ -d ${__root_dir} ]]; then
    echR "      - Invalid qt root dir: ${__root_dir}"
  elif [[ ${__version} == "" ]]; then
    echR "      - Invalid qt version: ${__version}"
  elif ! [[ -d ${__library_path} ]]; then
    echR "      - Invalid qt library path: ${__library_path}"
  elif ! [[ -d ${__bin_dir} ]]; then
    echR "      - Invalid qt bin dir: ${__bin_dir}"
  elif ! [[ -d ${__lib_dir} ]]; then
    echR "      - Invalid qt lib dir: ${__lib_dir}"
  elif ! [[ -d ${__plugin_dir} ]]; then
    echR "      - Invalid qt plugin dir: ${__plugin_dir}"
  elif ! [[ -f ${__qmake} ]]; then
    echR "      - Invalid qmake application: ${__qmake}"
  elif [[ ${__src_dir} == "" ]]; then
    echR "      - Invalid source dir: ${__src_dir}"
  elif ! [[ -f ${__project_file} ]]; then
    echR "      - Invalid project file: ${__project_file}"
  else
    #build
    local QT_PLUGIN_PATH=${__plugin_dir}
    local QT_QPA_PLATFORM_PLUGIN_PATH=${__lib_dir}:${QT_PLUGIN_PATH}
    local LD_LIBRARY_PATH=${__library_path}
    rm -rf ${__build_dir}
    mkdir -p ${__build_dir};

    cd ${__build_dir}
    echM "    QMake running"
    echC "      - source dir: ${__src_dir}"
    echY "      - qmake TARGET=${__target_name} CONFIG+=release $(basename ${__project_file})"
    echo $( \
            ${__qmake} \
            DESTDIR=${__build_dir} \
            TARGET=${__target_name} \
            CONFIG-=debug CONFIG+=release \
            ${__project_file}\
        )&>/dev/null
    echM "    Make running"
    echC "      - build dir: ${__src_dir}"
    echY "      - make --silent --quiet -j12"
    echo $(make --silent --quiet -j12)&>/dev/null
    if ! [[ -f ${__target_file} ]]; then
      echR "      - Invalid qt target file: ${__target_file}"
    else
      local __target_file_final=${__base_dir}/${__target_name}
      cp -rf ${__target_file} ${__target_file_final}
      cd ${__base_dir};
      rm -rf ${__src_dir}
      export __func_return=${__target_file_final}
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
  local __build_src_dir=${1}
  local __jar_filter=${2}

  echG "  Source building with Maven"
  local __check=$(which mvn)
  if [[ ${__check} == ""  ]]; then
    echR "  ==============================  "
    echR "     ************************     "
    echR "  ***MAVEN não está instalado***  "
    echR "     ************************     "
    echR "  ==============================  "
    return 0
  fi
  if ! [[ -d ${__build_src_dir} ]]; then
    echR "  ==============================  "
    echR "       ********************       "
    echR "  *****Source dir no exists*****  "
    echR "       ********************       "
    echR "  ==============================  "
    return 0;
  fi
  if ! [[ -f "${__build_src_dir}/pom.xml" ]]; then
    echR "  ==============================  "
    echR "           *************          "
    echR "  *********POM no exists*******"
    echR "           *************          "
    echR "  ==============================  "
    return 0;
  fi

  cd ${__build_src_dir}
  local __build_base_dir=$(dirname ${__build_src_dir});
  local __build_src_bin_dir=${__build_src_dir}/target

  local __cmd="mvn install -DskipTests"
  echM "    Maven build"
  echC "      - Source dir: ${__build_src_dir}"
  echY "      - ${__cmd}"
  local __output=$(${__cmd})
  local __check=$(echo ${__output} | grep ERROR)
  if [[ ${__check} != "" ]]; then
    echR "    source build fail:"
    echR "    ==============================  "
    echR "    *******Maven build fail*******  "
    echR "    *******Maven build fail*******  "
    echR "    ==============================  "
    printf "${__output}"
  else
    local __cmd="mvn help:evaluate -Dexpression=project.build.finalName -q -DforceStdout"
    echY "      - ${__cmd}"
    #__jar_filter=$(mvn help:evaluate -Dexpression=project.build.finalName -q -DforceStdout)
    local __jar_filter="app-0.0.1-SNAPSHOT.jar"
    #binary jar file name
    local __jar_source_file=${__build_src_bin_dir}/${__jar_filter}
    echG "      - jar file: ${__jar_source_file}"
    if ! [[ -f ${__jar_source_file} ]]; then
      echY "      jar file: ${__jar_source_file}"
      echR "      ==============================  "
      echR "      ******JAR file not found******  "
      echR "      ******JAR file not found******  "
      echR "      ==============================  "
    else
      local __jar_source_file_new=${__build_base_dir}/$(basename ${__jar_source_file})
      mv ${__jar_source_file} ${__jar_source_file_new}
      export __func_return="${__func_return} ${__jar_source_file_new}"
      echC "      - JAR file: ${__jar_source_file_new}"
    fi
  fi
  cd ${__build_base_dir}
  rm -rf ${__build_src_dir}
  echG "    Finished"
  if [[ ${__func_return} == "" ]]; then
    return 0
  fi
  return 1
}

function nodeBuild()
{
  unset __func_return
  local __build_src_dir=${1}
  local __jar_filter=${2}

  echG "  Source building with PHP"
  local __check=$(which node)
  if [[ ${__check} == "" ]]; then
    echR "  ====================  "
    echR "     **************     "
    echR "  ***NODE not found***  "
    echR "     **************     "
    echR "  ====================  "
    return 0
  fi
  if ! [[ -d ${__build_src_dir} ]]; then
    echR "  ==============================  "
    echR "       ********************       "
    echR "  *****Source dir not found*****  "
    echR "       ********************       "
    echR "  ==============================  "
    return 0;
  fi
  if [[ -f ${__build_src_dir}/package.json ]]; then
    echR "  ============================  "
    echR "     **********************     "
    echR "  ***package.json not found***  "
    echR "     **********************     "
    echR "  ============================  "
    return 0
  fi
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
  echY "      - source ${__src_script_path} --quiet"

  source ${__src_script_path} --quiet
  if [[ ${__func_return} == "" || ${__func_return} == "true" ]]; then
    echG "    Finished"
    return 1;
  fi
  echR "    fault on calling ./${__src_script_path}"
  echR "      - ${__func_return}"
  return 0
}
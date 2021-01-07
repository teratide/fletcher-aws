#!/bin/bash

if [[ $# -lt 2 ]];
then
  echo "Usage: project-generate.sh PROJECT-NAME VHDL_PATH [VHDEPS_INCLUDE_DIRS]..."
  echo "The VHDL_PATH should contain your design with an AxiTop module that was generated by Fletcher."
  echo "(You should have implemented your own kernels based on the Fletcher-generated files)"
  echo "If there are other directories that contain source files, include them as arguments with -i"
  exit 1
fi

#TODO: check it is named vhdl and convert into absolute path
VHDL_PATH="$2"
PROJ_NAME="$1"
VHDEPS_INCLUDE_ARGS="${@:3}"

if [ -e "$PROJ_NAME" ]; then
  echo "Project name already exists"
  exit 1
fi

cp --recursive --no-dereference skeleton "$PROJ_NAME"
cd "$PROJ_NAME"



for version in 1DDR 4DDR; do
  cd $version
  # copy vhdl dir into project/design
  cp --recursive --no-dereference "$VHDL_PATH" design/

  # Get an list (in compile order) of source files from vhdeps, place it in build/scripts/encrypt.tcl (replacing #FLETCHER_AXITOP_VHDL_FILES) 
  # and verif/scripts/top.vivado.vhdl.f
  if ! cd design/vhdl; then
    echo "vhdl directory not found, please make sure you have referenced a Fletcher-generated directory that is named 'vhdl'."
    exit -1
  else
    vhdeps -i . ${VHDEPS_INCLUDE_ARGS} dump AxiTop > sources.tmp.txt
    cut -d ' ' -f4 sources.tmp.txt > sources.txt
    cp sources.txt ../../verif/scripts/top.vivado.vhdl.f #These are now absolute paths
    
    sed -e 's<^<file copy -force <' sources.txt > sources.encrypt.tmp.txt
    sed -e 's<$< $TARGET_DIR<' sources.encrypt.tmp.txt > sources.encrypt.txt
    sed -e 's<#FLETCHER_AXITOP_VHDL_FILES<cat sources.encrypt.txt; echo "&"<e' ../../build/scripts/encrypt.tcl.template > ../../build/scripts/encrypt.tcl
    rm ../../build/scripts/encrypt.tcl.template
    sed -i -e 's<#FLETCHER_AXITOP_VHDL_FILES<<' ../../build/scripts/encrypt.tcl
    cd ../..
  fi
  cd ..
done;



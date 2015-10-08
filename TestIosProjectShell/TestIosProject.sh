#!/bin/bash

#--------------------------------------------
# 功能：
#		编译project
#--------------------------------------------

echo "Test..."

if [$# -lt 0]; then
	echo " Error! "
fi

echo "Test1..."

param_pattern=":u:v:m:"
base_uri='https://github.com/MrsJIeYang/TestIosProject.git'
testIosProject_version='' 
checkout_mode='fresh'

while getopts "$param_pattern" opt; do
	case "$opt" in
		"u" )
			base_uri=$OPTARG
			;;
		"v")
			testIosProject_version=$OPTARG
			;;
		"m")
			checkout_mode=$OPTARG
	esac
done

if [ ${checkout_mode} = fresh ];then
	echo "Test2..."
	#clean_repo="rm -rf ${dir_path}"
	#${clean_repo}
	#checkout libraries
	#git clone ${base_uri} ${dir_path}
	git fetch --all  
	git reset --hard origin/master 
	git submodule update --init

	echo "Test3..."
fi
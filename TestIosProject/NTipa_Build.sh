#!/bin/bash

#--------------------------------------------
# 功能：编译xcode项目并打ipa包
# 使用说明：
#		编译project
#			ipa-build <project directory> [-c <project configuration>] [-o <ipa output directory>] [-t <target name>] [-n]
#		编译workspace
#			ipa-build  <workspace directory> -w -s <schemeName> [-c <project configuration>] [-n]
#
# 参数说明：-c NAME				工程的configuration,默认为Release。
#			-o PATH				生成的ipa文件输出的文件夹（必须为已存在的文件路径）默认为工程根路径下的”build/ipa-build“文件夹中
#			-t NAME				需要编译的target的名称
#			-w					编译workspace	
#			-s NAME				对应workspace下需要编译的scheme
#			-n					编译前是否先clean工程
#---------------------------------------------
echo "Test one..."
if [ $# -lt 1 ];then
    echo "Error! "
echo "Test two..."
echo " 参数1: -o（必须 output）"
echo "****************************************************************"
echo "                     输入工程绝对路径                        	  "
echo "****************************************************************"
echo " 参数1: -w（非必须 workspace）"
echo "****************************************************************"
echo "                     1. TestIosProject.xcworkspace              "
echo "****************************************************************"
echo " 参数2: -s（scheme 如果有workspace 为必须）"
echo "****************************************************************"
echo "                     1. TestIosProject                    	  "
echo "****************************************************************"
echo " 参数2: -c（非必须 configuration）"
echo "****************************************************************"
echo "                     1. Debug                                   "
echo "                     2. Release                                 "
echo "****************************************************************"
echo " 参数3: -a（非必须 application）"
echo "****************************************************************"
echo "                     1. TestIosProject                          "
echo "****************************************************************"
echo " 参数4: -t（非必须 target）"
echo "****************************************************************"
echo "                     1. TestIosProject                   		  "
echo "****************************************************************"

	exit 2
fi

#设定各个参数
param_pattern=":n:c:o:t:w:s:a:m:"
build_config="Debug"
appdirname="Debug-iphoneos"
with_time=false

while getopts "$param_pattern" opt; do
    case "$opt" in
        "o")
            project_path=$OPTARG
            ;;
        "w")
			build_workspace=$OPTARG
            ;;
        "s")
			build_scheme=$OPTARG
            ;;
        "t")
            build_target=$OPTARG
            ;;
        "c")
            build_config=$OPTARG
            if [ "$build_config" = "Debug" ];then
                appdirname="Debug-iphoneos"
            elif [ "$build_config" = "AdHoc" ];then
                appdirname="AdHoc-iphoneos"
            elif [ "$build_config" = "Release" ];then
                appdirname="Release-iphoneos"
            else
                appdirname="Debug-iphoneos"
            fi
            ;;
        "a")
            build_app=$OPTARG
            if [  "$build_app" = "TestIosProject" ];then
                if [ "$build_config" = "Release" ];then
                    certificate="iPhone Distribution: Shanghai TianMengYunHe Investment Center(Limited Partnership) (JHP8B47P62)"
                    profile_name="LifeAdhoc"
                else
                    certificate="iPhone Developer: Xu Deliang (9W673N38DR)"
                    profile_name="LifeDev"
                fi
			else
				echo "Error!"
				exit
			fi
			;;
		"m")
			with_time=true
			;;
        "\?")
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

#工程绝对路径
cd "$project_path"
project_path=$(pwd)

echo "project path: $project_path"

#build文件夹路径
build_path=${project_path}/${build_app}/build
compiled_path=${build_path}

#xcode MedicalRecordsFolder clean
cd "${project_path}/${build_app}/"
xcodebuild clean || exit 1

customized_clean_cmd="sh ${project_path}/${build_app}/NTipa_Build_Clean_Customized.sh ${project_path}"
echo "EXEC: ${customized_clean_cmd}"
${customized_clean_cmd} || exit 1

cd "$project_path"

echo ======= clean success==========

#组合编译命令
build_cmd='xcodebuild'

if [ "$build_workspace" != "" ];then
	#编译workspace
	if [ "$build_scheme" = "" ];then
		echo "Error! Must provide a scheme by -s option together when using -w option to compile a workspace."
		exit 2
	fi
	build_cmd=${build_cmd}' -sdk iphoneos -workspace '${build_workspace}' -scheme '${build_scheme}' -configuration '${build_config}' CONFIGURATION_BUILD_DIR='${compiled_path}/${appdirname}' ONLY_ACTIVE_ARCH=NO'

else
	#编译project
	build_cmd=${build_cmd}' -configuration '${build_config}

	if [ "$build_target" != "" ];then
        build_cmd=${build_cmd}' -target '${build_target}
	fi
fi

echo "execute: $build_cmd"

#编译工程
cd $project_path
#build_cmd=${build_cmd}' CODE_SIGN_IDENTITY='${certificate}

$build_cmd || exit 1

#进入build路径
cd $build_path

#创建ipa-build文件夹
if [ -d ./ipa-build ];then
	rm -rf ipa-build
fi
mkdir ipa-build

#app文件名称
appname=$(basename ${build_path}/${appdirname}/*.app)

#通过app文件名获得工程target名字
target_name=$(echo $appname | awk -F. '{print $1}')
#app文件中Info.plist文件路径
app_infoplist_path=${build_path}/${appdirname}/${appname}/Info.plist
#取版本号
bundleShortVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${app_infoplist_path})
#取build值
bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_infoplist_path})

#IPA名称
if [ "$with_time" = "true" ];then
   ipa_name="${target_name}_${bundleShortVersion}_${build_config}${bundleVersion}_$(date +"%Y%m%d%H%M%S")"
else
   ipa_name="${target_name}${bundleShortVersion}"
fi
echo $ipa_name

#xcrun打包
#xcrun -sdk iphoneos PackageApplication -v ${build_path}/${appdirname}/*.app -o ${build_path}/ipa-build/${ipa_name}.ipa || exit
xcrun_cmd='xcrun -sdk iphoneos PackageApplication -v '${build_path}'/'${appdirname}'/*.app -o '${build_path}'/ipa-build/'${ipa_name}'.ipa' || exit 1

if [ -n "$build_app" ];then
	xcrun_cmd=${xcrun_cmd}' —sign '\"${certificate}\" 
	PROVISIONING_PROFILE='/Users/'${USER}'/Library/MobileDevice/Provisioning Profiles/'${profile_name}'.mobileprovision'
	xcrun_cmd=${xcrun_cmd}' —embed '"$PROVISIONING_PROFILE"
fi

echo "$xcrun_cmd"
$xcrun_cmd||exit

if [ "$output_path" != "" ];then
	cp ${build_path}/ipa-build/${ipa_name}.ipa $output_path/${ipa_name}.ipa
	echo "Copy ipa file successfully to the path $output_path/${ipa_name}.ipa"
fi




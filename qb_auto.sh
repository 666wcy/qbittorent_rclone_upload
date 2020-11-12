#!/bin/sh
torrent_name=$1
content_dir=$2
root_dir=$3
save_dir=$4
files_num=$5
torrent_size=$6
file_hash=$7
#将下列命令添加至qb的下载完成后运行
#bash /upload/qb_auto.sh  "%N" "%F" "%R" "%D" "%C" "%Z" "%I"
DRIVE_NAME='onedrive'   # 挂载盘名称
DRIVE_PATH='/upload'		#上传到盘的地址，后面没有 /
DOWNLOAD_PATH='/downloads/'		#qb下载默认地址

RETRY_NUM=3		#rclone上传重试次数

qb_version="4.3.0.1"  #qb版本
qb_username=""        #qb用户名
qb_password=""        #qb密码
qb_web_url="http://localhost:8080"   #qb web地址
leeching_mode="false"  #true为自动删除上传的种子
log_dir="/config/log"  #日志保存地址
auto_del_flag="test"   #上传完成后将种子标记的标签


if [ ! -d ${log_dir} ]
then
	mkdir -p ${log_dir}
fi

version=$(echo $qb_version | grep -P -o "([0-9]\.){2}[0-9]" | sed s/\\.//g)


RED_FONT_PREFIX="\033[31m"
LIGHT_GREEN_FONT_PREFIX="\033[1;32m"
YELLOW_FONT_PREFIX="\033[1;33m"
LIGHT_PURPLE_FONT_PREFIX="\033[1;35m"
FONT_COLOR_SUFFIX="\033[0m"
INFO="[${LIGHT_GREEN_FONT_PREFIX}INFO]"
ERROR="[${RED_FONT_PREFIX}ERROR]"
WARRING="[${YELLOW_FONT_PREFIX}WARRING]"





function UPLOAD_FILE() {
    echo -e "$(DATE_TIME) ${INFO} Start upload files..."
    RETRY=0
    while [ ${RETRY} -le ${RETRY_NUM} ]; do
        [ ${RETRY} != 0 ] && (
            echo
            echo -e "$(DATE_TIME) ${ERROR} Upload failed! Retry ${RETRY}/${RETRY_NUM} ..."
            echo
        )
        echo ${UPLOAD_PATH}
        echo ${REMOTE_PATH}
        rclone copy -v "${UPLOAD_PATH}" "${REMOTE_PATH}"
        RCLONE_EXIT_CODE=$?
        if [ ${RCLONE_EXIT_CODE} -eq 0 ]; then
            
            break
        else
            RETRY=$((${RETRY} + 1))
            [ ${RETRY} -gt ${RETRY_NUM} ] && (
                echo "$(DATE_TIME) ${ERROR} Upload failed: ${UPLOAD_PATH}"
               
            )
            sleep 3
        fi
    done
}




function qb_login(){
	if [ ${version} -gt 404 ]
	then
		qb_v="1"
		cookie=$(curl -i --header "Referer: ${qb_web_url}" --data "username=${qb_username}&password=${qb_password}" "${qb_web_url}/api/v2/auth/login" | grep -P -o 'SID=\S{32}')
		if [ -n ${cookie} ]
		then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}" >> ${log_dir}/autodel.log

		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败！" >> ${log_dir}/autodel.log
		fi
	elif [[ ${version} -le 404 && ${version} -ge 320 ]]
	then
		qb_v="2"
		cookie=$(curl -i --header "Referer: ${qb_web_url}" --data "username=${qb_username}&password=${qb_password}" "${qb_web_url}/login" | grep -P -o 'SID=\S{32}')
		if [ -n ${cookie} ]
		then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}" >> ${log_dir}/autodel.log
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败" >> ${log_dir}/autodel.log
		fi
	elif [[ ${version} -ge 310 && ${version} -lt 320 ]]
	then
		qb_v="3"
		echo "陈年老版本，请及时升级"
		exit
	else
		qb_v="0"
		exit
	fi
}



function qb_del(){
	if [ ${leeching_mode} == "true" ]
	then
		if [ ${qb_v} == "1" ]
		then
			curl "${qb_web_url}/api/v2/torrents/delete?hashes=${file_hash}&deleteFiles=true" --cookie ${cookie}
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}" >> ${log_dir}/qb.log
		elif [ ${qb_v} == "2" ]
		then
			curl -X POST -d "hashes=${file_hash}" "${qb_web_url}/command/deletePerm" --cookie ${cookie}
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子文件:${torrent_name}" >> ${log_dir}/qb.log
			echo "qb_v=${qb_v}" >> ${log_dir}/qb.log
		fi
	else
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子" >> ${log_dir}/qb.log
	fi
}


function qb_add_auto_del_tags(){
	if [ ${qb_v} == "1" ]
	then
		curl -X POST -d "hashes=${file_hash}&tags=${auto_del_flag}" "${qb_web_url}/api/v2/torrents/addTags" --cookie "${cookie}"
	elif [ ${qb_v} == "2" ]
	then
		curl -X POST -d "hashes=${file_hash}&category=${auto_del_flag}" "${qb_web_url}/command/setCategory" --cookie ${cookie}
	else
		echo "qb_v=${qb_v}" >> ${log_dir}/qb.log
	fi
}

echo ${content_dir}
if [ -f "${content_dir}" ]
then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：文件"
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：文件" >> ${log_dir}/qb.log
   type="file"
   
    
    
    RELATIVE_PATH=${content_dir#${DOWNLOAD_PATH}}  #文件夹名称
    
    echo $RELATIVE_PATH
    NEW_PATH=${RELATIVE_PATH%%/*}
    echo $NEW_PATH
    UPLOAD_PATH="${content_dir}"
    REMOTE_PATH="${DRIVE_NAME}:${DRIVE_PATH}/${NEW_PATH}"
    echo $UPLOAD_PATH
    echo $REMOTE_PATH
   UPLOAD_FILE
   qb_login
   qb_add_auto_del_tags
   qb_del
elif [ -d "${content_dir}" ]
then 
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：目录"
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：目录" >> ${log_dir}/qb.log
   type="dir"
   RELATIVE_PATH=${content_dir#${DOWNLOAD_PATH}}  #文件夹名称
    
    echo $RELATIVE_PATH
    UPLOAD_PATH="${content_dir}"
    REMOTE_PATH="${DRIVE_NAME}:${DRIVE_PATH}/${RELATIVE_PATH}"

    echo $UPLOAD_PATH
    echo $REMOTE_PATH
   UPLOAD_FILE
   qb_login
   qb_add_auto_del_tags
   qb_del
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 未知类型，取消上传"
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 未知类型，取消上传" >> ${log_dir}/qb.log
fi

echo "种子名称：${torrent_name}" >> ${log_dir}/qb.log
echo "内容路径：${content_dir}" >> ${log_dir}/qb.log
echo "根目录：${root_dir}" >> ${log_dir}/qb.log
echo "保存路径：${save_dir}" >> ${log_dir}/qb.log
echo "文件数：${files_num}" >> ${log_dir}/qb.log
echo "文件大小：${torrent_size}Bytes" >> ${log_dir}/qb.log
echo "HASH:${file_hash}" >> ${log_dir}/qb.log
echo "上传地址:${REMOTE_PATH}" >> ${log_dir}/qb.log
#echo "Cookie:${cookie}" >> ${log_dir}/qb.log
echo -e "-------------------------------------------------------------\n" >> ${log_dir}/qb.log




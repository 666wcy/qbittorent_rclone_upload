	#!/bin/bash
  file="/upload/qb_auto.sh"	
	if [ -f "$file" ]	
	then				
	 echo "$file found."
	 tail -f /dev/null
	else				
	 wget -P /upload https://github.com/666wcy/qbittorent_rclone_upload/raw/main/qb_auto.sh	
	 chmod 777 /upload/qb_auto.sh
  	 tail -f /dev/null
	fi		

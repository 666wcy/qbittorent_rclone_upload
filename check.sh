	#!/bin/bash
  file="/upload/qb_auto.sh"	
	if [ -f "$file" ]	
	then				
	 echo "$file found."	
	else				
	 wget -P /upload https://github.com/666wcy/qbittorent_rclone_upload/raw/main/qb_auto.sh	
	fi		

#!/bin/sh

. /jffs/etc/config/lib/common.sh

chsh_simple(){
	local homedir usershell
	
	while getopts ":h:s:u:" flag; do
		case "$flag" in
			h) homedir=$OPTARG;;
			s) usershell=$OPTARG;;
			u) username=$OPTARG;;
			\?)
			  echo "illegal option: -$OPTARG" >&2
			  exit 1
			  ;;
		esac
	done
	
	if [ -z $username ]; then
		echo "username not specified" >&2
		exit 1
	fi
	
	#/etc/passwd is linked to /tmp/etc/passwd
	local passwdPath="/tmp/etc/passwd"
	local passwdTmpPath="/tmp/etc/passwd_copy"
	local delim=":"
	while read -r line; do
		if echo $line | grep -q "^$username:"; then
			#sh doesn't have array support
			echo $line | cut -d$delim -f1-5 | rtrim_n
			echo -n $delim
			
			if [ ! -z $homedir ]; then
				echo -n $homedir
			else
				echo $line | cut -d$delim -f6 | rtrim_n
			fi
			echo -n $delim
			
			if [ ! -z $usershell ]; then
				echo -n $usershell
			else
				echo $line | cut -d$delim -f7 | rtrim_n
			fi
			echo
		else
			echo $line
		fi 1>>$passwdTmpPath
	done <$passwdPath
	mv $passwdTmpPath $passwdPath
}

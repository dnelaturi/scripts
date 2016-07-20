#!/bin/bash - 
#===============================================================================
#
#          FILE: check-52.sh
# 
#         USAGE: ./check-52.sh 
# 
#   DESCRIPTION: This script would check if the remote server is up or not. 
#		 It can run everyminute in cron. When the server goes down 
# 		 only for the first time he would send email "machine is down"
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Daniel Raj (), 
#  ORGANIZATION: 
#       CREATED: 07/11/2016 12:23
#      REVISION:  ---
#===============================================================================

ip=17.10.16.52
statusfile=/tmp/server_status.log
statu=down #default value

status=$(grep Status $statusfile | awk -F':' '{print $2}')

ping -c 2 $ip &> /dev/null 

if [[ $? -ne 0 ]]  
then
    if [[ $status != "down"  ]]
    then
	lk=`grep last_known_time $statusfile|sed 's/last_known_time://'`

cat <<EOF | /usr/sbin/sendmail -t
To: Daniel.Raj@gmail.com
Subject: [Cron] Server ($ip) Went Down, Please Bring Him up !   <EOM>
Last know uptime : $lk
EOF

	sed -i -e 's/up$/down/g' $statusfile
    fi
else
	if [[ ! -e $statusfile ]]
	then
		echo "Status:up" >$statusfile
		echo "last_known_time:$(date)" >>$statusfile
		echo "up_time: $(ssh roamware@$ip uptime)" >>$statusfile
		echo "IPv4 Address:$ip" >>$statusfile
	fi
	
	if [[ $status == "down" ]]
	then
		sed -i -e 's/down/up/g' $statusfile
	fi

	sed -i -e 's/last_known_time:.*/last_known_time:'"`date`"'/g' $statusfile
	#ssh roamware@$ip uptime | xclip | sed -i -e 's/up_time:.*/up_time:'"`xclip -o`"'/g' $statusfile
	srv_uptime=`ssh roamware@$ip uptime` 
	sed -i -e 's/up_time:.*/up_time:'"$srv_uptime"'/g' $statusfile
fi

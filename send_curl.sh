#!/bin/bash
############################################################################################################
: << 'END'
Uwe Sommer 05/2020
Version 0.70
send email with curl smtp directly (via TLS)
usefull for testing mailservers and filtering SMTP gateways
Some test messages included
no need for additonal mailserver

Requirements:
- curl > 7.20.0 - February 9 2010
- dig from dnsutils

Features:
- sending predefined message templates
- no need for MTA
- use SSL
- Bulk Sending of massmails for stresstests
- predefined message templates for content filter tests
- direkt server addressing without MX Lookup possible
- recipients can be specified directly or via listfile
- message templates are stored in separate file (compose_message)
- DSN support

Install:
 "source send_curl.sh compose_message" or include these in your bashrc/zshrc as function

Usage: 
"sm recipient type"
Type can be: macro,html,url,virus,spam,corrupt,spoof or massmailing (1-100)
additional types can be added to the compose_message function
recipient can also be a file with a list of recipients (not for massmailings)

Todos:
- add more message templates 
END
#############################################################################################################
red=$(tput setaf 1)
reset=$(tput sgr0)
e_error () { # colorize function for errors in red
	printf "${red}✖ %s${reset}\n" "$@"
}
#############################################################################################################
sm () { # main function
#############################################################################################################
#set -x # debug switch
gettemplates() {
	typeset -f compose_message |grep -e "[a-z]*)" |
	grep -v "date\|*\|template\|compose_message\|\[" |
	awk '{print $1}' |tr -d "()" |tr '\n' ' '
}
helptext(){
cat <<EOF

	sm is a commandline mailer based on predefined templates
	sm depends on curl and requires 1-3 params
	
	email address or email address file argument required
	second param can define message type: 
			
	${red}$(gettemplates)${reset}
	
	an optional third paramter defines destination server
	
	Examples: 
	${red}sm test@example.com spam${reset}
	this will send a spammail to test@example.com

	${red}sm test@example.com spam destserver${reset}
	this will send a spammail to test@example.com on server destserver

	${red}sm -vs validsender test@example.com${reset}
	this will get a DSN notification if the destination server supports it to validsender

	${red}sm test@example.com 10${reset}
	this will send 10 messages to test@example.com

	additional mail templates can be defined in the 'compose_message' function
EOF
}
#############################################################################################################
sender_dsn="<>" # need valid sender for DSN
dsn=no # set to yes to retrieve a delivery status notification
while getopts "h?vs:" opt; do # read additonal switches and remove them from params
    case "$opt" in
    h|\?) helptext ;return 0 ;;
    v) dsn=yes ;;
    s) sender_dsn=$OPTARG ;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift # remove switches from params
# Variables and catch input errors
recipients="$1" # first param defines recipients
switch="$2" # case selector for different message templates
sender=evil@evil-domain.com # The sender address may be changed
direct_server="$3"
# template mail file will be created dynamically
mail=/tmp/email.txt
# get my external ip, do reverse lookup and use this as helo-name
helo=$(dig +short -x $(dig +short myip.opendns.com @resolver1.opendns.com)|sed s/.$//)
#############################################################################################################
if [ -z "$1" ] # catch missing params
then # display usage help text
helptext
	return 1
elif [[ "$1" != *@* && ! -f "$1" ]] # first param must be recipient address or addresslist-file
then
	e_error "valid E-mail address required"
	return 1
fi
#############################################################################################################
# functions
#############################################################################################################
dig_server () {	# if there is a third param, take this as server
	if [ -n "$direct_server" ] ; then
	server="$direct_server"
	echo "static server: $server"
	elif [[ "$switch" =~ ^.*\\..*\\..*$ ]] ; then	# if the second param looks like an ip or server, take this as server
	server="$switch"
	else # all other cases: dig for mx
        server=$(dig +short +nodnssec mx $(echo "$each"| awk -F"@" '{print $2}') |sort -nr |tail -1 |awk '{print $2}'|sed s/.$//)
	fi
	if [ -z $server ] ; then 	# if there is no server string so far try to deliver to domain part of email
	server=$(echo "$each" |awk -F "@" '{print $2}' )
    e_error "No MX Record Found, trying domain of email recipient: $server"
	fi
}
send_mail () { # sending mail template via curl to destination server and catch some errors
	[[ "$dsn" == "yes" ]] && curl -k -v --ssl smtp://"$server"/"$helo" --mail-from "$sender_dsn" --mail-rcpt "<$each> NOTIFY=SUCCESS" --upload-file "$mail" || # retrieve DSN notification
	curl -k --ssl smtp://"$server"/"$helo" --mail-from "$sender" --mail-rcpt "$each" --upload-file "$mail" # or send normal message with spoofed sender
	res=$? # catch curl errorcodes or use '-v' debug switch above for more details
	if [ "$res" -eq "55" ] ;then
	e_error "greylisting detected, waiting 300 Secs for retry"
	date
	sleep 300
	send_mail
	elif [ "$res" -eq "56" ] ;then
	e_error "Message rejected by $server"
	else
    e_error "$switch Message sent successfully"
	fi
}
main () { # get destination server and send email
	dig_server # get destination mailserver
	e_error "Recipient:  $each"
	e_error "Mailserver: $server"
	send_mail # send composed message body via curl
}
############################################################################################################
# send email
############################################################################################################
if [ -f "$recipients" ] ;then # enumerate listfile for recipients
    while read -r each
		do
		compose_message
		main
		done < "$recipients"
	else # first param is recipient
	each="$1" # detect numbers for massmailing (second param)
	if [[ "$switch" =~ ^[0-9]+$ ]]; then
		e_error "Massmailing"
		dig_server
		e_error "Recipient:  $each"
		e_error "Mailserver: $server"
		COUNTER=1
		for i in $(seq "$switch"); do
			echo "Message Number: $i"
     		compose_message
			send_mail
			COUNTER=$(( COUNTER+1 ))
		done
		e_error "$((COUNTER-1)) Messages were sent"
		else # choose message body
	    compose_message	# send email to destination server(s)
	    main
	fi
fi
}
############################################################################################################

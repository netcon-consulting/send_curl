#!/bin/bash
############################################################################################################
# Uwe Sommer 05/2020
# Version 0.6
# send email with curl directly (via TLS)
# Some test messages included (compose_message)
# no need for additonal mailserver (just "dig" is required for dns queries)
#
# Features:
# - sending predefined message templates from shell
# - no need for an MTA
# - use SSL/TLS
# - Bulk Sending of massmails for stresstests
# - predefined message templates for content filter tests
# - direkt server addressing without MX Lookup possible
# - recipients can be specified directly or via listfile
# - message templates are stored in separate file (compose_mail)
#
# Install: 
#  "source sm.sh" and "source  compose_message" or include these in your bashrc as function
# Usage:
#  "sm recipient type" 
# Type can be: macro,html,url,virus,spam,corrupt,spoof or massmailing (1-100)
# recipient can also be a file with a list of recipients (not for massmailings)
#
# Todos: 
# -Macro File not sufficient
# -tracking message needed
#############################################################################################################
# colorize function
red=$(tput setaf 1)
reset=$(tput sgr0)
e_error () {
	printf "${red}✖ %s${reset}\n" "$@"
}
# main function
sm () {
#############################################################################################################
# debug switch
#set -x
#############################################################################################################
# Variables and catch input errors
#############################################################################################################
	recipients="$1"
	switch="$2" # case selector for different message templates
	# The sender Address may be changed
	sender=evil@evil-domain.com
	direct_server="$3"
	# template mail file will be created dynamically by compose_message
	mail=/tmp/email.txt
	# get my external ip, do reverse lookup and use this as heloname
	helo=$(dig +short -x "$(dig +short myip.opendns.com @resolver1.opendns.com)"|sed s/.$//)
	# catch missing params
	if [ -z "$1" ] ;then
		e_error "email address or email address file argument required"
		return 1
	elif [[ "$1" != *@* && ! -f "$1" ]] ;then
		e_error "valid E-mail address required"
		return 1
	fi
#############################################################################################################
# functions
#############################################################################################################
	# find destination mailserver
	dig_server () {
		# if there is a third param, take this as server
		if [ -n "$direct_server" ] ; then
		server="$direct_server"
		echo "static server: $server"
		# if the second param looks like an ip or server, take this as server
		elif [[ "$switch" =~ ^.*\\..*\\..*$ ]] ; then
		server="$switch"
		# all other cases: dig for mx
		else
		server=$(dig +short +nodnssec mx "$(echo "$each"| awk -F"@" '{print $2}')" |sort -nr |tail -1 |awk '{print $2}'|sed s/.$//)
		fi
	}
	# sending mail template via curl to destination server
	send_mail () {
		curl -k --ssl smtp://"$server"/"$helo" --mail-from "$sender" --mail-rcpt "$each" --upload-file "$mail"
		if [ "$?" -eq "55" ] ;then
		echo "greylisting detected, waiting 300 Secs for retry" 
		date
		sleep 300 
		send_mail
		else echo "\033[31mMessage sent successfull\033[0m"
		fi
	}
	# get destination server and send email
	main () {
		# get destination mailserver
		dig_server
		echo -e "Recipient:  \033[31m$each\033[0m"
		echo -e "Mailserver: \033[31m$server\033[0m"
		# send composed message body via curl
		send_mail
	}
############################################################################################################
# send email
############################################################################################################
# enumerate listfile for recipients
if [ -f "$recipients" ] ;then
    while read -r each   
		do 
		compose_message
		main 
		done < "$recipients"
	else
	# first param is recipient
	each="$1"
	# detect numbers for massmailing (second param)
	if [[ "$switch" =~ ^[0-9]+$ ]] ;then
		echo "\033[31mMassmailing\033[0m"
		dig_server
		echo -e "Recipient:  \033[31m$each\033[0m"
		echo -e "Mailserver: \033[31m$server\033[0m"
		COUNTER=1
		for i in $(seq "$switch"); do
			echo "Message Number: $i"
     		compose_message
			send_mail
			COUNTER=$(( COUNTER+1 ))
		done
		echo "\033[31m$((COUNTER-1)) Messages were sent\033[0m"
		else
	# choose message body from external function
	compose_message
	# send email to destination server(s)
	main
	fi
fi
}
############################################################################################################

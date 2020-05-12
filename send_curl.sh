#!/bin/bash
# Uwe Sommer 05/2020
# Version 0.52
# send email with curl directly (via TLS)
# Some test messages included
# no need for additonal mailserver (just "dig" is required for dns queries)
#
# Latest changes: catch 450 on greylisting and wait 5 Mins for retry
#
# Usage: 
#  "source sm.sh" or include this in your bashrc as function
#  "sm recipient type" 
# Type can be: macro,html,url,virus,corrupt,spoof or massmailing (1-100)
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
	sender=evil@evil-domain.com
	mail=/tmp/email.txt
	helo=$(dig +short -x $(dig +short myip.opendns.com @resolver1.opendns.com)|sed s/.$//)
	if [ -z "$1" ]
	then
		e_error "email address or email address file argument required"
		return 1
	elif [[ "$1" != *@* && ! -f "$1" ]]
	then
		e_error "valid E-mail address required"
		return 1
	fi
#############################################################################################################
# functions
#############################################################################################################
	dig_server () {
		server=$(dig +short +nodnssec mx $(echo "$each"| awk -F"@" '{print $2}') |sort -nr |tail -1 |awk '{print $2}'|sed s/.$//)
	}
	compose_message() {
		case "$switch" in
		# Eicar Virus Test
		virus)
		(   
			echo "X-SPAM: NO"
			echo "Subject: eicar AV Test"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo 'Content-Type: multipart/mixed;'
			echo ' boundary="------------11C9D15A08B345C2A6100327"'
			echo 'Content-Language: de-DE'
			echo ''
			echo 'This is a multi-part message in MIME format.'
			echo '--------------11C9D15A08B345C2A6100327'
			echo 'Content-Type: text/plain; charset=utf-8'
			echo 'Content-Transfer-Encoding: 7bit'
			echo ''
			echo ''
			echo '--------------11C9D15A08B345C2A6100327'
			echo 'Content-Type: application/octet-stream; x-mac-type="54455854"; x-mac-creator="522A6368";'
			echo ' name="eicar.com"'
			echo 'Content-Transfer-Encoding: base64'
			echo 'Content-Disposition: attachment;'
			echo ' filename="eicar.com"'
			echo ''
			echo 'WDVPIVAlQEFQWzRcUFpYNTQoUF4pN0NDKTd9JEVJQ0FSLVNUQU5EQVJELUFOVElWSVJVUy1U'
			echo 'RVNULUZJTEUhJEgrSCo='
			echo '--------------11C9D15A08B345C2A6100327--'

		) > "$mail"
		;;
		# GTUBE Spamtest
	    spam)
		(   
			echo "X-SPAM: NO"
			echo "Subject: spam message with gtube"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo "Content-Type: text/plain; charset=utf-8; format=flowed"
			echo "Content-Transfer-Encoding: 8bit"
			echo "Content-Language: en-US"
			echo ''
			echo "Hallo $each"
			echo 'XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X'
		) > "$mail"
		;;
		# executable attachment
		exe)
		(   
			echo "X-SPAM: NO"
			echo "Subject: exe attachment"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo 'Content-Type: multipart/mixed;'
			echo ' boundary="------------F0724A537730ECB93BC9CEB4"'
			echo 'Content-Language: de-DE'
			echo ''
			echo 'This is a multi-part message in MIME format.'
			echo '--------------F0724A537730ECB93BC9CEB4'
			echo 'Content-Type: text/html; charset=utf-8'
			echo 'Content-Transfer-Encoding: 7bit'
			echo ''
			echo '<html>'
			echo '  <head>'
			echo ''
			echo '    <meta http-equiv="content-type" content="text/html; charset=UTF-8">'
			echo '  </head>'
			echo '  <body>'
			echo '    <p><br>'
			echo '    </p>'
			echo '  </body>'
			echo '</html>'
			echo ''
			echo '--------------F0724A537730ECB93BC9CEB4'
			echo 'Content-Type: application/zip; x-mac-type="0"; x-mac-creator="0";'
			echo ' name="attachment.zip"'
			echo 'Content-Transfer-Encoding: base64'
			echo 'Content-Disposition: attachment;'
			echo ' filename="attachment.zip"'
			echo ''
			echo 'UEsDBBQAAAAIAJxYq1AQcc19UwAAAFcAAAAJABwAc2NyaXB0LnNoVVQJAAM3FbleOBW5XnV4'
			echo 'CwABBPUBAAAEFAAAAFNW1E/KzNNPSizO4FJWcCwtycgvslIILU9VCM7PzU0tAgoWgxkOeakl'
			echo 'yfl5ukBcXJpTkpmXrpecn8uVmpyRr6AUnFyUWVCikJtaXJyYnqrExQUAUEsBAh4DFAAAAAgA'
			echo 'nFirUBBxzX1TAAAAVwAAAAkAGAAAAAAAAQAAAO2BAAAAAHNjcmlwdC5zaFVUBQADNxW5XnV4'
			echo 'CwABBPUBAAAEFAAAAFBLBQYAAAAAAQABAE8AAACWAAAAAAA='
			echo '--------------F0724A537730ECB93BC9CEB4'
			echo 'Content-Type: application/x-sh; x-mac-type="0"; x-mac-creator="0";'
			echo ' name="script.sh"'
			echo 'Content-Transfer-Encoding: 7bit'
			echo 'Content-Disposition: attachment;'
			echo ' filename="script.sh"'
			echo ''
			echo '#!/bin/bash'
			echo '# Author: Uwe Sommer'
			echo '# sommer@netcon-consulting.com'
			echo 'echo "Script message"'
			echo ''
			echo ''
			echo '--------------F0724A537730ECB93BC9CEB4--'
		) > "$mail"
		;;
		# html Mail with tracker
		html)
		(   
			echo "X-SPAM: NO"
			echo "Subject: html message"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo ''
			echo "Hallo $each"
		) > "$mail"
		;;
		# office macro attachment
		macro)
		(   
			echo "Subject: office macro attachment"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo 'MIME-Version: 1.0'
			echo 'Content-Type: multipart/mixed;'
			echo ' boundary="------------AB1AD3E5230A024F221F9B11"'
			echo 'Content-Language: en-US'
			echo ''
			echo 'This is a multi-part message in MIME format.'
			echo '--------------AB1AD3E5230A024F221F9B11'
			echo 'Content-Type: text/plain; charset=utf-8'
			echo 'Content-Transfer-Encoding: 7bit'
			echo ''
			echo 'Rspamd Test Message'
			echo ''
			echo '--------------AB1AD3E5230A024F221F9B11'
			echo 'Content-Type: application/msword;'
			echo ' name="rspamd.doc"'
			echo 'Content-Transfer-Encoding: base64'
			echo 'Content-Disposition: attachment;'
			echo ' filename="rspamd.doc"'
			echo ''
			echo '0M8R4KGxGuEAAAAAAAAAAAAAAAAAAAAAOwADAP7/CQAGAAAAAAAAAAAAAAABAAAADwAAAAAA'
			echo 'AAAAEAAAAgAAAAEAAAD+////AAAAAAAAAAD/////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '///////////////////////////////////9//////////7///8EAAAABQAAAAYAAAAHAAAA'
			echo 'CAAAAAkAAAAKAAAACwAAAAwAAAANAAAADgAAAP7///8QAAAA/v//////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '/////////////////////////////////////////////////////////////////////1IA'
			echo 'bwBvAHQAIABFAG4AdAByAHkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAWAAUA////////////////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAA/v///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///////////////8AAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD+////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//'
			echo '/////////////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP7///8AAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAA////////////////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAA/v///wAAAAAAAAAAAQAAAP7////+////BAAAAAUAAAAGAAAABwAAAAgA'
			echo 'AAAJAAAACgAAAAsAAAAMAAAADQAAAA4AAAAPAAAAEAAAABEAAAASAAAAEwAAABQAAAAVAAAA'
			echo 'FgAAABcAAAAYAAAAGQAAABoAAAAbAAAAHAAAAB0AAAAeAAAA/v///yAAAAAhAAAA/v///yMA'
			echo 'AAAkAAAAJQAAACYAAAAnAAAAKAAAACkAAAAqAAAAKwAAACwAAAAtAAAALgAAAC8AAAAwAAAA'
			echo 'MQAAADIAAAAzAAAANAAAADUAAAA2AAAANwAAADgAAAA5AAAAOgAAADsAAAA8AAAAPQAAAD4A'
			echo 'AAA/AAAAQAAAAEEAAABCAAAAQwAAAEQAAABFAAAARgAAAEcAAABIAAAASQAAAEoAAABLAAAA'
			echo 'TAAAAE0AAABOAAAATwAAAFAAAABRAAAAUgAAAFMAAABUAAAAVQAAAFYAAABXAAAAWAAAAFkA'
			echo 'AABaAAAA/v///1wAAAD+////////////////////////////////////////////////////'
			echo '////////////////////////////////////////////////////////////////////////'
			echo '//////////////////////////////////////////////////////////////////8BAP7/'
			echo 'AwoAAP////8GCQIAAAAAAMAAAAAAAABGGAAAAE1pY3Jvc29mdCBXb3JkLURva3VtZW50AAoA'
			echo 'AABNU1dvcmREb2MAEAAAAFdvcmQuRG9jdW1lbnQuOAD0ObJxAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAEAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAASABQACgABAFsADwAAAAAAAAAAAFoAABDx/wIA'
			echo 'WgAAAAYATgBvAHIAbQBhAGwAAAAIAAAAMSQBKiQBMwBCKgBPSgMAUUoDAENKGABtSAcEc0gH'
			echo 'BEtIAgBQSgQAbkgECHRIBAheSgUAYUoYAF9IOQQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAE4A/h8BAAIBTgAAAAsA3ABiAGUAcgBzAGMAaAByAGkAZgB0AAAADQAPABOk8AAUpHgA'
			echo 'BiQBABgAT0oGAFFKBgBDShwAUEoHAF5KBQBhShwANgBCEAEAAgE2AAAACgBUAGUAeAB0AGsA'
			echo '9gByAHAAZQByAAAAEAAQABJkFAEBABOkAAAUpIwAAAAiAC8QAQESASIAAAAFAEwAaQBzAHQA'
			echo 'ZQAAAAIAEQAEAF5KCABKACIQAQAiAUoAAAAMAEIAZQBzAGMAaAByAGkAZgB0AHUAbgBnAAAA'
			echo 'DQASABOkeAAUpHgADCQBABIAQ0oYADYIAV5KCABhShgAXQgBMgD+HwEAMgEyAAAACwBWAGUA'
			echo 'cgB6AGUAaQBjAGgAbgBpAHMAAAAFABMADCQBAAQAXkoIAAAAAAARAAAABAAADgAAAAD/////'
			echo 'AAgAACIIAAAFAAAAAAgAACIIAAAGAAAAAAAAABEAAAAAAAAAAhAAAAAAAAAAEQAAAFAAAAgA'
			echo 'AAAACQAAAEcWkAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABUAGkAbQBl'
			echo 'AHMAIABOAGUAdwAgAFIAbwBtAGEAbgAAADUWkAECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAABTAHkAbQBiAG8AbAAAADMmkAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAABBAHIAaQBhAGwAAABpFpABAREAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAATABpAGIAZQByAGEAdABpAG8AbgAgAFMAZQByAGkAZgAAAFQAaQBtAGUAcwAg'
			echo 'AE4AZQB3ACAAUgBvAG0AYQBuAAAASwaQAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAE4AbwB0AG8AIABTAGUAcgBpAGYAIABDAEoASwAgAFMAQwAAADkGkAEBAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABGAHIAZQBlAFMAYQBuAHMAAABTJpABARAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAATABpAGIAZQByAGEAdABpAG8AbgAg'
			echo 'AFMAYQBuAHMAAABBAHIAaQBhAGwAAABZBpABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAATgBvAHQAbwAgAFMAYQBuAHMAIABDAEoASwAgAFMAQwAgAFIAZQBnAHUAbABh'
			echo 'AHIAAAA5JJABAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARgByAGUAZQBT'
			echo 'AGEAbgBzAAAAQgAEAAEIjRgAAMUCAABoAQAAAAAT1HHHItRxxwAAAAABAAAAAAADAAAAEAAA'
			echo 'AAEAAQAAAAQAg5ABAAAAAwAAABAAAAABAAEAAAABAAAAAAAAAAcFACAAAAAAAAQAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAASMAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAgAAAEAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/v8AAAEAAgAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAQAAAOCFn/L5T2gQq5EIACsns9kwAAAAfAAAAAYAAAABAAAAOAAAAAkAAABAAAAA'
			echo 'CgAAAEwAAAALAAAAWAAAAAwAAABkAAAADQAAAHAAAAACAAAA6f0AAB4AAAACAAAAMgAAAEAA'
			echo 'AAAAnkgwAgAAAEAAAAAAAAAAAAAAAEAAAAB/lnKCirXUAUAAAABMRaayjLXUAQAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAA7KUBAU0gCQQAAPASvwAAAAAAADAAAAAAAAgAACIIAAAOAENhb2xhbjgw'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAACQQWACcOAAAAAAAAAAAAABEAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAA//8PAAUAAAABAAAA//8PAAYAAAABAAAA//8PAAAAAAAAAAAAAAAAAAAA'
			echo 'AACIAAAAAAC4AQAAAAAAALgBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALgB'
			echo 'AAAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMwBAAAMAAAA'
			echo '2AEAAAwAAAAAAAAAAAAAAAUCAACOAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOQBAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAkwQAAGICAAAAAAAAAAAAAPAB'
			echo 'AAAVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOQBAAAMAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAIA2QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAABSAHMAcABhAG0AZAAgAFQAZQBzAHQAIABXAG8AcgBkAA0AAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAiCAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAABAAgAACIIAAD9AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAElADwwAB+wgi4gsMZBIbBuBCKwbgQj'
			echo 'kG4EJJBuBDNQAAAoMgAOMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/v8AAAEAAgAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAgAAAALVzdWcLhsQk5cIACss+a5EAAAABdXN1ZwuGxCTlwgAKyz5rlwA'
			echo 'AAAYAAAAAQAAAAEAAAAQAAAAAgAAAOn9AAAYAAAAAQAAAAEAAAAQAAAAAgAAAOn9AAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABSAG8AbwB0ACAARQBuAHQA'
			echo 'cgB5AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFgAFAP//'
			echo '////////AQAAAAYJAgAAAAAAwAAAAAAAAEYAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAABAFwAA'
			echo 'AAAAAAEAQwBvAG0AcABPAGIAagAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAASAAIAAgAAAAQAAAD/////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAGoAAAAAAAAAAQBPAGwAZQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAoAAgD/////AwAAAP////8AAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAFAAAAAAAAAAxAFQAYQBiAGwA'
			echo 'ZQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'DgACAP///////////////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMA'
			echo 'AAD1BgAAAAAAAAUAUwB1AG0AbQBhAHIAeQBJAG4AZgBvAHIAbQBhAHQAaQBvAG4AAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAoAAIABQAAAAYAAAD/////AAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAHwAAAKwAAAAAAAAAVwBvAHIAZABEAG8AYwB1AG0AZQBuAHQA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAgD/////////////'
			echo '//8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAiAAAAJw4AAAAAAAAFAEQA'
			echo 'bwBjAHUAbQBlAG4AdABTAHUAbQBtAGEAcgB5AEkAbgBmAG8AcgBtAGEAdABpAG8AbgAAAAAA'
			echo 'AAAAAAAAOAACAP///////////////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAFsAAAB0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////////////////AAAAAAAAAAAAAAAA'
			echo 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/v///wAAAAAAAAAA'
			echo '--------------AB1AD3E5230A024F221F9B11--'
		) > "$mail"
		;;
		# bad url in body
		url)
		(   
			echo "Subject: url in message"
			echo "To: <$each>"
			echo 'Message-ID: <awbavkk04738050.28270528@mail.bizones.de>'
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo 'Content-Type: multipart/related;'
			echo '	type="multipart/alternative";'
			echo '	boundary="----=_NextPart_000_0006_01D624F7.16387890"'
			echo ''
			echo "This is a multi-part message in MIME format."
			echo ''
			echo "------=_NextPart_000_0006_01D624F7.16387890"
			echo "Content-Type: multipart/alternative;"
			echo '	boundary="----=_NextPart_000_0007_01D624F7.16387890"'
			echo ""
			echo "------=_NextPart_000_0007_01D624F7.16387890"
			echo "Content-Type: text/plain;"
			echo "	charset="windows-1251""
			echo "Content-Transfer-Encoding: quoted-printable"
			echo ""
			echo "------=_NextPart_000_0007_01D624F7.16387890"
			echo "Content-Type: text/html;"
			echo '	charset="windows-1251"'
			echo "Content-Transfer-Encoding: quoted-printable"
			echo ""
			echo "<HTML><HEAD>"
			echo '<META http-equiv="Content-Type" content="text/html; charset=windows-1251">'
			echo "</HEAD>"
			echo "<BODY bgColor=#ffffff>"
			echo "<DIV align=center><FONT size=2 face=Arial><A"
			echo 'href="https://www.b6kkoniv.space/btc-outlet/"><IMG border=0 hspace=0 alt="" src="http://external.evil-domain.com/evil-tracker.jpg" width=1 height=1></A></FONT></DIV></BODY></HTML>'
			echo "------=_NextPart_000_0007_01D624F7.16387890"
		) > "$mail"
		;;
		# encrypted zip attachment (pass geheim)
		encrypted)
		(   
			echo "Subject: encrypted zip attachment"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo 'User-Agent: Mailclient'
			echo 'MIME-Version: 1.0'
			echo 'Content-Type: multipart/mixed;'
			echo ' boundary="------------646B851E8F58F54832B0C7AA"'
			echo 'Content-Language: de-DE'
			echo ''
			echo 'This is a multi-part message in MIME format.'
			echo '--------------646B851E8F58F54832B0C7AA'
			echo 'Content-Type: text/plain; charset=utf-8'
			echo 'Content-Transfer-Encoding: 7bit'
			echo ''
			echo ''
			echo 'encrypted attachment'
			echo ''
			echo '--------------646B851E8F58F54832B0C7AA'
			echo 'Content-Type: application/zip; x-mac-type="0"; x-mac-creator="0";'
			echo ' name="encrypted.zip"'
			echo 'Content-Transfer-Encoding: base64'
			echo 'Content-Disposition: attachment;'
			echo ' filename="encrypted.zip"'
			echo ''
			echo 'UEsDBAoACQAAAPOTqVA8z1FoUAAAAEQAAAAJABwAZWljYXIuY29tVVQJAAPp2rZe69q2XnV4'
			echo 'CwABBPUBAAAEFAAAAErf83m5Vhogf3lTCOGGsWyT9pUAX5rh9EZmIyEgiJPIFA9G8EAR4Czu'
			echo 'M1ucv8P8GRNeYOJM9OdfYqnbCs1j3oR8qq6BfYEf6AkvehYGDNTJUEsHCDzPUWhQAAAARAAA'
			echo 'AFBLAQIeAwoACQAAAPOTqVA8z1FoUAAAAEQAAAAJABgAAAAAAAEAAACkgQAAAABlaWNhci5j'
			echo 'b21VVAUAA+natl51eAsAAQT1AQAABBQAAABQSwUGAAAAAAEAAQBPAAAAowAAAAAA'
			echo '--------------646B851E8F58F54832B0C7AA--'
		) > "$mail"
		;;
		# corrupt message (unscannable attachment)
		corrupt)
		(   
			echo "Subject: corrupted attachment"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo 'Content-Type: multipart/mixed;'
			echo ' boundary="------------5A2FDDB2EB722F44993C6192"'
			echo 'Content-Language: de-DE'
			echo ''
			echo 'This is a multi-part message in MIME format.'
			echo '--------------5A2FDDB2EB722F44993C6192'
			echo 'Content-Type: text/plain; charset=utf-8'
			echo 'Content-Transfer-Encoding: 7bit'
			echo ''
			echo ''
			echo '--------------5A2FDDB2EB722F44993C6192'
			echo 'Content-Type: application/zip; x-mac-type="0"; x-mac-creator="0";'
			echo ' name="broken_zip.zip"'
			echo 'Content-Transfer-Encoding: base64'
			echo 'Content-Disposition: attachment;'
			echo ' filename="broken_zip.zip"'
			echo ''
			echo 'UEsDBBQAAAAAAAAAIQAAAAAACwQAAAsEAAAJAAAAdGVzdF9maWxlRGVsZWN0dXMgcXVhcyBj'
			echo 'dW0gZXQgbmVxdWUgYXBlcmlhbSBxdWlidXNkYW0gY29uc2VxdXVudHVyCmF1dC4gQXJjaGl0'
			echo 'ZWN0byBmdWdpYXQgZG9sb3JlbXF1ZSBzb2x1dGEgc2FlcGUgdG90YW0uIFJlcHJlaGVuZGVy'
			echo 'aXQgYXV0IGFsaWFzCnF1aWEgcGxhY2VhdC4gTmVxdWUgZWl1cyBjb25zZXF1YXR1ciBpZCBl'
			echo 'c3QgZXQuIEFsaXF1YW0gZXQgdmVsaXQgcXVpIGVuaW0KY3VtcXVlLgoKU3VzY2lwaXQgY3Vw'
			echo 'aWRpdGF0ZSBlYSBxdWlzcXVhbSBhc3BlcmlvcmVzIGNvcnJ1cHRpIGFkaXBpc2NpIHZvbHVw'
			echo 'dGF0ZW0gaWxsby4KRnVnaWF0IHF1aXMgZGViaXRpcyBlYXJ1bSByZWN1c2FuZGFlIG5hbSB1'
			echo 'dC4gUXVpIHZlbGl0IGV2ZW5pZXQgbWFpb3JlcyBxdWFzIGlkCnBsYWNlYXQuCgpTdXNjaXBp'
			echo 'dCBtYWduaSBxdWkgbmVzY2l1bnQgcGVyZmVyZW5kaXMgcXVvIGluIG1vbGxpdGlhIG5lc2Np'
			echo 'dW50LiBUZW1wb3JlCmRlbGVjdHVzIHJlbSBkdWNpbXVzIHRlbXBvcmUgdGVtcG9yaWJ1cyBj'
			echo 'b25zZXF1YXR1ciByZXJ1bS4gSW5jaWR1bnQgZXQgYXV0IGEgdXQKZXQgY29uc2VxdWF0dXIg'
			echo 'bWFnbmkgcXVvZC4gU2VkIGRvbG9yZW1xdWUgZG9sb3JpYnVzIGlwc2FtIHN1bnQgbGliZXJv'
			echo 'IGV0LgoKQXV0IHF1aWEgc2ltaWxpcXVlIHF1b2QgY3VtcXVlIG9jY2FlY2F0aS4gRWFxdWUg'
			echo 'bGliZXJvIHNpbnQgbm9zdHJ1bSBmdWdhCnN1c2NpcGl0IHF1YWVyYXQgZHVjaW11cy4gRG9s'
			echo 'b3JlbSBxdW9kIHNpdCBjb3Jwb3Jpcy4gRGViaXRpcyB2ZW5pYW0gcXVhZQplbGlnZW5kaSB1'
			echo 'dCBhdXRlbSB2b2x1cHRhdGlidXMgc2FlcGUuIFF1aXMgZG9sb3JlbSBub3N0cnVtIGZ1Z2lh'
			echo 'dCBxdW9zLgoKRXQgbW9sZXN0aWFzIGF0IGV4ZXJjaXRhdGlvbmVtIHZlbCByZXJ1bSBleCB2'
			echo 'b2x1cHRhdGUuIE5paGlsIGVhcXVlIG9tbmlzCmV2ZW5pZXQgaWQgY3VwaWRpdGF0ZSBxdWku'
			echo 'IFZlbGl0IHF1aWJ1c2RhbSBuaWhpbCBwb3NzaW11cyB2b2x1cHRhdGUgcXVvZAp2ZW5pYW0u'
			echo 'IEVzdCBsaWJlcm8gY3VtIGRvbG9yIGNvbnNlcXVhdHVyIGlwc2FtIGVzdCB1dC4KUEsBAhQD'
			echo 'FAAAAAAAAAAhAAAAAAALBAAACwQAAAkAAAAAAAAAAAAAAIABAAAAAHRlc3RfZmlsZVBLBQYA'
			echo 'AAAAAQABADcAAAAyBAAAAAA='
			echo '--------------5A2FDDB2EB722F44993C6192--'
		) > "$mail"
		;;
		# Bulk Sender
		<2-100>)
		(   
			echo "X-SPAM: NO"
			echo "Subject: Massmailing Message Number: $COUNTER of $switch"
			echo "To: <$each>"
			echo "From: 'Evil Sender' <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-0815@$helo>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo "Content-Type: text/plain; charset=utf-8; format=flowed"
			echo "Content-Transfer-Encoding: 8bit"
			echo "Content-Language: en-US"
			echo ''
			echo "Hallo $each"
			echo "Message Number $COUNTER of $switch"
		) > "$mail"
		;;
		# Default Angela Merkel Spoof Mail
		*)
		(   
			echo "X-SPAM: NO"
			echo "Subject: Gruesse aus Berlin"
			echo "To: <$each>"
			echo "From: 'Angela Merkel' <bundeskanzler@bund.de>"
			echo "Reply-to: <evil@evil-domain.com>"
			echo "Message-Id: <$(date "+%m%d%H%M%Y")-114054033-4711@$helo>"
			echo "Date: $(date -R)"
			echo "MIME-Version: 1.0"
			echo "Content-Type: text/plain; charset=utf-8; format=flowed"
			echo "Content-Transfer-Encoding: 8bit"
			echo "Content-Language: en-US"
			echo ''
			echo "Hallo $each"
			echo ""
			echo 'Liebe Gruesse aus Berlin'
			echo 'Deine Angela'
		) > "$mail"
	    ;;
        esac
	}
	send_mail () {
		curl -k --ssl smtp://"$server"/$helo --mail-from "$sender" --mail-rcpt "$each" --upload-file "$mail"
		if [ "$?" -eq "55" ] ;then
		echo "greylisting detected, waiting 300 Secs for retry" 
		echo "$(date)"
		sleep 300 && curl -k --ssl smtp://"$server"/"$helo" --mail-from "$sender" --mail-rcpt "$each" --upload-file "$mail" 
		else echo "\033[31mMessage sent successfull\033[0m"
		fi
	}
	main () {
		dig_server
		echo -e "Recipient:  \033[31m$each\033[0m"
		echo -e "Mailserver: \033[31m$server\033[0m"
		send_mail
	}
############################################################################################################
# send email
############################################################################################################
if [ -f "$recipients" ] ;then
    for each in $(cat < "$recipients") 
		do 
		compose_message
		main 
		done 
	else
	each=$1
	if [[ "$switch" -gt "1" ]]; then
		echo "\033[31mMassmailing\033[0m"
		dig_server
		echo -e "Recipient:  \033[31m$each\033[0m"
		echo -e "Mailserver: \033[31m$server\033[0m"
		COUNTER=1
		for i in $(seq $switch); do
			echo "Message Number: $COUNTER"
     		compose_message
			send_mail
			COUNTER=$(( COUNTER+1 ))
		done
		echo "\033[31m$((COUNTER-1)) Messages were sent\033[0m"
		else
	compose_message
	main
	fi
fi
}
 send_curl is a bashscript for sending mails via curl via predefined mail templates.
These templates can be used to test mailfilters.

 Features:
 - sending predefined message templates from shell
 - no need for an MTA
 - use SSL/TLS
 - Bulk Sending of massmails for stresstests
 - predefined message templates for content filter tests
 - direkt server addressing without MX Lookup possible
 - recipients can be specified directly or via listfile
 - message templates are stored in separate file (compose_mail)

 Install:
  "source sm.sh" and "source  compose_message" or include these in your bashrc as function by adding this line
 and replace the path:
 
 for f in ~/dir/functions/*; do source $f; done
 
 Usage:
 
 "sm recipient type"
 
 Type can be: macro,html,url,virus,spam,corrupt,spoof or massmailing (1-100)
 recipient can also be a file with a list of recipients (not for massmailings)

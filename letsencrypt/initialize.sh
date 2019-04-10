#!/usr/bin/env bash

#########
# GLOBALS
#########
INSTALL_DIR="/shared/letsencrypt"
WORK_DIR="/var/www/dehydrated"
OCSP_CERT="letsencrypt_full_chain.crt"

DNS1="8.8.8.8"
DNS2="8.8.4.4"

function initialize_bigip {
	cd ${INSTALL_DIR}
	
	#create DNS resolver
	tmsh create net dns-resolver ldns-resolver route-domain 0 forward-zones replace-all-with { . { nameservers replace-all-with { ${DNS1}:53 ${DNS2}:53 } } }
	
	#configure sys::DNS::nameservers
	tmsh modify sys dns name-servers replace-all-with { ${DNS1} ${DNS2} }
	
	#create internal datagroup
	tmsh create ltm data-group internal acme_responses type string
	
	#create ACME challenge response iRule
	curl -sk -u admin:admin https://localhost/mgmt/tm/ltm/rule -H 'Content-Type: application/json' -X POST -d '{"kind":"tm:ltm:rule:rulestate","name":"lets_encrypt_irule","fullPath":"lets_encrypt_irule","generation":63,"selfLink":"https://localhost/mgmt/tm/ltm/rule/lets_encrypt_irule?ver=13.1.0.2","apiAnonymous":"when HTTP_REQUEST {\n\tif { not ([HTTP::path] starts_with \"/.well-known/acme-challenge/\") } { return }\n\tset token [lindex [split [HTTP::path] \"/\"] end]\n\tset response [class match -value -- $token equals acme_responses]\n\tif { \"$response\" == \"\" } {\n\t\tlog local0. \"Responding with 404 to ACME challenge $token\"\n\t\tHTTP::respond 404 content \"Challenge-response token not found.\"\n\t} else {\n\t\tlog local0. \"Responding to ACME challenge $token with response $response\"\n\t\tHTTP::respond 200 content \"$response\" \"Content-Type\" \"text/plain; charset=utf-8\"\n\t}\n}"}'
	
	#check if lets encrypt cert chain file exists
	if [ -e ${INSTALL_DIR}/${OCSP_CERT} ]; then 
		tmsh install sys crypto cert ${OCSP_CERT} from-local-file ./${OCSP_CERT}
		#create letsencrypt_ocsp profile
		tmsh create sys crypto cert-validator ocsp letsencrypt_ocsp { dns-resolver ldns-resolver route-domain 0 sign-hash sha1 status-age 86400 trusted-responders ${OCSP_CERT} }
	fi;
	
	#check if domains.txt file exists
	if [ -e ${INSTALL_DIR}/domains.txt ]; then 
		#create "auto_${domain}" clientssl profiles
		for i in $( cat domains.txt | awk '{ print $1}' ); do
			tmsh create ltm profile client-ssl auto_$i;
			echo "Created  auto_$i client-ssl profile";
		done;
	fi;

	#Check if wrapper.sh exists
	if [ -e ${INSTALL_DIR}/wrapper.sh ]; then 
		#create iCall script for wrapper.sh
		tmsh create sys icall script letsencrypt
		tmsh modify sys icall script letsencrypt definition { exec ${INSTALL_DIR}/wrapper.sh }
		tmsh create sys icall handler periodic letsencrypt first-occurrence 2019-02-20:00:00:00 interval 604800 script letsencrypt
	fi;
	
	#register this bigip with letsencrypt
	cd ${INSTALL_DIR}
	./dehydrated --register --accept-terms
}

function install {
	#Check file manifest
	
	#Ensure shell scripts are executable
	chmod 0755 hook.sh wrapper.sh dehydrated initialize.sh
	
	mkdir -p ${INSTALL_DIR}
	mkdir -p ${WORK_DIR}
	
	cp -a ./*.sh ${INSTALL_DIR}
	cp -a ./*.txt ${INSTALL_DIR}
	cp -a ./*.crt ${INSTALL_DIR}
	cp -a ./config ${INSTALL_DIR}
	cp -a ./dehydrated ${INSTALL_DIR}
	
	echo "Lets Encrypt automation installed to ${INSTALL_DIR}"
}	

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(install|initialize_bigip)$ ]]; then
  "$HANDLER" "$@";
else
  echo "Usage: ./initialize.sh install | initialize_bigip ";
fi;

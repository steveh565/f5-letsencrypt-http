#!/bin/bash
#########
# GLOBALS
#########
INSTALL_DIR="/shared/letsencrypt"
WORK_DIR="/var/www/dehydrated"

cd ${INSTALL_DIR}

ME=`echo $HOSTNAME|awk -F. '{print $1}'`
ACTIVE=$(tmsh show cm failover-status | grep ACTIVE | wc -l)

if [[ "${ACTIVE}" = "1" ]]; then
    echo "Unit is active - proceeding..."
	exec >>/var/log/letsencrypt.log 2>&1 
	./create_clientssl_profiles.sh 2>&1;
    exec >>/var/log/letsencrypt.log 2>&1
    ./dehydrated -c
	
    logger -p local0.notice "Lets Encrypt Report $ME: `cat /var/log/letsencrypt.log`"
fi

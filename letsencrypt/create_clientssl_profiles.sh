#!/usr/bin/env bash

#########
# GLOBALS
#########
INSTALL_DIR="/shared/letsencrypt"

cd ${INSTALL_DIR}

#check if domains.txt file exists
if [ -e ${INSTALL_DIR}/domains.txt ]; then 
	#create "auto_${domain}" clientssl profiles
	for i in $( cat domains.txt | awk '{ print $1}' ); do
		res=`tmsh list /ltm profile client-ssl |grep $i`
		if [ "$?" != 0 ]; then
			tmsh create ltm profile client-ssl auto_$i;
			echo "Created  auto_$i client-ssl profile";
		else
			echo "Client-SSL profile auto_$i already exists";
		fi;
	done;
fi;
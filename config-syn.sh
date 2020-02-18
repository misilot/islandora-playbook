#!/bin/bash
# 
# Simple script to enable or disable the Syn Valve for manipulating 
# Fedora directly w/in the Islandora 8 project.
#
# usage:  ./config-syn.sh enable|disable
#     enable turns the valve on, disabling direct write access to Fedora
#     disable turns the valve off, enabling direct write access to Fedora. 
#
# The first time disable is run, it will inject a few lines of code
# to add a user to fedora and also put in the framework to disable the valve. 
#
# author: bseeger
# since: Feb 2020

TOMCAT_USERS_FILE=/var/lib/tomcat8/conf/tomcat-users.xml
SYN_SETTINGS_FILE=/var/lib/tomcat8/conf/syn-settings.xml
#TOMCAT_USERS_FILE=./tomcat-users.xml    # for testing
#SYN_SETTINGS_FILE=./syn-settings.xml    # for testing
ISLANDORA_USER='<user username="islandora" password="islandora" roles="manager-gui"\/>'
FEDORA_USER='<user username="fedoraAdmin" password="secret3" roles="fedoraAdmin"\/>'
# these two users are used to demonstrate WebACLs in part of the workshop
TEST_USER='<user username="testuser" password="password1" roles="fedoraUser"\/>'
ADMIN_USER='<user username="adminuser" password="password2" roles="fedoraUser"\/>'

failed=0
if [ -z $1 ]; then
    echo 'Usage:  config-syn.sh [enable | disable]'
    exit 0
fi

##### Part 1: Add 'fedoraAdmin' user to the tomcat-users.xml file

# is the user in the file already? 
resp=`sed '/fedoraAdmin/,$p' $TOMCAT_USERS_FILE -n`

if [ -z "$resp" ]; then
    # add it
    `sed -i -e "s/$ISLANDORA_USER/$ISLANDORA_USER\n        $FEDORA_USER\n        $TEST_USER\n        $ADMIN_USER/g" $TOMCAT_USERS_FILE`
    echo 'Added user to tomcat-users.xml file.  User: fedoraAdmin  pass: secret3'

else
    echo $resp
fi

##### Part 2: Enable or disable the valve, depending on input

# normalize input to lower case
mode=`echo $1 | tr '[:upper:]' '[:lower:]'`

if [ "$mode" == "enable" ]; then
    `sed -i -e "s/^<config version='1' header='X-Islandora'.*>$/<config version='1' header='X-Islandora' disabled='false'>/g" $SYN_SETTINGS_FILE`
    echo "Syn valve enabled."
elif [ "$mode" == "disable" ]; then
    `sed -i -e "s/^<config version='1' header='X-Islandora'.*>$/<config version='1' header='X-Islandora' disabled='true'>/g" $SYN_SETTINGS_FILE`
    echo "Syn valve disabled."
else
    failed=1
    echo "Invalid option '$1' entered, valve not changed."
fi

if [ "$failed" -ne 1 ]; then
    echo "Now restart tomcat with: 'sudo service tomcat8 restart'"
fi


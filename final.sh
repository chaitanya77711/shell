#!/bin/bash

set -e 
trap 'echo  "there is an error in a $LINE_NO, command:$BASH_COMMAND"'ERR

user_id=$(id -u)
logsfolder="/var/log/shell-scripting"
logsfile="/var/log/shell-scripting/$0.log"

if [ $user_id -ne 0 ]; then
   echo "run with root user" | tee -a $logsfille
   exit 1
fi

mkdir -p $logsfolder

for packages in $a

do
dnf list installed $packages
if [ $? -ne 0 ]; then 
echo "doesnt installed installing now"
dnf install $packages -y >>$logsfile
else
    echo "skipping already there"

fi

done
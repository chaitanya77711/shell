#!/bin/bash

user_id=$(id -u)
logsfolder="/var/log/shell-scripting"
logsfile="/var/log/shell-scripting/$0.log"

if [ $user_id -ne 0 ]; then
   echo "run with root user" | tee -a $logsfille
   exit 1
fi

mkdir -p $logsfolder

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo "$2 is fail" | tee -a $logsfile
        exit 1

    else
        echo "$2 is success" | tee -a $logsfile
    
    fi
}


dnf install nginx -y & >>$logsfile
VALIDATE $? "installing nginx"

dnf install mysql -y & >>$logsfile
VALIDATE $? "installing mysql"
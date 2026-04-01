#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/robo-shop"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$(pwd)
MONGODB_HOST=mongodb.devops7.online


if [ $user_id -ne 0 ]; then
  echo -e $R "run with root user" $N | tee -a $logs_file
  exit 1

fi  

mkdir -p $logs_folder

validate() {
    if [ $1 -ne 0 ]; then
     echo -e $R  "$2 failure" $N | tee -a $logs_file
     exit 1

    else
     echo -e $G  "$2 success" $N | tee -a $logs_file

    fi  

} 

dnf module disable redis -y
dnf module enable redis:7 -y &>> $logs_file
validate $? "diabled and enabld redis"

dnf install redis -y &>> $logs_file
validate $? "installing reddis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no/' /etc/redis/redis.conf
validate $? "allowing remote connections"

systemctl enable redis 
systemctl start redis &>> $logs_file
validate $? "restrating reddis"
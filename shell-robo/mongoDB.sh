#!/bin/bash

user_id=$(id -u)
logs_folder=/var/log/robo-shop
logs_file=$logs_folder/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
  echo  $R "run with root user" $N | tee -a  &>> $logs_folder
  exit 1

fi  

mkdir -p $logs_folder

validate() {
    if [ $1 -ne 0 ]; then
     echo  $R  $2 "failure" $N | tee -a  &>> $logs_folder
     exit 1

    else
     echo  $G  $2 "success" $N | tee -a  &>> $logs_folder

    fi  

} 

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "copying mongo repo"

dnf install mongodb-org -y 
validate $? "installing mongoDB"

systemctl enable mongod 
validate $? "enable mongod"

systemctl start mongod
validate $? "starting mongod"

sed  -i '/s/127.0.0.1/0.0.0.0/g'/etc/mongod.conf
validate $? "allowing remote connections"

systemctl restart mongod
validate $? "restrating"
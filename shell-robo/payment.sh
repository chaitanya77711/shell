#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/robo-shop"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$(pwd)
MONGODB_HOST=devops7.online


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
dnf install python3 gcc python3-devel -y &>>$logs_file
validate $? "Installing Python"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
    validate $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
validate $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$logs_file
validate $? "Downloading payment code"

cd /app
validate $? "Moving to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/payment.zip &>>$logs_file
validate $? "Uzip payment code"

cd /app

pip3 install -r requirements.txt &>>$logs_file
validate $? "Installing dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service
validate $? "Created systemctl service"

systemctl daemon-reload

systemctl enable payment &>>$logs_file
systemctl start payment
validate $? "Enabled and started payment"
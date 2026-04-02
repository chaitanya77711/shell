#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/robo-shop"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$(pwd)

if [ $user_id -ne 0 ]; then
  echo -e $R "run with root user" $N | tee -a $logs_file
  exit 1
fi  

mkdir -p $logs_folder

validate() {
    if [ $1 -ne 0 ]; then
     echo -e $R "$2 failure" $N | tee -a $logs_file
     exit 1
    else
     echo -e $G "$2 success" $N | tee -a $logs_file
    fi  
}

# Install nginx
dnf module disable nginx -y &>>$logs_file
dnf module enable nginx:1.24 -y &>>$logs_file
dnf install nginx unzip -y &>>$logs_file
validate $? "Installing Nginx"

systemctl enable nginx &>>$logs_file
systemctl start nginx
validate $? "Enabled and started nginx"

# Remove default content
rm -rf /usr/share/nginx/html/*
validate $? "Remove default content"

# Download frontend
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$logs_file
validate $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$logs_file
validate $? "Unzipping frontend"

# IMPORTANT: DO NOT DELETE nginx.conf

# Copy config correctly
cp $script_dir/nginx.conf /etc/nginx/default.d/roboshop.conf
validate $? "Copied nginx config"

# Restart nginx
systemctl restart nginx
validate $? "Restarted Nginx"
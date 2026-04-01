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

dnf module disable nodejs -y
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y
validate $? "module enable nodejs"

dnf install nodejs -y &>> $logs_file
validate $? "installing nodejs"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
    validate $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
validate $? "Creating app directory"

rm -rf /app/*
validate $? "Removing existing code"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$logs_file
validate $? "Downloading catalogue code"

cd /app
validate $? "Moving to app directory"

unzip /tmp/catalogue.zip &>> $logs_file
validate $? "Uzip catalogue code"

npm install &>> $logs_file
validate $? "Installing dependencies"

cp  $script_dir/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Created systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>> $logs_file
systemctl start catalogue
validate $? "Starting and enabling catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Installing Mongo client"

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>> $logs_file
    validate $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
validate $? "Restarting catalogue"


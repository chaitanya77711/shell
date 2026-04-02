#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/robo-shop"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$(pwd)
mysql_host=mysql.devops7.online


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

dnf install maven -y
validate $? "installing"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
    validate $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
validate $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$logs_file
validate $? "Downloading shipping code"

cd /app
validate $? "Moving to app directory"

rm -rf *
validate $? "removing existing code"

unzip /tmp/shipping.zip &>> $logs_file
validate $? "Unzip shipping code"

dnf install unzip -y &>> $logs_file
validate $? "Installing unzip"

cd /app 
mvn clean package 
validate $? "building shipping"

mv target/shipping-1.0.jar shipping.jar
validate $? "moving and renaming shipping"

cp  $script_dir/shipping.service /etc/systemd/system/shipping.service
validate $? "Created systemctl service"

dnf install mysql -y 
validate $? "installing mysql"

mysql -h $mysql_host -uroot -pRoboShop@1 -e 'use cities'

if [ $? -ne 0 ]; then 

   mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/schema.sql &>>$logs_file
   mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$logs_file
   mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$logs_file
   validate $? "Loaded data into mysql"
else
    echo -e "data is already loaded ... $Y SKIPPING $N"
fi

systemctl enable shipping &>>$logs_file
systemctl start shipping
validate $? "Enabled and started shipping"

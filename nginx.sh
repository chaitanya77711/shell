#!/bin/bash

user_id=$(id -u)

if [ $user_id -ne 0 ]; then
   echo "run with root user"
   exit 1
fi

echo "install nginx"
dnf install nginx -y

if [ $? -ne 0 ]; then
  echo "installing nginx fail"
  exit 1
else 
    echo "installing nginx success"
  
fi
#!/bin/bash

cd `dirname $0`
[[ -s ./env.rc ]] && source ./env.rc

echo "======= setting up key pairs ======="
for KEY_NAME in $KEY_NAMES
do
  aws ec2 describe-key-pairs --output text --key-name $KEY_NAME >/dev/null 2>&1
  if [ $? -gt 0 ]
  then
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' | sed -e 's/^"//' -e 's/"$//' -e's/\\n/\
/g'> ../data/$KEY_NAME.pem
    chmod 400 ../data/$KEY_NAME.pem
  fi
  aws ec2 describe-key-pairs --output text --key-name $KEY_NAME
done

echo "======== setting up terraform back end ========"
cd terraform
terraform init
terraform apply

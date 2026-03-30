#!/bin/bash

# ====== VARIABLES (change these) ======
AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-04ed303a8ef1f4a07"
zone_id="Z0225359BD1MOLB4YVEF"
domain_name="devops7.online"

# ====== LOOP FOR MULTIPLE INSTANCES ======
for instance in "$@"
do
  echo "Creating instance: $instance"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --key-name $KEY_NAME \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  echo "Created instance with ID: $INSTANCE_ID"


  if [ "$instance" == "frontend" ]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query 'Reservations[].Instances[].PublicIpAddress' \
      --output text)
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query 'Reservations[].Instances[].PrivateIpAddress' \
      --output text)

  fi

       RECORD_NAME="$instance.$domain_name"

  echo "Instance: $instance | IP: $IP"

  aws route53 change-resource-record-sets \
--hosted-zone-id $zone_id \
--change-batch '
{
    "Comment": "Updating record",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                    {
                        "Value": "'"$IP"'"
                    }
                ]
            }
        }
    ]
}
'

    echo "DNS record created: $RECORD_NAME"

done
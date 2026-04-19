#!/bin/bash
set -e

while pgrep -x apt-get > /dev/null || pgrep -x dpkg > /dev/null; do
  echo "Waiting for background apt/dpkg to finish..."
  sleep 5
done
systemctl disable --now unattended-upgrades || true

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3-dev python3-setuptools python3-pip unzip curl git mysql-client-core-8.0

# Install AWS CLI v2 (awscli no longer in apt on Ubuntu 24.04)
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version

python3 -m pip install --break-system-packages pillow boto3 mysql-connector-python

# Pull the GitHub deploy key from Secrets Manager
aws secretsmanager get-secret-value --secret-id github-deploy-key --region us-east-1 --query SecretString --output text > /home/ubuntu/.ssh/github-deploy-key
chmod 600 /home/ubuntu/.ssh/github-deploy-key
chown ubuntu:ubuntu /home/ubuntu/.ssh/github-deploy-key

sudo -u ubuntu ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts

cat > /home/ubuntu/.ssh/config <<EOF
Host github.com
  IdentityFile /home/ubuntu/.ssh/github-deploy-key
  StrictHostKeyChecking no
EOF
chown ubuntu:ubuntu /home/ubuntu/.ssh/config
chmod 600 /home/ubuntu/.ssh/config

sudo -u ubuntu git clone git@github.com:fu-ceverhart/ITMO463.git /home/ubuntu/ITMO463

cd /home/ubuntu/ITMO463/module5/M5-assessment-templates-and-code

# Provision the database schema
RDS_HOST=$(aws rds describe-db-instances --region us-east-1 --query 'DBInstances[0].Endpoint.Address' --output text)
DB_USER=$(aws secretsmanager get-secret-value --secret-id uname --region us-east-1 --query SecretString --output text)
DB_PASS=$(aws secretsmanager get-secret-value --secret-id pword --region us-east-1 --query SecretString --output text)

until mysql -h $RDS_HOST -u $DB_USER -p$DB_PASS -e "SELECT 1;" 2>/dev/null; do
  echo "Waiting for RDS to be reachable..."
  sleep 10
done

mysql -h $RDS_HOST -u $DB_USER -p$DB_PASS < ./create.sql

cp ./app.py /usr/local/bin/
cp ./checkqueue.timer /etc/systemd/system/
cp ./checkqueue.service /etc/systemd/system/

systemctl enable --now checkqueue.timer
systemctl enable checkqueue.service

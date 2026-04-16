#!/bin/bash

# Install Backend dependecies here:

##############################################################################
# Installing Python Pip and library Dependencies
##############################################################################
sudo apt update -y
sudo apt install -y python3-dev python3-setuptools python3-pip
sudo -u ubuntu python3 -m pip install pip --upgrade
python3 -m pip install pillow
python3 -m pip install boto3
python3 -m pip install mysql-connector-python

sudo apt install -y awscli

cd /home/ubuntu

# Pull the GitHub deploy key from Secrets Manager
aws secretsmanager get-secret-value --secret-id github-deploy-key --region us-east-1 --query SecretString --output text > /home/ubuntu/.ssh/github-deploy-key
chmod 600 /home/ubuntu/.ssh/github-deploy-key
chown ubuntu:ubuntu /home/ubuntu/.ssh/github-deploy-key

# Add GitHub to known hosts
sudo -u ubuntu ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts

# Configure SSH to use the deploy key
cat > /home/ubuntu/.ssh/config <<EOF
Host github.com
  IdentityFile /home/ubuntu/.ssh/github-deploy-key
  StrictHostKeyChecking no
EOF
chown ubuntu:ubuntu /home/ubuntu/.ssh/config
chmod 600 /home/ubuntu/.ssh/config

# Command to clone your private repo via SSH using the Private key
sudo -u ubuntu git clone git@github.com:fu-ceverhart/ITMO463.git /home/ubuntu/ITMO463

# Copy files into place and enable the systemd timer
cd /home/ubuntu/ITMO463/module5/M5-assessment-templates-and-code

echo "Copying ./app.py to /usr/local/bin/..."
sudo cp ./app.py /usr/local/bin/
echo "Copying ./checkqueue.timer to /etc/systemd/system/..."
sudo cp ./checkqueue.timer /etc/systemd/system/
echo "Copying ./checkqueue.service to /etc/systemd/system/..."
sudo cp ./checkqueue.service /etc/systemd/system/

sudo systemctl enable --now checkqueue.timer
sudo systemctl enable checkqueue.service

#!/bin/bash

# Install dependecies here:

##############################################################################
# Installing Nginx, git, and awscli
##############################################################################
sudo apt update -y
sudo apt install -y nginx unzip git awscli

##############################################################################
# Enable and start Nginx service
##############################################################################
sudo systemctl enable nginx
sudo systemctl start nginx

##############################################################################
# Install Node JS
# https://github.com/nodesource/distributions#installation-instructions-deb
##############################################################################
curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install -y nodejs
node -v

##############################################################################
# Use NPM (node package manager to install AWS JavaScript SDK)
##############################################################################
sudo npm install pm2 -g

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

# Clone the repo
sudo -u ubuntu git clone git@github.com:fu-ceverhart/ITMO463.git /home/ubuntu/ITMO463

# Install npm packages in the app directory
cd /home/ubuntu/ITMO463/module5/M5-assessment-templates-and-code
sudo -u ubuntu npm install @aws-sdk/client-sqs @aws-sdk/client-s3 @aws-sdk/client-sns \
  @aws-sdk/client-rds @aws-sdk/client-secrets-manager \
  express multer multer-s3 mysql2 uuid

# Configure nginx reverse proxy
sudo cp /home/ubuntu/ITMO463/module5/M5-assessment-templates-and-code/default /etc/nginx/sites-available/default
sudo systemctl daemon-reload
sudo systemctl restart nginx

# Start the app with pm2
sudo -u ubuntu pm2 start /home/ubuntu/ITMO463/module5/M5-assessment-templates-and-code/app.js
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
sudo -u ubuntu pm2 save

#!/bin/bash

# Command to clone your private repo via SSH usign the Private key
####################################################################
# Note - change "git@github.com:jhajek/coursera-cloud-computing.git"
# to be your private repo name for the Coursera Class
####################################################################
cd /home/ubuntu

# Update and install dependencies
apt-get update -y
apt-get install -y git nginx mysql-client

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install awscli
# apt-get install -y awscli
apt-get install -y python3-pip
pip3 install awscli --break-system-packages

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

# Install app dependencies
cd /home/ubuntu/ITMO463/module4
npm install

# Configure nginx using the config from the repo
cp /home/ubuntu/ITMO463/module4/default /etc/nginx/sites-available/default
systemctl restart nginx
systemctl enable nginx

# Wait for RDS to be available and run create.sql
RDS_HOST=$(aws rds describe-db-instances --region us-east-1 --query 'DBInstances[0].Endpoint.Address' --output text)
DB_USER=$(aws secretsmanager get-secret-value --secret-id uname --region us-east-1 --query SecretString --output text)
DB_PASS=$(aws secretsmanager get-secret-value --secret-id pword --region us-east-1 --query SecretString --output text)

# Wait until RDS is reachable
until mysql -h $RDS_HOST -u $DB_USER -p$DB_PASS -e "SELECT 1;" 2>/dev/null; do
  echo "Waiting for RDS..."
  sleep 10
done

mysql -h $RDS_HOST -u $DB_USER -p$DB_PASS < /home/ubuntu/ITMO463/module4/create.sql

# Start the app
cd /home/ubuntu/ITMO463/module4
node app.js &
#!/bin/bash
set -e

while pgrep -x apt-get > /dev/null || pgrep -x dpkg > /dev/null; do
  echo "Waiting for background apt/dpkg to finish..."
  sleep 5
done
systemctl disable --now unattended-upgrades || true

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx unzip git curl

systemctl enable nginx
systemctl start nginx

# Install AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version

# Install Node JS 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh
apt-get install -y nodejs
node -v
npm -v

npm install pm2 -g

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

cd /home/ubuntu/ITMO463/module7/M7-assessment-template-code
sudo -u ubuntu npm install @aws-sdk/client-sqs @aws-sdk/client-s3 @aws-sdk/client-sns @aws-sdk/client-dynamodb express multer multer-s3 uuid ip

cp /home/ubuntu/ITMO463/module7/M8-assessment-template-code/default /etc/nginx/sites-available/default
systemctl daemon-reload
systemctl restart nginx

sudo -u ubuntu pm2 start /home/ubuntu/ITMO463/module7/M7-assessment-template-code/app.js
sudo -u ubuntu pm2 save
$(which pm2) startup systemd -u ubuntu --hp /home/ubuntu || true

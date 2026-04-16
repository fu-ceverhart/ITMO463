#!/bin/bash

# Install Backend dependecies here:

##############################################################################
# Installing Python Pip and library Dependencies
##############################################################################
sudo apt update -y
sudo apt install -y python3-dev python3-setuptools python3-pip
python3 -m pip install pip --upgrade
python3 -m pip install pillow
python3 -m pip install boto3

cd /home/ubuntu

# Command to clone your private repo via SSH usign the Private key
####################################################################
# Note - change "hajek.git" to be your private repo name (hawk ID) #
####################################################################
sudo -u ubuntu git clone git@github.com:jhajek/coursera-cloud-computing.git

# Start the nodejs app where it is located via PM2
# https://pm2.keymetrics.io/docs/usage/quick-start
cd /home/ubuntu/coursera-cloud-computing/itmo-463-563/M5L3
# Pull latest changes

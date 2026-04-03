#!/bin/bash

# Install dependecies here:

##############################################################################
# Installing Nginx
##############################################################################
sudo apt update -y
sudo apt install nginx unzip -y

##############################################################################
# Enable and start Nginx service
##############################################################################
sudo systemctl enable nginx
sudo systemctl start nginx


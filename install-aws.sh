#!/bin/bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --install-dir ~/aws-cli --bin-dir ~/bin
# echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
# source ~/.bashrc
# aws --version
# aws configure
!#/bin/bash

# Setting up Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Setting up WordPress
mkdir wordpress
cd wordpress


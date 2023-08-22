#!/bin/bash

# Instalar Docker
yum update -y
yum install docker -y
systemctl start docker.service && systemctl enable docker.service
usermod -aG docker ec2-user

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Montar Amazon EFS
yum install -y amazon-efs-utils
mkdir /mnt/efs
efs_mount_target="fs-028553ba57c8f1212.efs.us-east-1.amazonaws.com:/"
echo "$efs_mount_target /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
mount -a -t efs,nfs4 defaults

# Crie o docker-compose.yml
cat <<EOF > /mnt/efs/docker-compose.yml
version: '3'
services:
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: wordpress.ctl3b1vgbby2.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: wordpress
EOF

# Iniciar o Docker Compose
cd /mnt/efs
docker-compose up -d

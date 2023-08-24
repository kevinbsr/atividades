#!/bin/bash

# estes comandos instalarão e habilitarão o Docker
yum update -y
yum install docker -y
systemctl start docker.service && systemctl enable docker.service
usermod -aG docker ec2-user

# estes comandos instalarão o Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# estes comando montarão o EFS
yum install -y amazon-efs-utils
mkdir /mnt/efs
efs_mount_target="fs-00c69a321c7e11584.efs.us-east-1.amazonaws.com:/" # cole o DNS do seu EFS nesta linha
echo "$efs_mount_target /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
mount -a -t efs,nfs4 defaults

# estes comando criarão o docker-compose.yml
cat <<EOF > /mnt/efs/docker-compose.yml
version: '3'
services:
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: wordpress-db.ctl3b1vgbby2.us-east-1.rds.amazonaws.com # cole o endpoint da sua db nesta linha 
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: wordpress
EOF

# estes comando iniciarão o Docker Compose
cd /mnt/efs
docker-compose up -d

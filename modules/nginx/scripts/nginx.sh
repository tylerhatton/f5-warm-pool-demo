#!/usr/bin/env bash

# Connectivity check to see if NAT Gateway is up
count=0
while true
do
  if ping -c 1 -W 5 google.com 1>/dev/null 2>&1 
  then
    echo "Connected!"
    break
  elif [ $count -le 15 ]
  then
    echo "Not Connected!"
    count=$[$count+1]
  else
    echo "Giving up"
    break
  fi
  sleep 1
done

#Get IP
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

#Utils
sudo apt update

#Install Dockers
sudo snap install docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

#Run  nginx
sleep 10
cat << EOF > docker-compose.yml
version: "3.7"
services:
  web:
    image: nginxdemos/hello
    ports:
    - "80:80"
    restart: always
    command: [nginx-debug, '-g', 'daemon off;']
    network_mode: "host"
EOF
sudo docker-compose up -d
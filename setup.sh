#!/bin/bash

# Obtiene la ruta del directorio que contiene este script.
rutaScript=$(dirname "${BASH_SOURCE[0]}")

# Comprobar actualización
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalación docker
curl -sSL https://get.docker.com | sh
sudo sh get-docker.sh
sudo usermod -aG docker ${USER}

# Instalación Portainer
sudo docker volume create portainer_data
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# Docker-composes
sudo docker compose -f $rutaScript/docker/cloudflare/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/cloudflare/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/duplicati/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/filebrowser/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/heimdall/docker-compose.yml up -d
git clone https://github.com/oijkn/Docker-Raspberry-PI-Monitoring.git $rutaScript/docker/monitorizacion/


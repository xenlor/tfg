#!/bin/bash

# Obtiene la ruta del directorio que contiene este script.
rutaScript=$(dirname "${BASH_SOURCE[0]}")
sudo curl -fsSL https://get.docker.com/ -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ${USER}
sudo docker compose -f $rutaScript/docker/cloudflare/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/cloudflare/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/duplicati/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/filebrowser/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/heimdall/docker-compose.yml up -d
sudo docker compose -f $rutaScript/docker/monitoring/docker-compose.yml up -d


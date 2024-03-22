#!/bin/bash

# Obtiene la ruta del directorio que contiene este script.
rutaScript=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

# Comprobar actualización
sudo apt-get update -y
sudo apt-get upgrade -y

# Comprobar si Docker ya está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado. Instalando Docker..."
    # Instalación de Docker
    curl -sSL https://get.docker.com | sh
    # Añade el usuario actual al grupo docker
    sudo usermod -aG docker "$USER"
else
    echo "Docker ya está instalado."
fi

# Instalación de Portainer
if [ ! "$(sudo docker ps -f name=portainer)" ]; then
    echo "Instalando Portainer..."
    sudo docker volume create portainer_data
    sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
else
    echo "Docker no está disponible. Portainer no se puede instalar."
fi

# Clonar repositorio para monitorización si no está ya clonado
if [ ! -d "$rutaScript/docker/monitorizacion" ]; then
        git clone https://github.com/oijkn/Docker-Raspberry-PI-Monitoring.git "$rutaScript"/docker/monitorizacion/
fi

sudo docker compose -f "$rutaScript"/docker/cloudflare/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/duplicati/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/filebrowser/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/heimdall/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/monitorizacion/docker-compose.yml up -d


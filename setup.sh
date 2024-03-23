#!/bin/bash

# Obtiene la ruta del directorio que contiene este script.
rutaScript=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

sudo chmod -R 777 $rutaScript

# Comprobar actualización
echo "Actualizando repertorios..."
sudo apt-get update -y > /dev/null
sudo apt-get upgrade -y > /dev/null

# Instalar Fail2Ban
sudo apt install fail2ban -y > /dev/null

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
if [ ! "$(sudo docker ps -a | grep portainer)" ]; then
    echo "Instalando Portainer..."
    sudo docker volume create portainer_data
    sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
else
    echo "Portainer ya está instalado."
fi

# Clonar repositorio para monitorización si no está ya clonado
#if [ ! -d "$rutaScript/docker/monitorizacion" ]; then
#        sudo git clone https://github.com/oijkn/Docker-Raspberry-PI-Monitoring.git "$rutaScript"/docker/monitorizacion/ > /dev/null
#        sudo chmod -R 777 $rutaScript
#        sudo chown -R 472:472 $rutaScript/docker/monitorizacion/grafana  > /dev/null
#        sudo chown -R 65534:65534 $rutaScript/docker/monitorizacion/prometheus  > /dev/null
#fi
echo "Arrancando contenedores..."
sudo docker compose -f "$rutaScript"/docker/monitorizacion/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/cloudflare/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/duplicati/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/filebrowser/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/heimdall/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/wg-pihole/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/nginx/docker-compose.yml up -d


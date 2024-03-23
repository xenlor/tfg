#!/bin/bash

# Obtiene la ruta del directorio que contiene este script.
rutaScript=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

sudo chmod -R 777 $rutaScript

# Comprobar actualización
echo "Actualizando repertorios..."
sudo apt-get update -y 2> /dev/null
sudo apt-get upgrade -y 2> /dev/null
echo "Repertorios actualizados correctamente."

# Instalar Fail2Ban
echo "Instalando Fail2Ban..."
sudo apt install fail2ban -y 2> /dev/null
echo "Fail2Ban instalado correctamente."

# Comprobar si Docker ya está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado. Instalando Docker..."
    # Instalación de Docker
    curl -sSL https://get.docker.com | sh  2> /dev/null
    # Añade el usuario actual al grupo docker
    echo "Usuario '"$USER"' añadido al grupo 'docker'."
    sudo usermod -aG docker "$USER"  > /dev/null
    echo "Docker instalado correctamente."
else
    echo "Docker ya está instalado."
fi

# Instalación de Portainer
if [ ! "$(sudo docker ps -a | grep portainer)" ]; then
    echo "Instalando Portainer..."
    sudo docker volume create portainer_data > /dev/null
    sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest  > /dev/null
    echo "Portainer instalado correctamente."
else
    echo "Portainer ya está instalado."
fi

./home/pi/ruta.sh

echo "Arrancando contenedores..."
sudo docker compose -f "$rutaScript"/docker/monitorizacion/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/cloudflare/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/duplicati/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/filebrowser/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/heimdall/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/wg-pihole/docker-compose.yml up -d
sudo docker compose -f "$rutaScript"/docker/nginx/docker-compose.yml up -d


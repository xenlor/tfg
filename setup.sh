#!/bin/bash
clear
# Obtiene la ruta del directorio que contiene este script.
rutaScript=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

sudo chmod -R 777 $rutaScript

# Montar disco duro automáticamente
sudo bash -c 'cat >> /etc/fstab << EOF
/dev/sda /mnt/hdd auto defaults,noatime,nofail   0   0
EOF'

# Comprobar actualización
echo "Actualizando repertorios..."
sudo apt-get update -y &> /dev/null
sudo apt-get upgrade -y &> /dev/null
echo "Repertorios actualizados correctamente."

# Comprobar si Fail2Ban ya está instalado
if ! command -v fail2ban-client &> /dev/null; then
    echo "Fail2Ban no está instalado. Instalando Fail2Ban..."
    sudo apt install fail2ban -y &> /dev/null
    echo "Fail2Ban instalado correctamente."
else
    echo "Fail2Ban ya está instalado."
fi

# Comprobar si Samba ya está instalado
if ! command -v smbpasswd &> /dev/null; then
    echo "Samba no está instalado. Instalando Samba..."
    sudo apt install samba -y &> /dev/null
    echo "Samba instalado correctamente."
else
    echo "Samba ya está instalado."
fi

# Comprobar si Docker ya está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado. Instalando Docker..."
    # Instalación de Docker
    curl -sSL https://get.docker.com | sh  &> /dev/null
    # Añade el usuario actual al grupo docker
    echo "Usuario '"$USER"' añadido al grupo 'docker'."
    sudo usermod -aG docker "$USER"  &> /dev/null
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

read -sp "Presiona enter para continuar con la configuración de los contenedores..."

clear
# Configurar Wireguard + Pihole
read -p "Quieres crear una nueva configuración de Wireguard? [y/n] " opcion
case $opcion in
    [Yy]* ) sudo $rutaScript/docker/wg-pihole/config.sh;;
    *) read -sp "Se usará la configuración por defecto. Presiona 'enter' para continuar...";;
esac

clear
# Configurar DDNS Cloudflare
read -p "Quieres crear una nueva configuración de DDNS? [y/n] " opcion
case $opcion in
    [Yy]* ) sudo $rutaScript/docker/cloudflare/config.sh;;
    *) read -sp "Se usará la configuración por defecto. Presiona 'enter' para continuar...";;
esac

echo ""
echo "Arrancando contenedores..."
sudo docker compose -f "$rutaScript"/docker/authelia/docker-compose.yml up -d 2> /dev/null
sudo docker compose -f "$rutaScript"/docker/nginx/docker-compose.yml up -d 2> /dev/null
sudo docker compose -f "$rutaScript"/docker/monitorizacion/docker-compose.yml up -d 2> /dev/null
sudo docker compose -f "$rutaScript"/docker/cloudflare/docker-compose.yml up -d 2> /dev/null
sudo docker compose -f "$rutaScript"/docker/duplicati/docker-compose.yml up -d 2> /dev/null
sudo docker compose -f "$rutaScript"/docker/filebrowser/docker-compose.yml up -d 2> /dev/null
sudo docker compose -f "$rutaScript"/docker/heimdall/docker-compose.yml up -d 2> /dev/null
sudo docker compose -f "$rutaScript"/docker/wg-pihole/docker-compose.yml up -d 2> /dev/null


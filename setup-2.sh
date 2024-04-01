#!/bin/bash

clear
rutaScript=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

crearRaid(){
    sudo apt install mdadm -y
    if [ ! -e /dev/md0 ]; then
        sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 $disco1 $disco2
        sudo update-initramfs -u
        sudo mkfs.ext4 /dev/md0
    else
        echo "El RAID ya existe"
    fi
    if [ ! -d /mnt/hdd ];then
        sudo mkdir -p /mnt/hdd
    
    fi
    sudo bash -c 'cat >> /etc/fstab << EOF
/dev/md0    /mnt/hdd    ext4    defaults    0   2
EOF'
    sudo mount -a
    sudo chmod -R 777 /mnt/hdd/
}

installApps(){
    sudo apt-get update -y
    sudo apt-get upgrade -y
    if ! command -v smbpasswd &> /dev/null; then
        sudo apt install samba -y
    else
        echo "Samba ya está instalado."
    fi
    if ! command -v fail2ban-client &> /dev/null; then
        sudo apt install fail2ban -y
    else
        echo "Fail2Ban ya está instalado."
    fi
    if ! command -v docker &> /dev/null; then
        curl -sSL https://get.docker.com | sh
    else
        echo "Docker ya está instalado"
    fi
}

dockerContainers(){
    if ! sudo docker ps -a | grep portainer &> /dev/null; then
        sudo docker volume create portainer_data
        sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    else
        echo "Portainer ya instalado."
    fi
    echo "Arrancando contenedores..."
    sudo docker compose -f "$rutaScript"/docker/authelia/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/nginx/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/monitorizacion/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/cloudflare/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/duplicati/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/filebrowser/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/heimdall/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/wg-pihole/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/homarr/docker-compose.yml up -d
}

installApps
dockerContainers

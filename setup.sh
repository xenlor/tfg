#!/bin/bash

clear
rutaScript=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

crearRaid(){
    if ! command -v mdadm &> /dev/null;then
        sudo apt install mdadm -y
        clear
        echo "'mdadm' instalado correctamente."
    else
        clear
        echo "'mdadm' ya está instalado.'"
    fi
    read -p "Presiona 'enter' para continuar... "
    clear
    sudo lsblk -d -o NAME,SIZE 
    read -p "ingresa el nombre de los discos, separados por un espacio (ej. /dev/sda1 /dev/sdb1): " disco1 disco2
    if [ -z $disco1 ] || [ -z $disco2 ];then
        echo "Error: Debes ingresar dos discos para hacer el RAID 0."
    else
        echo "Disco 1: $disco1"
        echo "Disco 2: $disco2"
    fi
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
    sudo docker compose -f "$rutaScript"/docker/wg-pihole/docker-compose.yml up -d
    sudo docker compose -f "$rutaScript"/docker/homarr/docker-compose.yml up -d
    sudo docker restart portainer
}

read -p "¿Tienes dos discos extras conectados para crear un RAID? (y/n): " respuestaDiscoExtra
case $respuestaDiscoExtra in
    [Yy]*)
        crearRaid
        ;;
    [Nn]*)
        echo "Operación cancelada por falta de discos."
        ;;
    *)
        echo "Respuesta no válida. Se asume 'no'."
        ;;
esac
installApps
dockerContainers
echo "Ya está todo listo!"
read -p "Presiona 'enter' para continuar..."
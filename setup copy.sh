#!/bin/bash
clear

crearRaid(){
    sudo apt install mdadm -y
    sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 $disco1 $disco2
    sudo update-initramfs -u
    sudo mkfs.ext4 /dev/md0
    sudo mkdir -p /mnt/hdd
    sudo bash -c 'cat >> /etc/fstab << EOF
    /dev/md0    /mnt/hdd    ext4    defaults    0   2
    EOF'
    sudo mount -a
    sudo chmod -R 777 /mnt/hdd/
}

installApps(){  
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt install samba -y
    sudo apt install fail2ban -y
    curl -sSL https://get.docker.com | sh
}

dockerContainers(){
    if [ ! "$(sudo docker ps -a | grep portainer)" ]; then
        sudo docker volume create portainer_data
        sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    else
        echo "Portainer ya instalado."
    fi
}

installApps

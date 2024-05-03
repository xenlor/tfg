#!/bin/bash
clear
rutaScript=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

rm $rutaScript/.logs
touch $rutaScript/.logs

discos=$(lsblk -d -o NAME -nr)

disco_existe(){
    if echo "$discos" | grep -qw "$1";then
        return 0
    else
        return 1
    fi
}

if ! command -v mdadm > /dev/null;then
    echo "'mdadm' no instalado."
    sudo apt install mdadm -y >> "$rutaScript/.logs"
    echo "Instalando 'mdadm'..."
else
    echo "'mdadm' ya está instalado."
fi

clear
while true;do

echo "┌─────────┐"
echo "│  DISCOS │"
echo "└─────────┘"
sudo lsblk -d -o NAME,SIZE
echo

read -p "Ingresa dos de los discos que aparecen arriba para crear el RAID, separados por un espacio (ej. sda1 sdb): " disco1 disco2

if [ -z $disco1 ] || [ -z $disco2 ];then
    clear
    echo "Error: Debes ingresar dos discos para hacer el RAID 0."
    continue
fi

if disco_existe "$disco1" && disco_existe "$disco2" && [[ "$disco1" != "$disco2" ]];then
    clear
    echo "Ambos discos son válidos:"
    echo "Disco 1: /dev/$disco1"
    echo "Disco 2: /dev/$disco2"
    break
elif ! disco_existe "$disco1" && ! disco_existe "$disco2";then
    clear
    echo "Debes ingresar dos discos válidos."
elif ! disco_existe "$disco1";then
    clear
    echo "Error. El disco '$disco1' no existe."
elif ! disco_existe "$disco2";then
    clear
    echo "Error. El disco '$disco2' no existe."
elif [ "$disco1" == "$disco2" ];then
    clear
    echo "Los discos deben ser distintos."
fi

done

if [ ! -e /dev/md0 ]; then
    echo "Montando RAID 0..."
    yes | sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/$disco1 /dev/$disco2 >> "$rutaScript/.logs"
    if [ $? -ne 0 ];then
        echo "Error al crear RAID 0. Revisar los logs."
        exit 1
    fi
    sudo update-initramfs -u
    yes | sudo mkfs.ext4 /dev/md0
    echo "RAID 0 creado correctamente."
    echo "Montando RAID en /mnt/hdd..."
    sudo mkdir -p /mnt/hdd
    sudo bash -c 'cat >> /etc/fstab << EOF
/dev/md0    /mnt/hdd    ext4    defaults    0   2
EOF'
    sudo mount -a
    sudo chmod -R 777 /mnt/hdd/
    echo "RAID montado correctamente."
fi

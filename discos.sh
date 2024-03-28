#!/bin/bash
# Crear RAID 1 con discos
discos=$(lsblk -dpno NAME,SIZE | grep "931.5G" | awk '{print $1}')
discos_array=($discos)

if ! command -v mdadm &> /dev/null; then
    echo "La herramienta 'mdadm' no está instalada. Instalando 'mdadm'..."
    sudo apt install mdadm -y &> /dev/null
    echo "'mdadm' instalado correctamente."
else
    echo "'mdadm' ya está instalado."
fi

sudo umount ${discos_array[0]} &> /dev/null
sudo umount ${discos_array[1]} &> /dev/null
echo "Creando RAID 1..."
sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 ${discos_array[0]} ${discos_array[1]} --run 2> /dev/null
echo "RAID 1 creado correctamente."
echo "Guardando configuracion..."
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf > /dev/null
sudo update-initramfs -u > /dev/null
echo "Configuracion guardada correctamente."
sudo mkdir -p /mnt/raid
echo "Formateando RAID a ext4..."
sudo mkfs.ext4 -F /dev/md0 &> /dev/null
echo "RAID formateado correctamente."
sudo bash -c 'cat >> /etc/fstab << EOF
/dev/md0    /mnt/raid   ext4    defaults    0   2
EOF'
echo "Montando directorio RAID..."
sudo mount -a &> /dev/null
echo "Directorio RAID montado correctamente en '/mnt/raid'."

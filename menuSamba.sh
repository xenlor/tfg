#!/bin/bash
clear
confSamba='/etc/samba/smb.conf'

#if [ "$(id -u)" != "0" ]; then
#    echo "Este script debe ser ejecutado como root" 1>&2
#    exit 1
#fi

# Función para comprobar si la carpeta compartida ya existe
comprobarCarpeta() {
    local nombreCarpeta=""
    while [[ -z "$nombreCarpeta" ]];do
        read -p "Introduce el nombre de la carpeta compartida: " nombreCarpeta
        if [[ -z "$nombreCarpeta" ]];then
            echo "El nombre de la carpeta compartida no puede estar en blanco. Por favor introduce un nombre válido."
        fi
    done
    if grep -q "^### $nombreCarpeta ###" $confSamba; then
        echo "La carpeta compartida '$nombreCarpeta' ya existe en el archivo smb.conf."
        read -p "Presiona 'enter' para continuar..."
    else
        local rutaCarpeta=""
        while [[ (-z "$rutaCarpeta") || ($rutaCarpeta != /*) ]];do
            read -p "Introduce el camino absoluto de la carpeta a compartir: " rutaCarpeta
            if [[ -z "$rutaCarpeta" ]];then
                echo "La ruta no puede estar en blanco. Por favor introduce una ruta válida."
            elif [[ "$rutaCarpeta" != /* ]];then
                echo "La ruta debe ser absoluta (ej. /ruta/de/la/carpeta). Por favor introduce una ruta válida."
            fi
        done
        read -p "¿Quieres que sea solo lectura? [y/n]: " respuestaSoloLectura
        case $respuestaSoloLectura in
            [Yy]*)
                soloLectura="yes"
                ;;
            [Nn]*)
                soloLectura="no"
                ;;
            * )
                echo "Respuesta no válida. Se asume 'no'."
                soloLectura="no"
                ;;
        esac
        read -p "¿Quieres que sea visible en la red? [y/n]: " respuestaBrowsable
        case $respuestaBrowsable in
            [Yy]*)
                browsable="yes"
                ;;
            [Nn]*)
                browsable="no"
                ;;
            * )
                echo "Respuesta no válida. Se asume 'no'."
                browsable="no"
                ;;
        esac
        if [ ! -d "$rutaCarpeta" ]; then
            echo "Creando carpeta $rutaCarpeta..."
            sudo mkdir -p "$rutaCarpeta"
        fi
        crearCompartida "$nombreCarpeta" "$rutaCarpeta" "$soloLectura" "$browsable"
    fi
}

# Función para añadir una nueva carpeta compartida a smb.conf
crearCompartida() {
    local nombreCarpeta=$1
    local rutaCarpeta=$2
    local soloLectura=$3
    local browsable=$4
    echo "### $nombreCarpeta ###
[$nombreCarpeta]
   path = $rutaCarpeta
   read only = $soloLectura
   browsable = $browsable
   create mask = 0774
   directory mask = 0774
### $nombreCarpeta ###" | sudo tee -a $confSamba > /dev/null
    sudo chown :users "$rutaCarpeta" 2> /dev/null
    sudo chmod 0774 "$rutaCarpeta" 2> /dev/null
    echo "Reiniciando Samba..."
    sudo systemctl restart smbd 2> /dev/null
    echo "Carpeta compartida '$nombreCarpeta' añadida exitosamente."
    read -p "Presiona 'enter' para continuar..."
}

# Función para eliminar una carpeta compartida de smb.conf
eliminarCompartida() {
    read -p "Introduce el nombre de la carpeta compartida a eliminar: " nombreCarpeta
    # Verificar si la sección existe en smb.conf
    if grep -q "^### $nombreCarpeta ###" $confSamba; then
        read -p "¿Estás seguro que deseas eliminar la carpeta compartida '$nombreCarpeta'? [y/n]: " respuesta
        case "$respuesta" in
        [yY]*)
            # Obteniendo la ruta de la carpeta compartida desde smb.conf
            rutaCarpeta=$(sed -n "/^### $nombreCarpeta ###/,/^### $nombreCarpeta ###$/p" $confSamba | grep "path" | awk '{print $3}')
            echo $rutaCarpeta
            sudo sed -i "/^### $nombreCarpeta ###/,/^### $nombreCarpeta ###$/d" $confSamba
            echo "La carpeta compartida '$nombreCarpeta' ha sido eliminada de la configuración de Samba."
            read -p "¿Deseas eliminar también la carpeta '$nombreCarpeta' de forma local? [y/n]: " eliminarLocal
            case "$eliminarLocal" in
            [yY]*)
                if [[ -n "$rutaCarpeta" ]]; then
                    echo "Eliminando la carpeta $rutaCarpeta de forma local..."
                    sudo rm -rf "$rutaCarpeta"
                    echo "La carpeta $rutaCarpeta ha sido eliminada de forma local."
                else
                    echo "No se pudo obtener la ruta de la carpeta compartida para eliminarla localmente."
                fi
                ;;
            [nN]*)
                echo "No se elimina la carpeta de forma local."
                ;;
            *)
                echo "Respuesta inválida. No se elimina la carpeta de forma local."
                ;;
            esac
            echo "Reiniciando Samba..."
            sudo systemctl restart smbd 2> /dev/null
            echo "Cambio aplicado. Samba reiniciado."
            ;;
        *)
            echo "No se eliminó la carpeta $nombreCarpeta"
            ;;
        esac
    else
        echo "La carpeta compartida '$nombreCarpeta' no se encuentra en la configuración de Samba."
    fi
    read -p "Presiona 'enter' para continuar..."
}


crearUsuarioSamba() {
    local username=$1
    while [[ -z "$username" ]];do
        read -p "Introduce el nombre del usuario de Samba a crear: " username
        if [[ -z "$username" ]];then
            echo "El nombre del usuario no puede estar en blanco. Ingresa un nombre válido."
        fi
    done
    if id "$username" &>/dev/null; then
        echo "El usuario $username ya existe en el sistema."
        sudo usermod -aG users "$username"
    else
        sudo useradd -M -s /usr/sbin/nologin "$username"
        echo "Usuario $username creado en el sistema."
        sudo usermod -aG users "$username"
    fi

    if sudo pdbedit -L | grep -q "^$username:"; then
        echo "El usuario $username ya está habilitado en Samba."
    else
        read -sp "Introduce una contraseña para el usuario de Samba: " samba_password
        echo
        (echo "$samba_password"; echo "$samba_password") | sudo smbpasswd -a "$username"
        sudo smbpasswd -e "$username"
        echo "Usuario $username habilitado en Samba con éxito."
    fi
    read -p "Presiona 'enter' para continuar..."
}

eliminarUsuarioSamba() {
    read -p "Introduce el nombre del usuario de Samba a eliminar: " username
    if sudo pdbedit -L | grep -q "^$username:"; then
        sudo smbpasswd -x "$username"
        echo "Usuario $username eliminado de Samba."

        read -p "Deseas eliminar también el usuario $username del sistema? [y/n]: " respuesta
        case "$respuesta" in
        [yY]*)
            sudo userdel "$username"
            echo "Usuario $username eliminado del sistema."
            ;;
        [nN]*)
            echo "El usuario no fue eliminado del sistema."
            ;;
        *)
            echo "El usuario no fue eliminado del sistema."
            ;;
        esac

    else
        echo "El usuario $username no existe en Samba."
    fi
    read -p "Presiona 'enter' para continuar..."
}

# Función para listar carpetas de Samba
listadoCarpetasSamba() {
   echo "Carpetas compartidas en Samba:"
   grep '^### ' $confSamba | uniq
   read -p "Presiona 'enter' para continuar..."
}

# Función para listar usuarios de Samba
listarUsuariosSamba() {
    echo "Usuarios de Samba:"
    sudo pdbedit -L | cut -d: -f1
    read -p "Presiona 'enter' para continuar..."
}


# Función para mostrar el menú
mostrarMenu() {
    echo "--------------------------------------"
    echo "            MENÚ PRINCIPAL            "
    echo "--------------------------------------"
    echo " 1) Añadir carpeta compartida"
    echo " 2) Eliminar carpeta compartida"
    echo " 3) Añadir usuario en Samba"
    echo " 4) Eliminar usuario en Samba"
    echo " 5) Listar carpetas compartidas"
    echo " 6) Listar usuarios en Samba"
    echo " 7) Salir"
    echo "--------------------------------------"
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1)
            clear
            echo "--------------------------------------"
            echo "     AÑADIR CARPETA COMPARTIDA       "
            echo "--------------------------------------"
            comprobarCarpeta
            ;;
        2)
            clear
            echo "--------------------------------------"
            echo "     ELIMINAR CARPETA COMPARTIDA     "
            echo "--------------------------------------"
            eliminarCompartida
            ;;
        3)
            clear
            echo "--------------------------------------"
            echo "        AÑADIR USUARIO EN SAMBA       "
            echo "--------------------------------------"
            crearUsuarioSamba
            ;;
        4)
            clear
            echo "--------------------------------------"
            echo "       ELIMINAR USUARIO EN SAMBA      "
            echo "--------------------------------------"
            eliminarUsuarioSamba
            ;;
        5)
            clear
            echo "--------------------------------------"
            echo "    LISTAR CARPETAS COMPARTIDAS       "
            echo "--------------------------------------"
            listadoCarpetasSamba
            ;;
        6)
            clear
            echo "--------------------------------------"
            echo "       LISTAR USUARIOS EN SAMBA       "
            echo "--------------------------------------"
            listarUsuariosSamba
            ;;
        7)
            clear
            echo "Hasta pronto..."
            exit 0
            ;;
        *)
            clear
            echo "Opción no válida. Por favor, intenta de nuevo."
            ;;
    esac
}

# Bucle principal
while true; do
    clear
    mostrarMenu
done

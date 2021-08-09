#!/bin/bash

# Colores  para Terminal
WHITE="\033[m"       # Blanco
WHITE_BOLD="\033[1m" # Blanco Bold
BLUE="\033[34m"      # Azul "\033[94m"
RED="\033[31m"       # Rojo
YELLOW="\033[33m"    # Amarrillo
GREEN="\033[32m"     # Verde
CEND="\033[0m"       # Fin de color
# Colores para Dialog
DBLACK="\Z0"     # Negro
DRED="\Z1"       # Rojo
DGREEN="\Z2"     # Verde
DYELLOW="\Z3"    # Amarillo
DBLUE="\Z4"      # Azul
DPINK="\Z5"      # Rosa
DCYAN="\Z6"      # Cian
DWHITE="\Z7"     # Blanco
DBOLD="\Zb"      # Obscura
DREVERSE="\Zr"   # Reversa
DUNDERLINE="\Zu" # Subrayado
DCEND="\Zn"      # Fin de color
# Color para mensajes del sistema
WARNING="${RED}[x]:: ${CEND}"
SUCCESS="${GREEN}[✔]:: ${CEND}"
INFO="${BLUE}[!]:: ${CEND}"
# Para Dialog
DWARNING="${DRED}[x]:: ${DCEND}"
DSUCCESS="${DGREEN}[✔]:: ${DCEND}"
DINFO="${DBLUE}[!]:: ${DCEND}"
MountPoint="mnt"

# Clona repositorio de git y ejecuta un comando, después de terminar borra la carpeta
# @param $1 : _pkg                    type: string (nombre del paquete)
# @param $1 : _cmd                    type: string (comando a ejecutar)
# @param $1 : _url                    type: string (url si es distinto a git o solo nombre usuario del repositorio si es de git)
_git() {
    local _path="/tmp"
    local _pkg=$([[ -z $1 ]] && echo "makepkg -si --noconfirm" || echo "${1}")
    local _cmd=$([[ -z $2 ]] && echo "" || ([[ $2 == "makepkg" ]] && echo "&& makepkg -si --noconfirm" || echo "&& chmod +x ${2} && ${2}"))
    local _url=$([[ $3 == *http* ]] && echo "${3}" || ([[ -z $3 ]] && echo "https://github.com/foxfher" || echo "https://github.com/${3}"))

    if [[ ! -z ${MountPoint} ]]; then
        arch-chroot /${MountPoint} cd $_path && git clone ${_url}/${_pkg}.git && (cd $_pkg $_cmd) && sudo rm -rf $_path/$_pkg
    else
        cd $_path && git clone ${_url}/${_pkg}.git && (cd $_pkg $_cmd) && sudo rm -rf $_path/$_pkg
    fi
    #[[ -d /tmp/grub2-archses ]] && sudo rm -rf /tmp/grub2-archses
    #cd $_path && git clone ${_url}/${_pkg}.git && (cd $_pkg $_cmd) && sudo rm -rf $_path/$_pkg
    #CONFIG_FOLDERS=($(ls -aF | grep / | tail -n +3))
    #  echo ${CONFIG_FOLDERS[*]}
    #_git yay "makepkg" https://aur.archlinux.org
    #_git dotfilesarchses-grub install.sh
    #_git grub2-archses "install.sh -i"
    #_git grub2-archses
    #_git grub2Hat-ArchSES "install.sh -i"
    #_git bspwmbydarch-Arcris "install.sh -i" darch7
}

_yay_install() {
    #  _ProgressBar "${_Messages[RequierePackage]} " "yay"
    sed -i 's/%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
    runuser -l ${user} -c "cd /home/$user && git clone https://aur.archlinux.org/yay.git && (cd yay && makepkg -si --noconfirm) && sudo rm -rf /home/$user/yay"
    if [[ -f /etc/pamac.conf ]]; then
        sed -i '/#EnableAUR/ s/^#//' /etc/pamac.conf 
        sed -i '/#CheckAURUpdates/ s/^#//' /etc/pamac.conf
    fi
}

_detect_hardware() {
    #cpu
    local _hardware=$(lspci | grep -i "Host bridge" | sed 's/.*://' | sed 's/(.*//' | sed 's/^[ \t]*//' | awk '{print tolower($0)}')
    cpu=$([[ $_hardware == *intel* ]] && echo "intel-ucode" || echo "amd-ucode")
    #wifi
    _hardware=$(lspci | grep -i "Network Controller" | sed 's/.*://' | sed 's/(.*//' | sed 's/^[ \t]*//' | awk '{print tolower($0)}')
    wifi_pack="netctl wireless-regdb wpa_supplicant wireless_tools"
    wifi=$([[ $_hardware == *broadcom* ]] && echo "broadcom-wl$([[ $KERNEL == "linux" ]] && echo "" || echo "-dkms")" || echo "")
    #bluetooh
    [[ ! -z "$(lsusb | grep -i "Bluetooth")" ]] && bluetooh='bluez bluez-utils'
    diver="$(lsusb | grep -i "Bluetooth" | cut -d" " -f9- | cut -d " " -f1 | awk '{print tolower($0)}')-firmware"
    arch-chroot /${MountPoint} /bin/bash -c "pacman -Sy --noconfirm --needed ${bluetooh} ${wifi} ${cpu}"
    arch-chroot /mnt runuser -l ${user} -c "yay -S --noconfirm --needed ${dirver}"
}

# Detecta los Controladdores de de Video Intel/AMD/NVIDIA y en Máquinas virtuales
_detect_video() {
    local _hardware="$(lspci | grep -i "vga" | sed 's/.*://' | sed 's/(.*//' | sed 's/^[ \t]*//')"
    Hypervisor=$(systemd-detect-virt)

    echo -e "${SUCCESS} ${_Messages[Hardware_Detetect]} ${GREEN}Video${CEND} \n${_hardware}"
    if [ "$Hypervisor" = "none" ]; then
        if [[ $(echo $_hardware | grep "VGA" | grep -i "Intel") ]]; then
            arch-chroot /${MountPoint} pacman -Sy --noconfirm --needed xf86-video-intel 
        elif [[ $(echo $_hardware | grep "VGA" | grep -i "NVIDIA") ]]; then
            arch-chroot /${MountPoint}/bin/bash -c "pacman -S nvidia-dkms nvidia-utils egl-wayland --noconfirm --needed"
        elif [[ $(echo $_hardware | grep "VGA" | grep -i "ATI\|AMD") ]]; then
                arch-chroot /${MountPoint} pacman -Sy --noconfirm --needed 'xf86-video-ati' 'mesa'
        fi
    else
        echo -e ":: ${_Messages[Hardware_VirtualMachine]} ${GREEN}${Hypervisor}${CEND}"
        case "$Hypervisor" in
        "vmware")
            arch-chroot /${MountPoint} pacman -Sy --noconfirm --needed 'open-vm-tools' 'xf86-video-vmware' 'xf86-input-vmmouse' 'mesa' 'gtkmm' 'gtkmm3'
            echo -e "${SUCCESS} ${_Messages[Service_MV]}"
            arch-chroot /${MountPoint} systemctl enable vmtoolsd.service &>/dev/null
            arch-chroot /${MountPoint} systemctl enable vmware-vmblock-fuse.service &>/dev/null
            ;;
        "oracle")
            [[ $KERNEL == "linux" ]] &&
                arch-chroot /${MountPoint} pacman -Sy --noconfirm --needed 'virtualbox-guest-utils' 'virtualbox-host-modules-arch' mesa mesa-libgl ||
                arch-chroot /${MountPoint} pacman -Sy --noconfirm --needed 'virtualbox-guest-dkms' 'virtualbox-host-dkms' mesa mesa-libgl
            echo -e "${SUCCESS} ${_Messages[Service_MV]} "
            arch-chroot /${MountPoint} systemctl enable vboxservice.service &>/dev/null
            ;;
        "parallels") arch-chroot /${MountPoint} pacman -Sy --noconfirm --needed 'xf86-video-vesa' ;;
        *)
            arch-chroot /${MountPoint} pacman -Sy --noconfirm --needed xf86-video-fbdev mesa mesa-libgl qemu-guest-agent
            arch-chroot /mnt runuser -l ${user} -c  yay -S --noconfirm --needed spice-vdagent
            ;;
        esac
    fi
}

_detect_touch() {
    # Paquetes para los distintos tipos perifeficos de entrada (Teclado, ratón, etc)
    if [[ ! -z $(sudo dmidecode | grep -i "touch") ]]; then
        echo -e "${SUCCESS} ${_Messages[Hardware_Detetect]} ${GREEN}Touch${CEND} \n${_hardware}"
        arch-chroot /${MountPoint} /bin/$SHELL -c "pacman -Sy --noconfirm --needed  xf86-input-synaptics tlp"
        mkdir -p /${MountPoint}/etc/X11/xorg.conf.d
        echo -e 'Section "InputClass"' >/${MountPoint}/etc/X11/xorg.conf.d/30-touchpad.conf
        echo -e 'Identifier "libinput touchpad catchall"' >>/${MountPoint}/etc/X11/xorg.conf.d/30-touchpad.conf
        echo -e 'MatchIsTouchpad "on"' >>/${MountPoint}/etc/X11/xorg.conf.d/30-touchpad.conf
        echo -e 'Driver "libinput"' >>/${MountPoint}/etc/X11/xorg.conf.d/30-touchpad.conf
        echo -e 'Option "Tapping" "on"' >>/${MountPoint}/etc/X11/xorg.conf.d/30-touchpad.conf
        echo -e 'Option "NaturalScrolling" "true"' >>/${MountPoint}/etc/X11/xorg.conf.d/30-touchpad.conf
        echo -e 'EndSection' >>/${MountPoint}/etc/X11/xorg.conf.d/30-touchpad.conf
        arch-chroot /${MountPoint} systemctl enable tlp
    fi
}

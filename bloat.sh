#!/bin/bash

# WARNING: BLOAT SHALL BE RUN AS A CHILD OF THE BASE SCRIPT BECAUSE PARU CAN'T BE RUN AS ROOT
# However feel free to override the inherited user variable if you know what you're doing
#user="your_username"

clear
echo "Bloat by SimplyArch (BETA)"
echo "Copyright (C) 2021 Victor Bayas"
echo
echo "NOTE: THIS STEP IS COMPLETELY OPTIONAL, feel free to select None and finish the installation process"
echo
echo "We'll guide you through the process of installing a DE, additional software and drivers."
echo
echo ">>> Desktop Environment <<<"
echo
desktop="3"
#while ! [[ "$desktop" =~ ^(1|2|3|4|5|6|7|8)$ ]]; do
#    echo "Please select one option:"
#    echo "1. GNOME Minimal"
#    echo "2. GNOME Full (beware of pkgs count)"
#    echo "3. KDE Plasma"
#    echo "4. Xfce"
#    echo "5. LXQt"
#    echo "6. LXDE"
#    echo "7. Cinnamon"
#    echo "8. None - I don't want bloat"
#    read -p "Desktop (1-8): " desktop
#done
case $desktop in
1)
    DEpkg="gdm gnome-shell gnome-backgrounds gnome-control-center gnome-screenshot gnome-system-monitor gnome-terminal gnome-tweak-tool nautilus gedit gnome-calculator gnome-disk-utility eog evince"
    DM="gdm"
    ;;
2)
    DEpkg="gdm gnome gnome-tweak-tool"
    DM="gdm"
    ;;
3)
    DEpkg="xorg xorg-server-xwayland plasma plasma-wayland-session dolphin konsole kate kcalc ark gwenview spectacle okular packagekit-qt5 partitionmanager"
    DM="sddm"
    ;;
4)
    DEpkg="lxdm xfce4 xfce4-goodies network-manager-applet"
    DM="lxdm"
    ;;
5)
    DEpkg="sddm lxqt breeze-icons featherpad"
    DM="sddm"
    ;;
6)
    DEpkg="lxdm lxde leafpad galculator"
    DM="lxdm"
    ;;
7)
    DEpkg="lxdm cinnamon cinnamon-translations gnome-terminal"
    DM="lxdm"
    ;;
8) 
    echo "No desktop environment will be installed."
    exit 0
    ;;
esac


# install packages accordingly
arch-chroot /mnt /bin/bash -c "pacman -Sy $DEpkg firefox  pavucontrol pipewire pipewire-pulse pipewire-pulse pipewire-jack libdbusmenu-glib libsecret simplescreenrecorder "
# enable DM accordingly
arch-chroot /mnt /bin/bash -c "systemctl enable ${DM}.service"


echo ">>> Printer Support (CUPS) <<<"
echo
#echo "Do you want to add printing support? (Y/N)"
#read -p "Printing Support: " printerSupport
#if [[ $printerSupport == "y" || $printerSupport == "Y" || $printerSupport == "yes" || $printerSupport == "Yes" ]]; then
    arch-chroot /mnt /bin/bash -c "pacman -S cups cups-filterscups-pdf cups-pk-helper bluez-cups ghostscript a2ps gsfonts gutenprint foomatic-db foomatic-db-ppds foomatic-db-gutenprint-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds foomatic-db-engine system-config-printer python-pysmbc splix hplip python-pyqt5 python-reportlab --noconfirm --needed"
    arch-chroot /mnt systemctl enable cups.service
#fi
echo "Install pacmac, google,vlc, mpv"
arch-chroot /mnt /bin/bash -c "pacman -S --noconfirm --needed tar gzip bzip2 zip unzip unrar p7zip arj lzop xz "
arch-chroot /mnt runuser -l ${user} -c "yay -S --noconfirm --needed pamac-all-git google-chrome vlc mpv visual-studio-code-bin ice-ssb mailspring auto-cpufreq"
arch-chroot /mnt /bin/bash -c "systemctl enable auto-cpufreq"
sleep 2

echo "Install ZRam"
arch-chroot /mnt /bin/bash -c "pacman -S --noconfirm  --needed systemd-swap"
echo -e "# Archivo de configuración básica de ZRam" >/mnt/etc/systemd/swap.conf
echo -e "zram_enabled=1" >>/mnt/etc/systemd/swap.conf
echo -e 'zram_size=$(($RAM_SIZE))      # This is  of ram size by default.' >>/mnt/etc/systemd/swap.conf
echo -e 'zram_streams=$NCPU' >>/mnt/etc/systemd/swap.conf
echo -e 'zram_alg=lz4                    # lzo lz4 deflate lz4hc 842 - for Linux 4.8.4' >>/mnt/etc/systemd/swap.conf
echo -e 'zram_prio=200                   # 1 - 32767' >>/mnt/etc/systemd/swap.conf
arch-chroot /mnt /bin/bash -c "systemctl enable systemd-swap.service"
sleep 2

echo "Install timeshift"
arch-chroot /mnt runuser -l ${user} -c "yay -Syu --noconfirm --needed timeshift timeshift-autosnap"
exit 0

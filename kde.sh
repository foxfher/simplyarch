#!/bin/bash

# WARNING: BLOAT SHALL BE RUN AS A CHILD OF THE BASE SCRIPT BECAUSE PARU CAN'T BE RUN AS ROOT
# However feel free to override the inherited user variable if you know what you're doing
user="fernando"

clear
echo "Bloat by SimplyArch (BETA)"
echo "Copyright (C) 2021 Fernando Bello M"
echo
echo "NOTE: THIS STEP IS COMPLETELY OPTIONAL, feel free to select None and finish the installation process"
echo
echo "We'll guide you through the process of installing a DE, additional software and drivers."
echo
echo ">>> Desktop KDE Plasma Environment <<<"
echo
desktop="3"

    DEpkg="xorg xorg-server-xwayland plasma plasma-meta plasma-wayland-session dolphin konsole kate kcalc ark gwenview spectacle okular packagekit-qt5 partitionmanager kde-gtk-config"
    DM="sddm"
# install packages accordingly
pacman -Sy --noconfirm --needed $DEpkg firefox  pavucontrol pipewire pipewire-pulse pipewire-pulse pipewire-jack libdbusmenu-glib libsecret simplescreenrecorder
# enable DM accordingly
systemctl enable ${DM}.service


echo ">>> Printer Support (CUPS) <<<"
echo
    pacman -S --noconfirm --needed cups cups-filterscups-pdf cups-pk-helper bluez-cups ghostscript a2ps gsfonts gutenprint foomatic-db foomatic-db-ppds foomatic-db-gutenprint-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds foomatic-db-engine system-config-printer python-pysmbc splix hplip python-pyqt5 python-reportlab 
     systemctl enable cups.service

echo "Install pacmac, google,vlc, mpv"
pacman -S --noconfirm --needed tar gzip bzip2 zip unzip unrar p7zip arj lzop xz 
yay -S --noconfirm --needed pamac-all-git google-chrome vlc mpv visual-studio-code-bin ice-ssb mailspring auto-cpufreq
systemctl enable auto-cpufreq
sleep 2

echo "Install ZRam"
pacman -S --noconfirm  --needed systemd-swap
echo -e "# Archivo de configuración básica de ZRam" >/etc/systemd/swap.conf
echo -e "zram_enabled=1" >>/etc/systemd/swap.conf
echo -e 'zram_size=$(($RAM_SIZE))      # This is  of ram size by default.' >>/etc/systemd/swap.conf
echo -e 'zram_streams=$NCPU' >>/etc/systemd/swap.conf
echo -e 'zram_alg=lz4                    # lzo lz4 deflate lz4hc 842 - for Linux 4.8.4' >>/etc/systemd/swap.conf
echo -e 'zram_prio=200                   # 1 - 32767' >>/etc/systemd/swap.conf
systemctl enable systemd-swap.service
sleep 2

echo "Install timeshift"
yay -Syu --noconfirm --needed timeshift timeshift-autosnap
exit 0

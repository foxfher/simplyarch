#!/bin/bash

# short URL: https://is.gd/simplyarch
# see stats at: https://is.gd/stats.php?url=simplyarch

clear
echo "SimplyArch bootstrapper..."
echo "Copyright (C) 2021 Fernando Bello M"
echo 
pacman -Syy
pacman -Sy glibc --noconfirm
pacman -S git --noconfirm
pacman -S --noconfirm dmidecode lspci lsusb
git clone https://github.com/foxfher/simplyarch
cd simplyarch
chmod +x simplyarch.sh
./simplyarch.sh

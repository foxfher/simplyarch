#!/bin/bash

KERNEL="Linux-zen"

# WARNING: THIS SCRIPT USES RELATIVE FILE PATHS SO IT MUST BE RUN FROM THE SAME WORKING DIRECTORY AS THE CLONED REPO

clear
echo
echo "Welcome to SimplyArch Installer"
echo "Copyright (C) 2021 Fernando Bello M"
echo
echo "DISCLAIMER: THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED"
echo
echo "WARNING: MAKE SURE TO TYPE CORRECTLY BECAUSE THE SCRIPT WON'T PERFORM INPUT VALIDATIONS"
echo
echo "We'll guide you through the installation process of a fully functional Arch Linux system"
echo
read -p "Do you want to continue? (Y/N): " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
	clear
	# Ask locales
	echo ">>> Region & Language <<<"
	echo
	echo "EXAMPLES:"
	echo "us United States | us-acentos US Intl | latam Latin American Spanish | es Spanish"
	read -p "Keyboard layout: " keyboard
	if [[ -z "$keyboard" ]]; then
		keyboard="latam"
	fi
	echo
	echo "EXAMPLES: en_US | es_ES (don't add .UTF-8)"
	read -p "Locale: " locale
	if [[ -z "$locale" ]]; then
		locale="es_MX"
	fi
	clear
	# Ask account
	echo ">>> Account Setup <<<"
	echo
	read -p "Hostname: " hostname
	echo
	echo "Administrator User"
	echo "User: root"
	read -sp "Password: " rootpw
	echo
	read -sp "Re-type password: " rootpw2
	echo
	while [[ $rootpw != "$rootpw2" ]]; do
		echo
		echo "Passwords don't match. Try again"
		echo
		read -sp "Password: " rootpw
		echo
		read -sp "Re-type password: " rootpw2
		echo
	done
	echo
	echo "Standard User"
	read -p "User: " user
	export user
	read -sp "Password: " userpw
	echo
	read -sp "Re-type password: " userpw2
	echo
	while [[ $userpw != "$userpw2" ]]; do
		echo
		echo "Passwords don't match. Try again"
		echo
		read -sp "Password: " userpw
		echo
		read -sp "Re-type password: " userpw2
		echo
	done
	# Disk setup
	clear
	echo ">>> Disks Setup <<<"
	echo
	echo "Make sure to have your disk previously partitioned, if you are unsure press CTRL+C and run this script again"
	sleep 5
	clear
	echo "Partition Table"
	echo
	lsblk
	echo
	while ! [[ "$partType" =~ ^(1|2)$ ]]; do
		echo "Please select partition type (1/2):"
		echo "1. EXT4"
		echo "2. BTRFS"
		read -p "Partition Type: " partType
	done
	clear
	echo "Partition Table"
	echo
	lsblk
	echo
	echo "Write the name of the partition e.g: /dev/sdaX /dev/nvme0n1pX"
	read -p "Root partition: " rootPart
	case $partType in
	1)
		mkfs.ext4 $rootPart
		mount $rootPart /mnt
		;;
	2)
		mkfs.btrfs -f -L "Arch Linux" $rootPart
		btrfs_pack="btrfs-progs grub-btrfs "
		mount $rootPart /mnt
		btrfs sub cr /mnt/@
		btrfs su cr /mnt/@home
		btrfs su cr /mnt/@var
		btrfs su cr /mnt/@opt
		btrfs su cr /mnt/@tmp
		btrfs su cr /mnt/@.snapshots
		umount $rootPart
		mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@ $rootPart /mnt
		# You need to manually create folder to mount the other subvolumes at
		mkdir -p /mnt/{boot,home,var,opt,tmp,.snapshots}
		mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@home $rootPart /mnt/home
		mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@opt $rootPart /mnt/opt
		mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@tmp $rootPart /mnt/tmp
		mount -o noatime,commit=120,compress=zstd,space_cache,subvol=@.snapshots $rootPart /mnt/.snapshots
		mount -o subvol=@var $rootPart /mnt/var
		;;
	esac
	clear
	if [[ -d /sys/firmware/efi ]]; then
		echo "Partition Table"
		echo
		lsblk
		echo
		echo "Write the name of the partition e.g: /dev/sdaX /dev/nvme0n1pX"
		read -p "EFI partition: " efiPart
		echo
		echo "DUALBOOT USERS: If you are sharing this EFI partition with another OS type N"
		read -p "Do you want to format this partition as FAT32? (Y/N): " formatEFI
		if [[ $formatEFI == "y" || $formatEFI == "Y" || $formatEFI == "yes" || $formatEFI == "Yes" ]]; then
			mkfs.fat -F32 $efiPart
		fi
		mkdir -p /mnt/boot/efi
		mount $efiPart /mnt/boot/efi
		echo
		clear
	fi
	echo "Partition Table"
	echo
	lsblk
	echo
	echo "NOTE: If you don't want to use a Swap partition type N below"
	echo
	echo "Write the name of the partition e.g: /dev/sdaX /dev/nvme0n1pX"
	read -p "Swap partition: " swap
	if [[ $swap == "n" || $swap == "N" || $swap == "no" || $swap == "No" ]]; then
		echo
		echo "Swap partition not selected"
		sleep 1
	else
		mkswap $swap
		swapon $swap
	fi
	clear
	# update mirrors
	chmod +x simple_reflector.sh
	./simple_reflector.sh
	clear
	echo ">>> Installing and configuring the base system <<<"
	echo
	echo "This process may take a while, please wait..."
	sleep 3
	# Install base systems
	if [[ -d /sys/firmware/efi ]]; then
		pacstrap /mnt base base-devel  $KERNEL $KERNEL-headers  linux-firmware  grub efibootmgr os-prober bash-completion sudo nano vim networkmanager network-manager-applet  dialog ntfs-3g nfs-utils neofetch htop git reflector xdg-user-dirs xdg-utils e2fsprogs man-db gvfs gvfs-smb ${btrfs_pack}
	else
		pacstrap /mnt base base-devel  $KERNEL $KERNEL-headers  linux-firmware  grub os-prober bash-completion sudo nano vim networkmanager network-manager-applet dialog ntfs-3g nfs-utils neofetch htop git reflector xdg-user-dirs xdg-utils e2fsprogs man-db gvfs gvfs-smb ${btrfs_pack}
	fi
	# fstab
	genfstab -U /mnt >>/mnt/etc/fstab
	# configure base systemefibootmgr
	# locales
	echo "$locale.UTF-8 UTF-8" >/mnt/etc/locale.gen
	echo "LANG=$locale.UTF-8" >/mnt/etc/locale.conf
	arch-chroot /mnt /bin/bash -c "locale-gen"
	# keyboard
	echo "KEYMAP=$keyboard" >/mnt/etc/vconsole.conf
	# timezone
	arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/$(curl https://ipapi.co/timezone) /etc/localtime"
	arch-chroot /mnt /bin/bash -c "hwclock --systohc"
	# enable multilib
	sed -i '93d' /mnt/etc/pacman.conf
	sed -i '94d' /mnt/etc/pacman.conf
	sed -i "93i [multilib]" /mnt/etc/pacman.conf
	sed -i "94i Include = /etc/pacman.d/mirrorlist" /mnt/etc/pacman.conf
	# hostname
	echo "$hostname" >/mnt/etc/hostname
	echo "127.0.0.1	localhost" >/mnt/etc/hosts
	echo "::1		localhost" >>/mnt/etc/hosts
	echo "127.0.1.1	$hostname.localdomain	$hostname" >>/mnt/etc/hosts

	# grub
	#btrfs
	[[ ! -z $btrfs_pack ]] &&
		sed -e '/^HOOKS=/s/\ fsck//g' -e "s/modconf block/modconf block btrfs /" -i /mnt/etc/mkinitcpio.conf
	# Carga tema
	theme_grub="grub2Hat-ArchSES"
	_git "$theme_grub" "./install.sh"

	if [[ -d /sys/firmware/efi ]]; then
		arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch"
	else
		arch-chroot /mnt /bin/bash -c "grub-install ${rootPart::-1}"
	fi
	arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
	#services
	# networkmanager
	arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager.service"
	arch-chroot /mnt /bin/bash -c "systemctl enable reflector.timer"
	# root pw
	arch-chroot /mnt /bin/bash -c "(echo $rootpw ; echo $rootpw) | passwd root"
	# create user
	arch-chroot /mnt /bin/bash -c "useradd -m -G wheel $user"
	arch-chroot /mnt /bin/bash -c "(echo $userpw ; echo $userpw) | passwd $user"
	arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
	arch-chroot /mnt /bin/bash -c "xdg-user-dirs-update"
	# update mirrors
	cp ./simple_reflector.sh /mnt/home/$user/simple_reflector.sh
	arch-chroot /mnt /bin/bash -c "chmod +x /home/$user/simple_reflector.sh"
	clear
	arch-chroot /mnt /bin/bash -c "/home/$user/simple_reflector.sh"
	clear
	# paru
	#	echo ">>> AUR Helper <<<"
	#	echo
	#	echo "Installing the Paru AUR Helper..."
	#	echo "cd && git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si --noconfirm && cd && rm -rf paru-bin" | arch-chroot /mnt /bin/bash -c "su $user"
	#	clear
	_yay_install
	# detect hardware
	[[ -r detect.sh ]] && source detect.sh
	_detect_hardware
	_detect_video
	_detect_touch
	# end
	clear
	# bloat
	chmod +x bloat.sh
	./bloat.sh
	# end
	clear
	echo "SimplyArch Installer"
	echo
	echo ">>> Installation finished sucessfully <<<"
	echo
	read -p "Do you want to reboot? (Y/N): " reboot
	if [[ $reboot == "y" || $reboot == "Y" || $reboot == "yes" || $reboot == "Yes" ]]; then
		echo "System will reboot in a moment..."
		sleep 3
		clear 
		umount -a
		reboot
	fi
fi

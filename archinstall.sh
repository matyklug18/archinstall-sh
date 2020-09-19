#!/bin/bash

set -e

# set this to your root drive. for example, /dev/sda
ROOT_DRIVE=

if [[ -z $ROOT_DRIVE ]]; then
	exit
fi

# change this to your keymap
KEYMAP=cz-qwertz
loadkeys $KEYMAP
timedatectl set-ntp true

# manually partition
# | ROOT |
# | SWAP |
# | EFI  |
cfdisk $ROOT_DRIVE

# edit this if you have a different layout
ROOT_PART="${ROOT_DRIVE}1"
SWAP_PART="${ROOT_DRIVE}2"
 EFI_PART="${ROOT_DRIVE}3"

mkfs.ext4 $ROOT_PART
mkfs.fat -F32 $EFI_PART

mkswap $SWAP_PART
swapon $SWAP_PART

mount $ROOT_PART /mnt

mkdir -p /mnt/boot/efi
mount $EFI_PART /mnt/boot/efi

pacstrap /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/sh -c \
"
set -e

# change this to your timezone
ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
hwclock --systohc

# change this to your language
LANGUAGE=en_US

echo \"\$LANGUAGE.UTF-8 UTF-8\" >> /etc/locale.gen
locale-gen
echo \"LANG=$\LANGUAGE.UTF-8\" >> /etc/locale.conf

echo \"KEYMAP=$KEYMAP\" >> /etc/vconsole.conf

# change this to your hostname
HOSTNAME=matyk

echo \$HOSTNAME >> /etc/hostname

echo \"
127.0.0.1 localhost
::1       localhost
127.0.1.1 \$HOSTNAME.localdomain \$HOSTNAME
\" >> /etc/hosts

echo \"root password\"
until passwd; do :; done

# change this to your username
NAME=matyk

useradd -G wheel -m \$NAME
echo \"\$NAME password\"
until passwd \$NAME; do :; done

# change this to your wm
WINDOW_MANAGER=i3-gaps

# change this to your terminal
TERMINAL=kitty

# change this to your browser
BROWSER=firefox

# add extra packages here
EXTRA_PKGS=git

pacman -Syu --noconfirm \
	xorg sudo base-devel\
	git curl \
	networkmanager \
	lightdm lightdm-gtk-greeter feh\
	\$EXTRA_PKGS \
	\$WINDOW_MANAGER \$TERMINAL \$BROWSER

su \$NAME
cd
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -r ./yay
exit

systemctl enable NetworkManager
systemctl enable lightdm

pacman -Syu --noconfirm grub efibootmgr

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo \"%wheel ALL=(ALL) ALL\" >> /etc/sudoers

# set this to an url of the wallpaper
WALLPAPER=\"\"

curl \$WALLPAPER -o /home/\$NAME/.wallpaper.png

# change this to yours X keymap
X_KEY_MAP=cz
echo \"
setxkbmap \$X_KEY_MAP
feh --bg-fill ~/.wallpaper.png
\" >> /home/\$NAME/.xprofile

printf \"\\033[0;32mSCRIPT FINISHED\\033[0m\\n\"
"

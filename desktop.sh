#!/bin/bash

################################################################
### Introduction
###
### https://github.com/przytular/spaceship_init
###
### This script is made to initialize fresh Debian-based distro.
### Tested on Debian 11
###

#################
### Configuration

SYSTEM_PACKAGES=(
	zsh  			# shell
	wget curl		# data transfer
	terminator		# terminal emulator
	neovim			# text editor
	tree mc	xz		# file manipulation
	git			# dev tools
	gnome-shell-extensions	# gnome apperance
	netstat htop		# sys info
)

# Add intel wifi card drivers (for hyper)
if [[ $(hostname | grep hyper) ]]; then SYSTEM_PACKAGES+=(firmware-iwlwifi); fi

# Nordic (Gnome theme) vars here
VERSION_NORDIC_NUMBER="2.2.0"
NORDIC_STYLE="Nordic-darker-v40"

# VSCodium version here
VERSION_CODIUM="1.73.1.22314"

###############
### Main script

# Preflight checks
if [[ $(id -u) -eq 0 ]]
then
	echo -e "\e[31mYou must run this script as \e[1mnon-root user!\e[0m"
	exit 2
fi

if ! dpkg-query -W sudo &>/dev/null; then
	echo -e "\e[31mNo sudo package detected! Please install it before using this script!\e[0m"
	exit 2
fi

# User input
read -p "Do you wish to install VSCodium? [y/N] " answer_codium
read -p "Do you wish to install Google Chrome? [y/N] " answer_chome

echo "Adding contrib and non-free to Debian repositories list..."

# Add contrib debian repository
if grep -Fxq "contrib" /etc/apt/sources.list; then
	sudo sed -i '/^deb/ s/$/ contrib/' /etc/apt/sources.list
fi

# Add non-free debian repository
if grep -Fxq "non-free" /etc/apt/sources.list; then
        sudo sed -i '/^deb/ s/$/ non-free/' /etc/apt/sources.list
fi

set -e
echo "Installing system packages..."
sudo apt-get update 1> /dev/null && sudo apt-get install -y ${SYSTEM_PACKAGES[@]} 1> /dev/null
set +e

# Gnome settings
echo "Installing Gnome dark mode..."
wget https://github.com/EliverLara/Nordic/releases/download/v${VERSION_NORDIC}/${NORDIC_STYLE}.tar.xz
tar -xf ${VERSION_NORDIC_STYLE}
mv ./${NORDIC_STYLE} ./Nordic
sudo cp -r ./Nordic /usr/share/themes
sudo mkdir -p /usr/share/themes
gsettings set org.gnome.desktop.interface gtk-theme "Nordic"
gsettings set org.gnome.desktop.wm.preferences theme "Nordic"

# TODO: ZSH

# AstroVIM
echo "Installing Astrovim..."
cp -r ~/.config/nvim ~/.config/nvim.bkp 2> /dev/null
git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim 1> /dev/null
nvim +PackerSync

# VSCodium
case ${answer_codium:0:1} in
	y|Y )
		echo "Installing VSCodium..."
		wget https://github.com/VSCodium/vscodium/releases/download/1.73.1.22314/codium_${VERSION_CODIUM}_amd64.deb
		sudo apt install -y codium_${VERSION_CODIUM}_amd64.deb
		rm ./codium_${VERSION_CODIUM}_amd64.deb
	;;
	* ):;;
esac

# Google Chrome
case ${answer_chrome:0:1} in
	y|Y )
		echo "Installing Google Chrome..."
		wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
		sudo apt install -y google-chrome-stable_current_amd64.deb
		rm ./google-chrome-stable_current_amd64.deb
	;;
	* ):;;
esac


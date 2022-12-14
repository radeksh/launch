#!/bin/bash

################################################################
### Introduction
###
### This script is made to initialize fresh Debian-based distro.
### Tested on: Debian 11
################################################################

#################
### Configuration

# VSCodium version here
VERSION_CODIUM="1.73.1.22314"

# Nordic (Gnome theme) vars here
VERSION_NORDIC="2.2.0"
VERSION_NORDIC_STYLE="Nordic-darker-v40"

SYSTEM_PACKAGES=(
    zsh # shell
    wget curl ntp # sys tools
    whois host nmap net-tools nethogs netcat mtr dnsutils # net tools
    mutt thunderbird # e-mail
    wireguard network-manager-openvpn # vpn
    terminator # terminal emulator
    tree mc xz-utils # file manipulation
    python3 python3-dev python3-pip # python
    git jq docker.io docker-compose # dev tools
    gnome-shell-extensions # gnome
    python3-jinja2 python3-psutil python3-setuptools hddtemp lm-sensors # for glances
    gimp # user apps
)

# Add intel wifi card drivers (for hyper)
if [[ $(hostname | grep hyper) ]]; then SYSTEM_PACKAGES+=(firmware-iwlwifi); fi

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
if ! sudo id &>/dev/null; then
    echo -e "\e[31mYou must have posibility to run commands with sudo!\e[0m"
    exit 2
fi

# User input
read -p "Do you wish to install oh-my-zsh and change shell to ZSH? [Y/n] " answer_zsh
read -p "Do you wish to install VSCodium? [y/N] " answer_codium
read -p "Do you wish to install Google Chrome? [y/N] " answer_chrome

# Add contrib debian repository
if ! grep -Fq "contrib" /etc/apt/sources.list; then
    echo "Adding contrib to Debian repositories list..."
    sudo sed -i '/^deb/ s/$/ contrib/' /etc/apt/sources.list
fi

# Add non-free debian repository
if ! grep -Fq "non-free" /etc/apt/sources.list; then
    echo "Adding non-free to Debian repositories list..."
    sudo sed -i '/^deb/ s/$/ non-free/' /etc/apt/sources.list
fi

# Install software
set -e
echo "Installing system packages..."
sudo apt-get update 1>/dev/null && sudo apt-get install -y ${SYSTEM_PACKAGES[@]} 1>/dev/null
pip3 install glances
set +e

# Gnome settings
echo "Setting Gnome..."
set -e
wget -q https://github.com/EliverLara/Nordic/releases/download/v${VERSION_NORDIC}/${VERSION_NORDIC_STYLE}.tar.xz
tar -xf ${VERSION_NORDIC_STYLE}.tar.xz
sudo mkdir -p /usr/share/themes
sudo cp -r ./${VERSION_NORDIC_STYLE} /usr/share/themes/Nordic
rm -rf ./${VERSION_NORDIC_STYLE} ./${VERSION_NORDIC_STYLE}.tar.xz
gsettings set org.gnome.desktop.interface gtk-theme "Nordic"
gsettings set org.gnome.desktop.wm.preferences theme "Nordic"
set +e

# ZSH
echo "Setting ZSH..."
case ${answer_zsh:0:1} in
    n|N ):;;
    * )
        set -e
        rm -rf /home/$USER/.oh-my-zsh
        sh -c "$(curl -A 'Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0' -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 1>/dev/null
        sudo chsh -s $(which zsh) $USER
        cp dotenv/.zshrc ~
        set +e
    ;;
esac

# AstroVIM
if ! dpkg-query -W neovim &>/dev/null; then
    echo "Installing Astrovim..."
    set -e
    wget -q https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb
    sudo apt install -y ./nvim-linux64.deb 1>/dev/null
    rm nvim-linux64.deb
    set +e
    mv ~/.config/nvim ~/.config/nvim.bkp 2>/dev/null
    git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim 1> /dev/null
    # TODO: BUGGED?
    # nvim --headless -c 'autocmd User PackerComplete quitall' \
    #     -c 'PackerSync' \
    #     -c 'TSInstall python'
fi

# VSCodium
if ! dpkg-query -W codium &>/dev/null; then
    case ${answer_codium:0:1} in
        y|Y )
            echo "Installing VSCodium..."
            set -e
            wget -q https://github.com/VSCodium/vscodium/releases/download/${VERSION_CODIUM}/codium_${VERSION_CODIUM}_amd64.deb
            sudo apt install -y ./codium_${VERSION_CODIUM}_amd64.deb &>/dev/null
            rm ./codium_${VERSION_CODIUM}_amd64.deb
            set +e
        ;;
        * )
        :;;
    esac
fi

# Google Chrome
if ! dpkg-query -W google-chrome-stable &>/dev/null; then
    case ${answer_chrome:0:1} in
        y|Y )
            echo "Installing Google Chrome..."
            set -e
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            sudo apt install -y ./google-chrome-stable_current_amd64.deb &>/dev/null
            rm ./google-chrome-stable_current_amd64.deb
            set +e
        ;;
        * )
        :;;
    esac
fi

# TODO: SSH configuration (from mounted pendrive)
# TODO: VPN configuration (from mounted pendrive)
# TODO: Email client configuration [Thunderbird/Mutt] (from mounted pendrive)
# TODO: Remove CTRL+SHIFT+E Gnome/Terminator collision

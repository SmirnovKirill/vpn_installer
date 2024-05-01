#!/bin/sh

set -ex

CURRENT_DIRECTORY="$(dirname "$0")"
source "$CURRENT_DIRECTORY/variables.sh"
source "$CURRENT_DIRECTORY/functions.sh"

sudo apt update
sudo apt install openvpn easy-rsa

mkdir /home/$USER/easy-rsa
cp "$CURRENT_DIRECTORY/configs/easy_rsa_vars" "/home/$USER/easy-rsa/vars"

cd /home/$USER/easy-rsa
/usr/share/easy-rsa/easyrsa init-pki
/usr/share/easy-rsa/easyrsa build-ca nopass
/usr/share/easy-rsa/easyrsa gen-req server nopass
/usr/share/easy-rsa/easyrsa sign-req server server
openvpn --genkey --secret ta.key

cd $CURRENT_DIRECTORY

sudo cp /home/$USER/easy-rsa/pki/private/server.key /etc/openvpn/server
sudo cp /home/$USER/easy-rsa/pki/ca.crt /etc/openvpn/server
sudo cp /home/$USER/easy-rsa/pki/issued/server.crt /etc/openvpn/server
sudo cp /home/$USER/easy-rsa/ta.key /etc/openvpn/server

mkdir -p /home/$USER/client-configs/keys
mkdir -p /home/$USER/client-configs/files
cp "$CURRENT_DIRECTORY/configs/openvpn_client_base.conf" "/home/$USER/client-configs"
substitute_variables "/home/$USER/client-configs/openvpn_client_base.conf"

sudo cp "$CURRENT_DIRECTORY/configs/openvpn_server.con" /etc/openvpn/server/server.conf
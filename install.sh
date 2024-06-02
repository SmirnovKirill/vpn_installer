#!/bin/sh

set -ex

CURRENT_DIRECTORY="$(dirname "$0")"
source "$CURRENT_DIRECTORY/variables.sh"
CK_SERVER_PUBLIC_KEY=""
CK_SERVER_PRIVATE_KEY=""
CK_CLIENT_ADMIN_UID=""
source "$CURRENT_DIRECTORY/functions.sh"
source "$CURRENT_DIRECTORY/constants.sh"

sudo apt update
sudo apt install openvpn easy-rsa squid apache2-utils

cat "Enter password for squid user $SQUID_NAME"
sudo htpasswd -c /etc/squid/passwords $SQUID_NAME

sudo sed -i 's#include /etc/squid/conf.d/\*#include /etc/squid/conf.d/*\nauth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords\nauth_param basic realm proxy\nacl authenticated proxy_auth REQUIRED#g' /etc/squid/squid.conf
sudo sed -i 's#http_access allow localhost$#http_access allow localhost\nhttp_access allow authenticated#g' /etc/squid/squid.conf

mkdir "/home/$USER/easy-rsa"
cp "$CURRENT_DIRECTORY/configs/easy_rsa_vars" "/home/$USER/easy-rsa/vars"

cd "/home/$USER/easy-rsa"
/usr/share/easy-rsa/easyrsa init-pki
/usr/share/easy-rsa/easyrsa build-ca nopass
/usr/share/easy-rsa/easyrsa gen-req server nopass
/usr/share/easy-rsa/easyrsa sign-req server server
openvpn --genkey --secret ta.key

cd "$CURRENT_DIRECTORY"

sudo cp "/home/$USER/easy-rsa/pki/private/server.key" /etc/openvpn/server
sudo cp "/home/$USER/easy-rsa/pki/ca.crt" /etc/openvpn/server
sudo cp "/home/$USER/easy-rsa/pki/issued/server.crt" /etc/openvpn/server
sudo cp "/home/$USER/easy-rsa/ta.key" /etc/openvpn/server

mkdir -p "/home/$USER/client-configs/keys"
mkdir -p "/home/$USER/client-configs/files"
cp -a "$CURRENT_DIRECTORY/configs/client/." "/home/$USER/client-configs"
cp -a "$CURRENT_DIRECTORY/scripts/make_client_config.py" "/home/$USER/client-configs"
sudo cp "/home/$USER/easy-rsa/ta.key" "/home/$USER/client-configs/keys"
sudo cp "/home/$USER/easy-rsa/pki/ca.crt" "/home/$USER/client-configs/keys"
sudo chown $USER "/home/$USER/client-configs/keys/ta.key"
sudo chown $USER "/home/$USER/client-configs/keys/ca.crt"

sudo cp "$CURRENT_DIRECTORY/configs/openvpn_server.conf" /etc/openvpn/server/server.conf

sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

sudo bash -c "cat << EndOfText >> /etc/ufw/before.rules

# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to $NETWORK_INTERFACE
-A POSTROUTING -s 10.8.0.0/8 -o $NETWORK_INTERFACE -j MASQUERADE
COMMIT
# END OPENVPN RULES
EndOfText"

sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

sudo ufw allow OpenSSH
sudo ufw allow 443
sudo ufw allow 3128
sudo ufw enable

sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service


wget "$CK_SERVER_URL" -O "/home/$USER/ck-server"
chmod +x "/home/$USER/ck-server"
sudo mv "/home/$USER/ck-server" /usr/bin/ck-server

read CK_SERVER_PUBLIC_KEY CK_SERVER_PRIVATE_KEY <<< $(/usr/bin/ck-server -key | awk -F ":" '{print $2}' | sed -e $SED_COLOR_CODES_REPLACE | sed 's/ //g' | tr '\n' ' ')
read CK_CLIENT_ADMIN_UID <<< $(/usr/bin/ck-server -uid | awk -F ":" '{print $2}' | sed -e $SED_COLOR_CODES_REPLACE | sed 's/ //g')

substitute_variables "/home/$USER/client-configs/template_amnezia.json"
substitute_variables "/home/$USER/client-configs/template_amnezia_backup.json"
substitute_variables "/home/$USER/client-configs/template_amnezia_openvpn.json"
substitute_variables "/home/$USER/client-configs/template_cloak.json"
substitute_variables "/home/$USER/client-configs/template_openvpn.conf"
substitute_variables "/home/$USER/client-configs/template_shadowsocks.json"

sudo mkdir /etc/cloak
sudo cp "$CURRENT_DIRECTORY/configs/ckserver.json" /etc/cloak/ckserver.json
substitute_variables /etc/cloak/ckserver.json "AS_ROOT"
sudo cp "$CURRENT_DIRECTORY/configs/cloak-server.service" /etc/systemd/system/cloak-server.service
sudo systemctl daemon-reload
sudo systemctl enable cloak-server.service
sudo systemctl start cloak-server.service
sudo systemctl restart openvpn-server@server.service
sudo systemctl restart squid.service

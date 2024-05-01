#!/bin/sh

set -ex

source "$HOME/vpn_installer/variables.sh"
source "$HOME/vpn_installer/functions.sh"
source "$HOME/vpn_installer/constants.sh"

cd "$HOME/easy-rsa"
/usr/share/easy-rsa/easyrsa gen-req ${1} nopass
cp "$HOME/easy-rsa/pki/private/${1}.key" "$HOME/client-configs/keys/"
/usr/share/easy-rsa/easyrsa sign-req client ${1}
cp "$HOME/easy-rsa/pki/issued/${1}.crt" "$HOME/client-configs/keys/"
cd "$HOME"

KEY_DIR="$HOME/client-configs/keys"
OUTPUT_DIR="$HOME/client-configs/files"
BASE_CONFIG="$HOME/client-configs/openvpn_client_base.conf"

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-crypt>') \
    > ${OUTPUT_DIR}/${1}.ovpn

OPENVPN_CLIENT_CONFIG_ESCAPED=$(cat ${OUTPUT_DIR}/${1}.ovpn | sed -z 's/\n/\\n/g')
OPENVPN_CLIENT_CONFIG_ESCAPED_FOR_SED=$(escape_variable_for_sed $OPENVPN_CLIENT_CONFIG_ESCAPED)
echo $OPENVPN_CLIENT_CONFIG_ESCAPED

read CK_CLIENT_USER_UID <<< $(/usr/bin/ck-server -uid | awk -F ":" '{print $2}' | sed -e $SED_COLOR_CODES_REPLACE | sed 's/ //g')
CK_CLIENT_USER_UID=$(escape_variable_for_sed $CK_CLIENT_USER_UID)

AMNEZIA_TEMPLATE=$(cat "$HOME/client-configs/amnezia_template.json" \
  | sed "s/\$CK_CLIENT_USER_UID/$CK_CLIENT_USER_UID/g" \
  | sed "s/\$OPENVPN_CLIENT_CONFIG_ESCAPED/$OPENVPN_CLIENT_CONFIG_ESCAPED_FOR_SED/g" \
  | sed "s/\$AMNEZIA_CONTAINER_NAME/$1/g")
echo $AMNEZIA_TEMPLATE
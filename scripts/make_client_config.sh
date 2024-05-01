#!/bin/bash

cd ~/easy-rsa
/usr/share/easy-rsa/easyrsa gen-req ${1} nopass
cp ~/easy-rsa/pki/private/${1}.key ~/client-configs/keys/
/usr/share/easy-rsa/easyrsa sign-req client ${1}
cp ~/easy-rsa/pki/issued/${1}.crt ~/client-configs/keys/
cd ~

KEY_DIR=~/client-configs/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/openvpn_client_base.conf

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

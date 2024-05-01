import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

OPENVPN_TEMPLATE = '''
{base_config}
<ca>
{ca}</ca>
<cert>
{cert}</cert>
<key>
{key}</key>
<tls-crypt>
{tls_crypt}</tls-crypt>
'''

CLOAK_CONFIG_TEMPLATE = '''
{
    "BrowserSig": "chrome",
    "EncryptionMethod": "aes-gcm",
    "NumConn": 1,
    "ProxyMethod": "openvpn",
    "PublicKey": "{ck_server_public_key}",
    "RemoteHost": "{vps_ip}",
    "RemotePort": "443",
    "ServerName": "{cloak_fake_host}",
    "StreamTimeout": 300,
    "Transport": "direct",
    "UID": "{cloak_uid}"
}
'''


# todo разобраться как получать вывод всегда, даже при интерактивном вводе
def run_command(command, directory=None, capture_output=False):
    process = subprocess.run(shlex.split(command), capture_output=capture_output, cwd=directory, text=True)
    if capture_output:
        return process.stdout
    else:
        return None


def get_validated_pofile_name():
    if len(sys.argv) < 2:
        raise ValueError('Profile name is not set')

    profile_name = sys.argv[1]
    if not profile_name:
        raise ValueError('Profile name is not set')

    if not re.compile("^[-a-z0-9]+$").match(profile_name):
        raise ValueError('Profile name is incorrect')

    return profile_name

profile_name = get_validated_pofile_name()
home_dir = os.environ['HOME']
easy_rsa_dir = f"{home_dir}/easy-rsa/"

run_command(f'/usr/share/easy-rsa/easyrsa gen-req {profile_name} nopass', easy_rsa_dir)
run_command(f'/usr/share/easy-rsa/easyrsa sign-req client ${profile_name}', easy_rsa_dir)
open_vpn_config = Path(f"{home_dir}/client-configs/template_openvpn.conf").read_text()
open_vpn_config = open_vpn_config.replace(
    "$OPENVPN_PROFILE_CERT",
    Path(f"{home_dir}/easy-rsa/pki/issued/{profile_name}.crt").read_text()
)
open_vpn_config = open_vpn_config.replace(
    "$OPENVPN_PROFILE_KEY",
    Path(f"{home_dir}/easy-rsa/pki/private/{profile_name}.key").read_text()
)

cloak_uid = run_command('/usr/bin/ck-server -uid', capture_output=True)
cloak_uid = cloak_uid.split()[-1].replace("\n", "")

cloak_config = Path(f"{home_dir}/client-configs/template_cloak.json").read_text()
cloak_config = cloak_config.replace("$CK_USER_UID", cloak_uid)

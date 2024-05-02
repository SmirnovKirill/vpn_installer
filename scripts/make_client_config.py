import os
import re
import shlex
import subprocess
import sys
from pathlib import Path


def main():
    profile_name = get_validated_pofile_name()
    home_dir = os.environ['HOME']

    openvpn_config = generate_openvpn_config(home_dir, profile_name)
    print("openvpn config:")
    print(openvpn_config)
    print("openvpn config end")

    amnezia_openvpn_config = generate_amnezia_openvpn_config(openvpn_config, home_dir)
    print("amnezia openvpn config:")
    print(amnezia_openvpn_config)
    print("amnezia openvpn config end")

    cloak_config = generate_cloak_config(home_dir)
    print("cloak config:")
    print(cloak_config)
    print("cloak config end")


def get_validated_pofile_name():
    if len(sys.argv) < 2:
        raise ValueError('Profile name is not set')

    profile_name = sys.argv[1]
    if not profile_name:
        raise ValueError('Profile name is not set')

    if not re.compile("^[-a-z0-9]+$").match(profile_name):
        raise ValueError('Profile name is incorrect')

    return profile_name


# todo разобраться как получать вывод всегда, даже при интерактивном вводе
def run_command(command, directory=None, capture_output=False):
    process = subprocess.run(shlex.split(command), capture_output=capture_output, cwd=directory, text=True)
    if capture_output:
        return process.stdout
    else:
        return None


def generate_openvpn_config(home_dir, profile_name):
    easy_rsa_dir = f"{home_dir}/easy-rsa/"
    run_command(f'/usr/share/easy-rsa/easyrsa gen-req {profile_name} nopass', easy_rsa_dir)
    run_command(f'/usr/share/easy-rsa/easyrsa sign-req client {profile_name}', easy_rsa_dir)
    openvpn_config = Path(f"{home_dir}/client-configs/template_openvpn.conf").read_text()
    openvpn_config = openvpn_config.replace(
        "$OPENVPN_CA_CERT",
        Path(f"{home_dir}/client-configs/keys/ca.crt").read_text()
    )
    openvpn_config = openvpn_config.replace(
        "$OPENVPN_TA_KEY",
        Path(f"{home_dir}/client-configs/keys/ta.key").read_text()
    )
    openvpn_config = openvpn_config.replace(
        "$OPENVPN_PROFILE_CERT",
        Path(f"{home_dir}/easy-rsa/pki/issued/{profile_name}.crt").read_text()
    )
    return openvpn_config.replace(
        "$OPENVPN_PROFILE_KEY",
        Path(f"{home_dir}/easy-rsa/pki/private/{profile_name}.key").read_text()
    )


def generate_amnezia_openvpn_config(openvpn_config, home_dir):
    amnezia_openvpn_config = Path(f"{home_dir}/client-configs/template_amnezia_openvpn.json").read_text()
    amnezia_openvpn_config = amnezia_openvpn_config.replace(
        "$OPENVPN_CLIENT_CONFIG_ESCAPED",
        openvpn_config.replace("\n", "\\n").replace("\"", "\\\"")
    )
    return amnezia_openvpn_config


def generate_cloak_config(home_dir):
    cloak_uid = run_command('/usr/bin/ck-server -uid', capture_output=True)
    cloak_uid = cloak_uid.split()[-1].replace("\n", "")
    cloak_config = Path(f"{home_dir}/client-configs/template_cloak.json").read_text()
    return cloak_config.replace("$CK_USER_UID", cloak_uid)


if __name__ == "__main__":
    main()

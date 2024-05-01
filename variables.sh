#!/bin/sh

set -ex

USER=""
VPS_IP=""
NETWORK_INTERFACE="" # ip route list default
CLOAK_FAKE_HOST="ya.ru"
CK_SERVER_URL="https://github.com/cbeuw/Cloak/releases/download/v2.9.0/ck-server-linux-amd64-v2.9.0"
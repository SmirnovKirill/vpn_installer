#!/bin/sh

set -ex

function substitute_variables {
  sudo -u $USER sed -i "s/\$USER/$USER/g" $1
  sudo -u $USER sed -i "s/\$VPS_IP/$VPS_IP/g" $1
  sudo -u $USER sed -i "s/\$CK_SERVER_PUBLIC_KEY/$CK_SERVER_PUBLIC_KEY/g" $1
  sudo -u $USER sed -i "s/\$CK_SERVER_PRIVATE_KEY/$CK_SERVER_PRIVATE_KEY/g" $1
  sudo -u $USER sed -i "s/\$CK_CLIENT_ADMIN_UID/$CK_CLIENT_ADMIN_UID/g" $1
}
#!/bin/sh

set -ex

function substitute_variables {
  sudo -u $USER sed -i "s/\$USER/$USER/g" $1
  sudo -u $USER sed -i "s/\VPS_IP/VPS_IP/g" $1
}
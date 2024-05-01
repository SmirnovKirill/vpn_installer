#!/bin/sh

set -ex

function substitute_variables {
  local USER_TO_PERFORM=$USER
  if [[ $2 == "AS_ROOT" ]];
  then
    USER_TO_PERFORM="root"
  fi

  local CK_SERVER_PUBLIC_KEY_ESCAPED=$(escape_variable_for_sed $CK_SERVER_PUBLIC_KEY)
  local CK_SERVER_PRIVATE_KEY_ESCAPED=$(escape_variable_for_sed $CK_SERVER_PRIVATE_KEY)
  local CK_CLIENT_ADMIN_UID_ESCAPED=$(escape_variable_for_sed $CK_CLIENT_ADMIN_UID)
  sudo -u $USER_TO_PERFORM sed -i "s/\$USER/$USER/g" $1
  sudo -u $USER_TO_PERFORM sed -i "s/\$VPS_IP/$VPS_IP/g" $1
  sudo -u $USER_TO_PERFORM sed -i "s/\$CK_SERVER_PUBLIC_KEY/$CK_SERVER_PUBLIC_KEY_ESCAPED/g" $1
  sudo -u $USER_TO_PERFORM sed -i "s/\$CK_SERVER_PRIVATE_KEY/$CK_SERVER_PRIVATE_KEY_ESCAPED/g" $1
  sudo -u $USER_TO_PERFORM sed -i "s/\$CK_CLIENT_ADMIN_UID/$CK_CLIENT_ADMIN_UID_ESCAPED/g" $1
}

function escape_variable_for_sed {
  echo $1 | sed 's/\//\\\//g'
}
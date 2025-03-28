#!/usr/bin/env sh

set -eu

cd "$(dirname "$(readlink -f "$0")")"

. ./.env

MODS_FOLDER=${MODS_FOLDER:?"Mods folder env var MODS_FOLDER is undefined"}
SERVER_MODS_FOLDER=${SERVER_MODS_FOLDER:?"Server mods folder env var SERVER_MODS_FOLDER is undefined"}

exec ./arma3server_x64 \
  -config=server.cfg \
  -servermod="$(printf "%s;" "$SERVER_MODS_FOLDER"/*)" \
  -mod="$(printf "%s;" "$MODS_FOLDER"/*)"

#!/usr/bin/env sh

set -eu

cd "$(dirname "$(readlink -f "$0")")"

. ./.env

INSTALL_FOLDER="/opt/games/arma3"
ARMA3_ID=107410
MODS_FOLDER=${MODS_FOLDER:?"Mods folder env var MODS_FOLDER is undefined"}
SERVER_MODS_FOLDER=${SERVER_MODS_FOLDER:?"Server mods folder env var SERVER_MODS_FOLDER is undefined"}
MOD_IDS=${MOD_IDS:?"Mod IDs env var MOD_IDS is undefined"}
SERVER_MOD_IDS=${SERVER_MOD_IDS:?"Server mod IDs env var SERVER_MOD_IDS is undefined"}

steamcmd_params="+force_install_dir $INSTALL_FOLDER +login angelin01"

for mod_id in $MOD_IDS $SERVER_MOD_IDS; do
  steamcmd_params="$steamcmd_params +workshop_download_item $ARMA3_ID $mod_id validate"
done

steamcmd_params="$steamcmd_params +quit"

echo "Downloading/updating all mods"
steamcmd $steamcmd_params
echo

mkdir -p "$MODS_FOLDER" "$SERVER_MODS_FOLDER"

echo "Deleting old symlinks"
find "$MODS_FOLDER" "$SERVER_MODS_FOLDER" -type l -delete

lowercase_mod_name() {
    for file in "$1/meta.cpp" "$1/mod.cpp"; do
        if [ -f "$file" ]; then
            name=$(awk -F' = ' '/^name / {gsub(/[";\r]/, "", $2); print tolower($2)}' "$file" 2>/dev/null)
            [ -n "$name" ] && echo "$name" && return
        fi
    done
    basename "$1"
}

echo "Creating symlinks for standard mods..."
for mod_id in $MOD_IDS; do
  mod_path="$INSTALL_FOLDER/steamapps/workshop/content/$ARMA3_ID/$mod_id"
  mod_name=$(lowercase_mod_name "$mod_path")
  ln -vsfn "$INSTALL_FOLDER/steamapps/workshop/content/$ARMA3_ID/$mod_id" "$MODS_FOLDER/$mod_name"
done

echo "Creating symlinks for server mods..."
for mod_id in $SERVER_MOD_IDS; do
  mod_path="$INSTALL_FOLDER/steamapps/workshop/content/$ARMA3_ID/$mod_id"
  mod_name=$(lowercase_mod_name "$mod_path")
  ln -vsfn "$INSTALL_FOLDER/steamapps/workshop/content/$ARMA3_ID/$mod_id" "$SERVER_MODS_FOLDER/$mod_name"
done

echo "Transforming all mods to lowercase"
find "$INSTALL_FOLDER/steamapps/workshop/content/$ARMA3_ID/" -depth -exec rename -v 's|(.*)/(.*)|$1/\L$2|' {} +

echo "All mods updated and symlinked"

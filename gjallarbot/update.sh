#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

REPO=Angelin01/gjallarbot
REPO_URL="https://api.github.com/repos/$REPO/releases/latest"
DOWNLOAD_DIR="./bin"
SYMLINK="./$DOWNLOAD_DIR/gjallarbot"
SERVICE_NAME="gjallarbot"

latestVersion=$(curl -m1 -LsSf "$REPO_URL" | jq -r .tag_name)

if [ -L "$SYMLINK" ]; then
  currentVersion=$(readlink "$SYMLINK" | grep -oP '(?<=gjallarbot-).*(?=-armv7)')
else
  currentVersion=""
fi

if [ "$latestVersion" != "$currentVersion" ]; then
  downloadFile="gjallarbot-${latestVersion}-armv7-unknown-linux-gnueabihf"

  echo "New release found: $latestVersion. Downloading..."

  curl -LsSf -m5 -o "$DOWNLOAD_DIR/$downloadFile" "https://github.com/$REPO/releases/download/$latestVersion/$downloadFile"
  chmod +x "$DOWNLOAD_DIR/$downloadFile"

  previousRelease=$(ls -1t "$DOWNLOAD_DIR/gjallarbot-"* | tail -n +3)
  if [ -n "$previousRelease" ]; then
      echo "Deleting previous releases: $previousRelease"
      rm "$previousRelease"
  fi

  ln -sf "$downloadFile" "$SYMLINK"

  echo "Restarting service: $SERVICE_NAME"
  systemctl restart "$SERVICE_NAME"

  echo "Update complete. Current version is now $latestVersion."
fi

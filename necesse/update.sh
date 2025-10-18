#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

BASE_URL=https://necessegame.com
SERVER_URL_CACHE_FILE=./.server-url.txt
SERVER_BASE_DIR="."
SERVER_SERVICE=necesse.service

get_download_url() {
  curl -m5 -LsSf "$BASE_URL/server/" |
    grep -Eo '<a[^>]*>.*Linux.*</a>' |
    head -n 1 |
    sed -n 's/.*href="\([^"]*\)".*/\1/p'
}

get_previous_download_url() {
  if [ -f "$SERVER_URL_CACHE_FILE" ]; then
    cat "$SERVER_URL_CACHE_FILE"
  else
    printf ""
  fi
}

save_download_url() {
  local downloadUrl=$1
  printf "%s" "$downloadUrl" > "$SERVER_URL_CACHE_FILE"
}

update_server() {
  local downloadUrl=$1

  echo "Downloading server from ${BASE_URL}${downloadUrl}..."
  local tmpFolder
  tmpFolder=$(mktemp -d)

  local downloadZip="$tmpFolder/necesse.zip"
  curl -m300 -LsSf -o "$downloadZip" "${BASE_URL}${downloadUrl}"

  echo "Extracting update..."
  unzip -q "$downloadZip" -d "$tmpFolder"

  echo "Deleting old files..."
  rm -rf "${SERVER_BASE_DIR:?}/locale" "${SERVER_BASE_DIR:?}/lib"

  echo "Replacing new files"
  mv -f "$tmpFolder"/necesse-server-*/Server.jar "$tmpFolder"/necesse-server-*/lib "$tmpFolder"/necesse-server-*/locale "$SERVER_BASE_DIR"

  rm -rf "$tmpFolder"
  echo "Update completed"
}

is_server_running() {
  systemctl is-active --quiet "$SERVER_SERVICE"
}

stop_server() {
  echo "Stopping server service..."
  systemctl stop "$SERVER_SERVICE"
  echo "Server stopped"
}

restart_server() {
  echo "Restarting server service..."
  systemctl restart "$SERVER_SERVICE"
  echo "Server restarted"
}

main() {
  echo "Fetching latest download URL..."
  local currentDownloadUrl
  local previousDownloadUrl
  currentDownloadUrl=$(get_download_url)
  previousDownloadUrl=$(get_previous_download_url)

  if [ "$currentDownloadUrl" = "$previousDownloadUrl" ]; then
    echo "Server is already up to date"
    exit 0
  fi

  echo "New update detected"

  local wasRunning=false
  if is_server_running; then
    echo "Server is currently running"
    wasRunning=True
    stop_server
  fi

  save_download_url "$currentDownloadUrl"
  update_server "$currentDownloadUrl"

  if [ "$wasRunning" = "true" ]; then
    restart_server
  fi
}

main

#!/usr/bin/env bash

set -euo pipefail

# === Configuration ===
INTERVAL=60
IDLE_LIMIT=5
SHUTDOWN_DELAY_MIN=1

# Network
NETWORK_THRESHOLD_BYTES=$(( 512 * 1024 ))
NETWORK_INTERFACES=("enp12s0")

# Systemd Services
SYSTEM_SERVICES=("docker.service")
declare -A USER_SERVICES=(
  ["angelo"]="docker.service ssh-agent.service"
)

idleCount=0


log() { echo "$(date --iso-8601=seconds): $*"; }


declare -A RX_PREV TX_PREV
network_idle() {
  local totalBytesThisCheck=0
  for iface in "${NETWORK_INTERFACES[@]}"; do
    local rxNow rxDiff txNow txDiff

    if [[ ! -v RX_PREV["$iface"] || ! -v TX_PREV["$iface"] ]]; then
      RX_PREV[$iface]="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
      TX_PREV[$iface]="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"
      continue
    fi

    rxNow="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
    txNow="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"

    rxDiff=$((rxNow - RX_PREV["$iface"]))
    txDiff=$((txNow - TX_PREV["$iface"]))

    RX_PREV[$iface]=$rxNow
    TX_PREV[$iface]=$txNow
    totalBytesThisCheck=$(( rxDiff + txDiff + totalBytesThisCheck ))
  done

  [ "$totalBytesThisCheck" -lt "$NETWORK_THRESHOLD_BYTES" ]
}

no_users_logged_in() {
  [ "$(who | wc -l)" = "0" ]
}

system_services_idle() {
  for svc in "${SYSTEM_SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
      return 1
    fi
  done
  return 0
}

user_services_idle() {
  for user in "${!USER_SERVICES[@]}"; do
    for svc in ${USER_SERVICES[$user]}; do
      if systemctl --user --quiet --machine="$(id -u "$user")@.host" is-active "$svc"; then
        return 1
      fi
    done
  done
  return 0
}

while true; do
  # Check network first to ensure that the diff gets calculated properly
  if network_idle && system_services_idle && user_services_idle && no_users_logged_in; then
    idleCount=$(( idleCount + 1 ))
    log "System marked as idle ($idleCount/$IDLE_LIMIT)"
  else
    if [ "$idleCount" != 0 ]; then
      log "System no longer idle, resetting count"
    fi
    idleCount=0
  fi

  if [ "$idleCount" -ge "$IDLE_LIMIT" ]; then
    log "System idle for $IDLE_LIMIT intervals. Shutting down!"
    shutdown "$SHUTDOWN_DELAY_MIN"
    exit 0
  fi

  sleep "$INTERVAL"
done

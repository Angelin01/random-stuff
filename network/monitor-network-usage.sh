#!/usr/bin/env bash

set -euo pipefail

LOGFILE="network_usage.log"
INTERVAL=5

echo "Logging network traffic to $LOGFILE..."
echo "Timestamp: Interface=TX/RX (bytes per $INTERVAL sec)"

declare -A RX_PREV TX_PREV

while true; do
    timestamp=$(date --iso-8601=seconds)
    logEntry="$timestamp:"

    for ifacePath in /sys/class/net/*; do
        iface=$(basename "$ifacePath")
        if [ "$iface" = "lo" ]; then
          continue;
        fi

        if [[ ! -v RX_PREV["$iface"] || ! -v TX_PREV["$iface"] ]]; then
          RX_PREV[$iface]="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
          TX_PREV[$iface]="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"
          continue
        fi

        rxNow="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
        txNow="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"

        rxDiff=$((rxNow - RX_PREV["$iface"]))
        txDiff=$((txNow - TX_PREV["$iface"]))

        logEntry+=" $iface=${txDiff}/${rxDiff};"

        RX_PREV[$iface]=$rxNow
        TX_PREV[$iface]=$txNow
    done

    echo "$logEntry" | tee -a "$LOGFILE"
    sleep "$INTERVAL"
done

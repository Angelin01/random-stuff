#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

FIFO=in
if [ ! -p "$FIFO" ]; then
    mkfifo "$FIFO"
fi

echo "Starting Necesse server..."
tail -f "$FIFO" | java \
  -XX:+UseZGC \
  -Xms2G -Xmx4G \
  -XX:+AlwaysPreTouch \
  -XX:+UseStringDeduplication \
  -jar Server.jar \
    -nogui \
    -localdir \
    -ip 0.0.0.0 \
    -world default

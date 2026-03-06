#!/bin/bash

cd "$(dirname "$0")/.." || exit 1

echo
echo "running ensure_qbt_port at $(date)"

function get_listen_port {
  docker compose exec qbittorrent curl -s http://127.0.0.1:8080/api/v2/app/preferences | jq '.listen_port'
}

function is_healthy {
  docker compose ps "$1" | grep -q '(healthy)'
}

if ! is_healthy gluetun; then
  echo "gluetun is not healthy, exiting..."
  exit 1
fi

if ! is_healthy qbittorrent; then
  echo "qbittorrent is not healthy, exiting..."
  exit 1
fi

CURRENT_LISTEN_PORT="$(get_listen_port)"

echo "current listen port: $CURRENT_LISTEN_PORT"

if [ "$CURRENT_LISTEN_PORT" = 0 ]; then
  echo "current listen port is set to 0, attempting to set from gluetun"
  GLUETUN_FORWARDED_PORT="$(docker compose exec gluetun cat /tmp/gluetun/forwarded_port 2>/dev/null)"
  if [ -z "$GLUETUN_FORWARDED_PORT" ]; then
    echo "gluetun has no forwarded port, exiting"
    exit 1
  fi
  echo "gluetun forwarded port: $GLUETUN_FORWARDED_PORT"
  echo "attempting to set port to $GLUETUN_FORWARDED_PORT and interface to tun0"
  docker compose exec qbittorrent curl -s http://127.00.0.1:8080/api/v2/app/setPreferences --data "json={\"listen_port\":$GLUETUN_FORWARDED_PORT,\"current_network_interface\":\"tun0\",\"random_port\":false,\"upnp\":false}"
  echo "confirming port in preferences..."
  NEW_PORT="$(get_listen_port)"
  if [ "$NEW_PORT" = "$GLUETUN_FORWARDED_PORT" ]; then
    echo "successfully updated port"
  else
    echo "new port is $NEW_PORT instead of $GLUETUN_FORWARDED_PORT, something went wrong"
    exit 1
  fi
fi


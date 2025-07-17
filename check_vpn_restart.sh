#!/bin/bash

cd "$(dirname "$0")" || exit 1

# Check for Gluetun VPN restarts in the last 5 minutes
if docker compose logs gluetun --since 5m | grep -q "\[vpn\] starting"; then
    echo "restarting qBittorrent"
    docker compose restart qbittorrent

    # Prepare and send email to user 'foxfire'
    echo "qBittorrent was restarted at $(date)" | mail -s "qBittorrent Restarted" "$USER"
fi

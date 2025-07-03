#!/bin/bash

HOSTNAME=$(hostname)
SCRIPT_PATH="/usr/local/bin/update_node.sh"
ENV_PATH="$(dirname "$0")/.watcher.env"

VERSION=$(grep SCRIPT_VERSION "$SCRIPT_PATH" | cut -d'"' -f2)
SCHEDULE=$(cat /usr/local/share/minipool-watcher.schedule 2>/dev/null || echo "N/A")
VERSION_FILE="/usr/local/share/minipool-watcher.version"
LAST_LOG=$(ls -1t /var/log/${HOSTNAME}-watcher/update_report-*.txt 2>/dev/null | head -n 1)
EMAIL=$(grep EMAIL_TO "$ENV_PATH" | cut -d'"' -f2)
GRAFFITI=$(grep -m1 '^GRAFFITI=' "$HOME/eth-docker/.env" 2>/dev/null | cut -d'=' -f2)
if [[ -z "$GRAFFITI" ]]; then
  GRAFFITI=$(grep -m1 '^GRAFFITI=' "$(dirname "$0")/.watcher.env" | cut -d'"' -f2)
fi

echo "🛰️  watcher status · node: $HOSTNAME"
echo "--------------------------------------------"
echo "🔧 Installed Version    : v$VERSION"
echo "🪪 Graffiti Tag         : $GRAFFITI"
echo "📬 Email Recipient      : $EMAIL"
echo "📅 Scheduled Time       : $SCHEDULE"

echo -n "🕒 Next Run (from timer): "
systemctl list-timers --all update-node.timer | awk 'NR==2 {print $1, $2, $3}'

if [[ -f "$LAST_LOG" ]]; then
  LOG_DATE=$(basename "$LAST_LOG" | cut -d'-' -f3)
  echo "📓 Last Update Log      : $LOG_DATE → $LAST_LOG"
else
  echo "📓 Last Update Log      : (none found)"
fi

echo -n "🟢 Service Status        : "
systemctl is-active update-node.service

echo -n "⏱️  Timer Status          : "
systemctl is-active update-node.timer

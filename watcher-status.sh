#!/bin/bash

# --- Config & Paths ---
HOSTNAME=$(hostname)
SCRIPT_PATH="/usr/local/bin/update_node.sh"
ENV_PATH="$(dirname "$0")/.watcher.env"
VERSION_FILE="/usr/local/share/minipool-watcher.version"
SCHEDULE_FILE="/usr/local/share/minipool-watcher.schedule"
LOG_DIR="/var/log/${HOSTNAME}-watcher"
if [[ ! -d "$LOG_DIR" ]]; then
  mkdir -p "$LOG_DIR"
fi
if [[ ! -w "$LOG_DIR" ]]; then
  echo "⚠️  Log directory $LOG_DIR not writable by $(whoami). Attempting to fix..."
  sudo chown $(whoami):$(whoami) "$LOG_DIR"
  if [[ ! -w "$LOG_DIR" ]]; then
    echo "❌ Still cannot write to log directory. Exiting."
    exit 1
  fi
fi

# --- Data Extraction ---
VERSION=$(grep SCRIPT_VERSION "$SCRIPT_PATH" | cut -d'"' -f2 2>/dev/null || echo "N/A")
SCHEDULE=$(cat "$SCHEDULE_FILE" 2>/dev/null || echo "N/A")
LAST_LOG=$(ls -1t "$LOG_DIR"/update_report-*.txt 2>/dev/null | head -n 1)
EMAIL=$(grep EMAIL_TO "$ENV_PATH" | cut -d'"' -f2 2>/dev/null || echo "N/A")
GRAFFITI=$(grep -m1 '^GRAFFITI=' "$HOME/eth-docker/.env" 2>/dev/null | cut -d'=' -f2)
if [[ -z "$GRAFFITI" ]]; then
  GRAFFITI=$(grep -m1 '^GRAFFITI=' "$ENV_PATH" | cut -d'"' -f2)
fi
GRAFFITI=${GRAFFITI:-N/A}

# --- Output ---
echo "🛰️  watcher status · node: $HOSTNAME"
echo "--------------------------------------------"
echo "🔧 Installed Version    : v$VERSION"
echo "🪪 Graffiti Tag         : $GRAFFITI"
echo "📬 Email Recipient      : $EMAIL"
echo "📅 Scheduled Time       : $SCHEDULE"

# Next run (from timer)
NEXT_RUN=$(systemctl list-timers --all update-node.timer | awk 'NR==2 {print $1, $2, $3}')
echo "🕒 Next Run (from timer): ${NEXT_RUN:-N/A}"

# Last update log
if [[ -f "$LAST_LOG" ]]; then
  LOG_DATE=$(basename "$LAST_LOG" | cut -d'-' -f3)
  echo "📓 Last Update Log      : $LOG_DATE → $LAST_LOG"
else
  echo "📓 Last Update Log      : (none found)"
fi

# Service status
SERVICE_STATUS=$(systemctl is-active update-node.service 2>/dev/null)
case "$SERVICE_STATUS" in
  active)
    echo "🟢 Service Status        : active"
    ;;
  inactive)
    echo "🔴 Service Status        : inactive"
    ;;
  *)
    echo "⚪ Service Status        : $SERVICE_STATUS"
    ;;
esac

# Timer status
TIMER_STATUS=$(systemctl is-active update-node.timer 2>/dev/null)
case "$TIMER_STATUS" in
  active)
    echo "⏱️  Timer Status          : active"
    ;;
  inactive)
    echo "⏱️  Timer Status          : inactive"
    ;;
  *)
    echo "⏱️  Timer Status          : $TIMER_STATUS"
    ;;
esac

# Show last 3 log summaries if available
echo ""
echo "📝 Recent Update Logs:"
LOGS=($(ls -1t "$LOG_DIR"/update_report-*.txt 2>/dev/null | head -n 3))
if [[ ${#LOGS[@]} -eq 0 ]]; then
  echo "  (none found)"
else
  for log in "${LOGS[@]}"; do
    log_date=$(basename "$log" | cut -d'-' -f3)
    # Clean summary: remove HTML, variable expansions, color codes, and empty lines
    summary=$(grep -m1 -E '^(SUCCESS|FAIL|ERROR|WARN)' "$log" 2>/dev/null | \
      sed -E 's/<[^>]+>//g' | \
      sed -E 's/\\$\{?[A-Z0-9_]+\}?//g' | \
      sed -E 's/\\x1B\[[0-9;]*[mK]//g' | \
      sed 's/^ *//;s/ *$//' | \
      grep -vE '^$')
    if [[ -z "$summary" ]]; then
      summary="(no summary)"
    fi
    echo "  $log_date: $summary"
  done
fi

#!/bin/bash
# watcher-health.sh — Validator Health Monitor v2.3
# 🧠 Reads /etc/watcher/.watcher.env
# 📬 Sends Gmail + Telegram alerts
# 🔔 Supports --debug and --force
# 🚦 Emoji severity, custom subject, rich logs

# --- Config ---
ENV_FILE="/etc/watcher/.watcher.env"
BEACON_CONTAINER="eth-docker-consensus-1"
LOG_WINDOW_MINUTES="${LOG_WINDOW_MINUTES:-10}"
EMAIL_SUBJECT_PREFIX="${EMAIL_SUBJECT_PREFIX:-Watcher Alert}"

# --- Globals ---
DEBUG=false
FORCE=false
NOW_TS=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
HOSTNAME=$(hostname)
SINCE_TS=$(date -u -d "$LOG_WINDOW_MINUTES minutes ago" +%Y-%m-%dT%H:%M:%SZ)
ALERT_LOG="/var/log/${HOSTNAME}-watcher/health-alerts.log"

# --- Flags ---
[[ "$1" == "--debug" ]] && DEBUG=true
[[ "$1" == "--force" ]] && FORCE=true
[[ "$DEBUG_MODE" == "true" ]] && DEBUG=true

# --- Init ---
init() {
  mkdir -p "$(dirname "$ALERT_LOG")"

  if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Missing env file: $ENV_FILE"
    exit 1
  fi
  source "$ENV_FILE"
  : "${TELEGRAM_BOT_TOKEN:?❌ TELEGRAM_BOT_TOKEN not set}"
  : "${TELEGRAM_CHAT_ID:?❌ TELEGRAM_CHAT_ID not set}"

  for bin in docker curl mail; do
    command -v $bin &>/dev/null || {
      echo "❌ Missing tool: $bin"
      exit 1
    }
  done

  if ! docker ps --format '{{.Names}}' | grep -qx "$BEACON_CONTAINER"; then
    $DEBUG && echo "⚠️ Container $BEACON_CONTAINER not running."
    exit 0
  fi
}

# --- Telegram ---
send_telegram() {
  local msg="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    --data-urlencode text="$msg" >/dev/null
}

# --- Email ---
send_email() {
  local emoji="$1"
  local subject="$2"
  local body="$3"
  if [[ -n "$EMAIL_TO" ]]; then
    local full_subject="${EMAIL_SUBJECT_PREFIX} ${emoji} · ${HOSTNAME}"
    echo -e "$body" | mail -s "$full_subject" "$EMAIL_TO"
    $DEBUG && echo "📬 Email sent to $EMAIL_TO with subject '$full_subject'"
  fi
}

# --- Status ---
report_status() {
  $DEBUG && echo "$1"
}

# --- Alert Wrapper ---
send_alert() {
  local severity="$1"
  local header="$2"
  local body="$3"

  local emoji=""
  case "$severity" in
    OK)      emoji="✅";;
    WARN)    emoji="⚠️";;
    CRIT)    emoji="🚨";;
    *)       emoji="🔔";;
  esac

  local telegram_msg="${emoji} <b>${header}</b>\n<b>Time:</b> ${NOW_TS}\n${body}"
  local email_body="${emoji} ${header}\nTime: ${NOW_TS}\n\n${body}"

  send_telegram "$telegram_msg"
  send_email "$emoji" "$header" "$email_body"
  echo -e "${NOW_TS} ${emoji} ${header}\n${body}" >> "$ALERT_LOG"
  report_status "📣 Sent alert — Telegram + Email + log"
}

# --- Manual Trigger ---
run_forced_alert() {
  send_alert "CRIT" "Manual Test · $HOSTNAME" \
             "• This is a forced validator alert via --force flag."
  report_status "🧪 Manual alert triggered"
  exit 0
}

# --- Log Scanner ---
scan_logs() {
  # Use Consensus API to check for missed attestations/blocks
  API_URL="http://localhost:5052"
  # Get current epoch
  CURRENT_EPOCH=$(curl -s "$API_URL/eth/v1/beacon/headers" | jq -r '.data[0].header.message.slot' | awk '{print int($1/32)}')
  # Get validator performance for last epoch
  PERFORMANCE=$(curl -s "$API_URL/eth/v1/validator/performance?epoch=$((CURRENT_EPOCH-1))")
  MISSED_ATTESTATIONS=$(echo "$PERFORMANCE" | jq '.data.missed_attestations // 0')
  MISSED_BLOCKS=$(echo "$PERFORMANCE" | jq '.data.missed_blocks // 0')

  report_status "🔍 Consensus API: Missed attestations: $MISSED_ATTESTATIONS, missed blocks: $MISSED_BLOCKS (epoch $((CURRENT_EPOCH-1)))"

  if (( MISSED_ATTESTATIONS > 0 || MISSED_BLOCKS > 0 )); then
    local body=""
    (( MISSED_ATTESTATIONS > 0 )) && body+="• Missed attestations: $MISSED_ATTESTATIONS\n"
    (( MISSED_BLOCKS > 0 )) && body+="• Missed blocks: $MISSED_BLOCKS\n"
    send_alert "CRIT" "Consensus Duties Missed · $HOSTNAME" "$body"
  fi
}

# --- Main ---
init
$FORCE && run_forced_alert
scan_logs
exit 0


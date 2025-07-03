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
  LOGS=$(docker logs --since "$SINCE_TS" "$BEACON_CONTAINER" 2>&1)
  LOG_LINES=$(echo "$LOGS" | wc -l)
  missed_att=$(echo "$LOGS" | grep -cE \
  "Timed out waiting for attestation|Failed to publish attestation|Previous epoch attestation\(s\) missing|Previous epoch attestation\(s\) failed to match head|Previous epoch attestation\(s\) failed to match target")
  missed_blk=$(echo "$LOGS" | grep -cE "Failed to propose block|No block to propose")

  report_status "📦 Scanned $LOG_LINES lines since $SINCE_TS"
  report_status "🔍 Attestation errors: $missed_att"
  report_status "🔍 Proposal errors:    $missed_blk"

  if (( missed_att + missed_blk > 0 )); then
    local body=""
    (( missed_att > 0 )) && body+="• Missed attestations: $missed_att\n"
    (( missed_blk > 0 )) && body+="• Missed proposals: $missed_blk\n"
    send_alert "CRIT" "Validator Duties Failed · $HOSTNAME" "$body"
  else
    send_alert "OK" "Validator Health Check · $HOSTNAME" \
               "• No missed duties in last $LOG_WINDOW_MINUTES minutes."
  fi
}

# --- Main ---
init
$FORCE && run_forced_alert
scan_logs
exit 0


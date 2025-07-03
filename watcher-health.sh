#!/bin/bash
# watcher-health.sh — Modular Docker validator monitor v2.2
# 🧠 Reads .watcher.env from /etc/watcher/
# 💬 Supports --debug and --force flags

# --- Config ---
ENV_FILE="/etc/watcher/.watcher.env"
BEACON_CONTAINER="eth-docker-consensus-1"
LOG_WINDOW_MINUTES="${LOG_WINDOW_MINUTES:-10}"

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

# --- Functions ---

init() {
  mkdir -p "$(dirname "$ALERT_LOG")"

  if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Missing env file: $ENV_FILE"
    exit 1
  fi
  source "$ENV_FILE"
  : "${TELEGRAM_BOT_TOKEN:?❌ TELEGRAM_BOT_TOKEN not set}"
  : "${TELEGRAM_CHAT_ID:?❌ TELEGRAM_CHAT_ID not set}"

  for bin in docker curl; do
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

send_telegram() {
  local msg="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    --data-urlencode text="$msg" >/dev/null
}

report_status() {
  $DEBUG && echo "$1"
}

send_alert() {
  local header="$1"
  local body="$2"
  local full_report="🚨 <b>${header}</b>\n<b>Time:</b> $NOW_TS\n$body"
  send_telegram "$full_report"
  echo -e "$NOW_TS $full_report" >> "$ALERT_LOG"
  report_status "📣 Alert sent to Telegram + logged locally"
}

run_forced_alert() {
  send_alert "Forced Validator Alert · $HOSTNAME" \
             "• Manual test alert via <code>--force</code> triggered."
  report_status "🧪 Forced alert triggered — no logs scanned."
  exit 0
}

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
    send_alert "Validator Duty Alert · $HOSTNAME" "$body"
  else
    report_status "✅ All clear: no missed duties in last $LOG_WINDOW_MINUTES minutes."
  fi
}

# --- Main ---
init
$FORCE && run_forced_alert
scan_logs
exit 0

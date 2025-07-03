#!/bin/bash
# update_node.sh

SCRIPT_VERSION="1.9"
source /etc/watcher/.watcher.env
GRAFFITI="brazilpracima"
HOSTNAME=$(hostname)

# Explicit eth-docker path for root/systemd
ETH_DOCKER_PATH="/home/egk/eth-docker"

# 🔐 Smart log directory fallback if /var/log is unwritable

# Log directory logic with auto-fix for permissions
if [ -w "/var/log" ]; then
  LOG_DIR="/var/log/${HOSTNAME}-watcher"
else
  LOG_DIR="$HOME/logs/${HOSTNAME}-watcher"
fi

DATE=$(date -u +%F)
mkdir -p "$LOG_DIR"
if [[ ! -w "$LOG_DIR" ]]; then
  echo "⚠️  Log directory $LOG_DIR not writable by $(whoami). Attempting to fix..."
  sudo chown $(whoami):$(whoami) "$LOG_DIR"
  if [[ ! -w "$LOG_DIR" ]]; then
    echo "❌ Still cannot write to log directory. Exiting."
    exit 1
  fi
fi

LOG_FILE="$LOG_DIR/update_report-$DATE.txt"
CHANGELOG_FILE="$LOG_DIR/watcher-changelog.log"
DRYRUN=false
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# 🔍 Smart detection of ethd binary location
detect_ethd_binary() {
  if [[ -x "$ETH_DOCKER_PATH/ethd" ]]; then
    echo "$ETH_DOCKER_PATH/ethd"
  elif [[ -x "$HOME/eth2-docker/ethd" ]]; then
    echo "$HOME/eth2-docker/ethd"
  elif command -v ethd &> /dev/null; then
    echo "$(command -v ethd)"
  else
    echo ""
  fi
}


log_message() {
  echo -e "$1" | tee -a "$LOG_FILE"
}

send_notifications() {
  # ========== 1. Extract client versions from log ==========
  CLIENT_PATTERNS=("Lighthouse" "Prysm" "Teku" "Nimbus" "Nethermind" "Geth" "Besu" "Erigon" "mev-boost" "prometheus" "Grafana" "Contributoor")
  CLIENT_SUMMARY=""
  CLIENT_SUMMARY_HTML=""
  for pattern in "${CLIENT_PATTERNS[@]}"; do
    match=$(grep -i "$pattern" "$LOG_FILE" 2>/dev/null | head -n 3)
    if [[ -n "$match" ]]; then
      CLIENT_SUMMARY+="$match"$'\n'
      CLIENT_SUMMARY_HTML+="$match<br>"
    fi
  done

  # ========== 2. Extract log snippet for Telegram ==========
  TAIL_LOG=$(tail -n 40 "$LOG_FILE" 2>/dev/null | head -c 3500 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

  # ========== 3. Build Telegram summary ==========

read -r -d '' TELEGRAM_MSG <<'EOF'
✅ <b>Watcher Complete: $HOSTNAME</b>
🪪 <b>Graffiti:</b> $GRAFFITI
🛠 <b>Version:</b> v$SCRIPT_VERSION
🕒 <b>UTC:</b> $(date -u '+%Y-%m-%d %H:%M')

📦 <b>Clients:</b>
<pre>$CLIENT_SUMMARY</pre>

📓 <b>Log Tail:</b>
<pre>$TAIL_LOG</pre>
EOF



  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    --data-urlencode text="$TELEGRAM_MSG"
  # ========== 4. Extract update block for email ==========
  # ========== 4. Extract update block for email ==========
  UPDATE_BLOCK=$(awk '/Running: ethd update/,/Post-Update Component Versions/' "$LOG_FILE" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
  UPDATE_BLOCK_HTML=$(echo "$UPDATE_BLOCK" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | awk '{print "<div style=\"font-family:monospace; white-space:pre; font-size:13px;\">" $0 "</div>"}')

  # ========== 5. HTML Email summary ==========
  EXEC_MODE=$( [[ "$DRYRUN" == true ]] && echo "DRY RUN (simulated)" || echo "LIVE")

  EMAIL_HTML=$(cat <<EOF
<html>
<body style="font-family:sans-serif; color:#222; background:#fff; padding:20px; max-width:700px;">
  <h2>🛰️ minipool-watcher summary · <code>$HOSTNAME</code></h2>
  <p>
    <b>🛠 Script Version:</b> v$SCRIPT_VERSION<br>
    <b>🪪 Graffiti:</b> $GRAFFITI<br>
    <b>📆 Time (UTC):</b> $(date -u '+%Y-%m-%d %H:%M')<br>
    <b>🧪 Mode:</b> $EXEC_MODE
  </p>

  <h3>📦 Client Versions</h3>
  <p style="font-family:monospace; background:#f9f9f9; padding:10px 12px; border-left:4px solid #ccc;">
    $CLIENT_SUMMARY_HTML
  </p>

  <h3>🔁 Update Activity</h3>
  $UPDATE_BLOCK_HTML

  <h3>⛓️ Validator Health</h3>
  <p style="font-style:italic;">(placeholder for beaconcha.in stats)</p>

  <hr>
  <p style="font-size:0.9em; color:#999;">
    📓 Log file saved to: <code>$LOG_FILE</code>
  </p>
</body>
</html>
EOF
)

  # ========== 6. Send HTML Email ==========
  echo "$EMAIL_HTML" | mail -a "Content-Type: text/html" -s "🛰️ $HOSTNAME watcher v$SCRIPT_VERSION summary" "$EMAIL_TO"
}


get_component_versions_from_ethd() {
  local ethd_path
  ethd_path="$(detect_ethd_binary)"

  if [[ -z "$ethd_path" ]]; then
    echo "❌ Could not locate ethd binary."
    return
  fi

  echo "🧠 eth-docker version report:"
  "$ethd_path" version
}

update_and_log() {
  if [[ $1 == "--dry-run" ]]; then
    DRYRUN=true
    log_message "${YELLOW}[DRY RUN] Simulating update for: $HOSTNAME (graffiti=$GRAFFITI, version=$SCRIPT_VERSION)${RESET}"
  fi

  if [[ ! -d "$LOG_DIR" ]]; then
    echo "🔧 Creating log directory: $LOG_DIR"
    sudo mkdir -p "$LOG_DIR"
    sudo chown "$(whoami)":"$(whoami)" "$LOG_DIR"
  fi
  # 📦 Ensure the log directory exists
  mkdir -p "$LOG_DIR"

  log_message "\n🔎 Pre-Update Component Versions:"
  get_component_versions_from_ethd | tee -a "$LOG_FILE"

  if [[ $DRYRUN == false ]]; then
    log_message "\n�️ Running: OS package update (apt update/upgrade)"
    sudo apt-get update | tee -a "$LOG_FILE"
    sudo apt-get upgrade -y | tee -a "$LOG_FILE"
    log_message "\n�📦 Running: ethd update && ethd up"
    ETHD_BIN="$(detect_ethd_binary)"
    if [[ -n "$ETHD_BIN" ]]; then
      (cd "$(dirname "$ETHD_BIN")" && ./ethd update && ./ethd up) | tee -a "$LOG_FILE"
    else
      log_message "❌ Could not find ethd binary."
    fi
  else
    log_message "\n⏭️ Skipped actual update due to dry-run mode."
  fi

  log_message "\n🔍 Post-Update Component Versions:"
  get_component_versions_from_ethd | tee -a "$LOG_FILE"

  log_message "\n⛓️ Validator Health Summary (placeholder for beaconcha.in stats)"
  log_message "\n📬 Summary delivered by ${HOSTNAME}-watcher · graffiti: $GRAFFITI · version: v$SCRIPT_VERSION"
  log_message "\n📓 Log file saved to: $LOG_FILE"

  echo "$(date -u) — Ran update_node.sh v$SCRIPT_VERSION on $HOSTNAME" >> "$CHANGELOG_FILE"

  send_notifications
  signoff
}

signoff() {
  local lines=(
    "⚡ Automated by ${HOSTNAME}-watcher · born to validate"
    "👁️ Watching since Epoch Zero · graffiti: $GRAFFITI"
    "🪛 Bash, logs, and zero missed slots"
    "🔁 Don’t just stake. Dominate. $GRAFFITI style."
  )
  local pick=$((RANDOM % ${#lines[@]}))
  log_message "\n${GREEN}${lines[$pick]}${RESET}\n"
}

# ✅ Run only if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  update_and_log "$@"
fi

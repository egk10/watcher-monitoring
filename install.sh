#!/bin/bash
# install.sh — watcher deployment script v3.0
# 🧠 Modular installer with Gmail alert provisioning

set -e

VERSION="3.0"
CURRENT_DIR="$(pwd)"
ENV_FILE_SOURCE="$CURRENT_DIR/.watcher.env"
ENV_FILE_DEST="/etc/watcher/.watcher.env"
STATUS_SCRIPT="$CURRENT_DIR/watcher-status.sh"
HEALTH_SCRIPT="$CURRENT_DIR/watcher-health.sh"
SCRIPT_PATH="/usr/local/bin"
SYSTEMD_PATH="/etc/systemd/system"

### 🔍 Check core system dependencies
check_deps() {
  echo "🔍 Checking system dependencies..."
  for bin in curl docker systemctl; do
    command -v $bin &>/dev/null || {
      echo "❌ Missing required tool: $bin"
      exit 1
    }
  done
  echo "✅ Core dependencies OK"
}

### 📝 Install .watcher.env
install_env_file() {
  echo "📜 Setting up .watcher.env..."
  if [[ ! -f "$ENV_FILE_SOURCE" ]]; then
    echo "❌ Missing .watcher.env in current directory!"
    exit 1
  fi
  sudo mkdir -p "$(dirname "$ENV_FILE_DEST")"
  sudo cp "$ENV_FILE_SOURCE" "$ENV_FILE_DEST"
  echo "✅ Env file installed to $ENV_FILE_DEST"
}

### 📬 Install mail tools and generate ~/.msmtprc
install_mail_stack() {
  echo "📬 Installing mail client + msmtp..."
  sudo apt-get update
  sudo apt-get install -y mailutils msmtp msmtp-mta

  if [[ -f "$ENV_FILE_DEST" ]]; then
    source "$ENV_FILE_DEST"
    if [[ -n "$GMAIL_USER" && -n "$GMAIL_PASS" ]]; then
      cat <<EOF > ~/.msmtprc
account gmail
host smtp.gmail.com
port 587
from $GMAIL_USER
auth on
user $GMAIL_USER
password $GMAIL_PASS
tls on
tls_starttls on
logfile ~/.msmtp.log

account default : gmail
EOF
      chmod 600 ~/.msmtprc
      echo "✅ msmtp configured for Gmail alerts"

      # Optional: test send immediately
      echo "Install complete. msmtp relay active." | mail -s "Watcher Install Test" "$GMAIL_USER"
    else
      echo "⚠️ GMAIL_USER or GMAIL_PASS missing — skipping SMTP setup"
    fi
  fi
}

### 📦 Deploy watcher scripts
install_scripts() {
  echo "📦 Deploying watcher scripts..."
  sudo cp "$STATUS_SCRIPT" "$SCRIPT_PATH/watcher-status.sh"
  sudo cp "$HEALTH_SCRIPT" "$SCRIPT_PATH/watcher-health.sh"
  sudo chmod +x "$SCRIPT_PATH/watcher-"*.sh
  echo "✅ Scripts installed to $SCRIPT_PATH/"
}

### ⏱️ Set up systemd health check timer
setup_systemd_timer() {
  echo "🛠️ Configuring systemd service + timer..."
  sudo tee "$SYSTEMD_PATH/watcher-health.service" > /dev/null <<EOF
[Unit]
Description=Validator Health Check
After=network-online.target

[Service]
Type=oneshot
ExecStart=${SCRIPT_PATH}/watcher-health.sh
EOF

  sudo tee "$SYSTEMD_PATH/watcher-health.timer" > /dev/null <<EOF
[Unit]
Description=Run validator health check every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=watcher-health.service

[Install]
WantedBy=timers.target
EOF

  sudo systemctl daemon-reexec
  sudo systemctl enable --now watcher-health.timer
  echo "✅ Timer enabled: watcher-health.service every 5 min"
}

### 🎉 Final summary banner
success_banner() {
  echo ""
  echo "🎉 install.sh complete — watcher v$VERSION deployed"
  echo "📡 watcher-health.sh: scheduled via systemd"
  echo "📈 watcher-status.sh: ready to run manually"
  echo "📁 Logs → /var/log/$(hostname)-watcher/"
  echo "🗃️ Env file → $ENV_FILE_DEST"
  echo "🔔 Telegram + Gmail alerts configured"
  echo "✅ Next run: $(systemctl list-timers | grep watcher-health | awk '{print $2, $3, $4}')"
}

### 🚀 Run all steps
check_deps
install_env_file
install_mail_stack
install_scripts
setup_systemd_timer
success_banner
exit 0

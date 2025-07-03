#!/bin/bash
# install.sh — watcher deployment script v2.1
# 🧠 Installs watcher-status & watcher-health
# 📦 Deploys to /usr/local/bin
# 🛜 Moves .watcher.env to /etc/watcher/
# 🛠️ Configures systemd timer


echo "🔍 Checking .watcher.env configuration..."
bash ./check_env_sanity.sh || {
  echo "🚫 Aborting install due to environment config errors."
  exit 1
}

set -e

VERSION="2.1"
CURRENT_DIR="$(pwd)"
ENV_FILE_SOURCE="$CURRENT_DIR/.watcher.env"
ENV_FILE_DEST="/etc/watcher/.watcher.env"
STATUS_SCRIPT="$CURRENT_DIR/watcher-status.sh"
HEALTH_SCRIPT="$CURRENT_DIR/watcher-health.sh"
SCRIPT_PATH="/usr/local/bin"
SYSTEMD_PATH="/etc/systemd/system"

echo "🧠 watcher toolkit • install.sh v$VERSION"
echo "——————————————"

check_deps() {
  echo "🔍 Checking system dependencies..."
  for bin in curl docker systemctl; do
    command -v $bin &>/dev/null || {
      echo "❌ Missing required tool: $bin"
      exit 1
    }
  done
  echo "✅ Dependencies OK"
}

install_env_file() {
  echo "📝 Setting up .watcher.env..."
  if [[ ! -f "$ENV_FILE_SOURCE" ]]; then
    echo "❌ Missing .watcher.env in current directory!"
    exit 1
  fi
  sudo mkdir -p "$(dirname "$ENV_FILE_DEST")"
  sudo cp "$ENV_FILE_SOURCE" "$ENV_FILE_DEST"
  echo "✅ Env file installed to $ENV_FILE_DEST"
}

install_scripts() {
  echo "📦 Deploying watcher scripts..."
  sudo cp "$STATUS_SCRIPT" "$SCRIPT_PATH/watcher-status.sh"
  sudo cp "$HEALTH_SCRIPT" "$SCRIPT_PATH/watcher-health.sh"
  sudo chmod +x "$SCRIPT_PATH/watcher-"*.sh
  echo "✅ Scripts installed to $SCRIPT_PATH/"
}

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

  sudo systemctl daemon-reload
  sudo systemctl enable --now watcher-health.timer
  echo "✅ Timer enabled: watcher-health.service every 5 min"
}

success_banner() {
  echo ""
  echo "🎉 install.sh complete — watcher v$VERSION deployed"
  echo "📡 watcher-health.sh: scheduled via systemd"
  echo "📈 watcher-status.sh: ready to run manually"
  echo "📁 Logs → /var/log/$(hostname)-watcher/"
  echo "🗃️ Env file → $ENV_FILE_DEST"
  echo "🔔 Telegram alerts will trigger from next run"
  echo "✅ Next run: $(systemctl list-timers | grep watcher-health | awk '{print $2, $3, $4}')"
}

# Main flow
check_deps
install_env_file
install_scripts
setup_systemd_timer
success_banner
exit 0

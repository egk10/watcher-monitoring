# 🧾 Changelog

# v1.0.3 — Watcher Toolkit Upgrade

## 🎉 Highlights
- 📬 Gmail Alerting: Uses `msmtp` + `mailutils` with auto-generated `~/.msmtprc`
- 🛠 Modular Installer: `install.sh` v3.0 splits setup into reusable steps
- 📡 Telegram + Email Alerts: Dual-channel notifications in `watcher-health.sh` v2.3

## 🧠 watch-health.sh v2.3
- Emoji severity tagging (✅ ⚠️ 🚨)
- Custom email subject with `EMAIL_SUBJECT_PREFIX`
- Rich formatting for Telegram + plain-text email
- Logs alert status to `/var/log/<hostname>-watcher/health-alerts.log`

## 🧪 install.sh v3.0
- Installs mail stack dependencies
- Auto-generates msmtp config using `.watcher.env`
- Sends test email during install


## [v1.0] — July 2, 2025
- 🎉 Initial public release
- Added: watcher-health.sh, watcher-status.sh
- Added: update_node.sh for smooth node upgrades
- Added: .env.template for safe environment setup

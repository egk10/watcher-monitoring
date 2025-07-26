# Copilot Instructions for watcher-monitoring

## Project Overview
- **Purpose:** Shell-based toolkit for Ethereum node operators to monitor validator health, automate updates, and send notifications (Telegram, email).
- **Key Components:**
  - `watcher-status.sh`: Prints validator/node status, checks logs, systemd timers, and service health.
  - `watcher-health.sh`: Sends health alerts (Telegram/email), can be run manually for testing.
  - `update_node.sh`, `update_watcher.sh`: Automate node and watcher updates, managed by systemd timers.
  - `install.sh`: Interactive installer, sets up environment and systemd integration.
  - `.watcher.env`: Stores secrets and config; can be pre-created or generated interactively.
  - Logs: Written to `/var/log/<hostname>-watcher/`.

## Developer Workflows
- **Install:** Run `./install.sh` from repo root. Prompts for secrets if `.watcher.env` is missing.
- **Status:** Run `./watcher-status.sh` for a summary of validator/node state, next scheduled runs, and recent logs.
- **Health Test:** Run `./watcher-health.sh --force --debug` to send a test alert.
- **Systemd Integration:**
  - Scripts are installed to `/usr/local/bin/`.
  - Timers/services: `watcher-health.service`, `update-node.service`, `update-watcher.service` (see `systemctl list-timers --all | grep watcher`).
- **Logs:** All logs are in `/var/log/<hostname>-watcher/`. Scripts handle directory creation and permissions.

## Project-Specific Conventions
- **Environment Variables:**
  - `.watcher.env` required for secrets (Telegram, Gmail, etc). If missing, installer prompts for values.
  - Values with spaces must be single-quoted.
- **Systemd:**
  - All automation is via systemd timers/services. Do not use cron.
  - Scripts check and fix log directory permissions automatically.
- **Error Handling:**
  - Scripts print actionable error messages and exit on critical failures (e.g., log dir not writable).
- **Log Summaries:**
  - `watcher-status.sh` parses and summarizes recent logs, stripping HTML and color codes for clarity.

## Integration Points
- **External Dependencies:**
  - Docker, curl, systemd, eth-docker (or compatible beacon client).
  - Telegram Bot API, Gmail App Passwords for notifications.
- **Config Paths:**
  - Environment: `/etc/watcher/.watcher.env` (or repo root for initial setup).
  - Scripts: `/usr/local/bin/`
  - Logs: `/var/log/<hostname>-watcher/`

## Examples
- To check all watcher timers: `systemctl list-timers --all | grep watcher`
- To trigger a test alert: `./watcher-health.sh --force --debug`
- To view recent update logs: `ls -1t /var/log/<hostname>-watcher/update_report-*.txt | head -n 3`

## Key Files
- `watcher-status.sh`, `watcher-health.sh`, `update_node.sh`, `update_watcher.sh`, `install.sh`, `.watcher.env`, `/var/log/<hostname>-watcher/`

---
If you add new scripts or change integration patterns, update this file and the README accordingly.

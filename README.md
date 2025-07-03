# 🧠 watcher-monitoring

**Validator Monitoring + Operations Toolkit for Ethereum Node Operators**  
Make Ethereum independent node operators great again 💪

Monitor missed attestations, send Telegram alerts, update your node, and manage validator health — all via shell scripts built for uptime and clarity.
---

## 🚀 Manual Install

> **Setup is interactive!**
>
> - You can run `./install.sh` directly and it will prompt you for all required secrets if `.watcher.env` is missing.
> - Optionally, you may pre-create a `.watcher.env` file in the repo root (see below for required variables) to skip the prompts.
> - **If any value contains spaces, wrap it in single quotes (e.g. 'my app password').**

```bash
git clone https://github.com/egk10/watcher-monitoring.git ~/watcher-monitoring
cd watcher-monitoring
./install.sh
```

> **Note:** `install.sh` is now versioned (currently v3.3). It will always deploy the latest scripts to `/usr/local/bin/` and ensure systemd uses the correct version.

---

🔐 **Environment Configuration: .watcher.env**

You can let the installer prompt you for the required values, or pre-create a file named `.watcher.env` inside the repo root before running `./install.sh`. You can also edit `/etc/watcher/.watcher.env` after install.

**Required Notification Variables:**
```env
TELEGRAM_BOT_TOKEN=xxxxxxxxxxxxxxxxxxxxxx
TELEGRAM_CHAT_ID=123456789
GMAIL_USER=your-email@gmail.com
GMAIL_PASS='your app password with spaces'
EMAIL_TO=your-email@gmail.com
```
**Notes:**
- If any value contains spaces, wrap it in single quotes (e.g. `'my app password'`).
- Telegram Bot Token: Create a bot via BotFather → https://t.me/BotFather  and copy the API token
- Chat ID: Use userinfobot → https://t.me/userinfobot  to find your numeric Telegram ID
- Gmail Credentials: You must use a Gmail App Password → https://myaccount.google.com/security (not your regular password)
- EMAIL_TO: The email address to receive notifications (can be the same as GMAIL_USER)

## 📡 Usage

| Command                                  | Purpose                             |
|------------------------------------------|-------------------------------------|
| `watcher-status.sh`                      | Prints validator activity summary   |
| `watcher-health.sh --force --debug`      | Sends test alert to Telegram        |
| `systemctl list-timers | grep watcher`   | Shows next scheduled check          |

```
📁 Scripts installed to:     /usr/local/bin/
🔐 Environment file:         /etc/watcher/.watcher.env
🕒 Systemd timers active:
    watcher-health.service (every 5 min)
    update-node.service (daily, randomized time)
📈 Manual summary check:     watcher-status.sh
📡 Trigger test alert:       watcher-health.sh --force --debug
🗂️  Logs directory:          /var/log/<hostname>-watcher/
```

### 🔍 Systemd Service Status Commands

Check the status of the installed services and timers:

```bash
systemctl status watcher-health.service
systemctl status watcher-health.timer
systemctl status update-node.service
systemctl status update-node.timer
```

## 🛠 Requirements

- Docker  
- curl  
- systemd  
- eth-docker or compatible beacon client  

## 🧾 Changelog

v3.3 — July 3, 2025

    - install.sh versioning and redeployment logic improved
    - Always redeploys latest update_node.sh to /usr/local/bin for systemd
    - Documentation and usage clarified
    - Interactive .watcher.env setup if missing
    - EMAIL_TO now required and documented
    - Instructions for handling spaces in secrets
    - No need to manually create .watcher.env (installer is interactive)

v1.0 — July 2, 2025

    🎉 Initial public release
    Telegram alerts and validator health
    Smart node update logic via update_node.sh
    .env template included

## 🩺 Coming Soon

- `watcher-doctor.sh` — validate setup and alert flow  
- `watcher-exporter.sh` — Prometheus metrics  

## 💬 Contributing

Open to PRs, ideas, and integrations. This toolkit is built for uptime, clarity, and independence — make it better and share it!


# 🧠 watcher-monitoring

**Validator Monitoring + Operations Toolkit for Ethereum Node Operators**  
Make Ethereum independent node operators great again 💪

Monitor missed attestations, send Telegram alerts, update your node, and manage validator health — all via shell scripts built for uptime and clarity.
---


## 🚀 Install Instructions

> **Quick Start:**
>
> 1. **Clone the repository:**
>    ```bash
>    git clone https://github.com/egk10/watcher-monitoring.git
>    cd watcher-monitoring
>    ```
> 2. **Run the installer:**
>    ```bash
>    ./install.sh
>    ```
>    The installer is interactive and will prompt you for all required secrets if `.watcher.env` is missing. Optionally, you may pre-create a `.watcher.env` file in the repo root (see below for required variables) to skip the prompts.
> 3. **That's it!**
>    - All scripts and systemd timers (including auto-updates) are deployed automatically.
>    - No manual update steps are needed—your node will always stay up to date.
>    - **If any value contains spaces, wrap it in single quotes (e.g. 'my app password').**

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


## 📡 Usage & Systemd Monitoring

| Command                                          | Purpose                                 |
|--------------------------------------------------|-----------------------------------------|
| `watcher-status.sh`                              | Prints validator activity summary       |
| `watcher-health.sh --force --debug`              | Sends test alert to Telegram            |
| `systemctl list-timers --all | grep watcher`     | Shows all watcher-related timers        |

**Quick System Overview:**
```
📁 Scripts installed to:     /usr/local/bin/
🔐 Environment file:         /etc/watcher/.watcher.env
🕒 Systemd timers active:
    watcher-health.service (every 5 min)
    update-node.service (daily, randomized time)
    update-watcher.service (daily, randomized time)
📈 Manual summary check:     watcher-status.sh
📡 Trigger test alert:       watcher-health.sh --force --debug
🗂️  Logs directory:          /var/log/<hostname>-watcher/
```

To check the status and next run of all watcher-related systemd timers at any time, use:
```bash
systemctl list-timers --all | grep watcher
```


## 🛠 Requirements

- Docker
- curl
- systemd
- eth-docker or compatible beacon client


## 🧾 Changelog

v3.4 — July 4, 2025

  - Automated update_watcher.sh via systemd timer (auto-updates from GitHub)
  - README: streamlined, added systemctl list-timers instructions
  - install.sh and update_node.sh: always use explicit eth-docker path for systemd/root
  - All scripts: robust log directory permission handling
  - .watcher.env creation and quoting instructions improved
  - Changelog and documentation improvements

v3.3 — July 3, 2025

  - install.sh versioning and redeployment logic improved
  - Always redeploys latest update_node.sh to /usr/local/bin for systemd
  - Documentation and usage clarified
  - Interactive .watcher.env setup if missing
  - EMAIL_TO now required and documented
  - Instructions for handling spaces in secrets
  - No need to manually create .watcher.env (installer is interactive)
  - Added update instructions for all nodes
  - Added update_watcher.sh automation script

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


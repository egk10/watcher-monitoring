# 🧠 watcher-monitoring

**Validator Monitoring + Operations Toolkit for Ethereum Node Operators**  
Make Ethereum independent node operators great again 💪

Monitor missed attestations, send Telegram alerts, update your node, and manage validator health — all via shell scripts built for uptime and clarity.
---

## 🚀 Manual Install

```bash
git clone https://github.com/egk10/watcher-monitoring.git ~/watcher-monitoring
cd watcher-monitoring
./install.sh
```

## ⚡ Quick Install (.deb)
}
}
}

}
}
```bash
```
wget https://github.com/egk10/watcher-monitoring/releases/download/v1.0.14/watcher-monitoring-v1.0.14.deb && sudo dpkg -i watcher-monitoring-v1.0.14.deb


🔐 Environment Configuration: .watcher.env

Create a file named .watcher.env inside the repo root, or edit /etc/watcher/.watcher.env after install.
Required Variables:
```
TELEGRAM_BOT_TOKEN=xxxxxxxxxxxxxxxxxxxxxx
TELEGRAM_CHAT_ID=123456789
GMAIL_USER=your-email@gmail.com
GMAIL_PASS=your-app-password
```
Notes:
- Telegram Bot Token: Create a bot via BotFather → https://t.me/BotFather  and copy the API token
- Chat ID: Use userinfobot → https://t.me/userinfobot  to find your numeric Telegram ID
- Gmail Credentials: You must use a Gmail App Password → https://myaccount.google.com/security (not your regular password)

## 📡 Usage

| Command                                  | Purpose                             |
|------------------------------------------|-------------------------------------|
| `watcher-status.sh`                      | Prints validator activity summary   |
| `watcher-health.sh --force --debug`     | Sends test alert to Telegram        |
| `systemctl list-timers | grep watcher`  | Shows next scheduled check          |


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
    

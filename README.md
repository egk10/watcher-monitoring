# 🧠 watcher-monitoring

**Validator Monitoring + Operations Toolkit for Ethereum Node Operators**  
Make Ethereum independent node operators great again 💪

Monitor missed attestations, send Telegram alerts, update your node, and manage validator health — all via shell scripts built for uptime and clarity.
---


## 🚀 Installation Instructions

### **Method 1: Quick Install via .deb Package (Recommended)**

```bash
# Download the latest release
wget https://github.com/egk10/watcher-monitoring/releases/download/v3.5/watcher-monitoring-v3.5.deb

# Install the package
sudo dpkg -i watcher-monitoring-v3.5.deb

# Run the interactive installer
sudo /usr/local/bin/install.sh
```

### **Method 2: Alternative Package Installation**

```bash
# Download and install in one step
wget https://github.com/egk10/watcher-monitoring/releases/download/v3.5/watcher-monitoring-v3.5.deb
sudo apt install ./watcher-monitoring-v3.5.deb

# Run the interactive installer
sudo /usr/local/bin/install.sh
```

### **Method 3: Manual Installation from Source**

```bash
# Clone the repository
git clone https://github.com/egk10/watcher-monitoring.git
cd watcher-monitoring

# Run the installer
./install.sh
```

### **📊 Installation Methods Comparison**

| Method | Best For | Advantages | Requirements |
|--------|----------|------------|--------------|
| **📦 .deb Package** | Production nodes | • Proper package management<br>• Clean uninstall via apt<br>• System integration | • Root access<br>• Ubuntu/Debian |
| **📂 Source Install** | Development/Testing | • Easy modifications<br>• Latest code<br>• Git integration | • Git installed<br>• Manual updates |

> **📋 Notes:**
> - The installer is interactive and will prompt you for all required secrets if `.watcher.env` is missing
> - All scripts and systemd timers (including auto-updates) are deployed automatically
> - No manual update steps are needed—your node will always stay up to date
> - **If any value contains spaces, wrap it in single quotes (e.g. 'my app password')**

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
| `./complete_cleanup.sh`                          | Complete uninstall from all nodes      |
| `./verify_complete_cleanup.sh`                   | Verify complete removal                 |

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

---

## 🗑️ Uninstall Instructions

### **Method 1: Complete Removal via Package (Recommended)**

If you installed via .deb package:

```bash
# Complete cleanup from all nodes
/usr/local/bin/complete_cleanup.sh

# Verify removal
/usr/local/bin/verify_complete_cleanup.sh

# Remove the package (cleans up /usr/local/bin/ scripts)
sudo apt remove watcher-monitoring

# Optional: Remove configuration directory
sudo rm -rf /etc/watcher/
```

### **Method 2: Complete Removal from All Nodes (Source Install)**

If you installed from source and want to remove from multiple nodes:

```bash
# Run complete cleanup (removes from all configured nodes)
./complete_cleanup.sh

# Verify removal across all nodes
./verify_complete_cleanup.sh

# Remove local repository
cd .. && rm -rf watcher-monitoring/
```

### **Method 3: Manual Single-Node Removal**

If you need to remove from a specific node manually:

```bash
# SSH to the target node
ssh user@your-node.example.com

# Download and run uninstall script
curl -sL https://raw.githubusercontent.com/egk10/watcher-monitoring/main/uninstall.sh | sudo bash

# Or run from local repository
cd watcher-monitoring
sudo ./uninstall.sh
```

### **What Gets Removed**
- ✅ All systemd timers and services (`watcher-health`, `update-node`, `update-watcher`)
- ✅ All scripts from `/usr/local/bin/` (`watcher-*`, `update_*.sh`)
- ✅ All configuration files (`/etc/watcher/`, `~/.watcher.env`)
- ✅ All log directories (`/var/log/*-watcher/`)
- ✅ Git repository (`~/watcher-monitoring/`)
- ✅ All temporary files (`/tmp/watcher-*`, `/tmp/uninstall.sh`)

---


## 🛠 Requirements

- Docker
- curl
- systemd
- eth-docker or compatible beacon client


## 🧾 Changelog

v3.5 — July 26, 2025

- **MAJOR:** Added complete uninstall/cleanup functionality
- New scripts: `complete_cleanup.sh`, `verify_complete_cleanup.sh`, `uninstall.sh`
- Multi-node cleanup via SSH automation with fallback to manual instructions
- Complete removal of all components: systemd services, scripts, configs, logs, and repositories
- Comprehensive verification system to ensure clean removal
- Updated documentation with detailed uninstall instructions
- Fixed emoji encoding issues in bash scripts
- Enhanced error handling and user feedback

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


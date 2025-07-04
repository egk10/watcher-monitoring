#!/bin/bash
# update_watcher.sh — One-liner to update watcher-monitoring from GitHub and redeploy scripts

git fetch origin && git reset --hard origin/main
./install.sh
sudo systemctl restart update-node.service
sudo systemctl status update-node.service

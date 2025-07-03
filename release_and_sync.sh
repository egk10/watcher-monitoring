#!/bin/bash
# release_and_sync.sh — orchestrates Git sync + deb release

REPO_PATH=~/watcher-monitoring
LOG_PREFIX="[release_and_sync]"

echo "$LOG_PREFIX 🔄 Syncing local repo with GitHub main..."

cd "$REPO_PATH" || { echo "$LOG_PREFIX ❌ Repo not found. Abort."; exit 1; }

if [ ! -f "./sync_main.sh" ] || [ ! -f "./make_deb_autotag.sh" ]; then
  echo "$LOG_PREFIX ❌ Required scripts not found in repo."
  echo "Expected: sync_main.sh and make_deb_autotag.sh"
  exit 1
fi

chmod +x sync_main.sh make_deb_autotag.sh

./sync_main.sh || { echo "$LOG_PREFIX ⚠️ Sync failed. Aborting release."; exit 1; }

echo "$LOG_PREFIX 🚀 Sync complete. Starting release flow..."
./make_deb_autotag.sh

echo "$LOG_PREFIX ✅ Full release pipeline finished."

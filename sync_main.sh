#!/bin/bash
# sync_main.sh — safely sync local main with GitHub

LOG_PREFIX="[sync_main]"

echo "$LOG_PREFIX 🔎 Checking repo status..."

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "$LOG_PREFIX ❌ Not a Git repo. Abort."
  exit 1
fi

CHANGES=$(git status --porcelain)

if [[ -n "$CHANGES" ]]; then
  echo "$LOG_PREFIX 📝 Unstaged changes detected"

  echo "$LOG_PREFIX 📦 Stashing changes..."
  git stash push -m "Local edits before rebase"
else
  echo "$LOG_PREFIX ✅ Working directory is clean"
fi

echo "$LOG_PREFIX 🔄 Rebasing from origin/main..."
git pull origin main --rebase

echo "$LOG_PREFIX 🚀 Pushing local changes to GitHub..."
git push origin main

if git stash list | grep "Local edits before rebase" > /dev/null; then
  echo "$LOG_PREFIX 🔁 Reapplying stashed edits..."
  git stash pop
fi

echo "$LOG_PREFIX ✅ Sync complete"

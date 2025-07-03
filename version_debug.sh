#!/bin/bash
# version_debug.sh — Print current and next watcher-monitoring version info

REPO_NAME="watcher-monitoring"
REPO_PATH=~/watcher-monitoring
cd "$REPO_PATH"

# Get highest semantic tag
LATEST_TAG=$(git tag | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)

IFS='.' read -r major minor patch <<< "${LATEST_TAG/v/}"
NEW_PATCH=$((patch + 1))
DEB_VERSION="${major}.${minor}.${NEW_PATCH}"
FINAL_NAME=${REPO_NAME}-v${DEB_VERSION}.deb

echo "🧠 Latest Git tag:     $LATEST_TAG"
echo "🚀 Next release tag:   v${DEB_VERSION}"
echo "📦 Next .deb filename: ${FINAL_NAME}"

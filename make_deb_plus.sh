#!/bin/bash
# make_deb_plus.sh — Auto-package, tag, release, and badge watcher-monitoring

REPO_OWNER="egk10"
REPO_NAME="watcher-monitoring"
BUILD_ROOT=~/deb-build
REPO_PATH=~/watcher-monitoring

# 🧠 Auto-extract SCRIPT_VERSION from update_node.sh
SCRIPT_VERSION=$(grep -oP 'SCRIPT_VERSION="\K[^"]+' "$REPO_PATH/update_node.sh")
DEB_VERSION="2.3.3"  # Optionally read from version.txt for future automation
FINAL_NAME=${REPO_NAME}-v${DEB_VERSION}-v${SCRIPT_VERSION}.deb
BUILD_DIR=$BUILD_ROOT/${REPO_NAME}_${DEB_VERSION}
LOG_PREFIX="[make_deb]"

echo "$LOG_PREFIX 📦 Packaging $REPO_NAME — deb v$DEB_VERSION · script v$SCRIPT_VERSION"

# 🧼 Clean build folder
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/DEBIAN"

# 📋 Control file
cp "$BUILD_ROOT/watcher-monitoring_2.3/DEBIAN/control" "$BUILD_DIR/DEBIAN/control"
sed -i "s/Version: .*/Version: ${DEB_VERSION}/" "$BUILD_DIR/DEBIAN/control"

# 📤 Copy script assets
cp "$REPO_PATH"/*.sh "$BUILD_DIR/usr/local/bin/"
chmod +x "$BUILD_DIR/usr/local/bin/"*.sh

# 📦 Build .deb
cd "$BUILD_ROOT"
dpkg-deb --build ${REPO_NAME}_${DEB_VERSION}
mv ${REPO_NAME}_${DEB_VERSION}.deb "$FINAL_NAME"
echo "$LOG_PREFIX ✅ Built: $FINAL_NAME"

# 📋 Install command
echo -e "\n💡 To install remotely:\n"
echo "wget https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${DEB_VERSION}/${FINAL_NAME} && sudo dpkg -i ${FINAL_NAME}"

# 📂 Switch back to repo before Git operations
cd "$REPO_PATH"

if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "$LOG_PREFIX 🏷️ Tagging and pushing: v${DEB_VERSION}"
  git tag "v${DEB_VERSION}"
  git push origin "v${DEB_VERSION}"

  echo "$LOG_PREFIX 🚀 Creating GitHub release"
  gh release create "v${DEB_VERSION}" "$BUILD_ROOT/$FINAL_NAME" \
    --repo "${REPO_OWNER}/${REPO_NAME}" \
    --title "${REPO_NAME} v${DEB_VERSION}" \
    --notes "Includes update_node.sh v${SCRIPT_VERSION} · Smart log fallback · Telegram/email fixes"
else
  echo "$LOG_PREFIX ⚠️ Not inside a Git repo. Skipping tag and GitHub release."
fi

# 🖼️ Markdown badge
BADGE="[![Deb Version](https://img.shields.io/badge/deb-v${DEB_VERSION}--v${SCRIPT_VERSION}-blue)](https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/tag/v${DEB_VERSION})"
echo "$BADGE" > "$REPO_PATH/.badge.md"
echo "$LOG_PREFIX 🖼️ Badge markdown saved to .badge.md"

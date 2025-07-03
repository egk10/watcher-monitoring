#!/bin/bash
# make_deb_autotag.sh — Full release automation for watcher-monitoring

REPO_OWNER="egk10"
REPO_NAME="watcher-monitoring"
REPO_PATH=~/watcher-monitoring
BUILD_ROOT=~/deb-build
CONTROL_PATH="$BUILD_ROOT/watcher-monitoring_2.3/DEBIAN/control"
README="$REPO_PATH/README.md"

cd "$REPO_PATH"

# 🔍 Highest semantic version tag
LATEST_TAG=$(git tag | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
IFS='.' read -r major minor patch <<< "${LATEST_TAG/v/}"
NEW_PATCH=$((patch + 1))
DEB_VERSION="${major}.${minor}.${NEW_PATCH}"

FINAL_NAME=${REPO_NAME}-v${DEB_VERSION}.deb

echo "🧠 Latest tag: $LATEST_TAG"
echo "🚀 Releasing v${DEB_VERSION} — filename: $FINAL_NAME"

# 📝 Recent commits
CHANGELOG=$(git log -n 3 --pretty=format:"- %s")

# 🛠️ Build folder
BUILD_DIR="$BUILD_ROOT/${REPO_NAME}_${DEB_VERSION}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/usr/local/bin" "$BUILD_DIR/DEBIAN"

# 📋 Copy and modify control file
cp "$CONTROL_PATH" "$BUILD_DIR/DEBIAN/control"
sed -i "s/Version: .*/Version: ${DEB_VERSION}/" "$BUILD_DIR/DEBIAN/control"

# 📤 Copy scripts
cp "$REPO_PATH"/*.sh "$BUILD_DIR/usr/local/bin/"
chmod +x "$BUILD_DIR/usr/local/bin/"*.sh

# 📦 Build .deb
cd "$BUILD_ROOT"
dpkg-deb --build "${REPO_NAME}_${DEB_VERSION}"
mv "${REPO_NAME}_${DEB_VERSION}.deb" "$FINAL_NAME"
echo "✅ Built: $FINAL_NAME"

# 🏷️ Tag and push
cd "$REPO_PATH"
git add .
git commit -m "Release v${DEB_VERSION}"
git tag "v${DEB_VERSION}"
git push origin main --tags

# 🚀 GitHub release
gh release create "v${DEB_VERSION}" "$BUILD_ROOT/$FINAL_NAME" \
  --repo "${REPO_OWNER}/${REPO_NAME}" \
  --title "${REPO_NAME} v${DEB_VERSION}" \
  --notes "$CHANGELOG"

# 🖼️ Badge
BADGE="[![Deb Version](https://img.shields.io/badge/deb-v${DEB_VERSION}-blue)](https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/tag/v${DEB_VERSION})"
echo "$BADGE" > "$REPO_PATH/.badge.md"

# 📘 README patching
INSTALL_CMD="wget https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${DEB_VERSION}/${FINAL_NAME} && sudo dpkg -i ${FINAL_NAME}"

# Replace badge line
sed -i "s|^

\[!

\[Deb Version\]

.*|${BADGE}|" "$README"

# Replace install command line
sed -i "s|^wget https://github.com/.*/${REPO_NAME}/releases/download/v[0-9.]\+/${REPO_NAME}-v[0-9.]\+\.deb && sudo dpkg -i ${REPO_NAME}-v[0-9.]\+\.deb|${INSTALL_CMD}|" "$README"

echo "📘 README.md updated for v${DEB_VERSION}"

# 📋 Final echo
echo -e "\n💡 To install remotely:\n"
echo "$INSTALL_CMD"

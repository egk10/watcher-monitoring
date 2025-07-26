#!/bin/bash
# create_release.sh - Create GitHub release with .deb package

set -e

VERSION="3.5.1"
PACKAGE_NAME="watcher-monitoring"
PACKAGE_FILE="${PACKAGE_NAME}-v${VERSION}.deb"
TAG_NAME="v${VERSION}"

echo "🚀 Creating GitHub Release v${VERSION}"
echo "======================================"

# Check if package exists
if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "❌ Package file $PACKAGE_FILE not found!"
    echo "💡 Run ./build_deb.sh first"
    exit 1
fi

# Check if we're on the right branch and up to date
echo "🔍 Checking git status..."
git fetch origin

if [[ $(git rev-parse HEAD) != $(git rev-parse origin/main) ]]; then
    echo "⚠️  Your local branch is not up to date with origin/main"
    echo "💡 Run: git pull origin main"
    exit 1
fi

# Create git tag
echo "🏷️  Creating git tag ${TAG_NAME}..."
if git tag -l | grep -q "^${TAG_NAME}$"; then
    echo "⚠️  Tag ${TAG_NAME} already exists"
    echo "💡 Delete it first: git tag -d ${TAG_NAME} && git push origin :refs/tags/${TAG_NAME}"
    exit 1
fi

git tag -a "${TAG_NAME}" -m "Release ${TAG_NAME}

🎉 watcher-monitoring v${VERSION} - Complete Uninstall & Cleanup Edition

## ✨ New Features:
- 🧹 Complete uninstall and cleanup functionality
- 🔄 Multi-node SSH automation with manual fallback  
- 🔍 Comprehensive verification system
- 📋 Enhanced documentation and user guides

## 🔧 What's Included:
- ✅ Complete removal of all watcher-monitoring components
- ✅ Removes: systemd services, scripts, configs, logs, repositories
- ✅ Multi-node cleanup via SSH automation
- ✅ Enhanced error handling and user feedback

## 📦 Installation:
\`\`\`bash
# Download and install .deb package
wget https://github.com/egk10/watcher-monitoring/releases/download/${TAG_NAME}/${PACKAGE_FILE}
sudo dpkg -i ${PACKAGE_FILE}

# Run installer
sudo /usr/local/bin/install.sh
\`\`\`

## 🗑️ Uninstallation:
\`\`\`bash
# Complete cleanup from all nodes
/usr/local/bin/complete_cleanup.sh

# Verify removal
/usr/local/bin/verify_complete_cleanup.sh

# Remove package
sudo apt remove ${PACKAGE_NAME}
\`\`\`"

echo "📤 Pushing tag to GitHub..."
git push origin "${TAG_NAME}"

# Create GitHub release
echo "🎁 Creating GitHub release..."
gh release create "${TAG_NAME}" \
    --title "watcher-monitoring v${VERSION} - Complete Uninstall & Cleanup Edition" \
    --notes "🎉 **Major Update: Complete Uninstall & Cleanup Functionality**

## ✨ New Features:
- 🧹 **Complete uninstall and cleanup functionality**
- 🔄 **Multi-node SSH automation** with manual fallback  
- 🔍 **Comprehensive verification system**
- 📋 **Enhanced documentation** and user guides
- 🛡️ **Fixed emoji encoding issues** in bash scripts

## 🔧 What's New in v${VERSION}:
- \`complete_cleanup.sh\` - Automated multi-node removal
- \`verify_complete_cleanup.sh\` - Verification system  
- \`git_sync_uninstall.sh\` - Repository-based cleanup
- Updated README.md with comprehensive uninstall documentation
- Enhanced error handling and user feedback

## 📦 Quick Installation:
\`\`\`bash
# Download and install
wget https://github.com/egk10/watcher-monitoring/releases/download/${TAG_NAME}/${PACKAGE_FILE}
sudo dpkg -i ${PACKAGE_FILE}
sudo /usr/local/bin/install.sh
\`\`\`

## 🗑️ Complete Removal:
\`\`\`bash
# Remove from all nodes
/usr/local/bin/complete_cleanup.sh

# Verify removal  
/usr/local/bin/verify_complete_cleanup.sh

# Uninstall package
sudo apt remove ${PACKAGE_NAME}
\`\`\`

## 🔧 What Gets Removed:
- ✅ All systemd timers and services
- ✅ All scripts from /usr/local/bin/
- ✅ All configuration files
- ✅ All log directories  
- ✅ Git repositories
- ✅ All temporary files

Perfect for Ethereum node operators who need reliable monitoring with easy cleanup! 🚀" \
    "${PACKAGE_FILE}"

echo ""
echo "🎉 Release created successfully!"
echo "================================"
echo "🏷️  Tag: ${TAG_NAME}"
echo "📦 Package: ${PACKAGE_FILE}"
echo "🌐 URL: https://github.com/egk10/watcher-monitoring/releases/tag/${TAG_NAME}"
echo ""
echo "📋 Users can now install with:"
echo "   wget https://github.com/egk10/watcher-monitoring/releases/download/${TAG_NAME}/${PACKAGE_FILE}"
echo "   sudo dpkg -i ${PACKAGE_FILE}"
echo "   sudo /usr/local/bin/install.sh"

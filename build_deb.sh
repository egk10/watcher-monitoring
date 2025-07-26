#!/bin/bash
# build_deb.sh - Build .deb package for watcher-monitoring

set -e

VERSION="3.5.1"
PACKAGE_NAME="watcher-monitoring"
PACKAGE_VERSION="${VERSION}"
BUILD_DIR="deb_build"
PACKAGE_DIR="${BUILD_DIR}/${PACKAGE_NAME}-${PACKAGE_VERSION}"

echo "🔧 Building ${PACKAGE_NAME} v${VERSION} .deb package"
echo "=================================================="

# Clean up previous build
if [[ -d "$BUILD_DIR" ]]; then
    echo "🧹 Cleaning previous build directory..."
    rm -rf "$BUILD_DIR"
fi

# Create package structure
echo "📁 Creating package structure..."
mkdir -p "${PACKAGE_DIR}/DEBIAN"
mkdir -p "${PACKAGE_DIR}/usr/local/bin"
mkdir -p "${PACKAGE_DIR}/etc/watcher"

# Create control file
echo "📝 Creating DEBIAN control file..."
cat > "${PACKAGE_DIR}/DEBIAN/control" << EOF
Package: ${PACKAGE_NAME}
Version: ${PACKAGE_VERSION}
Section: base
Priority: optional
Architecture: all
Maintainer: Elie <egk@example.com>
Description: Ethereum validator monitoring toolkit with Telegram alerts and health checks
 Complete toolkit for Ethereum node operators to monitor validator health,
 automate updates, and send notifications via Telegram and email.
 Features: systemd integration, multi-node support, complete uninstall capability.
EOF

# Create postinst script
echo "📝 Creating post-installation script..."
cat > "${PACKAGE_DIR}/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

echo "🔧 Configuring watcher-monitoring..."

# Create watcher user if it doesn't exist
if ! id "watcher" &>/dev/null; then
    useradd -r -s /bin/false -d /var/lib/watcher watcher
fi

# Create log directory
mkdir -p /var/log/$(hostname)-watcher
chown watcher:watcher /var/log/$(hostname)-watcher
chmod 755 /var/log/$(hostname)-watcher

# Make scripts executable
chmod +x /usr/local/bin/watcher-*
chmod +x /usr/local/bin/update_*.sh
chmod +x /usr/local/bin/install.sh
chmod +x /usr/local/bin/complete_cleanup.sh
chmod +x /usr/local/bin/verify_complete_cleanup.sh

echo "✅ watcher-monitoring installation completed!"
echo "📋 Next steps:"
echo "   1. Run: /usr/local/bin/install.sh"
echo "   2. Configure your .watcher.env file"
echo "   3. Check status: watcher-status.sh"
EOF

# Create prerm script for clean removal
echo "📝 Creating pre-removal script..."
cat > "${PACKAGE_DIR}/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

echo "🗑️ Removing watcher-monitoring services..."

# Stop and disable systemd services
systemctl stop watcher-health.timer watcher-health.service 2>/dev/null || true
systemctl stop update-node.timer update-node.service 2>/dev/null || true
systemctl stop update-watcher.timer update-watcher.service 2>/dev/null || true

systemctl disable watcher-health.timer watcher-health.service 2>/dev/null || true
systemctl disable update-node.timer update-node.service 2>/dev/null || true
systemctl disable update-watcher.timer update-watcher.service 2>/dev/null || true

# Remove systemd unit files
rm -f /etc/systemd/system/watcher-health.* 2>/dev/null || true
rm -f /etc/systemd/system/update-node.* 2>/dev/null || true
rm -f /etc/systemd/system/update-watcher.* 2>/dev/null || true

systemctl daemon-reload

echo "✅ watcher-monitoring services removed"
EOF

# Make maintainer scripts executable
chmod 755 "${PACKAGE_DIR}/DEBIAN/postinst"
chmod 755 "${PACKAGE_DIR}/DEBIAN/prerm"

# Copy all scripts to package
echo "📋 Copying scripts to package..."
cp watcher-health.sh "${PACKAGE_DIR}/usr/local/bin/"
cp watcher-status.sh "${PACKAGE_DIR}/usr/local/bin/"
cp update_node.sh "${PACKAGE_DIR}/usr/local/bin/"
cp update_watcher.sh "${PACKAGE_DIR}/usr/local/bin/"
cp install.sh "${PACKAGE_DIR}/usr/local/bin/"
cp check_env_sanity.sh "${PACKAGE_DIR}/usr/local/bin/"
cp complete_cleanup.sh "${PACKAGE_DIR}/usr/local/bin/"
cp verify_complete_cleanup.sh "${PACKAGE_DIR}/usr/local/bin/"

# Copy uninstall script
if [[ -f "uninstall.sh" ]]; then
    cp uninstall.sh "${PACKAGE_DIR}/usr/local/bin/"
fi

# Copy documentation
if [[ -f "README.md" ]]; then
    mkdir -p "${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}"
    cp README.md "${PACKAGE_DIR}/usr/share/doc/${PACKAGE_NAME}/"
fi

# Build the .deb package
echo "🔨 Building .deb package..."
PACKAGE_FILE="${PACKAGE_NAME}-v${VERSION}.deb"

dpkg-deb --build "${PACKAGE_DIR}" "${PACKAGE_FILE}"

echo ""
echo "🎉 Package built successfully!"
echo "==============================================="
echo "📦 Package: ${PACKAGE_FILE}"
echo "📊 Size: $(du -h "${PACKAGE_FILE}" | cut -f1)"
echo ""
echo "🔍 Package info:"
dpkg-deb --info "${PACKAGE_FILE}"
echo ""
echo "📋 To install:"
echo "   sudo dpkg -i ${PACKAGE_FILE}"
echo ""
echo "📋 To create GitHub release:"
echo "   ./create_release.sh"

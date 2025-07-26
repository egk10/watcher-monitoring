#!/bin/bash
# complete_cleanup.sh - Complete removal of watcher-monitoring folders and files

set -e

echo "🧹 Complete Watcher-Monitoring Cleanup"
echo "======================================"
echo ""

# Function to run cleanup on a single node
cleanup_node() {
    local node="$1"
    echo "🔍 Cleaning up node: $node"
    echo "─────────────────────────────────────"
    
    # Check if node is reachable
    if ! ssh -o ConnectTimeout=5 egk@"$node" 'echo "Connected"' >/dev/null 2>&1; then
        echo "⚠️  Cannot connect to $node - skipping"
        echo ""
        return
    fi
    
    # Run comprehensive cleanup on the node
    ssh egk@"$node" 'bash -s' << 'EOF'
        echo "🗑️  Stopping any remaining services..."
        sudo systemctl stop watcher-health.timer watcher-health.service 2>/dev/null || true
        sudo systemctl stop update-node.timer update-node.service 2>/dev/null || true
        sudo systemctl stop update-watcher.timer update-watcher.service 2>/dev/null || true
        
        echo "🗑️  Disabling and removing systemd services..."
        sudo systemctl disable watcher-health.timer watcher-health.service 2>/dev/null || true
        sudo systemctl disable update-node.timer update-node.service 2>/dev/null || true
        sudo systemctl disable update-watcher.timer update-watcher.service 2>/dev/null || true
        
        echo "🗑️  Removing systemd unit files..."
        sudo rm -f /etc/systemd/system/watcher-health.* 2>/dev/null || true
        sudo rm -f /etc/systemd/system/update-node.* 2>/dev/null || true
        sudo rm -f /etc/systemd/system/update-watcher.* 2>/dev/null || true
        
        echo "🗑️  Removing scripts from /usr/local/bin/..."
        sudo rm -f /usr/local/bin/watcher-* 2>/dev/null || true
        sudo rm -f /usr/local/bin/update_node.sh 2>/dev/null || true
        sudo rm -f /usr/local/bin/update_watcher.sh 2>/dev/null || true
        
        echo "🗑️  Removing configuration files..."
        sudo rm -rf /etc/watcher/ 2>/dev/null || true
        rm -f ~/.watcher.env 2>/dev/null || true
        
        echo "🗑️  Removing log directories..."
        sudo rm -rf /var/log/*-watcher/ 2>/dev/null || true
        sudo rm -rf /var/log/watcher/ 2>/dev/null || true
        
        echo "🗑️  Removing watcher-monitoring git repository..."
        rm -rf ~/watcher-monitoring/ 2>/dev/null || true
        
        echo "🗑️  Removing any temp files..."
        rm -f /tmp/uninstall.sh 2>/dev/null || true
        rm -f /tmp/watcher-* 2>/dev/null || true
        
        echo "🔄 Reloading systemd daemon..."
        sudo systemctl daemon-reload
        
        echo "✅ Cleanup completed on $(hostname)"
        echo ""
EOF
    
    echo "✅ Node $node cleaned up"
    echo ""
}

# List of nodes
NODES=(
    "minipcamd.velociraptor-scylla.ts.net"
    "minipcamd2.velociraptor-scylla.ts.net"
    "minipcamd3.velociraptor-scylla.ts.net"
    "eliedesk.velociraptor-scylla.ts.net"
    "laptop.velociraptor-scylla.ts.net"
)

echo "🎯 Starting complete cleanup on all nodes..."
echo ""

# Clean up each node
for node in "${NODES[@]}"; do
    if [[ -n "$node" ]]; then
        cleanup_node "$node"
    fi
done

echo "🧹 Local cleanup (current machine)..."
echo "─────────────────────────────────────"

# Also clean up locally if this machine has watcher-monitoring installed
if systemctl list-unit-files | grep -q watcher; then
    echo "🔍 Found watcher services locally, cleaning up..."
    
    sudo systemctl stop watcher-health.timer watcher-health.service 2>/dev/null || true
    sudo systemctl stop update-node.timer update-node.service 2>/dev/null || true
    sudo systemctl stop update-watcher.timer update-watcher.service 2>/dev/null || true
    
    sudo systemctl disable watcher-health.timer watcher-health.service 2>/dev/null || true
    sudo systemctl disable update-node.timer update-node.service 2>/dev/null || true
    sudo systemctl disable update-watcher.timer update-watcher.service 2>/dev/null || true
    
    sudo rm -f /etc/systemd/system/watcher-health.* 2>/dev/null || true
    sudo rm -f /etc/systemd/system/update-node.* 2>/dev/null || true
    sudo rm -f /etc/systemd/system/update-watcher.* 2>/dev/null || true
    
    sudo rm -f /usr/local/bin/watcher-* 2>/dev/null || true
    sudo rm -f /usr/local/bin/update_node.sh 2>/dev/null || true
    sudo rm -f /usr/local/bin/update_watcher.sh 2>/dev/null || true
    
    sudo rm -rf /etc/watcher/ 2>/dev/null || true
    rm -f ~/.watcher.env 2>/dev/null || true
    
    sudo rm -rf /var/log/*-watcher/ 2>/dev/null || true
    sudo rm -rf /var/log/watcher/ 2>/dev/null || true
    
    sudo systemctl daemon-reload
    
    echo "✅ Local cleanup completed"
else
    echo "✅ No watcher services found locally"
fi

echo ""
echo "🎉 COMPLETE CLEANUP FINISHED!"
echo "============================="
echo ""
echo "📋 What was removed from each node:"
echo "   • All systemd timers and services"
echo "   • All scripts in /usr/local/bin/"
echo "   • All configuration files (/etc/watcher/, ~/.watcher.env)"
echo "   • All log directories (/var/log/*-watcher/)"
echo "   • The entire watcher-monitoring git repository"
echo "   • All temporary files"
echo ""
echo "🔍 Run verification to confirm everything is clean:"
echo "   ./verify_complete_cleanup.sh"

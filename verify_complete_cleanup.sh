#!/bin/bash
# verify_complete_cleanup.sh - Verify complete removal of all watcher-monitoring components

echo "🔍 COMPLETE CLEANUP VERIFICATION"
echo "================================"
echo ""

# Function to verify cleanup on a single node
verify_node() {
    local node="$1"
    echo "🔍 Verifying node: $node"
    echo "─────────────────────────────────"
    
    # Check if node is reachable
    if ! ssh -o ConnectTimeout=5 egk@"$node" 'echo "Connected"' >/dev/null 2>&1; then
        echo "⚠️  Cannot connect to $node - skipping verification"
        echo ""
        return
    fi
    
    # Verify cleanup on the node
    ssh egk@"$node" 'bash -s' << 'EOF'
        echo "🔎 Checking systemd timers and services..."
        if systemctl list-timers --all | grep -E 'watcher|update' | grep -v grep; then
            echo "❌ Found remaining timers!"
        else
            echo "✅ No watcher timers found"
        fi
        
        if systemctl list-units --all | grep -E 'watcher|update' | grep -v grep; then
            echo "❌ Found remaining services!"
        else
            echo "✅ No watcher services found"
        fi
        
        echo "🔎 Checking scripts in /usr/local/bin/..."
        if ls -la /usr/local/bin/watcher* /usr/local/bin/update_*.sh 2>/dev/null; then
            echo "❌ Found remaining scripts!"
        else
            echo "✅ No watcher scripts found"
        fi
        
        echo "🔎 Checking configuration files..."
        if [ -d "/etc/watcher" ] || [ -f "~/.watcher.env" ]; then
            echo "❌ Found remaining config files!"
            ls -la /etc/watcher/ ~/.watcher.env 2>/dev/null || true
        else
            echo "✅ No config files found"
        fi
        
        echo "🔎 Checking log directories..."
        if ls -d /var/log/*watcher* 2>/dev/null; then
            echo "❌ Found remaining log directories!"
        else
            echo "✅ No log directories found"
        fi
        
        echo "🔎 Checking git repository..."
        if [ -d "~/watcher-monitoring" ]; then
            echo "❌ Found watcher-monitoring repository!"
            ls -la ~/watcher-monitoring/ 2>/dev/null || true
        else
            echo "✅ No watcher-monitoring repository found"
        fi
        
        echo "🔎 Checking temp files..."
        if ls /tmp/watcher* /tmp/uninstall.sh 2>/dev/null; then
            echo "❌ Found remaining temp files!"
        else
            echo "✅ No temp files found"
        fi
        
        echo "✅ Verification completed on $(hostname)"
        echo ""
EOF
    
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

echo "🎯 Verifying complete cleanup on all nodes..."
echo ""

# Verify each node
for node in "${NODES[@]}"; do
    if [[ -n "$node" ]]; then
        verify_node "$node"
    fi
done

echo "🔍 Local verification (current machine)..."
echo "──────────────────────────────────────────"

echo "🔎 Checking local systemd timers and services..."
if systemctl list-timers --all | grep -E 'watcher|update' | grep -v grep; then
    echo "❌ Found remaining timers locally!"
else
    echo "✅ No watcher timers found locally"
fi

if systemctl list-units --all | grep -E 'watcher|update' | grep -v grep; then
    echo "❌ Found remaining services locally!"
else
    echo "✅ No watcher services found locally"
fi

echo "🔎 Checking local scripts..."
if ls -la /usr/local/bin/watcher* /usr/local/bin/update_*.sh 2>/dev/null; then
    echo "❌ Found remaining scripts locally!"
else
    echo "✅ No watcher scripts found locally"
fi

echo "🔎 Checking local config files..."
if [ -d "/etc/watcher" ] || [ -f "~/.watcher.env" ]; then
    echo "❌ Found remaining config files locally!"
    ls -la /etc/watcher/ ~/.watcher.env 2>/dev/null || true
else
    echo "✅ No config files found locally"
fi

echo "🔎 Checking local log directories..."
if ls -d /var/log/*watcher* 2>/dev/null; then
    echo "❌ Found remaining log directories locally!"
else
    echo "✅ No log directories found locally"
fi

echo ""
echo "🎉 VERIFICATION COMPLETE!"
echo "========================"
echo ""
echo "If you see any ❌ markers above, some components weren't fully removed."
echo "If you see only ✅ markers, the cleanup was successful!"
echo ""
echo "📝 Note: This current watcher-monitoring directory can be removed manually with:"
echo "   cd .. && rm -rf watcher-monitoring/"

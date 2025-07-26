#!/bin/bash
# manual_uninstall_guide.sh — Step-by-step manual uninstall guide

NODES=(
    "minipcamd.velociraptor-scylla.ts.net"
    "minipcamd2.velociraptor-scylla.ts.net"
    "minipcamd3.velociraptor-scylla.ts.net"
    "eliedesk.velociraptor-scylla.ts.net"
    "laptop.velociraptor-scylla.ts.net"
    # Add your 6th node here
)

echo "📋 Manual Uninstall Guide for Watcher-Monitoring"
echo "=============================================="
echo ""
echo "Since automated deployment failed due to sudo password requirements,"
echo "here are the exact commands to run on each node:"
echo ""

for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    if [[ -n "$node" ]]; then
        echo "🔸 Node $((i+1)): $node"
        echo "   1. SSH to the node:"
        echo "      ssh egk@$node"
        echo ""
        echo "   2. Copy and run the uninstall script:"
        echo "      curl -sL https://raw.githubusercontent.com/egk10/watcher-monitoring/main/uninstall.sh | sudo bash"
        echo ""
        echo "   Or alternatively:"
        echo "      wget -O /tmp/uninstall.sh https://raw.githubusercontent.com/egk10/watcher-monitoring/main/uninstall.sh"
        echo "      chmod +x /tmp/uninstall.sh"
        echo "      echo 'y' | sudo /tmp/uninstall.sh"
        echo ""
        echo "   3. Verify cleanup:"
        echo "      systemctl list-timers --all | grep -E 'watcher|update'"
        echo "      ls -la /usr/local/bin/watcher* /usr/local/bin/update_node.sh 2>/dev/null || echo 'No scripts found'"
        echo ""
        echo "   ─────────────────────────────────────────"
        echo ""
    fi
done

echo "🎯 Quick One-Liner for Each Node:"
echo "================================="
for node in "${NODES[@]}"; do
    if [[ -n "$node" ]]; then
        echo "ssh egk@$node 'curl -sL https://raw.githubusercontent.com/egk10/watcher-monitoring/main/uninstall.sh | sudo bash'"
    fi
done

echo ""
echo "📝 After running on all nodes, verify with:"
echo "./verify_cleanup.sh"

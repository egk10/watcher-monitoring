#!/bin/bash
# git_sync_uninstall.sh — Pull latest repo and run uninstall on all nodes

NODES=(
    "minipcamd.velociraptor-scylla.ts.net"
    "minipcamd2.velociraptor-scylla.ts.net"
    "minipcamd3.velociraptor-scylla.ts.net"
    # eliedesk already done
    # laptop already done
)

echo "🔄 Git sync and uninstall across nodes..."
echo ""

for node in "${NODES[@]}"; do
    if [[ -n "$node" ]]; then
        echo "🔄 Processing $node..."
        echo "  1. Connecting to $node"
        echo "  2. Pulling latest watcher-monitoring repo"
        echo "  3. Running uninstall script"
        echo ""
        
        ssh "egk@$node" 'cd ~/watcher-monitoring && git pull origin main && echo "y" | sudo ./uninstall.sh'
        
        if [[ $? -eq 0 ]]; then
            echo "✅ Successfully completed uninstall on $node"
        else
            echo "❌ Failed to complete uninstall on $node"
        fi
        echo ""
        echo "─────────────────────────────────────────"
        echo ""
    fi
done

echo "🎉 Git sync and uninstall completed for all nodes!"
echo ""
echo "📝 Run verification: ./verify_cleanup.sh"

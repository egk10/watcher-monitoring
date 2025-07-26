#!/bin/bash
# ssh_uninstall.sh — Interactive SSH-based uninstall for all nodes

NODES=(
    "minipcamd.velociraptor-scylla.ts.net"
    "minipcamd2.velociraptor-scylla.ts.net"
    "minipcamd3.velociraptor-scylla.ts.net"
    "laptop.velociraptor-scylla.ts.net"
    # Skip eliedesk since it's the current node and already done
    # Add your 6th node here
)

echo "🚀 Interactive SSH-based Uninstall"
echo "This will open an SSH session to each node where you can run the uninstall manually."
echo ""

for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    if [[ -n "$node" ]]; then
        echo "========================================"
        echo "🔸 Ready to process: $node"
        echo "========================================"
        echo ""
        echo "Commands to run once connected:"
        echo "  curl -sL https://github.com/egk10/watcher-monitoring/raw/main/uninstall.sh -o /tmp/uninstall.sh"
        echo "  chmod +x /tmp/uninstall.sh"
        echo "  echo 'y' | sudo /tmp/uninstall.sh"
        echo "  exit"
        echo ""
        read -p "Press Enter to SSH to $node (or Ctrl+C to skip)..."
        
        echo "🔗 Connecting to $node..."
        ssh "egk@$node"
        
        echo ""
        echo "✅ Disconnected from $node"
        echo ""
    fi
done

echo "🎉 All nodes processed!"
echo "Run './verify_cleanup.sh' to check the results."

#!/bin/bash
# deploy_uninstall.sh — Deploy uninstall script to all nodes via Tailscale
# 🚀 Automates uninstall across your 6-node cluster

set -e

# Add your 6 Tailscale node addresses here
NODES=(
    "minipcamd.velociraptor-scylla.ts.net"
    "minipcamd2.velociraptor-scylla.ts.net"
    "minipcamd3.velociraptor-scylla.ts.net"
    "eliedesk.velociraptor-scylla.ts.net"
    "laptop.velociraptor-scylla.ts.net"
    # Add your 6th node here - replace with actual hostname
    # "node6.velociraptor-scylla.ts.net"
)

SCRIPT_PATH="$(pwd)/uninstall.sh"
REMOTE_PATH="/tmp/uninstall.sh"

echo "🚀 Deploying uninstall script to all nodes..."
echo "📁 Local script: $SCRIPT_PATH"
echo ""

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "❌ Uninstall script not found: $SCRIPT_PATH"
    exit 1
fi

# Function to run uninstall on a single node
uninstall_node() {
    local node="$1"
    echo "🔄 Processing node: $node"
    
    # Copy script to remote node
    if scp "$SCRIPT_PATH" "egk@$node:$REMOTE_PATH"; then
        echo "  ✅ Script copied to $node"
        
        # Make executable and run
        if ssh "egk@$node" "chmod +x $REMOTE_PATH && echo 'y' | $REMOTE_PATH"; then
            echo "  ✅ Uninstall completed on $node"
            
            # Clean up remote script
            ssh "egk@$node" "rm -f $REMOTE_PATH" || true
        else
            echo "  ❌ Uninstall failed on $node"
            return 1
        fi
    else
        echo "  ❌ Failed to copy script to $node"
        return 1
    fi
    echo ""
}

# Process all nodes
FAILED_NODES=()
SUCCESSFUL_NODES=()

for node in "${NODES[@]}"; do
    if [[ -n "$node" ]]; then  # Skip empty entries
        if uninstall_node "$node"; then
            SUCCESSFUL_NODES+=("$node")
        else
            FAILED_NODES+=("$node")
        fi
    fi
done

# Summary
echo "📊 Uninstall Summary:"
echo "✅ Successful (${#SUCCESSFUL_NODES[@]} nodes):"
for node in "${SUCCESSFUL_NODES[@]}"; do
    echo "  • $node"
done

if [[ ${#FAILED_NODES[@]} -gt 0 ]]; then
    echo "❌ Failed (${#FAILED_NODES[@]} nodes):"
    for node in "${FAILED_NODES[@]}"; do
        echo "  • $node"
    done
    echo ""
    echo "⚠️  Please run uninstall manually on failed nodes:"
    echo "   scp uninstall.sh egk@<node>:/tmp/"
    echo "   ssh egk@<node> 'chmod +x /tmp/uninstall.sh && echo y | /tmp/uninstall.sh'"
fi

echo ""
if [[ ${#FAILED_NODES[@]} -eq 0 ]]; then
    echo "🎉 All nodes successfully uninstalled!"
    echo "🔔 No more automated notifications will be sent from any node"
else
    echo "⚠️  Some nodes failed - please check manually"
fi

echo ""
echo "🗑️ You can now safely delete this repository from all nodes if no longer needed"
echo "📧 Consider removing msmtp mail configuration manually if desired"

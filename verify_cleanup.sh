#!/bin/bash
# verify_cleanup.sh — Verify watcher-monitoring removal across all nodes

NODES=(
    "minipcamd.velociraptor-scylla.ts.net"
    "minipcamd2.velociraptor-scylla.ts.net"
    "minipcamd3.velociraptor-scylla.ts.net"
    "eliedesk.velociraptor-scylla.ts.net"
    "laptop.velociraptor-scylla.ts.net"
    # Add your 6th node here
    # "node6.velociraptor-scylla.ts.net"
)

echo "🔍 Verifying watcher-monitoring cleanup across all nodes..."
echo ""

for node in "${NODES[@]}"; do
    if [[ -n "$node" ]]; then
        echo "🔍 Checking node: $node"
        
        # Check for systemd timers
        TIMERS=$(ssh "egk@$node" "systemctl list-timers --all 2>/dev/null | grep -E 'watcher|update-node|update-watcher' || true")
        if [[ -n "$TIMERS" ]]; then
            echo "  ⚠️  WARNING: Found active timers:"
            echo "$TIMERS" | sed 's/^/    /'
        else
            echo "  ✅ No watcher timers found"
        fi
        
        # Check for systemd services
        SERVICES=$(ssh "egk@$node" "systemctl list-units --all 2>/dev/null | grep -E 'watcher|update-node|update-watcher' || true")
        if [[ -n "$SERVICES" ]]; then
            echo "  ⚠️  WARNING: Found services:"
            echo "$SERVICES" | sed 's/^/    /'
        else
            echo "  ✅ No watcher services found"
        fi
        
        # Check for remaining scripts
        SCRIPTS=$(ssh "egk@$node" "ls -la /usr/local/bin/watcher-* /usr/local/bin/update_node.sh 2>/dev/null || true")
        if [[ -n "$SCRIPTS" ]]; then
            echo "  ⚠️  WARNING: Found scripts:"
            echo "$SCRIPTS" | sed 's/^/    /'
        else
            echo "  ✅ No watcher scripts found"
        fi
        
        # Check for environment file
        ENV_EXISTS=$(ssh "egk@$node" "test -f /etc/watcher/.watcher.env && echo 'exists' || echo 'not found'")
        if [[ "$ENV_EXISTS" == "exists" ]]; then
            echo "  ⚠️  WARNING: Environment file still exists"
        else
            echo "  ✅ Environment file removed"
        fi
        
        echo ""
    fi
done

echo "🎉 Verification complete!"
echo "📝 If any warnings appear above, run the uninstall script on those nodes again."

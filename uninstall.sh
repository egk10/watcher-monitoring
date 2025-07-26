#!/bin/bash
# uninstall.sh — Complete removal of watcher-monitoring v3.3
# 🗑️ Removes all traces of the watcher monitoring system

set -e

VERSION="3.3"
ENV_FILE_DEST="/etc/watcher/.watcher.env"
SCRIPT_PATH="/usr/local/bin"
SYSTEMD_PATH="/etc/systemd/system"
HOSTNAME=$(hostname)
LOG_DIR="/var/log/${HOSTNAME}-watcher"

echo "🗑️ Starting complete uninstall of watcher-monitoring v$VERSION..."
echo "⚠️  This will remove all watcher scripts, timers, services, and logs."
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Uninstall cancelled."
    exit 1
fi

### 🛑 Stop and disable all systemd timers and services
stop_systemd_services() {
    echo "🛑 Stopping and disabling systemd timers and services..."
    
    # List of all watcher-related services and timers
    SERVICES=(
        "watcher-health.timer"
        "watcher-health.service" 
        "update-node.timer"
        "update-node.service"
        "update-watcher.timer"
        "update-watcher.service"
    )
    
    for service in "${SERVICES[@]}"; do
        echo "  Processing $service..."
        
        # Force stop the service first (ignore errors)
        sudo systemctl stop "$service" 2>/dev/null || true
        
        # Kill any running processes if stop doesn't work
        sudo systemctl kill "$service" 2>/dev/null || true
        
        # Disable the service
        sudo systemctl disable "$service" 2>/dev/null || true
        
        # Mask the service to prevent restart
        sudo systemctl mask "$service" 2>/dev/null || true
        
        # Remove systemd unit files
        if [[ -f "$SYSTEMD_PATH/$service" ]]; then
            echo "  🗑️ Removing $SYSTEMD_PATH/$service"
            sudo rm -f "$SYSTEMD_PATH/$service"
        fi
    done
    
    # Also check for any remaining watcher processes and kill them
    echo "  🔍 Checking for remaining watcher processes..."
    WATCHER_PIDS=$(pgrep -f "watcher-health\|update_node\|update-watcher" 2>/dev/null || true)
    if [[ -n "$WATCHER_PIDS" ]]; then
        echo "  🛑 Killing remaining watcher processes: $WATCHER_PIDS"
        sudo kill -9 $WATCHER_PIDS 2>/dev/null || true
    fi
    
    # Reload systemd to pick up changes
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
    
    # Unmask services after removal
    for service in "${SERVICES[@]}"; do
        sudo systemctl unmask "$service" 2>/dev/null || true
    done
    
    echo "✅ All systemd services stopped and disabled"
}

### 🗑️ Remove installed scripts
remove_scripts() {
    echo "🗑️ Removing installed scripts..."
    
    SCRIPTS=(
        "watcher-status.sh"
        "watcher-health.sh" 
        "update_node.sh"
    )
    
    for script in "${SCRIPTS[@]}"; do
        if [[ -f "$SCRIPT_PATH/$script" ]]; then
            echo "  🗑️ Removing $SCRIPT_PATH/$script"
            sudo rm -f "$SCRIPT_PATH/$script"
        fi
    done
    echo "✅ Scripts removed from $SCRIPT_PATH/"
}

### 🗑️ Remove environment file and directory
remove_env_file() {
    echo "🗑️ Removing environment configuration..."
    
    if [[ -f "$ENV_FILE_DEST" ]]; then
        echo "  🗑️ Removing $ENV_FILE_DEST"
        sudo rm -f "$ENV_FILE_DEST"
    fi
    
    if [[ -d "$(dirname "$ENV_FILE_DEST")" ]]; then
        # Only remove if directory is empty
        if [[ -z "$(ls -A "$(dirname "$ENV_FILE_DEST")" 2>/dev/null)" ]]; then
            echo "  🗑️ Removing empty directory $(dirname "$ENV_FILE_DEST")"
            sudo rmdir "$(dirname "$ENV_FILE_DEST")"
        fi
    fi
    echo "✅ Environment configuration removed"
}

### 🗑️ Remove log files and directory
remove_logs() {
    echo "🗑️ Removing log files..."
    
    if [[ -d "$LOG_DIR" ]]; then
        echo "  🗑️ Removing log directory $LOG_DIR"
        sudo rm -rf "$LOG_DIR"
    fi
    
    # Also remove any debug logs in /tmp
    if [[ -f "/tmp/update_node_debug.log" ]]; then
        echo "  🗑️ Removing debug log /tmp/update_node_debug.log"
        sudo rm -f "/tmp/update_node_debug.log"
    fi
    echo "✅ Log files removed"
}

### 🗑️ Remove mail configuration (optional)
remove_mail_config() {
    echo "🗑️ Checking mail configuration..."
    
    if [[ -f "$HOME/.msmtprc" ]]; then
        read -p "Remove msmtp configuration (~/.msmtprc)? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "  🗑️ Removing $HOME/.msmtprc"
            rm -f "$HOME/.msmtprc"
            
            if [[ -f "$HOME/.msmtp.log" ]]; then
                echo "  🗑️ Removing $HOME/.msmtp.log"
                rm -f "$HOME/.msmtp.log"
            fi
        fi
    fi
    echo "✅ Mail configuration checked"
}

### 🔍 Verify complete removal
verify_removal() {
    echo "🔍 Verifying complete removal..."
    
    # Check for any remaining systemd units
    REMAINING_UNITS=$(systemctl list-units --all | grep -E 'watcher-health|update-node|update-watcher' || true)
    if [[ -n "$REMAINING_UNITS" ]]; then
        echo "⚠️  WARNING: Some systemd units may still exist:"
        echo "$REMAINING_UNITS"
    fi
    
    # Check for any remaining timers
    REMAINING_TIMERS=$(systemctl list-timers --all | grep -E 'watcher-health|update-node|update-watcher' || true)
    if [[ -n "$REMAINING_TIMERS" ]]; then
        echo "⚠️  WARNING: Some timers may still be scheduled:"
        echo "$REMAINING_TIMERS"
    fi
    
    # Check for any remaining files
    REMAINING_FILES=""
    for path in "$SCRIPT_PATH/watcher-"*.sh "$SCRIPT_PATH/update_node.sh" "$ENV_FILE_DEST" "$LOG_DIR"; do
        if [[ -e "$path" ]]; then
            REMAINING_FILES="$REMAINING_FILES\n  $path"
        fi
    done
    
    if [[ -n "$REMAINING_FILES" ]]; then
        echo "⚠️  WARNING: Some files may still exist:$REMAINING_FILES"
    fi
    
    if [[ -z "$REMAINING_UNITS" && -z "$REMAINING_TIMERS" && -z "$REMAINING_FILES" ]]; then
        echo "✅ Complete removal verified - no traces found"
    fi
}

### 🎉 Success banner
success_banner() {
    echo ""
    echo "🎉 Uninstall complete - watcher-monitoring v$VERSION removed"
    echo "✅ Systemd timers and services removed"
    echo "✅ Scripts removed from $SCRIPT_PATH/"
    echo "✅ Environment configuration removed"
    echo "✅ Log files removed"
    echo ""
    echo "📝 What was removed:"
    echo "  • watcher-health.timer/service (health checks)"
    echo "  • update-node.timer/service (node updates)"
    echo "  • update-watcher.timer/service (watcher updates)"
    echo "  • All scripts from $SCRIPT_PATH/"
    echo "  • Environment file $ENV_FILE_DEST"
    echo "  • Log directory $LOG_DIR"
    echo ""
    echo "🔔 No more automated notifications will be sent"
    echo "📧 Mail configuration (msmtp) left intact unless manually removed"
    echo ""
    echo "🗑️ You can safely delete this repository directory if no longer needed."
}

### 🚀 Run all removal steps
echo "Starting uninstall process..."
stop_systemd_services
remove_scripts
remove_env_file
remove_logs
remove_mail_config
verify_removal
success_banner

echo ""
echo "✅ Uninstall completed successfully on $(hostname)"
echo "🔄 Run this script on all 6 nodes to complete removal from your cluster"
exit 0

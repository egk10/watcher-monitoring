#!/bin/bash
# check_env_sanity.sh — Validates required environment variables in .watcher.env

ENV_PATH="/etc/watcher/.watcher.env"
[ -f ".watcher.env" ] && ENV_PATH=".watcher.env"

echo "🔎 Checking environment file: $ENV_PATH"

# Required for core alerting
REQUIRED_VARS=("TELEGRAM_BOT_TOKEN" "TELEGRAM_CHAT_ID")
# Required if enforcing Gmail alerts
GMAIL_VARS=("GMAIL_USER" "GMAIL_PASS")

MISSING=0

check_var() {
    VAR=$1
    VALUE=$(grep "^$VAR=" "$ENV_PATH" | cut -d '=' -f2-)
    if [[ -z "$VALUE" ]]; then
        echo "❌ Missing: $VAR"
        MISSING=$((MISSING + 1))
    else
        echo "✅ Found:  $VAR"
    fi
}

echo "🔐 Required for Telegram alerts:"
for var in "${REQUIRED_VARS[@]}"; do
    check_var "$var"
done

echo "📧 Required for Gmail alerts (ENFORCED):"
for var in "${GMAIL_VARS[@]}"; do
    check_var "$var"
done

EXPORT_LINES=$(grep "^export " "$ENV_PATH" | wc -l)
if [[ "$EXPORT_LINES" -gt 0 ]]; then
    echo "⚠️ Found $EXPORT_LINES 'export' lines — that's fine, but not needed"
else
    echo "ℹ️ No 'export' detected — clean style confirmed"
fi

if [[ "$MISSING" -eq 0 ]]; then
    echo "✅ .watcher.env is complete and ready!"
    exit 0
else
    echo "🚫 Environment incomplete — please fix before running install."
    exit 1
fi

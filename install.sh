#!/bin/zsh
# install.sh — install mcp-cleanup and register it as a launchd agent
set -e

INSTALL_DIR="${MCP_CLEANUP_INSTALL_DIR:-$HOME/.local/bin}"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_LABEL="com.$(whoami).mcp-cleanup"
PLIST_FILE="$PLIST_DIR/$PLIST_LABEL.plist"
SCRIPT_NAME="mcp-cleanup"
SCRIPT_DEST="$INSTALL_DIR/$SCRIPT_NAME"
INTERVAL="${MCP_CLEANUP_INTERVAL:-300}"  # seconds between runs (default: 5 min)
LOG_FILE="/tmp/mcp-cleanup.log"

echo "Installing mcp-cleanup..."

# 1. Create install dir if needed
mkdir -p "$INSTALL_DIR"

# 2. Copy script
cp "$(dirname "$0")/$SCRIPT_NAME" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"
echo "  Script installed to $SCRIPT_DEST"

# 3. Write launchd plist
mkdir -p "$PLIST_DIR"
cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>

    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DEST</string>
    </array>

    <key>StartInterval</key>
    <integer>$INTERVAL</integer>

    <key>StandardOutPath</key>
    <string>$LOG_FILE</string>

    <key>StandardErrorPath</key>
    <string>$LOG_FILE</string>

    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
echo "  LaunchAgent written to $PLIST_FILE"

# 4. Load the agent (unload first in case it was already registered)
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"
echo "  LaunchAgent loaded (runs every ${INTERVAL}s)"

echo ""
echo "Done. mcp-cleanup will run automatically every ${INTERVAL} seconds."
echo "Logs: $LOG_FILE"
echo ""
echo "To run manually:  $SCRIPT_DEST"
echo "To dry-run:       MCP_CLEANUP_DRY_RUN=1 $SCRIPT_DEST"
echo "To uninstall:     ./uninstall.sh"

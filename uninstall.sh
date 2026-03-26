#!/bin/zsh
# uninstall.sh — remove mcp-cleanup and its launchd agent
set -e

INSTALL_DIR="${MCP_CLEANUP_INSTALL_DIR:-$HOME/.local/bin}"
PLIST_LABEL="com.$(whoami).mcp-cleanup"
PLIST_FILE="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
SCRIPT_DEST="$INSTALL_DIR/mcp-cleanup"

echo "Uninstalling mcp-cleanup..."

if [[ -f "$PLIST_FILE" ]]; then
  launchctl unload "$PLIST_FILE" 2>/dev/null || true
  rm -f "$PLIST_FILE"
  echo "  LaunchAgent removed"
fi

if [[ -f "$SCRIPT_DEST" ]]; then
  rm -f "$SCRIPT_DEST"
  echo "  Script removed from $SCRIPT_DEST"
fi

echo "Done."

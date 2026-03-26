# mcp-cleanup

A macOS utility that automatically kills orphaned MCP (Model Context Protocol) server processes left behind by Claude Code, Codex, Cursor, and other AI coding tools.

## The problem

Tools like Claude Code and Codex spawn MCP server processes (via `npm exec` / `npx`) for each session. When a session ends, the host app often fails to clean up its child processes. Over time, hundreds of zombie node processes accumulate — all silently consuming CPU and RAM, draining your battery.

A single runaway MCP server can consume 100% of a CPU core. With hundreds of stale instances, your Mac ends up throttling under full load 24/7.

## How it works

Two-layer detection:

1. **Broken pipe detection** (primary) — MCP servers communicate with their host app via a stdio pipe. When the host app closes its end of the pipe (session ended), the other end's inode disappears from all live process file descriptors. Any MCP server whose stdin pipe is no longer connected to anything gets killed.

2. **Excess duplicate detection** (fallback) — No single parent app should need more than `MAX_PER_TYPE` (default: 3) instances of the same MCP server type simultaneously. Oldest instances beyond that threshold are killed, keeping the newest ones alive.

Both checks are safe: actively used MCP servers will always pass check 1 (their pipe is live), and check 2's threshold is generous enough to accommodate multiple open project windows.

## Installation

```sh
git clone https://github.com/YOUR_USERNAME/mcp-cleanup
cd mcp-cleanup
chmod +x install.sh uninstall.sh mcp-cleanup
./install.sh
```

This installs the script to `~/.local/bin/mcp-cleanup` and registers a launchd agent that runs it every 5 minutes, starting immediately on login.

## Manual usage

```sh
# Run once
mcp-cleanup

# Dry run — see what would be killed without actually killing anything
MCP_CLEANUP_DRY_RUN=1 mcp-cleanup

# Check the auto-run log
cat /tmp/mcp-cleanup.log
```

## Configuration

All configuration is via environment variables. You can set these in your shell profile or override them at runtime:

| Variable | Default | Description |
|---|---|---|
| `MCP_CLEANUP_MAX_PER_TYPE` | `3` | Max live instances per MCP type per parent app |
| `MCP_CLEANUP_PATTERNS` | `xcodemcp playwright-mcp mcp-remote mcp-server-darwin-arm64` | Space-separated list of MCP binary names to watch |
| `MCP_CLEANUP_DRY_RUN` | `0` | Set to `1` to preview without killing |
| `MCP_CLEANUP_INTERVAL` | `300` | Seconds between auto-runs (only used at install time) |

### Adding custom MCP servers

If you use MCP servers not in the default list, add them:

```sh
# In ~/.zshrc or ~/.zprofile
export MCP_CLEANUP_PATTERNS="xcodemcp playwright-mcp mcp-remote my-custom-mcp"
```

Or override at runtime:

```sh
MCP_CLEANUP_PATTERNS="my-custom-mcp another-mcp" mcp-cleanup
```

## Uninstall

```sh
./uninstall.sh
```

## Requirements

- macOS (uses `launchd`, `lsof`, `pgrep`)
- zsh (pre-installed on all modern Macs)

## Why not just `pkill -f xcodemcp`?

That kills everything indiscriminately, including MCP servers for your currently active sessions. `mcp-cleanup` uses pipe state to distinguish live servers from dead ones, so your active sessions are never affected.

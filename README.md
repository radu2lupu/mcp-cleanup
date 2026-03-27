# mcp-cleanup

A macOS utility that automatically kills orphaned MCP (Model Context Protocol) server processes left behind by Claude Code, Codex, Cursor, Windsurf, Pencil, and other AI coding tools.

## The problem

AI coding tools spawn MCP server processes for each session. When a session ends, the host app often fails to clean up its child processes. Over time, hundreds of zombie processes accumulate — silently consuming CPU and RAM and draining your battery.

A single runaway MCP server can consume 100% of a CPU core. With hundreds of stale instances, your Mac ends up under full load 24/7.

## How it works

### Generic detection — no hardcoded names

Instead of matching on server names (which change as new MCP servers are installed), `mcp-cleanup` identifies candidates by *how they were spawned*:

| Signal | What it catches |
|---|---|
| Parent is `npm exec` or `npx` | Any stdio MCP server installed via npm |
| Runs from `~/.npm/_npx/` or `node_modules/.bin/` | Any npx-cached MCP server |
| Direct child of a known AI tool with `mcp` or `server` in path | Native binary MCP servers (e.g. Pencil's `mcp-server-darwin-arm64`) |

### Safe kill checks

Once candidates are identified, two checks decide whether to kill:

1. **Broken pipe** (primary) — MCP servers communicate with their host app via a stdio pipe. If the host closed its end of the pipe (session ended), the other end's inode disappears from all live process file descriptors. Those get killed immediately.

2. **Excess duplicates** (fallback) — No single parent app should need more than `MAX_PER_TYPE` (default: 3) instances of the same binary simultaneously. Oldest instances beyond the threshold are killed, keeping the newest ones.

Both checks are safe: an actively used MCP server will always pass check 1 (its pipe is live), and check 2's threshold is generous enough for multiple open project windows.

## Installation

```sh
git clone https://github.com/radu2lupu/mcp-cleanup
cd mcp-cleanup
./install.sh
```

This installs the script to `~/.local/bin/mcp-cleanup` and registers a launchd agent that runs it every 5 minutes, starting immediately on login.

## Manual usage

```sh
# Run once
mcp-cleanup

# Dry run — see what would be killed without killing anything
MCP_CLEANUP_DRY_RUN=1 mcp-cleanup

# Verbose dry run — see candidate detection details
MCP_CLEANUP_DRY_RUN=1 MCP_CLEANUP_VERBOSE=1 mcp-cleanup

# Check the auto-run log
cat /tmp/mcp-cleanup.log
```

## Configuration

All configuration is via environment variables. Set them in your shell profile or override at runtime:

| Variable | Default | Description |
|---|---|---|
| `MCP_CLEANUP_MAX_PER_TYPE` | `3` | Max live instances per binary name per parent app |
| `MCP_CLEANUP_EXTRA_HOSTS` | _(none)_ | Extra AI tool name patterns to watch, space-separated |
| `MCP_CLEANUP_DRY_RUN` | `0` | Set to `1` to preview without killing |
| `MCP_CLEANUP_VERBOSE` | `0` | Set to `1` to log candidate detection details |
| `MCP_CLEANUP_INTERVAL` | `300` | Seconds between auto-runs (only used at install time) |

### Adding a host app not in the default list

If you use an AI tool not covered by the defaults, add it:

```sh
# In ~/.zshrc or ~/.zprofile
export MCP_CLEANUP_EXTRA_HOSTS="MyAITool AnotherApp"
```

Default host patterns: `Claude`, `Codex`, `Cursor`, `Windsurf`, `Zed`, `Pencil`, `Codeium`, `Aide`, `Continue`

## Uninstall

```sh
./uninstall.sh
```

## Requirements

- macOS (uses `launchd`, `lsof`, `pgrep`)
- zsh (pre-installed on all modern Macs)

## Why not just `pkill -f xcodemcp`?

That kills everything indiscriminately, including MCP servers for your currently active sessions. `mcp-cleanup` uses pipe state to distinguish live servers from dead ones, so your active sessions are never affected. It also catches any MCP server regardless of name — you don't need to update it every time you install a new one.

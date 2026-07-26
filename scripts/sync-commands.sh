#!/usr/bin/env bash
# sync-commands.sh
# .cursor/commands/ is the CANONICAL source for all slash commands.
# .claude/commands/ is GENERATED from it by this script so Claude Code
# users get the same commands. Do not edit .claude/commands/ directly.
#
# Why real copies instead of a symlink: Claude Code's command discovery
# has repeatedly shipped regressions that silently skip symlinked files
# and directories in .claude/commands/ (see anthropics/claude-code
# issues #10573, #41451, #45547, #55791). Copies always work.
#
# Behavior:
#   - .cursor/commands/*.md is copied over .claude/commands/*.md
#   - a file that exists ONLY in .claude/commands is treated as a custom
#     command and adopted back into .cursor/commands (never deleted)
#   - to remove a command for real, delete it from BOTH directories
#
# Usage:
#   ./scripts/sync-commands.sh          # sync .cursor/commands -> .claude/commands
#   ./scripts/sync-commands.sh --check  # exit 1 if out of sync (for CI/hooks)

set -euo pipefail

cd "$(dirname "$0")/.."

SRC=".cursor/commands"
DST=".claude/commands"

if [ ! -d "$SRC" ]; then
    echo "sync-commands: $SRC not found" >&2
    exit 1
fi

if [ "${1:-}" = "--check" ]; then
    if diff -rq "$SRC" "$DST" >/dev/null 2>&1; then
        echo "sync-commands: in sync"
        exit 0
    else
        echo "sync-commands: OUT OF SYNC — run ./scripts/sync-commands.sh" >&2
        diff -rq "$SRC" "$DST" 2>&1 | head -20 >&2 || true
        exit 1
    fi
fi

mkdir -p "$DST"

# A file that exists only in .claude/commands is a custom command someone
# added on the Claude side — ADOPT it into the canonical dir, never delete it.
# (To intentionally remove a command, delete it from BOTH dirs.)
for f in "$DST"/*.md; do
    [ -e "$f" ] || continue
    name=$(basename "$f")
    if [ ! -e "$SRC/$name" ]; then
        cp "$f" "$SRC/$name"
        echo "adopted $DST/$name -> $SRC/$name (custom command found on Claude side; canonical home is $SRC)"
    fi
done

# Copy everything from canonical
synced=0
for f in "$SRC"/*.md; do
    name=$(basename "$f")
    if ! cmp -s "$f" "$DST/$name" 2>/dev/null; then
        cp "$f" "$DST/$name"
        synced=$((synced + 1))
    fi
done

echo "sync-commands: $synced file(s) updated in $DST"

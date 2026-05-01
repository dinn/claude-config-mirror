#!/usr/bin/env bash
# PostToolUse hook for Edit/Write on ~/.claude/CLAUDE.md.
# Reads PostToolUse JSON from stdin, runs extract.sh only when the
# touched file is the CLAUDE.md source.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PATH="$HOME/.claude/CLAUDE.md"

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [[ "$file_path" == "$TARGET_PATH" ]]; then
  exec "$REPO_DIR/extract.sh" >/dev/null 2>&1
fi

exit 0

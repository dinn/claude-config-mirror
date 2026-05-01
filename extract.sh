#!/usr/bin/env bash
# extract.sh — Sync whitelisted CLAUDE.md sections to this private mirror.
# WL-only: H2 headers in wl-sections.txt are mirrored; everything else is
# silently excluded. No denylist (which would itself leak header names).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${CLAUDE_MD_SOURCE:-$HOME/.claude/CLAUDE.md}"
WL_FILE="$REPO_DIR/wl-sections.txt"
TARGET="$REPO_DIR/CLAUDE.md"
GH_REPO="dinn/claude-config-mirror"

notify() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$2\" with title \"$1\"" 2>/dev/null || true
  fi
}

abort() {
  echo "❌ $1" >&2
  notify "claude-config-mirror" "$1"
  exit 1
}

[[ -f "$SOURCE" ]]  || abort "source not found: $SOURCE"
[[ -f "$WL_FILE" ]] || abort "wl-sections.txt not found"

cd "$REPO_DIR"

if git remote get-url origin >/dev/null 2>&1; then
  # Mirror is intentionally PUBLIC so the cloud audit routine can fetch raw content
  # without a PAT. Guard ensures it doesn't accidentally flip to PRIVATE (which would
  # break the routine). If you ever want to switch to PAT-based PRIVATE access, change
  # this guard accordingly.
  visibility=$(GH_HOST=github.com gh repo view "$GH_REPO" --json visibility -q .visibility 2>/dev/null || echo "UNKNOWN")
  if [[ "$visibility" != "PUBLIC" ]]; then
    abort "repo visibility is '$visibility', expected PUBLIC (so routine can fetch)"
  fi
fi

awk -v wl_file="$WL_FILE" '
BEGIN {
  while ((getline line < wl_file) > 0) {
    if (line ~ /^## /) wl[line] = 1
  }
  close(wl_file)
  in_match = 0
  emitted = 0
}
/^## / {
  if ($0 in wl) {
    if (emitted) print ""
    print $0
    emitted = 1
    in_match = 1
    next
  } else {
    in_match = 0
    next
  }
}
in_match == 1 { print }
' "$SOURCE" > "$TARGET.tmp"

mv "$TARGET.tmp" "$TARGET"

if git diff --quiet -- CLAUDE.md 2>/dev/null && git diff --cached --quiet -- CLAUDE.md 2>/dev/null && git ls-files --error-unmatch CLAUDE.md >/dev/null 2>&1; then
  echo "✓ no changes to sync"
  exit 0
fi

git add CLAUDE.md
git commit -q -m "sync: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

if git remote get-url origin >/dev/null 2>&1; then
  git push -q
  notify "claude-config-mirror" "synced"
  echo "✓ synced and pushed"
else
  echo "✓ committed locally (remote not configured yet)"
fi

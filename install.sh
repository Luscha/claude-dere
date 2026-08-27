#!/usr/bin/env bash
# claude-dere installer
#   curl -fsSL https://raw.githubusercontent.com/Luscha/claude-dere/main/install.sh | bash
#   ./install.sh yandere           # install one
#   ./install.sh --list            # show available
#   ./install.sh --uninstall       # remove all claude-dere styles
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Luscha/claude-dere/main"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/output-styles"
STYLES=(beatrice hinedere imouto-nya tsundere yandere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"

c()  { printf '\033[38;5;209m%s\033[0m\n' "$*"; }
ok() { printf '\033[38;5;114m  ✓\033[0m %s\n' "$*"; }
er() { printf '\033[38;5;203m  ✗\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
claude-dere — anime-archetype output styles for Claude Code

  ./install.sh                 install all styles
  ./install.sh yandere         install specific styles
  ./install.sh --list          list available styles
  ./install.sh --uninstall     remove all claude-dere styles

Installs to: $DEST
USAGE
}

fetch() {           # fetch <name> <target>
  local name="$1" target="$2"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/styles/$name.md" ]]; then
    cp "$SCRIPT_DIR/styles/$name.md" "$target"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW/styles/$name.md" -o "$target"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$target" "$REPO_RAW/styles/$name.md"
  else
    er "need curl or wget"; return 1
  fi
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --list)    printf '%s\n' "${STYLES[@]}"; exit 0 ;;
  --uninstall)
    for s in "${STYLES[@]}"; do
      [[ -f "$DEST/$s.md" ]] && rm -f "$DEST/$s.md" && ok "removed $s"
    done
    c "done. run /output-style in Claude Code to pick another."
    exit 0 ;;
esac

WANTED=("${STYLES[@]}")
if [[ $# -gt 0 ]]; then
  WANTED=()
  for arg in "$@"; do
    if printf '%s\n' "${STYLES[@]}" | grep -qx "$arg"; then
      WANTED+=("$arg")
    else
      er "unknown style: $arg"; printf '%s\n' "available: ${STYLES[*]}" >&2; exit 1
    fi
  done
fi

mkdir -p "$DEST"
c "installing to $DEST"
for s in "${WANTED[@]}"; do
  tmp="$(mktemp)"
  if fetch "$s" "$tmp"; then
    if [[ -s "$tmp" ]] && head -1 "$tmp" | grep -q '^---$'; then
      mv "$tmp" "$DEST/$s.md"; chmod 644 "$DEST/$s.md"; ok "$s"
    else
      rm -f "$tmp"; er "$s — downloaded file looks wrong, skipped"
    fi
  else
    rm -f "$tmp"; er "$s — download failed"
  fi
done

c ""
c "installed. in Claude Code, run:  /output-style"
c "then pick one of the five."

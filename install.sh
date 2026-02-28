#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPGRADE=0

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --upgrade) UPGRADE=1 ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# ── Logging ───────────────────────────────────────────────────────────────────
info()    { echo "  [info] $*"; }
success() { echo "  [ ok ] $*"; }
warning() { echo "  [warn] $*"; }
error()   { echo "  [err ] $*" >&2; }

# ── Placeholder main ──────────────────────────────────────────────────────────
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"
  success "Done."
}

main

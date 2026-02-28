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

# ── Xcode Command Line Tools ──────────────────────────────────────────────────
install_xcode_clt() {
  if xcode-select -p &>/dev/null; then
    info "Xcode CLT already installed"
    return
  fi
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
  success "Xcode CLT installed"
}

# ── Homebrew ──────────────────────────────────────────────────────────────────
install_homebrew() {
  if command -v brew &>/dev/null; then
    info "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon Macs
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew installed"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"
  install_xcode_clt
  install_homebrew
  success "Done."
}

main

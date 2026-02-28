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

# ── Packages ──────────────────────────────────────────────────────────────────
install_packages() {
  info "Installing packages from Brewfile..."
  if [[ "$UPGRADE" == "1" ]]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile"
  else
    brew bundle --no-upgrade --file="$DOTFILES_DIR/Brewfile"
  fi
  success "Packages installed"
}

# ── Symlink engine ────────────────────────────────────────────────────────────
# Reads packages/<name>/symlinks.conf and creates symlinks.
# Format per line:  source -> $HOME/destination
link_package() {
  local pkg="$1"
  local pkg_dir="$DOTFILES_DIR/packages/$pkg"
  local conf="$pkg_dir/symlinks.conf"

  [[ -f "$conf" ]] || return 0

  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    local src dest
    src="${line%% -> *}"
    dest="${line##* -> }"
    # Strip leading/trailing whitespace
    src="${src#"${src%%[![:space:]]*}"}"
    src="${src%"${src##*[![:space:]]}"}"
    dest="${dest#"${dest%%[![:space:]]*}"}"
    dest="${dest%"${dest##*[![:space:]]}"}"
    # Expand $HOME
    dest="${dest/\$HOME/$HOME}"

    local src_path="$pkg_dir/$src"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    # Verify source exists
    if [[ ! -e "$src_path" ]]; then
      warning "Source not found, skipping: $src_path"
      continue
    fi

    # Create parent directory
    mkdir -p "$dest_dir"

    # Already linked correctly — skip
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src_path" ]]; then
      info "Already linked: $dest"
      continue
    fi

    # Real file/dir exists — prompt before overwriting
    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
      read -rp "  [warn] $dest exists. Overwrite? [y/N] " answer
      if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        info "Skipping $dest"
        continue
      fi
      rm -rf "$dest"
    fi

    # Remove stale symlink
    [[ -L "$dest" ]] && rm "$dest"

    ln -s "$src_path" "$dest"
    success "Linked: $dest"
  done < "$conf"
}

link_all() {
  for pkg_dir in "$DOTFILES_DIR/packages"/*/; do
    local pkg
    pkg="$(basename "$pkg_dir")"
    link_package "$pkg"
  done
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"
  install_xcode_clt
  install_homebrew
  install_packages
  link_all
  success "Done."
}

main

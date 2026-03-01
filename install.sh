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
  if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    until xcode-select -p &>/dev/null; do sleep 5; done
    success "Xcode CLT installed"
    return
  fi

  if [[ "$UPGRADE" == "1" ]]; then
    info "Checking for Xcode CLT updates..."
    local label
    label="$(softwareupdate --list 2>/dev/null | grep '^\* Label:.*[Cc]ommand [Ll]ine [Tt]ools' | sed 's/^\* Label: //' | xargs)" || true
    if [[ -n "$label" ]]; then
      info "Updating Xcode CLT: $label"
      softwareupdate --install "$label" --agree-to-license
      success "Xcode CLT updated"
    else
      info "Xcode CLT already up to date"
    fi
  else
    info "Xcode CLT already installed"
  fi
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
  info "Updating Homebrew..."
  brew update
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
      read -rp "  [warn] $dest exists. Overwrite? [y/N] " answer </dev/tty || answer=""
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

# ── Package hooks ─────────────────────────────────────────────────────────────
# Sources packages/<name>/install.sh if it exists.
# Hooks receive $DOTFILES_DIR and $UPGRADE as env vars.
run_hook() {
  local pkg="$1"
  local hook="$DOTFILES_DIR/packages/$pkg/install.sh"
  [[ -f "$hook" ]] || return 0
  info "Running hook: $pkg"
  # shellcheck source=/dev/null
  source "$hook"
}

# ── Default shell ─────────────────────────────────────────────────────────────
set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "$SHELL" == "$zsh_path" ]]; then
    info "zsh is already the default shell"
    return
  fi
  if ! grep -qF "$zsh_path" /etc/shells; then
    echo "$zsh_path" | sudo tee -a /etc/shells
  fi
  chsh -s "$zsh_path"
  success "Default shell set to zsh"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"

  install_xcode_clt
  install_homebrew
  install_packages
  link_all

  # Hooks run in explicit order — dependencies first
  run_hook "zsh"
  run_hook "nvim"
  run_hook "node"
  run_hook "python"
  run_hook "rectangle"

  set_default_shell

  echo ""
  success "Dotfiles installed. Restart your terminal."
}

main

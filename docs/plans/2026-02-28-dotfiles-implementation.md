# Dotfiles Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the Ruby/Rake dotfiles with a self-contained bash script that installs a full macOS dev environment idempotently from a single `./install.sh` invocation.

**Architecture:** A `Brewfile` manages all software. Each tool gets a `packages/<name>/` directory containing its config files and a `symlinks.conf` that maps source files to destination paths. The main `install.sh` orchestrates: Xcode CLT → Homebrew → brew bundle → symlinks → per-package hooks → default shell.

**Tech Stack:** Bash, Homebrew (brew bundle), ln -s, defaults (for plist), fnm, pyenv, lazy.nvim

---

## Phase 1: Infrastructure

### Task 1: Generate Brewfile from current environment

**Files:**
- Create: `Brewfile`

**Step 1: Dump current environment**

```bash
cd ~/code/dotfiles
brew bundle dump --file=Brewfile --describe --force
```

**Step 2: Open Brewfile and curate it**

Remove anything work-specific or no longer needed. Ensure these casks are present (add manually if missing):

```ruby
# Add these casks if not already present:
cask "ghostty"
cask "claude-code"
cask "codex"
cask "rectangle"
cask "chatgpt"
cask "figma"
cask "1password"
cask "google-chrome"
cask "linear-linear"
cask "whatsapp"

# Add font tap and font:
tap "homebrew/cask-fonts"
cask "font-hack-nerd-font"
```

Remove the `vscode` lines if any (not tracked here).

**Step 3: Verify Brewfile is valid**

```bash
brew bundle check --file=Brewfile
```

Expected: `The Brewfile's dependencies are satisfied.`

**Step 4: Commit**

```bash
git add Brewfile
git commit -m "feat: add Brewfile from current environment"
```

---

### Task 2: Create repo skeleton and .gitignore

**Files:**
- Create: `.gitignore`
- Remove: `Rakefile`, `README.md` (old), `vimrc`, `vimrc.plugins`, `gitconfig` (root-level), `zshrc` (root-level), `tmux.conf` (root-level)
- Create: `packages/` (directory, via later tasks)

**Step 1: Create .gitignore**

```bash
cat > ~/code/dotfiles/.gitignore << 'EOF'
# Machine-specific nvim config
packages/nvim/lua/local/

# Auth and secrets
packages/codex/auth.json
packages/claude-code/anthropic_key.sh

# Backups
packages/nvim/backups/
EOF
```

**Step 2: Remove old files**

```bash
cd ~/code/dotfiles
git rm Rakefile vimrc vimrc.plugins gitconfig zshrc tmux.conf README.md
git rm -r custom_zsh_plugins .tmuxinator
```

**Step 3: Verify tree looks clean**

```bash
ls ~/code/dotfiles
# Expected: Brewfile  .git  .gitignore  docs/
```

**Step 4: Commit**

```bash
git add .gitignore
git commit -m "feat: clean repo and add .gitignore"
```

---

### Task 3: Write install.sh — skeleton with args and logging

**Files:**
- Create: `install.sh`

**Step 1: Create the script**

```bash
cat > ~/code/dotfiles/install.sh << 'EOF'
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
EOF
chmod +x ~/code/dotfiles/install.sh
```

**Step 2: Run it to verify**

```bash
~/code/dotfiles/install.sh
# Expected:
#   [info] Dotfiles install starting (UPGRADE=0)
#   [ ok ] Done.

~/code/dotfiles/install.sh --upgrade
# Expected: UPGRADE=1 in output
```

**Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add install.sh skeleton with arg parsing and logging"
```

---

### Task 4: Add Xcode CLT and Homebrew installation

**Files:**
- Modify: `install.sh`

**Step 1: Add functions before `main()`**

Add after the logging section:

```bash
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
```

**Step 2: Update `main()`**

```bash
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"
  install_xcode_clt
  install_homebrew
  success "Done."
}
```

**Step 3: Verify (Xcode CLT and brew already present — should skip)**

```bash
~/code/dotfiles/install.sh
# Expected:
#   [info] Xcode CLT already installed
#   [info] Homebrew already installed
```

**Step 4: Commit**

```bash
git add install.sh
git commit -m "feat: add Xcode CLT and Homebrew installation steps"
```

---

### Task 5: Add brew bundle step

**Files:**
- Modify: `install.sh`

**Step 1: Add function**

```bash
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
```

**Step 2: Update `main()`**

```bash
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"
  install_xcode_clt
  install_homebrew
  install_packages
  success "Done."
}
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
# Expected: "Packages installed" — everything already present so fast
```

**Step 4: Commit**

```bash
git add install.sh
git commit -m "feat: add brew bundle package installation step"
```

---

### Task 6: Write symlink engine

**Files:**
- Modify: `install.sh`

**Step 1: Add `link_package` and `link_all` functions**

```bash
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
```

**Step 2: Update `main()` to call `link_all`**

```bash
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"
  install_xcode_clt
  install_homebrew
  install_packages
  link_all
  success "Done."
}
```

**Step 3: Create a test package to verify**

```bash
mkdir -p ~/code/dotfiles/packages/_test
echo "test_file -> \$HOME/.dotfiles_test" > ~/code/dotfiles/packages/_test/symlinks.conf
echo "hello" > ~/code/dotfiles/packages/_test/test_file
~/code/dotfiles/install.sh
# Expected: "Linked: /Users/<you>/.dotfiles_test"
ls -la ~/.dotfiles_test
# Expected: symlink pointing to packages/_test/test_file
```

**Step 4: Clean up test package**

```bash
rm -rf ~/code/dotfiles/packages/_test
rm ~/.dotfiles_test
```

**Step 5: Commit**

```bash
git add install.sh
git commit -m "feat: add symlink engine with idempotent link_all"
```

---

### Task 7: Add package hooks runner and finalize main()

**Files:**
- Modify: `install.sh`

**Step 1: Add `run_hook` and `set_default_shell` functions**

```bash
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
```

**Step 2: Finalize `main()` with hook execution order**

```bash
main() {
  info "Dotfiles install starting (UPGRADE=$UPGRADE)"

  install_xcode_clt
  install_homebrew
  install_packages
  link_all

  # Hooks run in explicit order — dependencies first
  run_hook "zsh"
  run_hook "node"
  run_hook "python"
  run_hook "rectangle"

  set_default_shell

  echo ""
  success "Dotfiles installed. Restart your terminal."
}
```

**Step 3: Verify (no hooks exist yet — should silently skip)**

```bash
~/code/dotfiles/install.sh
# Expected: completes without error, "zsh is already the default shell"
```

**Step 4: Commit**

```bash
git add install.sh
git commit -m "feat: add package hook runner and finalize main() orchestration"
```

---

## Phase 2: Config Packages

> For each package: copy config files, write symlinks.conf, verify symlinks, commit.

### Task 8: zsh package

**Files:**
- Create: `packages/zsh/.zshrc`
- Create: `packages/zsh/symlinks.conf`
- Create: `packages/zsh/custom_plugins/` (directory with plugin files)

**Step 1: Copy files**

```bash
mkdir -p ~/code/dotfiles/packages/zsh/custom_plugins
cp ~/.zshrc ~/code/dotfiles/packages/zsh/.zshrc
cp ~/.config/zsh/custom_plugins/*.zsh ~/code/dotfiles/packages/zsh/custom_plugins/ 2>/dev/null || true
# Or from the old dotfiles location if plugins are elsewhere:
# ls ~/.zsh/custom_plugins/ or wherever they live
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/zsh/symlinks.conf << 'EOF'
.zshrc -> $HOME/.zshrc
EOF
```

Note: if custom_plugins are sourced from a specific path in `.zshrc`, add that symlink too. Check `.zshrc` for the source path and adjust accordingly.

**Step 3: Verify**

```bash
# Remove existing symlink if present, then re-run
~/code/dotfiles/install.sh
ls -la ~/.zshrc
# Expected: symlink -> ~/code/dotfiles/packages/zsh/.zshrc
```

**Step 4: Commit**

```bash
git add packages/zsh/
git commit -m "feat: add zsh package with .zshrc"
```

---

### Task 9: ghostty package

**Files:**
- Create: `packages/ghostty/config`
- Create: `packages/ghostty/symlinks.conf`

**Step 1: Copy config**

```bash
mkdir -p ~/code/dotfiles/packages/ghostty
cp ~/.config/ghostty/config ~/code/dotfiles/packages/ghostty/config
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/ghostty/symlinks.conf << 'EOF'
config -> $HOME/.config/ghostty/config
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/ghostty/config
# Expected: symlink -> ~/code/dotfiles/packages/ghostty/config
```

**Step 4: Commit**

```bash
git add packages/ghostty/
git commit -m "feat: add ghostty package"
```

---

### Task 10: starship package

**Files:**
- Create: `packages/starship/starship.toml`
- Create: `packages/starship/symlinks.conf`

**Step 1: Copy config**

```bash
mkdir -p ~/code/dotfiles/packages/starship
cp ~/.config/starship.toml ~/code/dotfiles/packages/starship/starship.toml
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/starship/symlinks.conf << 'EOF'
starship.toml -> $HOME/.config/starship.toml
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/starship.toml
# Expected: symlink -> ~/code/dotfiles/packages/starship/starship.toml
```

**Step 4: Commit**

```bash
git add packages/starship/
git commit -m "feat: add starship package"
```

---

### Task 11: tmux package

**Files:**
- Create: `packages/tmux/tmux.conf`
- Create: `packages/tmux/symlinks.conf`

**Step 1: Copy config**

```bash
mkdir -p ~/code/dotfiles/packages/tmux
cp ~/.config/tmux/tmux.conf ~/code/dotfiles/packages/tmux/tmux.conf
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/tmux/symlinks.conf << 'EOF'
tmux.conf -> $HOME/.config/tmux/tmux.conf
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/tmux/tmux.conf
# Expected: symlink -> ~/code/dotfiles/packages/tmux/tmux.conf
```

**Step 4: Commit**

```bash
git add packages/tmux/
git commit -m "feat: add tmux package"
```

---

### Task 12: tmux-powerline package

**Files:**
- Create: `packages/tmux-powerline/` (mirror of `~/.config/tmux-powerline/`)
- Create: `packages/tmux-powerline/symlinks.conf`

**Step 1: Copy config**

```bash
mkdir -p ~/code/dotfiles/packages/tmux-powerline
cp -r ~/.config/tmux-powerline/config.sh ~/code/dotfiles/packages/tmux-powerline/
cp -r ~/.config/tmux-powerline/segments ~/code/dotfiles/packages/tmux-powerline/
cp -r ~/.config/tmux-powerline/themes ~/code/dotfiles/packages/tmux-powerline/
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/tmux-powerline/symlinks.conf << 'EOF'
config.sh -> $HOME/.config/tmux-powerline/config.sh
segments -> $HOME/.config/tmux-powerline/segments
themes -> $HOME/.config/tmux-powerline/themes
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/tmux-powerline/config.sh
# Expected: symlink
```

**Step 4: Commit**

```bash
git add packages/tmux-powerline/
git commit -m "feat: add tmux-powerline package"
```

---

### Task 13: git package

**Files:**
- Create: `packages/git/gitconfig`
- Create: `packages/git/symlinks.conf`

**Step 1: Copy config**

`~/.gitconfig` is at the home root (not under `~/.config/git`):

```bash
mkdir -p ~/code/dotfiles/packages/git
cp ~/.gitconfig ~/code/dotfiles/packages/git/gitconfig
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/git/symlinks.conf << 'EOF'
gitconfig -> $HOME/.gitconfig
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.gitconfig
# Expected: symlink -> ~/code/dotfiles/packages/git/gitconfig
```

**Step 4: Commit**

```bash
git add packages/git/
git commit -m "feat: add git package"
```

---

### Task 14: gh package

**Files:**
- Create: `packages/gh/config.yml`
- Create: `packages/gh/symlinks.conf`

> **Note:** `~/.config/gh/hosts.yml` contains OAuth tokens. Do NOT copy it.

**Step 1: Copy config only (not hosts.yml)**

```bash
mkdir -p ~/code/dotfiles/packages/gh
cp ~/.config/gh/config.yml ~/code/dotfiles/packages/gh/config.yml
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/gh/symlinks.conf << 'EOF'
config.yml -> $HOME/.config/gh/config.yml
EOF
```

**Step 3: Add hosts.yml to .gitignore**

```bash
echo "packages/gh/hosts.yml" >> ~/code/dotfiles/.gitignore
```

**Step 4: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/gh/config.yml
# Expected: symlink
```

**Step 5: Commit**

```bash
git add packages/gh/ .gitignore
git commit -m "feat: add gh package (config only, hosts.yml excluded)"
```

---

### Task 15: glow package

**Files:**
- Create: `packages/glow/glow.yml`
- Create: `packages/glow/symlinks.conf`

**Step 1: Copy config**

```bash
mkdir -p ~/code/dotfiles/packages/glow
cp ~/.config/glow/glow.yml ~/code/dotfiles/packages/glow/glow.yml
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/glow/symlinks.conf << 'EOF'
glow.yml -> $HOME/.config/glow/glow.yml
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/glow/glow.yml
# Expected: symlink
```

**Step 4: Commit**

```bash
git add packages/glow/
git commit -m "feat: add glow package"
```

---

### Task 16: alacritty package

**Files:**
- Create: `packages/alacritty/alacritty.toml`
- Create: `packages/alacritty/symlinks.conf`

**Step 1: Copy config (skip the .bak file)**

```bash
mkdir -p ~/code/dotfiles/packages/alacritty
cp ~/.config/alacritty/alacritty.toml ~/code/dotfiles/packages/alacritty/alacritty.toml
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/alacritty/symlinks.conf << 'EOF'
alacritty.toml -> $HOME/.config/alacritty/alacritty.toml
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/alacritty/alacritty.toml
# Expected: symlink
```

**Step 4: Commit**

```bash
git add packages/alacritty/
git commit -m "feat: add alacritty package"
```

---

### Task 17: mole package

**Files:**
- Create: `packages/mole/config.sh`
- Create: `packages/mole/symlinks.conf`

> **Note:** Inspect `~/.config/mole/config.sh` before copying — it may contain hostnames or credentials. Remove any before committing.

**Step 1: Inspect then copy**

```bash
cat ~/.config/mole/config.sh
# Review output. Remove any credentials/hostnames/IPs.
mkdir -p ~/code/dotfiles/packages/mole
cp ~/.config/mole/config.sh ~/code/dotfiles/packages/mole/config.sh
# Edit to sanitize if needed:
# vim ~/code/dotfiles/packages/mole/config.sh
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/mole/symlinks.conf << 'EOF'
config.sh -> $HOME/.config/mole/config.sh
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.config/mole/config.sh
# Expected: symlink
```

**Step 4: Commit**

```bash
git add packages/mole/
git commit -m "feat: add mole package"
```

---

### Task 18: nvim package — copy config and refactor init.lua for local overrides

**Files:**
- Create: `packages/nvim/` (mirror of `~/.config/nvim/`)
- Create: `packages/nvim/symlinks.conf`
- Modify: `packages/nvim/init.lua` (add local overrides support)

**Step 1: Copy entire nvim config**

```bash
mkdir -p ~/code/dotfiles/packages/nvim
cp -r ~/.config/nvim/init.lua ~/code/dotfiles/packages/nvim/
cp -r ~/.config/nvim/lazy-lock.json ~/code/dotfiles/packages/nvim/
cp -r ~/.config/nvim/lua ~/code/dotfiles/packages/nvim/
# Do NOT copy backups/ or doc/
```

**Step 2: Create `lua/local/` directory with .gitkeep and gitignore**

```bash
mkdir -p ~/code/dotfiles/packages/nvim/lua/local
touch ~/code/dotfiles/packages/nvim/lua/local/.gitkeep
```

The `.gitignore` already excludes `packages/nvim/lua/local/` — verify:
```bash
grep "local" ~/code/dotfiles/.gitignore
# Expected: packages/nvim/lua/local/
```

But `.gitkeep` itself should be tracked. Update `.gitignore` to be more specific:
```bash
# In .gitignore, change:
#   packages/nvim/lua/local/
# To:
#   packages/nvim/lua/local/*
#   !packages/nvim/lua/local/.gitkeep
```

**Step 3: Refactor `packages/nvim/init.lua` — extract DBUI into local plugin**

Find the DBUI plugin block in `init.lua` (around line 277). It looks like:

```lua
{
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
  config = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_factories = { 'f2', 'f3' }
    -- ... load_db_connections and all the machine-specific logic ...
  end,
},
```

Replace the entire DBUI block's `config` function with a delegation to `local.dbui`:

```lua
{
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
  config = function()
    vim.g.db_ui_use_nerd_fonts = 1
    -- Machine-local DBUI config lives in lua/local/dbui.lua (gitignored)
    pcall(require, 'local.dbui')
  end,
},
```

**Step 4: Add general local override at end of init.lua**

Find the last line of `init.lua` (the modeline comment):
```lua
-- vim: ts=2 sts=2 sw=2 et
```

Insert before it:
```lua
-- Machine-local configuration overrides (lua/local/init.lua, gitignored)
pcall(require, 'local')

-- vim: ts=2 sts=2 sw=2 et
```

**Step 5: Create `lua/local/dbui.lua` on your current machine (NOT tracked)**

```bash
# This file lives only on this machine, not in the repo
cat > ~/.config/nvim/lua/local/dbui.lua << 'EOF'
-- Machine-specific DBUI configuration
-- This file is gitignored and must be created manually per machine.

vim.g.db_ui_factories = { 'f2', 'f3' }

local function load_db_connections(opts)
  -- paste your existing load_db_connections implementation here
end

load_db_connections()

vim.api.nvim_create_user_command('DBUIRefresh',
  function() load_db_connections { refresh = true } end,
  { desc = 'Refresh dadbod-ui database connections (force vault re-fetch)' }
)

-- paste DBUIExportCSV command here too
EOF
```

(Paste the full existing implementations from `init.lua` into this file.)

**Step 6: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/nvim/symlinks.conf << 'EOF'
init.lua -> $HOME/.config/nvim/init.lua
lazy-lock.json -> $HOME/.config/nvim/lazy-lock.json
lua -> $HOME/.config/nvim/lua
EOF
```

**Step 7: Verify — open nvim and confirm DBUI still works**

```bash
~/code/dotfiles/install.sh
# Manually run and check no errors:
nvim -c "checkhealth" -c "q"
# Launch nvim and run :DBUI — should work as before (local/dbui.lua is in place)
```

**Step 8: Commit**

```bash
git add packages/nvim/
git commit -m "feat: add nvim package with local override support for DBUI"
```

---

### Task 19: rectangle package

**Files:**
- Create: `packages/rectangle/rectangle.plist`
- Create: `packages/rectangle/install.sh`

> No `symlinks.conf` — rectangle uses `defaults import/export` instead of symlinks.

**Step 1: Export current rectangle preferences**

```bash
mkdir -p ~/code/dotfiles/packages/rectangle
defaults export com.knollsoft.Rectangle ~/code/dotfiles/packages/rectangle/rectangle.plist
```

**Step 2: Write install hook**

```bash
cat > ~/code/dotfiles/packages/rectangle/install.sh << 'EOF'
#!/usr/bin/env bash
PLIST="$DOTFILES_DIR/packages/rectangle/rectangle.plist"

if [[ ! -f "$PLIST" ]]; then
  warning "rectangle.plist not found, skipping"
  return
fi

defaults import com.knollsoft.Rectangle "$PLIST"
success "Rectangle preferences imported"
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
# Expected: "Rectangle preferences imported"
```

**Step 4: Commit**

```bash
git add packages/rectangle/
git commit -m "feat: add rectangle package with plist import"
```

---

### Task 20: codex package

**Files:**
- Create: `packages/codex/config.toml`
- Create: `packages/codex/symlinks.conf`

**Step 1: Copy config (not auth.json)**

```bash
mkdir -p ~/code/dotfiles/packages/codex
cp ~/.codex/config.toml ~/code/dotfiles/packages/codex/config.toml
```

**Step 2: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/codex/symlinks.conf << 'EOF'
config.toml -> $HOME/.codex/config.toml
EOF
```

**Step 3: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.codex/config.toml
# Expected: symlink
```

**Step 4: Commit**

```bash
git add packages/codex/
git commit -m "feat: add codex package"
```

---

### Task 21: claude-code package

**Files:**
- Create: `packages/claude-code/settings.json`
- Create: `packages/claude-code/symlinks.conf`

**Step 1: Copy settings only**

```bash
mkdir -p ~/code/dotfiles/packages/claude-code
cp ~/.claude/settings.json ~/code/dotfiles/packages/claude-code/settings.json
```

**Step 2: Review settings.json for any secrets before committing**

```bash
cat ~/code/dotfiles/packages/claude-code/settings.json
# Make sure no API keys or sensitive data is present
```

**Step 3: Write symlinks.conf**

```bash
cat > ~/code/dotfiles/packages/claude-code/symlinks.conf << 'EOF'
settings.json -> $HOME/.claude/settings.json
EOF
```

**Step 4: Verify**

```bash
~/code/dotfiles/install.sh
ls -la ~/.claude/settings.json
# Expected: symlink
```

**Step 5: Commit**

```bash
git add packages/claude-code/
git commit -m "feat: add claude-code package"
```

---

## Phase 3: Package Hooks

### Task 22: zsh hook — set default shell

**Files:**
- Create: `packages/zsh/install.sh`

**Step 1: Write hook**

```bash
cat > ~/code/dotfiles/packages/zsh/install.sh << 'EOF'
#!/usr/bin/env bash
# Sets zsh as the default shell — also handled in main install.sh.
# This hook is a no-op; default shell is set by set_default_shell() in install.sh.
EOF
```

> The default shell is already handled by `set_default_shell()` in `install.sh`. This file exists as a placeholder for future zsh-specific setup (e.g. zsh plugin manager if you add one).

**Step 2: Commit**

```bash
git add packages/zsh/install.sh
git commit -m "feat: add zsh hook placeholder"
```

---

### Task 23: node hook — fnm + Node LTS

**Files:**
- Create: `packages/node/install.sh`

**Step 1: Write hook**

```bash
mkdir -p ~/code/dotfiles/packages/node
cat > ~/code/dotfiles/packages/node/install.sh << 'EOF'
#!/usr/bin/env bash
if ! command -v fnm &>/dev/null; then
  warning "fnm not found — was it installed via Brewfile? Skipping node setup."
  return
fi

# Load fnm into current shell
eval "$(fnm env --use-on-cd 2>/dev/null)"

if fnm list 2>/dev/null | grep -q "lts-latest" && [[ "$UPGRADE" != "1" ]]; then
  info "Node LTS already installed"
  fnm default lts-latest 2>/dev/null || true
  return
fi

info "Installing Node LTS via fnm..."
fnm install --lts
fnm default lts-latest
success "Node $(fnm current) installed and set as default"
EOF
```

**Step 2: Verify**

```bash
~/code/dotfiles/install.sh
# Expected: "Node LTS already installed" (since fnm and node are already set up)
```

**Step 3: Commit**

```bash
git add packages/node/
git commit -m "feat: add node hook with fnm LTS install"
```

---

### Task 24: python hook — pyenv + latest Python 3

**Files:**
- Create: `packages/python/install.sh`

**Step 1: Write hook**

```bash
mkdir -p ~/code/dotfiles/packages/python
cat > ~/code/dotfiles/packages/python/install.sh << 'EOF'
#!/usr/bin/env bash
if ! command -v pyenv &>/dev/null; then
  warning "pyenv not found — was it installed via Brewfile? Skipping python setup."
  return
fi

latest="$(pyenv latest 3 2>/dev/null)"
if [[ -z "$latest" ]]; then
  warning "Could not determine latest Python 3 version"
  return
fi

if pyenv versions 2>/dev/null | grep -q "$latest" && [[ "$UPGRADE" != "1" ]]; then
  info "Python $latest already installed"
  pyenv global "$latest"
  return
fi

info "Installing Python $latest via pyenv..."
pyenv install --skip-existing "$latest"
pyenv global "$latest"
success "Python $latest installed and set as global"
EOF
```

**Step 2: Verify**

```bash
~/code/dotfiles/install.sh
# Expected: "Python 3.x.x already installed"
```

**Step 3: Commit**

```bash
git add packages/python/
git commit -m "feat: add python hook with pyenv latest install"
```

---

## Phase 4: Cleanup and Verification

### Task 25: Write README.md

**Files:**
- Create: `README.md`

**Step 1: Write README**

```bash
cat > ~/code/dotfiles/README.md << 'EOF'
# dotfiles

macOS development environment setup.

## Install

```bash
git clone https://github.com/<you>/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./install.sh
```

## Upgrade existing packages

```bash
./install.sh --upgrade
```

## Add a new package

1. `mkdir packages/mypkg`
2. Copy config files into `packages/mypkg/`
3. Write `packages/mypkg/symlinks.conf`:
   ```
   myconfig -> $HOME/.config/mypkg/myconfig
   ```
4. Optionally add `packages/mypkg/install.sh` for post-install steps
5. Add the brew formula or cask to `Brewfile`

## Machine-local nvim config

Create `~/.config/nvim/lua/local/` for machine-specific overrides (gitignored).
DBUI configuration goes in `~/.config/nvim/lua/local/dbui.lua`.
General overrides go in `~/.config/nvim/lua/local/init.lua` (loaded via `pcall(require, 'local')`).
EOF
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with install and usage instructions"
```

---

### Task 26: End-to-end dry run verification

> Simulate a fresh install by temporarily removing and re-running.

**Step 1: Check all expected symlinks exist**

```bash
links=(
  "$HOME/.zshrc"
  "$HOME/.config/ghostty/config"
  "$HOME/.config/starship.toml"
  "$HOME/.config/tmux/tmux.conf"
  "$HOME/.config/tmux-powerline/config.sh"
  "$HOME/.gitconfig"
  "$HOME/.config/gh/config.yml"
  "$HOME/.config/glow/glow.yml"
  "$HOME/.config/alacritty/alacritty.toml"
  "$HOME/.config/mole/config.sh"
  "$HOME/.config/nvim/init.lua"
  "$HOME/.config/nvim/lazy-lock.json"
  "$HOME/.config/nvim/lua"
  "$HOME/.codex/config.toml"
  "$HOME/.claude/settings.json"
)

all_ok=1
for link in "${links[@]}"; do
  if [[ -L "$link" ]]; then
    echo "  [ok] $link"
  else
    echo "  [MISSING] $link"
    all_ok=0
  fi
done
[[ "$all_ok" == "1" ]] && echo "All symlinks present." || echo "Some symlinks missing."
```

**Step 2: Run install.sh a second time — verify idempotency**

```bash
~/code/dotfiles/install.sh
# Expected: all "Already linked" messages, no errors, no prompts
```

**Step 3: Check brew packages are satisfied**

```bash
brew bundle check --file=~/code/dotfiles/Brewfile
# Expected: The Brewfile's dependencies are satisfied.
```

**Step 4: Commit any final fixes**

```bash
git add -A
git status
# Commit anything outstanding
git commit -m "chore: final cleanup and verification"
```

---

## Summary

After completing all tasks:

```
dotfiles/
├── install.sh           # ./install.sh or ./install.sh --upgrade
├── Brewfile             # all software
├── README.md
├── .gitignore
└── packages/
    ├── zsh/             .zshrc
    ├── ghostty/         config
    ├── starship/        starship.toml
    ├── tmux/            tmux.conf
    ├── tmux-powerline/  config.sh, segments/, themes/
    ├── git/             gitconfig
    ├── gh/              config.yml
    ├── glow/            glow.yml
    ├── alacritty/       alacritty.toml
    ├── mole/            config.sh
    ├── nvim/            init.lua, lazy-lock.json, lua/ (local/ gitignored)
    ├── rectangle/       rectangle.plist + install.sh hook
    ├── codex/           config.toml
    ├── claude-code/     settings.json
    ├── node/            install.sh hook
    └── python/          install.sh hook
```

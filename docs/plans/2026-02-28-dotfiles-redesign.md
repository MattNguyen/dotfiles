# Dotfiles Redesign

**Date:** 2026-02-28
**Status:** Approved

## Overview

Complete rewrite of dotfiles from a Ruby/Rake-based system to a self-contained bash script. Goal: run one script on a fresh Mac to reproduce the full development environment.

## Requirements

1. Script runs idempotently — already-installed programs are skipped
2. `--upgrade` flag to update/upgrade existing programs
3. Install Homebrew
4. Install Claude Code (binary via cask)
5. Install Codex (binary via cask)
6. Install all brew packages from current environment (formulas + casks + fonts)
7. Copy all current config files into repo for all tracked packages
8. Script symlinks config files from repo into correct filesystem locations
9. Adding a new package is easy: drop a folder, write `symlinks.conf`, add to Brewfile
10. Zero dependencies to execute (pure bash + brew)
11. Install language managers: fnm (Node/latest LTS), pyenv (Python/latest 3.x), go (via brew)

## Target Platform

macOS only.

## Approach

Single `install.sh` bash script. Packages live in `packages/<name>/` with config files and a `symlinks.conf` manifest. A `Brewfile` manages all installable software. Optional `install.sh` hooks per package handle anything brew cannot.

## Repository Structure

```
dotfiles/
├── install.sh              # main entrypoint
├── Brewfile                # all brew packages (formulas + casks + fonts)
├── packages/
│   ├── zsh/
│   │   ├── symlinks.conf
│   │   ├── install.sh      # set zsh as default shell
│   │   └── .zshrc
│   ├── ghostty/
│   │   ├── symlinks.conf
│   │   └── config
│   ├── starship/
│   │   ├── symlinks.conf
│   │   └── starship.toml
│   ├── nvim/
│   │   ├── symlinks.conf   # entire dir -> ~/.config/nvim/
│   │   └── ...             # init.lua, lua/, lazy-lock.json (local.lua gitignored)
│   ├── tmux/
│   │   ├── symlinks.conf
│   │   └── tmux.conf
│   ├── tmux-powerline/
│   │   ├── symlinks.conf
│   │   └── ...
│   ├── git/
│   │   ├── symlinks.conf
│   │   └── gitconfig
│   ├── gh/
│   │   ├── symlinks.conf
│   │   └── config.yml
│   ├── glow/
│   │   ├── symlinks.conf
│   │   └── glow.yml
│   ├── alacritty/
│   │   ├── symlinks.conf
│   │   └── alacritty.toml
│   ├── mole/
│   │   ├── symlinks.conf
│   │   └── ...
│   ├── rectangle/
│   │   ├── install.sh      # defaults import/export for plist
│   │   └── rectangle.plist
│   ├── codex/
│   │   ├── symlinks.conf
│   │   └── config.toml     # -> ~/.codex/config.toml (auth.json gitignored)
│   ├── claude-code/
│   │   ├── symlinks.conf
│   │   └── settings.json   # -> ~/.claude/settings.json
│   ├── node/
│   │   └── install.sh      # fnm install --lts && fnm default lts-latest
│   └── python/
│       └── install.sh      # pyenv install latest 3.x + pyenv global
└── docs/
    └── plans/
```

## Brewfile Categories

- **Formulas:** go, neovim, starship, tmux, fnm, pyenv, uv, ripgrep, fzf, jq, gh, direnv, glow, just, zsh-autocomplete, buf, colima, docker, docker-compose, helm, k9s, kubectx, kubernetes-cli, awscli, vault, pgformatter, sqlcmd, postgresql@18, redis, pre-commit, golangci-lint, pnpm, tree-sitter, yq, jq, wget, + all remaining current formulas
- **Casks:** ghostty, claude-code, codex, rectangle, chatgpt, figma, 1password, google-chrome, linear-linear, whatsapp, alacritty
- **Fonts:** font-hack-nerd-font

## `install.sh` Flow

```
./install.sh           # full install, skip already-installed
./install.sh --upgrade # full install + brew upgrade all packages
```

1. Check/install Xcode Command Line Tools (idempotent)
2. Check/install Homebrew (idempotent)
3. `brew bundle [--no-upgrade]` — installs all Brewfile packages
4. For each `packages/*/symlinks.conf`: create symlinks at destinations
   - Skip if symlink already points to correct target
   - Prompt before overwriting an existing real file
   - Create parent directories as needed
5. Run package hooks in explicit order: `zsh → node → python → rectangle`
6. Set zsh as default shell (idempotent check)

## `symlinks.conf` Format

One mapping per line. Source is relative to the package directory. Destination supports `$HOME`.

```
# source -> destination
.zshrc -> $HOME/.zshrc
config -> $HOME/.config/ghostty/config
```

For entire directories:
```
. -> $HOME/.config/nvim
```

## nvim: Machine-specific Config

The `init.lua` is refactored to call `pcall(require, 'local')` at the end. Any machine-specific config (DBUI database connections referencing `~/code/local-cluster/db_connections.sh`, Vault integration, etc.) lives in `~/.config/nvim/lua/local.lua`, which is gitignored.

## Package Hook Conventions

Each `packages/<name>/install.sh` hook:
- Is sourced (not executed) so it inherits shell environment
- Checks `$UPGRADE` env var to decide whether to upgrade vs skip
- Is idempotent — safe to run multiple times

Example node hook:
```bash
if ! fnm list | grep -q "lts-latest" || [ "$UPGRADE" = "1" ]; then
  fnm install --lts
  fnm default lts-latest
fi
```

## Rectangle

Rectangle stores preferences as a binary plist at `~/Library/Preferences/com.knollsoft.Rectangle.plist`. The hook handles sync:
- **On install:** `defaults import com.knollsoft.Rectangle packages/rectangle/rectangle.plist`
- **To update repo:** run `./install.sh --export-prefs` (or a documented manual command)

## .gitignore

```gitignore
packages/codex/auth.json
packages/claude-code/anthropic_key.sh
packages/nvim/lua/local.lua
packages/nvim/backups/
```

## Adding a New Package

```bash
mkdir packages/mypkg
cp ~/.config/mypkg/config packages/mypkg/
echo "config -> \$HOME/.config/mypkg/config" > packages/mypkg/symlinks.conf
# optionally: vim packages/mypkg/install.sh
# add formula/cask to Brewfile
```

## What Is Not Tracked

- k9s config (`~/.config/k9s/`) — machine/cluster-specific
- App configs that are cloud-synced: ChatGPT, Figma, Linear, WhatsApp
- Security-sensitive data: 1Password vaults, Chrome profile, codex/claude auth tokens
- nvim machine-specific overrides (`lua/local.lua`)

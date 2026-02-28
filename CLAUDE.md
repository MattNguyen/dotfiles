# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A self-contained bash dotfiles system for macOS. A single `./install.sh` invocation installs all software and symlinks all configs idempotently.

## Running the Installer

```bash
./install.sh           # Install/re-run (no upgrades)
./install.sh --upgrade # Allow brew to upgrade existing packages
```

## Architecture

### Orchestration order (install.sh)

1. Xcode CLT → Homebrew → `brew bundle` from `Brewfile`
2. `link_all` — iterates every `packages/*/symlinks.conf` and creates symlinks
3. Package hooks in explicit order: `zsh`, `node`, `python`, `rectangle`
4. `set_default_shell` — sets zsh if not already default

### Package structure

Each tool lives in `packages/<name>/`:

| File | Purpose |
|---|---|
| `symlinks.conf` | Maps `source -> $HOME/destination` (one per line) |
| `install.sh` | Optional hook, sourced by `run_hook` — has `$DOTFILES_DIR` and `$UPGRADE` |

### symlinks.conf format

```
configfile -> $HOME/.config/tool/configfile
dir        -> $HOME/.config/tool/dir
```

- `$HOME` is expanded; paths with spaces work fine (e.g., ghostty's `Library/Application Support/...`)
- Comments (`#`) and blank lines are skipped
- Existing correct symlinks are silently skipped (idempotent)
- Real files prompt before overwriting

### Package hooks

Hooks are `source`d (not executed in a subshell), so they can use `return` to exit early. They inherit `info`, `success`, `warning`, `error` logging functions and `$DOTFILES_DIR`/`$UPGRADE`.

Hooks run **after** all symlinks are created — so config files are in place when hooks execute.

To add a new hook, create `packages/<name>/install.sh` and add `run_hook "<name>"` to `main()` in `install.sh` in the desired order.

## Adding a New Package

1. `mkdir packages/mypkg`
2. Copy config files in
3. Write `packages/mypkg/symlinks.conf`
4. Optionally add `packages/mypkg/install.sh`
5. Add the formula/cask to `Brewfile`

## Key Details

- **rectangle** uses `defaults import/export` (no symlinks) — preferences are in `packages/rectangle/rectangle.plist`
- **nvim** machine-local overrides live in `~/.config/nvim/lua/local/` (gitignored via `packages/nvim/lua/local/*`). `dbui.lua` goes there for machine-specific DB connections. The `lua/local/.gitkeep` is tracked to ensure the directory exists on clone.
- **gh** — `hosts.yml` (OAuth tokens) is gitignored; only `config.yml` is tracked
- **claude-code** — `anthropic_key.sh` is gitignored; only `settings.json` is tracked
- **codex** — `auth.json` is gitignored; only `config.toml` is tracked

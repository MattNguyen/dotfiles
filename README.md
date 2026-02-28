# dotfiles

macOS development environment setup.

## Install

```bash
git clone https://github.com/matt-nguyen/dotfiles.git ~/code/dotfiles
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

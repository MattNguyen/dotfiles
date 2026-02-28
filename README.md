# dotfiles

macOS development environment setup.

## Install

```bash
git clone https://github.com/mattnguyen/dotfiles.git ~/code/dotfiles
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

## Machine-local zsh config

Create `~/.zshrc.local` for machine or work-specific exports (lives outside this repo):

```bash
export VAULT_ADDR="https://vault.example.com:8200"
export DOCKER_HOST="..."
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
```

`.zshrc` sources this file automatically if it exists.

## Git identity

`packages/git/gitconfig` ships with placeholder values. Set your identity after install:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## Machine-local nvim config

Create `~/.config/nvim/lua/local/` for machine-specific overrides (gitignored).
DBUI configuration goes in `~/.config/nvim/lua/local/dbui.lua`.
General overrides go in `~/.config/nvim/lua/local/init.lua` (loaded via `pcall(require, 'local')`).

#!/usr/bin/env bash
if ! command -v nvim &>/dev/null; then
  warning "nvim not found, skipping plugin setup"
  return
fi

lazy_dir="$HOME/.local/share/nvim/lazy"

if [[ ! -d "$lazy_dir/lazy.nvim" ]]; then
  info "Installing nvim plugins from lockfile (this may take a minute)..."
  nvim --headless "+Lazy! restore" +qa 2>/dev/null || true
  success "nvim plugins installed"
elif [[ "$UPGRADE" == "1" ]]; then
  info "Syncing nvim plugins..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
  success "nvim plugins synced"
else
  info "nvim plugins already installed"
fi

# Ensure nvim-treesitter plugins are on main branch (new API) not master (old API)
for ts_plugin in nvim-treesitter nvim-treesitter-textobjects; do
  ts_dir="$lazy_dir/$ts_plugin"
  if [[ -d "$ts_dir" ]]; then
    current_branch="$(git -C "$ts_dir" branch --show-current 2>/dev/null)"
    if [[ "$current_branch" != "main" ]]; then
      info "Switching $ts_plugin to main branch..."
      git -C "$ts_dir" fetch origin main --quiet 2>/dev/null || true
      git -C "$ts_dir" checkout main 2>/dev/null || true
      git -C "$ts_dir" pull origin main --quiet 2>/dev/null || true
    fi
  fi
done

# Fix LuaSnip submodules — jsregexp can get into an inconsistent state
# preventing Lazy from updating the plugin
luasnip_dir="$lazy_dir/LuaSnip"
if [[ -d "$luasnip_dir" ]]; then
  git -C "$luasnip_dir" submodule update --init --force --recursive 2>/dev/null || true
fi

# Update treesitter parsers using the synchronous variant (works headlessly)
if [[ ! -d "$lazy_dir/nvim-treesitter/parser" ]] || [[ "$UPGRADE" == "1" ]]; then
  info "Updating treesitter parsers..."
  nvim --headless "+TSUpdateSync all" +qa 2>/dev/null || true
fi

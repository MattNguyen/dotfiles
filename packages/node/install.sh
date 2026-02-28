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

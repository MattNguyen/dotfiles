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

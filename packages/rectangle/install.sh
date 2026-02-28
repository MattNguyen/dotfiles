#!/usr/bin/env bash
PLIST="$DOTFILES_DIR/packages/rectangle/rectangle.plist"

if [[ ! -f "$PLIST" ]]; then
  warning "rectangle.plist not found, skipping"
  return
fi

defaults import com.knollsoft.Rectangle "$PLIST"
success "Rectangle preferences imported"

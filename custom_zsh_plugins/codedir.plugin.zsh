code() { cd ~/Code/$1;  }

_code() { _files -W ~/Code -/; }
compdef _code code

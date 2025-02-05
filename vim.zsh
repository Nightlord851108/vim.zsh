#===============================================================================
# LICENCE: GNU GPL version 3
#
# vim.zsh is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This project is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#===============================================================================
# Setting up all vim mode mapping and special keys
#
# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo

get-x-clipboard() {
  if which xsel >/dev/null 2>&1; then
    clippaste='xsel --clipboard --output'
  elif which xclip >/dev/null 2>&1; then
    clippaste='xclip -selection clipboard -out'
  elif which pbpaste >/dev/null 2>&1; then
    clippaste='pbpaste'
  else
    return 1
  fi

  (( $+DISPLAY )) || return 1
  local r
  r=$(eval "$clippaste")
  if [[ -n $r && $r != $CUTBUFFER ]]; then
    killring=("$CUTBUFFER" "${(@)killring[1,-2]}")
    CUTBUFFER=$r
  fi
}

set-x-clipboard() {
  if which xsel >/dev/null 2>&1; then
    clipcopy='xsel --clipboard --input'
  elif which xclip >/dev/null 2>&1; then
    clipcopy='xclip -selection clipboard -in'
  elif which pbcopy >/dev/null 2>&1; then
    clipcopy='pbcopy'
  else
    return 1
  fi

  (( ! $+DISPLAY )) ||
    print -rn -- "$1" | eval "$clipcopy"
}

vi-set-buffer() {
  read -k keys
  if [[ $keys == '+' ]];then
    _clipcopy='+'
  else
    zle -U $keys
    zle .vi-set-buffer
  fi
}
zle -N vi-set-buffer

# mode settings
hooks-define-hook vim_mode_change

ZSH_VIM_MODE="i"
vi-mode-run-hooks() {
  local zsh_vim_mode
  case $KEYMAP in
    main|viins)
      zsh_vim_mode="i"
      ;;
    vicmd)
      case $REGION_ACTIVE in
        0)
          zsh_vim_mode="n"
          ;;
        1)
          zsh_vim_mode="v"
          ;;
        2)
          zsh_vim_mode="v"
          ;;
      esac
      ;;
    virep)
      zsh_vim_mode="r"
      ;;
  esac
  hooks-run-hook vim_mode_change $zsh_vim_mode $1
}

vi-mode-line-init() {
  vi-mode-run-hooks 'line-init'
}

vi-mode-line-finish() {
  vi-mode-run-hooks 'line-finish'
}

vi-mode-keymap-select() {
  vi-mode-run-hooks 'keymap-select'
}

add-vi-mode-hook() {
  hooks-add-hook vim_mode_change $1
}

add-zle-hook zle-line-init vi-mode-line-init
add-zle-hook zle-line-finish vi-mode-line-finish
add-zle-hook zle-keymap-select vi-mode-keymap-select

visual-mode() {
  zle .visual-mode
  vi-mode-run-hooks 'keymap-select'
}
zle -N visual-mode

visual-line-mode() {
  zle .visual-line-mode
  vi-mode-run-hooks 'keymap-select'
}
zle -N visual-line-mode

overwrite-mode() {
  zle -K virep
  zle .overwrite-mode
}
zle -N overwrite-mode

vi-put-after() {
  if [[ $_clipcopy == '+' ]];then
    local cbuf
    cbuf=$CUTBUFFER
    get-x-clipboard
    zle .vi-put-after
    unset _clipcopy
    CUTBUFFER=$cbuf
  else
    zle .vi-put-after
  fi
  zle .deactivate-region
  vi-mode-run-hooks 'keymap-select'
}
zle -N vi-put-after

vi-put-before() {
  if [[ $_clipcopy == '+' ]];then
    local cbuf
    cbuf=$CUTBUFFER
    get-x-clipboard
    zle .vi-put-before
    unset _clipcopy
    CUTBUFFER=$cbuf
  else
    zle .vi-put-before
  fi
  zle .deactivate-region
  vi-mode-run-hooks 'keymap-select'
}
zle -N vi-put-before

# redefine the copying widgets so that they update the clipboard.
for w in copy-region-as-kill vi-delete vi-yank vi-change vi-change-whole-line vi-change-eol; do
  eval $w'() {
    zle .'$w'
    vi-mode-run-hooks keymap-select
    if [[ $_clipcopy == "+" ]];then
      set-x-clipboard $CUTBUFFER
      unset _clipcopy
    fi
  }
  zle -N '$w
done

vi-visual-exit() {
  zle .deactivate-region
  zle .vi-cmd-mode
  vi-mode-run-hooks 'keymap-select'
}
zle -N vi-visual-exit

typeset -A key

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# special key setup
if [[ -n "${key[Home]}" ]]; then
  bindkey -M viins "${key[Home]}" beginning-of-line
  bindkey -M vicmd "${key[Home]}" beginning-of-line
fi
if [[ -n "${key[End]}" ]]; then
  bindkey -M viins "${key[End]}" end-of-line
  bindkey -M vicmd "${key[End]}" end-of-line
fi
if [[ -n "${key[Delete]}" ]]; then
  bindkey -M viins "${key[Delete]}" delete-char
  bindkey -M vicmd "${key[Delete]}" delete-char
fi
if [[ -n "${key[Up]}" ]]; then
  bindkey -M viins "${key[Up]}" up-line-or-search
  bindkey -M vicmd "${key[Up]}" up-line-or-search
fi
if [[ -n "${key[Down]}" ]]; then
  bindkey -M viins "${key[Down]}" down-line-or-search
  bindkey -M vicmd "${key[Down]}" down-line-or-search
fi
if [[ -n "${key[PageUp]}" ]]; then
  bindkey -M viins "${key[PageUp]}" beginning-of-buffer-or-history
  bindkey -M vicmd "${key[PageUp]}" beginning-of-buffer-or-history
fi
if [[ -n "${key[PageDown]}" ]]; then
  bindkey -M viins "${key[PageDown]}" end-of-buffer-or-history
  bindkey -M vicmd "${key[PageDown]}" end-of-buffer-or-history
fi
if [[ -n "${key[Insert]}" ]]; then
  bindkey -M viins "${key[Insert]}" overwrite-mode
  bindkey -M vicmd "${key[Insert]}" vi-insert
fi

# insert mode
dir-backward-delete-word() {
  local WORDCHARS="${WORDCHARS:s#/#}"
  zle backward-delete-word
}
zle -N dir-backward-delete-word
bindkey -M viins "^w" dir-backward-delete-word
bindkey -M viins "^h" backward-delete-char
bindkey -M viins "^u" backward-kill-line
bindkey -M viins "^?" backward-delete-char

bindkey -M viins "^p" up-line-or-search
bindkey -M viins "^n" down-line-or-search

# A temporary fix
# prevent vi-mode-run-hooks run multiple times in one execution cycle
# see https://github.com/sindresorhus/pure/commit/a3b22b242d2e4bc8d7e989c47e49a4bf03d7e2ab
bindkey -M viins "^[o" vi-open-line-below
bindkey -M viins "^[O" vi-open-line-above
bindkey -M viins "^[i" vi-insert
bindkey -M viins "^[I" vi-insert-bol
bindkey -M viins "^[a" vi-add-next
bindkey -M viins "^[A" vi-add-eol
bindkey -M viins "^[R" overwrite-mode

# create replace keymap
bindkey -N virep viins

# normal mode
bindkey -M vicmd "R" overwrite-mode
bindkey -M vicmd "^p" up-line-or-search
bindkey -M vicmd "^n" down-line-or-search

# visual mode
[[ -n "${key[Delete]}" ]] && bindkey -M visual "${key[Delete]}" vi-delete
bindkey -M visual "^[" vi-visual-exit

# replace mode
[[ -n "${key[Insert]}" ]] && bindkey -M virep "${key[Insert]}" vi-insert

# menu select mode
zmodload zsh/complist
bindkey -M menuselect '^[' vi-cmd-mode
bindkey -M menuselect '^p' reverse-menu-complete
bindkey -M menuselect '^n' menu-complete

# additional esc key binding
bindkey -M viins "^e" vi-cmd-mode
bindkey -M virep "^e" vi-cmd-mode
bindkey -M visual "^e" vi-visual-exit
bindkey -M menuselect "^e" vi-cmd-mode

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  zle-keybinds-init() {
    echoti smkx
  }
  zle-keybinds-finish() {
    echoti rmkx
  }
  add-zle-hook zle-line-init zle-keybinds-init
  add-zle-hook zle-line-finish zle-keybinds-finish
fi

bindkey -v

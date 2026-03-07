# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Performance Logging
#zmodload zsh/zprof
#zmodload zsh/datetime
#setopt PROMPT_SUBST
#PS4='+$EPOCHREALTIME %N:%i> '
#logfile=$(mktemp ~/zsh_profile.XXXXXXXX)
#echo "Logging to $logfile"
#exec 3>&2 2>$logfile
#setopt XTRACE
# change

# Path to your oh-my-zsh configuration.
export TERM="xterm-256color"

export ZSH=$HOME/.oh-my-zsh

# if you want to use this, change your non-ascii font to Droid Sans Mono for Awesome
export ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL10K_COLOR_SCHEME='light'
# export ZSH_THEME="agnoster"
POWERLEVEL10K_SHORTEN_DIR_LENGTH=2

vimode(){
    echo $(vi_mode_prompt_info)
}

POWERLEVEL10K_CUSTOM_VIMODE="vimode"

POWERLEVEL10K_LEFT_PROMPT_ELEMENTS=(vcs custom_vimode newline dir)
POWERLEVEL10K_RIGHT_PROMPT_ELEMENTS=(status history time)
# colorcode test
#
textcolortest() { for code ({000..255}) print -P -- "$code: %F{$code}This is how your text would look like%f"}

POWERLEVEL10K_NVM_FOREGROUND='000'
POWERLEVEL10K_NVM_BACKGROUND='072'
POWERLEVEL10K_SHOW_CHANGESET=true
#export ZSH_THEME="random"

# Set to this to use case-sensitive completion
export CASE_SENSITIVE="true"

# disable weekly auto-update checks
# export DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT=true

# disable colors in ls
export DISABLE_LS_COLORS="true"

# disable autosetting terminal title.
export DISABLE_AUTO_TITLE="true"

# Which plugins would you like to load? (plugins can be found in ~/.dotfiles/oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
#


plugins=(z colorize compleat dirpersist autojump gulp history cp zsh-autosuggestions history-substring-search  zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Default the shell to global history, local history can be accessed with keyboard toggle
#_per-directory-history-set-global-history

# Customize to your needs...
unsetopt correct

# run fortune on new terminal :)
# fortune

# Erase when we get vim.obsession installed, also need to install tmux-resurrect
#vim () {
#    if [ -f 'Session.vim' ] && [ $# -eq 0 ]; then
#        command $vim -S Session.vim
#    else
#        command $vim "$@"
#    fi
#}

function fgr {
   fgrep -r -n $@ .
}

export NVM_DIR="$HOME/.nvm"

# NVM autoload stuff below, nvmi function should do this if not make this below into a function. doing it on every load
# is too slow
#
nvmload() {
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

  autoload -U add-zsh-hook
  load-nvmrc() {
    if [[ -f .nvmrc && -r .nvmrc ]]; then
      nvm use &> /dev/null
    elif [[ $(nvm version) != $(nvm version default)  ]]; then
      nvm use default &> /dev/null
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
}
#nvmload

HISTFILESIZE=10000000

# fhr - Add a history repeat search using fzf, runs the command
#fhr() {
  #eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
#}

## fh - repeat history edit, drops the command into command line !
#writecmd (){ perl -e 'ioctl STDOUT, 0x5412, $_ for split //, do{ chomp($_ = <>); $_ }' ; }

#fh() {
  #([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -re 's/^\s*[0-9]+\s*//' | writecmd
#}

# Add aliases and convenience calls for - fasd
#eval "$(fasd --init auto)"
#alias v='f -e vim'  quick opening files with vim

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
eval "$(pyenv init -)"

# SCM Breeze
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"


[ -s "/Users/adam/.scm_breeze/scm_breeze.sh" ] && source "/Users/adam/.scm_breeze/scm_breeze.sh"

#
#
#
#
#
#       VIM Editing Mode
#
#
#
#
#

bindkey -v

# Make Vi mode transitions faster (KEYTIMEOUT is in hundredths of a second)
export KEYTIMEOUT=1


# `v` is already mapped to visual mode, so we need to use a different key to
# open Vim
bindkey -M vicmd "^V" edit-command-line

export EDITOR='vim'

# Updates editor information when the keymap changes.
#function zle-keymap-select() {
  #zle reset-prompt
  #zle -R
#}

#zle -N zle-keymap-select


function zle-keymap-select zle-line-init
{
    # change cursor shape in iTerm2
    case $KEYMAP in
        vicmd)      print -n -- "\E]50;CursorShape=0\C-G";;  # block cursor
        viins|main) print -n -- "\E]50;CursorShape=1\C-G";;  # line cursor
    esac

    zle reset-prompt
    zle -R
}

function zle-line-finish
{
    print -n -- "\E]50;CursorShape=0\C-G"  # block cursor
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

bindkey -v '^?' backward-delete-char

# Hardcode the fzf-history-widget binding to work in -v (vi insert) and -a (vi normal) modes.
#bindkey -v '^r' fzf-history-widget
#bindkey -a '^r' fzf-history-widget

# Hardcode the fzf-cd-widget binding to work in -v (vi insert) and -a (vi normal) modes.
# bindkey -v '^t' fzf-cd-widget
# bindkey -a '^t' fzf-cd-widget

function vi_mode_prompt_info() {
  echo "${${KEYMAP/vicmd/% NORMAL }/(main|viins)/% INSERT %}"
}

# define right prompt, regardless of whether the theme defined it
#RPS1='$(vi_mode_prompt_info)'
#RPS2=$RPS1

# Bat config
#
export BAT_CONFIG_PATH="/Users/adam/.dotfiles/homedir"

# Send "Meta" key with "alt/option"
bindkey '^[[1;9C' forward-word
bindkey '^[[1;9D' backward-word

# sent "meta" key with "alt/option"
[ -z "${TMUX}" ] && bindkey '^[[1;3C' forward-word
[ -z "${TMUX}" ] && bindkey '^[[1;3D' backward-word


#
#
#
#
#
#       Performance
#
#
#

# Performance Logging
#unsetopt XTRAC#E
#exec 2>&3 3>&-
#zprof
#
#. $HOME/.asdf/asdf.sh
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# dir env, move later
eval "$(direnv hook zsh)"

# chnode, move later
eval "$(rbenv init - zsh)"



export PAGER="/bin/sh -c \"unset PAGER;col -b -x | \
    vim -R -c 'set ft=man nomod nolist' -c 'map q :q<CR>' \
    -c 'map <SPACE> <C-D>' -c 'map b <C-U>' \
    -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""

#source $(brew --prefix)/opt/chnode/share/chnode/chnode.sh

#source $(brew --prefix)/Cellar/asdf/0.8.1_1/asdf.sh  

#if [ -f "$HOME/.mc_env.sh" ]; then
    #source "$HOME/.mc_env.sh"
#fi

alias ls='exa --long -a' 

RUBY_CFLAGS="-Wno-error=implicit-function-declaration"
#export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
#export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
#export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
#export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

export PATH="/Users/adam/.dotfiles/lib_compiled:$PATH"

PATH="/opt/homebrew/bin:$PATH"

export PATH="$PATH:$HOME/Projects/flutter/bin"
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp"


source <(mcfly init zsh)

export MCFLY_LIGHT=TRUE

export MCFLY_KEY_SCHEME=vim
export MCFLY_FUZZY=2
export MCFLY_INTERFACE_VIEW=BOTTOM

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export PATH="$PATH:/Users/adam/.local/bin"
export PATH="$PATH:/Users/adam/Projects/xcode-build-server"
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
export PATH="$PATH:/Users/adam/Projects/android-ndk"
export GPG_TTY=$(tty)
export GPG_TTY=$(tty)

# aliases
#

alias gcm='git commit -S -m '
alias gpoh='git push origin HEAD '
alias grs='git reset --soft '
alias gch='git cherry-pick -- '

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

alias dart-super-format='dart format --set-exit-if-changed lib test && dart fix --apply; dart format --set-exit-if-changed lib test && dart fix --apply && dart analyze'

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/adam/.dart-cli-completion/zsh-config.zsh ]] && . /Users/adam/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

eval "$(pyenv init -)"

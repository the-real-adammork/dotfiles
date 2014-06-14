# -----------------------------------------------------------------
# PRE-ZPREZTO CUSTOM ZSH CONFIGURATION
# -----------------------------------------------------------------


# Native site-functions come first
# NOTE: this must happen before initializing zprezto
fpath=(/usr/local/share/zsh/site-functions $fpath)
zstyle ':completion:*:*:git:*' script /usr/local/etc/bash_completion.d/git-completion.bash


# -----------------------------------------------------------------
# ZPREZTO CONFIGURATION
# -----------------------------------------------------------------

source "$HOME/.zprezto/init.zsh"


# -----------------------------------------------------------------
# CUSTOM ZSH CONFIGURATION
# -----------------------------------------------------------------

# Set interactive comments
set -k

# use vim key bindings
bindkey -v

# Disable shared histories
unsetopt share_history

# Deal with slow git completion
__git_files () { 
    _wanted files expl 'local files' _files 
}

# Source the common shell rc settings in .shellrc.
source ~/.shellrc

# Fix zsh annoying history behavior
h() { if [ -z "$*" ]; then history 1; else history 1 | egrep "$@"; fi; }

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '\eOA' up-line-or-beginning-search
bindkey '\e[A' up-line-or-beginning-search
bindkey '\eOB' down-line-or-beginning-search
bindkey '\e[B' down-line-or-beginning-search


# -----------------------------------------------------------------
# SOURCING LOCAL .ZSHRC
# -----------------------------------------------------------------

if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi







# the end

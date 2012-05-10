# ----------------------------------------------------------------- #
#                                                                   #
#           Kenneth Ballenegger's Awesome .bashrc                   #
#                                                                   #
# ----------------------------------------------------------------- #


# -----------------------------------------------------------------
# LOCAL BASHRC
# -----------------------------------------------------------------

if [ -f .local.bashrc ]; then
    source .local.bashrc
fi

# -----------------------------------------------------------------
# BASH CONFIGURATION
# -----------------------------------------------------------------

export EDITOR="vim"

export CLICOLOR="xterm-color"
export DISPLAY=:0.0

# history
export HISTCONTROL=erasedups
export HISTSIZE=10000
shopt -s histappend

# path
export PATH="/Users/kenneth/bin:$PATH"
export PATH="/usr/class/cs143/cool/bin:$PATH"

# -----------------------------------------------------------------
# BASH PROMPT
# -----------------------------------------------------------------

parse_git_branch() {
    git_branch=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [ $git_branch ]; then
        echo "•$git_branch"
    fi
}

# sexy prompt
export PS1='[\[\033[0;35m\]\h\[\033[0;36m\] \w\[\033[00m\]\[\033[33m\]$(parse_git_branch)\[\033[00m\]]\$ '
#export PS1="\[\033[G\]$PS1"

# -----------------------------------------------------------------
# APACHE, MYSQL, VERTICA, PHP
# -----------------------------------------------------------------

# apache
export PATH="/opt/local/apache2/bin:$PATH"

# mysql
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/mysql/bin:$PATH"
export PATH="/opt/local/lib/mysql5/bin:$PATH"

alias mysql='mysql5'

# vertica

alias vsql="/opt/vertica/bin/vsql -h 10.79.61.102 -U super_reader -w 67Unic0rns"

# php-shell
alias php-shell="php-shell.sh"

# -----------------------------------------------------------------
# GIT, RUBY, PYTHON, CLOJURE, NODE, COFFEE, LESS
# -----------------------------------------------------------------

# git
export GIT_EDITOR="vim"

alias gco="git checkout"
alias gps="git push"
alias gpl="git pull"
alias gm="git merge"
alias gcm="git commit -m"
alias gc="git commit"
alias gs="git status"
alias gb="git branch"
alias gd="git diff"
alias gcp="git cherry-pick"
alias ga="git add"
alias gmv="git mv"
alias grm="git rm"

# rubygems
export PATH="/Users/kenneth/.gem/ruby/1.8/bin:$PATH"

# rvm
if [[ -s /Users/kenneth/.rvm/scripts/rvm ]] ; then
    source /Users/kenneth/.rvm/scripts/rvm
fi
# rvm
if [[ -s /home/kenneth/.rvm/scripts/rvm ]] ; then
    source /home/kenneth/.rvm/scripts/rvm
fi

# python

alias pyi="easy_install"

#clojure

alias pyclj="clojurepy"
alias cake="/Users/kenneth/.rvm/gems/ruby-1.9.2-p290/gems/cake-0.6.3/bin/cake"

# node
export NODE_PATH="/usr/local/lib/node"

alias less-watch="coffee ~/lib/lessc-watch/src/lessc-watch.coffee . ."

# -----------------------------------------------------------------
# AUTOJUMP CONFIGURATION
# -----------------------------------------------------------------

if [ -x /usr/local/bin/brew ]; then
    if [ -f `brew --prefix`/etc/autojump ]; then
        . `brew --prefix`/etc/autojump
    fi
fi

# -----------------------------------------------------------------
# PACKAGE MANAGER CONFIGUREATION
# -----------------------------------------------------------------

export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

if [ -f /opt/local/etc/bash_completion ]; then
    . /opt/local/etc/bash_completion
fi

export PATH="/usr/local/bin:$PATH"


# -----------------------------------------------------------------
# CHARTBOOST-SPECIFIC CONFIGURATION
# -----------------------------------------------------------------

# bin path for scripts on server nodes
export PATH="/var/www/server/current/scripts/bin:$PATH"

# paraglide-live / dev
alias paraglide-live="export PARAGLIDE_ENVIRONMENT=live"
alias paraglide-dev="export PARAGLIDE_ENVIRONMENT=dev"

# misc shortcuts
alias remote-deploy="ssh cap 'cd server && git pull && cap production deploy'"
alias remote-deploy-lb="ssh cap 'cd server && git pull && cap lb deploy'"
alias remote-deploy-queue="ssh cap 'cd server && git pull && cap queue deploy'"
#alias cd-cb="cd ~/dev/caffeine/server"
alias cd-current="cd /var/www/server/current"

# reverse proxy dev.chartboost.com:9999 traffic to localhost
alias cb-proxy='ssh -R 9999:localhost:80 dev -N'

# reverse proxy for xdebug sessions
alias xdebug-tunnel='ssh -R 19000:localhost:19000 dev -N'

# connect to mongo / chartboost
alias mcb='mongo localhost/chartboost'

# resque
alias resque-remote-web='ssh -L 8282:redis_queue:8282 && open http://localhost:8282/'
alias resque-kill="ps aux | grep \"resque-1.0\" | grep -v grep | awk '{print \$2}' | xargs kill"

# -----------------------------------------------------------------
# ALIASES
# -----------------------------------------------------------------

alias ssh-proxy='ssh -D 9999 azure -N'
alias ssh-reverse-http='ssh -R 9999:localhost:80 azure -N'
alias free='free -m'
alias flushdns='dscacheutil -flushcache'

# keep environment when doing sudo su
alias ssu='sudo su -m'

function fgr {
    fgrep -r -n $@ .
}

function pbgist {
    if [ -z $1 ]; then
        _opt=""
    else
        _opt="-t $1"
    fi
    # export GITHUB_PASSWORD=`git config --get github.password`
    _out=`pbpaste | tab2space  | gist $_opt`
    echo $_out | pbcopy
    echo $_out
}

function macc {
    if [ -z $1]; then
        open /Applications/Macchiato.app
    else
        touch $1
        open -a /Applications/Macchiato.app $1
    fi
}

# -----------------------------------------------------------------
# LS, GREP AND DIRCOLORS
# -----------------------------------------------------------------

# we always pass these to ls(1)
LS_COMMON="-hBG"

# setup the main ls alias if we've established common args
test -n "$LS_COMMON" &&
alias ls="command ls $LS_COMMON"

# these use the ls aliases above
alias ll="ls -l"
alias l.="ls -d .*"
alias ll.="ls -dl .*"
alias lla="ls -al"

# grep colors
if echo hello|grep --color=auto l >/dev/null 2>&1; then
    export GREP_OPTIONS='--color=auto' GREP_COLOR='1;32'
fi



# -----------------------------------------------------------------
# PATH MANIPULATION FUNCTIONS
# -----------------------------------------------------------------

puniq () {
    echo "$1" |tr : '\n' |nl |sort -u -k 2,2 |sort -n |
    cut -f 2- |tr '\n' : |sed -e 's/:$//' -e 's/^://'
}

# condense PATH entries
PATH=$(puniq $PATH)
#MANPATH=$(puniq $MANPATH)


# -----------------------------------------------------------------
# SOURCING LOCAL .BASHRC
# -----------------------------------------------------------------

if [ -f ~/.bashrc.local ]; then
    source ~/.bashrc.local
fi


# -----------------------------------------------------------------
# AMAZON EC2 KEY PATHS
# -----------------------------------------------------------------

export EC2_PRIVATE_KEY="/var/www/server/current/config/amazon.key.pem"
export EC2_CERT="/var/www/server/current/config/amazon.cert.pem"



# misc
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

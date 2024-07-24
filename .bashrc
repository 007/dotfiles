#!/bin/bash

# source our shared functions
[ -e .posix_functions ] && source .posix_functions

# source aliases
[ -e .bash_alises ] && source .bash_aliases

function checkruneval { # eval command if it exists {{{
  type -P "${1}" > /dev/null && eval "$(eval "$@")"
} # }}}

function prefix_path { # add a prefix to the path if it exists and isn't already in the path {{{
    [[ ! "$PATH" =~ $1 && -e "$1" ]] && export PATH="${1}:${PATH}"
} # }}}

function suffix_path { # add a suffix to the path if it exists and isn't already in the path {{{
    [[ ! "$PATH" =~ $1 && -e "$1" ]] && export PATH="${PATH}:${1}"
} # }}}

# EXPORTS - swanky variables {{{
export EDITOR="vim"
export BROWSER=/home/rmoore/bin/echobrowser
export SRC_HOME=${HOME}/src
export XDISPLAY="$DISPLAY"
unset DISPLAY
export AWS_SDK_LOAD_CONFIG=1
export AWS_EC2_METADATA_DISABLED=true
export BASH_SILENCE_DEPRECATION_WARNING=1 # yes apple, I want to use bash

# go config
export GOCACHE="${HOME}/.cache/go"
export GOMODCACHE="${HOME}/.cache/go/pkg/mod"

# end exports }}}

# SHELL - magic shell incantations {{{

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
export HISTCONTROL=ignoreboth
# infinite history
HOSTNAME="$(hostname)"
HOSTNAME_SHORT="${HOSTNAME%%.*}"
mkdir -p "${HOME}/.history/$(date -u +%Y/%m/)" > /dev/null 2>&1
SESSIONPREFIX=$(date -u +%Y/%m/%d.%H.%M.%S)
export HISTFILE="${HOME}/.history/${SESSIONPREFIX}_${HOSTNAME_SHORT}_$$"
export HISTFILESIZE=500000
export HISTSIZE=500000
export PROMPT_COMMAND="history -a"

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# need gpg-agent ssh ability
export SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh
GPG_TTY=$(tty) && export GPG_TTY
pgrep -u $(id -u) gpg-agent > /dev/null || gpg-agent --daemon --enable-ssh-support > /dev/null 2>&1

# secrets, but only for interactive shells and only if we have secrets and gpg installed
grep -q i <<< $- && [ -e ~/secrets.sh.gpg ] && source /dev/stdin <<< $(type -P gpg && gpg --no-tty -q -d ~/secrets.sh.gpg)

# fancy PS1 with colors and such
if [ -x /usr/bin/tput ] && grep -q i <<< $- && tput setaf 1 >&/dev/null; then
    COLOR_RESET="$(tput sgr0)" && export COLOR_RESET
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[0;31m\]@\[\033[0;33m\]\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\n\$ '
  else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# end shell }}}

# PATHS - things we want to find easily {{{

# add paths carefully - match on the path we're adding so we don't double-add
prefix_path /usr/local/git/bin
prefix_path /usr/local/pear/bin
prefix_path /Applications/Xcode.app/Contents/Developer/usr/bin
prefix_path "/usr/local/opt/coreutils/libexec/gnubin"
prefix_path "/opt/homebrew/sbin"
prefix_path "/opt/homebrew/bin"
prefix_path "${HOME}/bin"
prefix_path "${HOME}/anaconda3/bin"
suffix_path "${HOME}/.local/bin"

# end paths }}}

# ETC - other stuff {{{

[[ -e "/etc/bash_completion" ]] && . /etc/bash_completion
[[ -f "/usr/local/etc/bash_completion" ]] && . /usr/local/etc/bash_completion
[[ -e "/usr/local/bin/aws_completer" ]] && complete -C '/usr/local/bin/aws_completer' aws

checkruneval dircolors
checkruneval thefuck --alias
#checkruneval minikube completion bash
checkruneval kubectl completion bash
# bonsai completion, but only for interactive shells
#grep -q i <<< $- && source <(cd ~/src/av;bonsai completion dump bash)

# end etc }}}

#eof

# [[ ! "$PATH" =~ $1 && -e "$1" ]] && export PATH="${1}:${PATH}"
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
[[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

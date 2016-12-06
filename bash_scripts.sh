#!/bin/bash

# FUNCTIONS - more complicated mojo {{{
function rekey-prod-robot {
  gpg -qd ${GR_HOME}/engineering/ssh/private/github-grh-drone-id-rsa-honesty.pem.gpg | gpg --quiet --symmetric --armor --cipher-algo AES256 -o $(grep 'echo stack=' original.json | head -1 | perl -pe 's/.*echo stack=(.*)\\n",/\1/').key.gpg --passphrase $(grep 'echo robot_password=' original.json | head -1 | perl -pe 's/.*echo robot_password=(.*)\\n",/\1/') --no-use-agent && aws s3 cp $(grep 'echo stack=' original.json | head -1 | perl -pe 's/.*echo stack=(.*)\\n",/\1/').key.gpg s3://grnds-production-robot/
}

function confirm { # require "YES" to be entered for a confirmation {{{
  read -t 60 -p "$1 [yes/NO] : "
  if [ "$REPLY" == "YES" ] ; then
    echo "YES"
    return 0
  else
    echo "NO"
    return -1
  fi
} # }}}

function smore { # syntax hilighting more command {{{
for S in $*; do source-highlight -i $S --out-format=esc -o STDOUT|more -r;done
} # }}}

function sniff_basics { # fix basic errors found in sniff {{{
#cat "$1" | sed 's/){/) {/g;s/if(/if (/g;s/' > temp1.php
sed 's/){/) {/g;s/if(/if (/g;s/foreach(/foreach (/g;s/for(/for (/g;s/}else/} else/g;s/else{/else {/g;s/while(/while (/g;s/( /(/g;s/ )/)/g;s/\s\+$//g;' < "$1" > temp1.php && mv temp1.php "$1"
} # }}}

function gitsync { # stash any changes, rebase from SVN and restore stash {{{
    if [ ! -e .git/ ]; then
        echo "not a git repo?"
        return
    fi
    echo 'foo' > rebase_foo &&
    git add rebase_foo &&
    git stash --quiet &&
    benice git svn rebase &&
    git stash pop --quiet &&
    git reset HEAD rebase_foo
    rm -f rebase_foo

    NOW_TIME="$(date +%s)"
    LAST_GC="$(stat --format=%Y .git/hooks/lastgc 2>/dev/null)"
    GC_DELTA="$(( NOW_TIME - LAST_GC ))"

    # run aggressive GC every 4 weeks
    if [ $GC_DELTA -gt $(( 86400 * 28 )) ]; then
        echo "Time to GC"
        touch .git/hooks/lastgc
        benice git gc --aggressive
    else
        echo "$(( GC_DELTA / 86400 )) days since last GC"
    fi
    echo -n "fsync... "
    sync
    echo "done"
} # }}}

function aws-check-instance-health { # check iowait and cpusteal for CFN instances {{{
    STACK_NAME=$(aws cloudformation describe-stacks | jq -r .Stacks[0].StackName)
    echo "Fetching instances for $STACK_NAME"
    for sys in $(aws cloudformation get-template --stack-name $STACK_NAME | jq -r .TemplateBody.Resources[].Properties.Name | grep -v null | grep -v vpngw | sort); do
        echo $(ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $sys "top -b -n5 -d0.1 | grep %Cpu | tail -1 | perl -pe 's/.*(\d+\.\d) wa,.*(\d+\.\d) st/wait: \$1 steal: \$2/'") sys: $sys
    done
} # }}}

function aws-lb-health { # enumerate load balancers, then show InService or OutOfService for each instance {{{
  for lb in $(aws elb describe-load-balancers | jq -r .LoadBalancerDescriptions[].LoadBalancerName); do
    echo "$lb $(aws elb describe-instance-health --load-balancer $lb | jq -r .InstanceStates[].State | xargs echo)"
  done
} # }}}

function gravatar { # show a gravatar for an email {{{
  display "https://s.gravatar.com/avatar/$(echo -n "$@" | md5sum | awk '{print $1}')?s=250"
} # }}}

function all-repo-stats { # show status and branch info for all repos {{{
  for i in ${GR_HOME}/*/.git/; do
    pushd ${i%.git/} > /dev/null 2> /dev/null
    # if we're on a non-feature branch, revert to master
    git status 2>/dev/null | head -1 | grep -Pq 'On branch rc/branch/\d{4}-\d{2}-\d{2}' && git checkout master >/dev/null 2>&1
    if [ "$(git status --porcelain)" == "" ] ; then
      if git status 2>/dev/null | head -1 | grep -Pq 'On branch master'; then
        # clean master branch
        STATUS_COLOR="\e[1;32m"
      else
        # clean branch, but not master
        STATUS_COLOR="\e[1;33m"
      fi
    else
      STATUS_COLOR="\e[1;31m"
    fi
    echo -e ${STATUS_COLOR} $(pwd;git status 2> /dev/null | head -2) ${COLOR_RESET} | paste - -
    popd > /dev/null
  done
} # }}}

function all-repo-update { # git update all repos {{{
  for i in ${GR_HOME}/*/.git/; do
    echo ""
    pushd ${i%.git/} > /dev/null 2> /dev/null
    echo $(pwd)
    # if we're on a non-feature branch, revert to master
    git status 2>/dev/null | head -1 | grep -Pq 'On branch rc/branch/\d{4}-\d{2}-\d{2}' && git checkout master >/dev/null 2>&1
    git pull
    if [ -a Gemfile ] ; then
      ping -c1 -w1 rubygems.org > /dev/null && gem install bundler && bundle | grep -v ^Using
    fi
    sleep 3
    popd > /dev/null
  done
} # }}}

function all-repo-clean { # clean out merged branches {{{
  for i in ${GR_HOME}/*/.git/; do
    pushd ${i%.git/} > /dev/null 2> /dev/null
    echo "pushd $(pwd)"
    git pull | grep -v 'up.to.date'
    git fetch --prune
    git branch --merged | grep -v '^\*' | grep -v 'rc/branch/'| grep -vE '^\s+master\s*$' | grep -vE '^\s+gh-pages\s*$' | sed 's/^/git branch -d/g'
    echo "git repack -a -d -f --depth=1000 --window=500"
    popd > /dev/null
    echo "popd"
  done
} # }}}

function prefix_path { # add a prefix to the path if it exists and isn't already in the path {{{
    [[ ! "$PATH" =~ "$1" && -e "$1" ]] && export PATH="${1}:${PATH}"
} # }}}

function suffix_path { # add a suffix to the path if it exists and isn't already in the path {{{
    [[ ! "$PATH" =~ "$1" && -e "$1" ]] && export PATH="${PATH}:${1}"
} # }}}

function gpgrep {
  find . -type f -name '*.gpg' -exec sh -c "gpg -q -d --no-tty \"{}\" | grep -InH --color=auto --label=\"{}\" $@" \;
}


# end functions }}}

# EXPORTS - swanky variables {{{

export EDITOR="vim"
export IPSEC_SECRETS_FILE="/usr/local/etc/ipsec.secrets"
export KEY_SUFFIX="grandrounds.com"
export GR_HOME=${HOME}/src
export GR_USERNAME="ryan.moore"
export COLOR_RESET="\e[0m"

# secrets, but only for interactive shells and only if we have secrets
/bin/grep -q i <<< $- && [ -a ~/secrets.sh.gpg ] && source /dev/stdin <<< $(gpg --no-tty -q -d ~/secrets.sh.gpg)

# end exports }}}

# SHELL - magic shell incantations {{{

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
export HISTCONTROL=ignoreboth
# infinite history
HOSTNAME="$(hostname)"
HOSTNAME_SHORT="${HOSTNAME%%.*}"
mkdir -p ${HOME}/.history/$(date -u +%Y/%m/) > /dev/null 2>&1
export HISTFILE="${HOME}/.history/$(date -u +%Y/%m/%d.%H.%M.%S)_${HOSTNAME_SHORT}_$$"
export HISTFILESIZE=500000
export HISTSIZE=500000
export PROMPT_COMMAND="history -a"

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# end shell}}}

# ALIASES - one-liners and whatnot {{{

# linux has /proc, osx doesn't
[ -a /proc ] && alias ll='ls -alF --color=auto' || alias ll='ls -Gal'

alias jslint='jsl -nologo -nocontext -nofilelisting -nosummary -process'
alias fixmacdns='dscacheutil -flushcache'
alias fact="curl -s randomfunfacts.com | grep strong | cut -d\> -f5- | cut -d\< -f1"
alias critic='svnperl | xargs perlcritic -p ~/.perlcriticrc.local --statistics --verbose "%f:%l:%c:[%p] %m\n"'
alias svngrep='find . -xdev -type f -not -path "*.svn/*" -not -path "*.git/*" -print0 2>/dev/null | xargs -0 grep --color=auto -InH'
alias histgrep='find ~/.history/ -type f -print0 2>/dev/null | xargs -0 grep --color=auto -InH'
alias lintperl="svnperl | xargs -I{} perl -cIlib {}"
alias lockup='light-locker-command --lock'
alias emacs="emacs -nw"
alias grep="grep --color=auto"
alias benice="nice -n19 ionice -c 3"
alias ..="cd .."
alias devsrc="for i in \$(find ~/src/engineering/bash -type f -o -type l); do echo \$i;source \$i;done"
alias icd10='xzcat ~/icd10.txt.xz | grep'
alias lintpuppet='find . -type f -name "*.pp" -exec puppet parser validate {} + && puppet-lint --fail-on-warnings modules || figlet FAIL'
alias sfo='sudo ipsec down grnds-sfo;sudo ipsec stop;sleep 3;sudo ipsec start;sleep 3;sudo ipsec up grnds-sfo'
alias gitgc='git repack -a -d -f --depth=1000 --window=500'
alias savepower='sudo powertop --auto-tune;xinput disable 9;sudo tee /proc/acpi/ibm/bluetooth <<< disabled >/dev/null;sudo tee /sys/class/backlight/intel_backlight/brightness <<< 426 >/dev/null'
alias mousefix='gsettings set org.gnome.settings-daemon.plugins.cursor active false'
alias prodincexstat='mysql --login-path=prod-primary -e "SELECT * FROM delayed_jobs WHERE queue = \"reports\" AND handler LIKE \"%id: 27%\"\G" jarvis_production'
alias prodmysqlstat='mysql --login-path=prod-primary -e "SHOW ENGINE INNODB STATUS\G" | grep -C2 TRANSACTION'
alias qreset='echo -e "\0033\0143"'

# end aliases }}}

# PATHS - things we want to find easily {{{

# add paths carefully - match on the path we're adding so we don't double-add
prefix_path /usr/local/git/bin
prefix_path /usr/local/pear/bin
prefix_path /Applications/Xcode.app/Contents/Developer/usr/bin
prefix_path "${HOME}/bin"
prefix_path "${HOME}/.rvm/bin"
suffix_path "${HOME}/src/engineering/bin"

# end paths }}}

# ETC - other stuff {{{

[[ -e "/etc/bash_completion" ]] && . /etc/bash_completion
[[ -e "/usr/share/awscli/aws_completer" ]] && complete -C '/usr/share/awscli/aws_completer' aws
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
[[ -e /usr/bin/dircolors ]] && eval $(/usr/bin/dircolors)
[[ -e /usr/local/bin/thefuck ]] && eval $(thefuck --alias)

# end etc }}}

#eof


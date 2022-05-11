#!/bin/bash

# FUNCTIONS - more complicated mojo {{{
function assume-aws-role {
  my_role="arn:aws:iam::${1}:role/OrganizationAccountAccessRole"

  role_creds=$(aws sts assume-role --role-arn "${my_role}" --role-session-name "OrgAccess")

  eval $(jq -r '.Credentials|
  "export AWS_ACCESS_KEY_ID=" + .AccessKeyId,
  "export AWS_SECRET_ACCESS_KEY=" + .SecretAccessKey,
  "export AWS_SESSION_TOKEN=" + .SessionToken' <<< "${role_creds}")

  echo "AWS Access Keys and SessionToken set for assumed role. Session will expire in ~1hr"
}

function dotplan {
  T=`mktemp` && curl -so $T https://plan.cat/~007 && $EDITOR $T && curl -su 007 -F "plan=<$T" https://plan.cat/stdin && rm "$T"
}

function confirm { # require "YES" to be entered for a confirmation {{{
  read -t 60 -p "$1 [yes/NO] : "
  if [ "$REPLY" == "YES" ] ; then
    echo "YES"
    return 0
  else
    echo "NO"
    return 1
  fi
} # }}}

function tax { # syntax hilighting command {{{
  if [ "$(date --date='8 hours ago' +%H)" -gt 12 ] ; then
    style='paraiso-dark'
  else
    style='rrt'
  fi

  for S in "$@"; do
    # if file has a suffix, lex as-is
    pygmentize -O style=$style -f terminal256 "$S";done
    
    # if not, guess-and-lex
    #cat "$S" | pygmentize -C
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

function avsync {
  local t
  nice -n19 ionice -c 3 git checkout main
  nice -n19 ionice -c 3 git fetch --prune --tags --prune-tags
  nice -n19 ionice -c 3 git merge FETCH_HEAD
  for t in min-ci lastci truck-lastci common_pull_point pbt-engdev-lastci sienna-engdev-lastci; do
    nice -n19 ionice -c 3 git fetch --force origin refs/tags/${t}:refs/tags/${t}
  done
}

function aws-check-instance-health { # check iowait and cpusteal for CFN instances {{{
    STACK_NAME=$(aws cloudformation describe-stacks | jq -r .Stacks[0].StackName)
    echo "Fetching instances for $STACK_NAME"
    for sys in $(aws cloudformation get-template --stack-name "$STACK_NAME" | jq -r .TemplateBody.Resources[].Properties.Name | grep -v null | grep -v vpngw | sort); do
        echo "$(ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$sys" "top -b -n5 -d0.1 | grep %Cpu | tail -1 | perl -pe 's/.*(\d+\.\d) wa,.*(\d+\.\d) st/wait: \$1 steal: \$2/'") sys: $sys"
    done
} # }}}

function aws-lb-health { # enumerate load balancers, then show InService or OutOfService for each instance {{{
  for lb in $(aws elb describe-load-balancers | jq -r .LoadBalancerDescriptions[].LoadBalancerName); do
    echo "$lb $(aws elb describe-instance-health --load-balancer "$lb" | jq -r .InstanceStates[].State | xargs echo)"
  done
} # }}}

function gcloudadmin {
  export GOOGLE_CLOUD_KEYFILE_JSON=${HOME}/.config/gcloud/cloud-admin-service-account.json
  gcloud auth activate-service-account --key-file=${GOOGLE_CLOUD_KEYFILE_JSON}
}

function gravatar { # show a gravatar for an email {{{
  open "https://s.gravatar.com/avatar/$(echo -n "$@" | md5sum | awk '{print $1}')?s=250"
} # }}}

function svg2png { # convert SVG to PNG nicely
  nice convert -background none -density 1200 "${1}" -depth 8 -trim +repage -geometry ${2-1024}x${2-1024}+ "${1}.png" && nice optipng -q -nx -strip all -o1 "${1}.png"
} # }}}

function all-repo-stats { # show status and branch info for all repos {{{
  for i in ${SRC_HOME}/*/.git/; do
    pushd "${i%.git/}" > /dev/null 2> /dev/null
    # if we're on a non-feature branch, revert to gitflow default
    git status 2>/dev/null | head -1 | grep -q 'On branch rc/' && git checkout develop >/dev/null 2>&1
    if [ "$(git status --porcelain)" == "" ] ; then
      if git status 2>/dev/null | head -1 | grep -q 'On branch develop'; then
        # clean default branch
        STATUS_COLOR="$(tput setaf 2)"
      else
        # clean branch, but not default
        STATUS_COLOR="$(tput setaf 3)"
      fi
    else
      STATUS_COLOR="$(tput setaf 1)"
    fi
    echo -e "${STATUS_COLOR}" "$(pwd;git status 2> /dev/null | head -2)" "${COLOR_RESET}" | paste -d\  - - -
    popd > /dev/null
  done
} # }}}

function all-repo-update { # git update all repos {{{
  for i in ${SRC_HOME}/*/.git/; do
    echo ""
    pushd "${i%.git/}" > /dev/null 2> /dev/null
    pushd "${i%.git/}" > /dev/null 2> /dev/null
    pwd
    # if we're on a non-feature branch, revert to master
    git status 2>/dev/null | head -1 | grep -q 'On branch rc/' && git checkout develop >/dev/null 2>&1
    git pull
    popd
    if [ -e Gemfile ] ; then
      ping -c1 -w1 rubygems.org > /dev/null && gem install bundler && bundle | grep -v ^Using
    fi
    popd > /dev/null
  done
} # }}}

function all-repo-clean { # clean out merged branches {{{
  for i in ${SRC_HOME}/*/.git/; do
    pushd "${i%.git/}" > /dev/null 2> /dev/null
    pwd
    git pull | grep -v 'up.to.date'
    git fetch --prune
    git branch --merged | grep -v '^\*' | grep -v 'rc/branch/'| grep -vE '^\s+master\s*$' | grep -vE '^\s+gh-pages\s*$' | xargs --no-run-if-empty git branch -d
    git repack -a -d -f --depth=1000 --window=500
    if [ -e Gemfile -a -e .ruby-gemset ] ; then
      rvm --force gemset empty;cd .;gem install bundler && bundle
    fi
    popd > /dev/null
  done
} # }}}

function flow-rebase {
  local OLD_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "Will switch back to $OLD_BRANCH when done"
  git checkout master
  git fetch --prune
  git pull
  bonsai show

  if [[ "${1:-all}" == "all" ]]; then
    bonsai cascade --rebase
  else
    for BRANCH in "$@"; do
      bonsai cascade --rebase master "$BRANCH"
    done
  fi
  bonsai branch "$OLD_BRANCH"
  bonsai show
}

function prefix_path { # add a prefix to the path if it exists and isn't already in the path {{{
    [[ ! "$PATH" =~ $1 && -e "$1" ]] && export PATH="${1}:${PATH}"
} # }}}

function suffix_path { # add a suffix to the path if it exists and isn't already in the path {{{
    [[ ! "$PATH" =~ $1 && -e "$1" ]] && export PATH="${PATH}:${1}"
} # }}}

function gpgrep {
  find . -type f -name '*.gpg' -exec sh -c "gpg -q -d --no-tty \"{}\" | grep -InH --color=auto --label=\"{}\" $*" \;
}

function savepower {
  sudo powertop --auto-tune
  TOUCHSCREEN_ID=$(xinput list | grep Touchscreen | perl -pe 's/.*id=(\d+).*/\1/')
  xinput disable "${TOUCHSCREEN_ID}"
  sudo tee /proc/acpi/ibm/bluetooth <<< disabled >/dev/null
  HALFBRIGHT=$(( $(cat /sys/class/backlight/intel_backlight/max_brightness) / 2))
  sudo tee /sys/class/backlight/intel_backlight/brightness <<< ${HALFBRIGHT} >/dev/null
}

# shellcheck disable=SC2005
function genpass-simple {
  echo "$(LC_ALL=C tr -cd A-Za-z0-9 < /dev/urandom | head -c${1:-16})"
}

# shellcheck disable=SC2005
function genpass-hex {
  echo "$(LC_ALL=C tr -cd a-f0-9 < /dev/urandom | head -c${1:-16})"
}

# shellcheck disable=SC2005
function genpass-b64 {
  echo "$(base64 -w0 < /dev/urandom | head -c${1:-32})"
}

# shellcheck disable=SC2005
function genpass-complex {
  echo "$(LC_ALL=C tr -cd ' -~' < /dev/urandom | head -c${1:-64})"
}

function genpass-annoying {
  echo "$(LC_ALL=C tr -cd iIl1oO0B8S5 < /dev/urandom | head -c${1:-32})"
}


# if (command exists) { run cmdline && eval output into current shell }
# wrapper to simplify this: type -P thefuck > /dev/null && eval "$(thefuck --alias)"
function checkruneval () {
  type -P "${1}" > /dev/null && eval "$(eval "$@")"
}

function wayback {
  curl "https://web.archive.org/save/${1}"
}

# end functions }}}

# EXPORTS - swanky variables {{{

export EDITOR="vim"
export SRC_HOME=${HOME}/src

# need gpg-agent ssh ability
export SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh
GPG_TTY=$(tty) && export GPG_TTY
pgrep -u $(id -u) gpg-agent > /dev/null || gpg-agent --daemon --enable-ssh-support > /dev/null 2>&1

# secrets, but only for interactive shells and only if we have secrets
grep -q i <<< $- && [ -e ~/secrets.sh.gpg ] && source /dev/stdin <<< $(gpg --no-tty -q -d ~/secrets.sh.gpg)

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

# end shell }}}
export AURORA_DEVPLATFORM_PREVIEW=true

# ALIASES - one-liners and whatnot {{{


alias jslint='jsl -nologo -nocontext -nofilelisting -nosummary -process'
alias fixmacdns='dscacheutil -flushcache'
alias fact="curl -s randomfunfacts.com | grep strong | cut -d\> -f5- | cut -d\< -f1"
alias critic='svnperl | xargs perlcritic -p ~/.perlcriticrc.local --statistics --verbose "%f:%l:%c:[%p] %m\n"'
alias svngrep='find . -xdev -type f -not -path "*.svn/*" -not -path "*.git/*" -print0 2>/dev/null | xargs -0 grep --color=auto -InH'
alias histgrep='find ~/.history/ -type f -print0 2>/dev/null | xargs -0 grep --color=auto -InH'
alias lintperl="svnperl | xargs -I{} perl -cIlib {}"
alias lockup='light-locker-command --lock'
alias ll='ls -alF --color=auto'
alias emacs="emacs -nw"
alias grep="grep --color=auto"
alias benice="nice -n19 ionice -c 3"
alias ..="cd .."
alias lintpuppet='find . -type f -name "*.pp" -exec puppet parser validate {} + && puppet-lint --fail-on-warnings modules || figlet FAIL'
alias gitgc='nice -n19 ionice -c 3 git repack -a -d -f --depth=1000 --window=500'
alias gitdev='git log --oneline develop..HEAD'
alias gitdevp='git log -p develop..HEAD'
alias gitdevd='git diff develop..HEAD'
alias mousefix='gsettings set org.gnome.settings-daemon.plugins.cursor active false'
alias qreset='echo -e "\0033\0143"'
alias lrmax='lrzip -vv -Uz -N 19 -L 9'
alias xzmax='xz -9evv --lzma2=dict=128MiB,lc=4,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=1024'
alias startipy='screen -S jupyter -Q select . || screen -dmS jupyter jupyter notebook --notebook-dir=${HOME}/src/personal/carnd'
alias nukedocker='ps -a -q | xargs --no-run-if-empty docker rm;docker image list -q | grep -v 7c09e61e9035 | xargs --no-run-if-empty docker rmi'
alias jenkinsbackup='rsync -a --rsync-path="sudo rsync" --info=progress2 jenkins-master:/var/lib/jenkins/ ~/working/jenkins/'
alias updateqa='ssh -t qabox ./update-qa.sh'
alias brewup='brew update;brew upgrade;brew cask outdated | cut -d\  -f1 | xargs brew cask reinstall'
alias ecrlogin='eval "$(aws ecr get-login --no-include-email)"'
alias awslogin='bazel run //cloud/terraform:aws_auth -- login'
alias k8slogin='bazel run //cloud/terraform:aws_auth -- k8s'
alias ubuntu='docker run --rm -it --mount type=bind,source=${HOME}/working,target=/working ubuntu:focal'
alias spacelift-container='docker run --rm -it public.ecr.aws/spacelift/runner-terraform:latest'
alias youtube-dl='youtube-dl --format '\''22/bestvideo[height<=?720][ext=mp4]+bestaudio[ext=m4a]'\'''
alias tfgo='terraform init && terraform get && terraform plan -out plan.out'
alias ident='figlet -w $COLUMNS -r $USER | lolcat -p 0.3'
alias fedrate='curl -s https://fred.stlouisfed.org/data/MORTGAGE15US.txt | tail -1 | awk '\''{print "Fed rate for " $1 " is " $2}'\'''
alias googsync='LOG_LEVEL=debug time bazel run //cloud/terraform:sso_admin -- sync-google --test-org --save-temp'
alias awsfind='2>/dev/null bazel run //cloud/terraform:acct_mgr find'
alias spaceliftdns='dig @8.8.8.8 +noall +answer +dnssec aurora-tech.app.spacelift.io'

# end aliases }}}

# PATHS - things we want to find easily {{{

# add paths carefully - match on the path we're adding so we don't double-add
prefix_path /usr/local/git/bin
prefix_path /usr/local/pear/bin
prefix_path /Applications/Xcode.app/Contents/Developer/usr/bin
prefix_path "/usr/local/opt/coreutils/libexec/gnubin"
prefix_path "${HOME}/bin"
prefix_path "${HOME}/anaconda3/bin"

# end paths }}}

# ETC - other stuff {{{

[[ -e "/etc/bash_completion" ]] && . /etc/bash_completion
[[ -f "/usr/local/etc/bash_completion" ]] && . /usr/local/etc/bash_completion
[[ -e "/usr/local/bin/aws_completer" ]] && complete -C '/usr/local/bin/aws_completer' aws
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

checkruneval dircolors
checkruneval thefuck --alias
#checkruneval minikube completion bash
checkruneval kubectl completion bash
checkruneval kops completion bash
source <(cd ~/src/av;bonsai completion dump bash)

# end etc }}}

#eof
alias avgitsync=" rsync -a --no-i-r --info=progress2 ~/src/av/ palpatine:~/working/av/"



_direnv_hook() {
  local previous_exit_status=$?;
  eval "$(direnv export bash)";
  return $previous_exit_status;
};
if ! [[ "$PROMPT_COMMAND" =~ _direnv_hook ]]; then
  PROMPT_COMMAND="_direnv_hook;$PROMPT_COMMAND";
fi


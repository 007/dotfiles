#!/bin/bash
# add paths carefully - match on the path we're adding so we don't double-add
[[ "$PATH" =~ .*\/usr\/local\/git\/bin.* ]] || export PATH=/usr/local/git/bin:$PATH
[[ "$PATH" =~ .*\/usr\/local\/pear\/bin.* ]] || export PATH=/usr/local/pear/bin:$PATH
[[ "$PATH" =~ .*\/Applications\/Xcode.app\/Contents\/Developer\/usr\/bin.* ]] || export PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH
[[ "$PATH" =~ .*\/home\/rmoore\/bin.* ]] || export PATH=/home/rmoore/bin:$PATH
[[ "$PATH" =~ .*\/Users\/rmoore\/bin.* ]] || export PATH=/Users/rmoore/bin:$PATH


# EXPORTS - swanky variables {{{

#export SSH_ASKPASS="/usr/libexec/ssh-askpass"
export EDITOR="vim"
export HISTCONTROL=ignoreboth
export HISTFILESIZE=50000
export HISTSIZE=50000

# end exports }}}

# ALIASES - one-liners and whatnot {{{

# linux has /proc, osx doesn't
[ -a /proc ] && alias ll='ls -al --color=yes' || alias ll='ls -Gal'

alias svnperl="svn st | grep '^\(M\|A\)' | awk '{print \$2;}' | grep '^\(lib\|bin\|worker\|cgi\|t\)'"
alias jslint='jsl -nologo -nocontext -nofilelisting -nosummary -process'
alias fixdns='dscacheutil -flushcache'
alias lssub='find . -type f -not -path "*.svn/*" -not -path "*.git/*" -print0 | xargs -0 stat -F'
alias fact="curl -s randomfunfacts.com | grep strong | cut -d\> -f5- | cut -d\< -f1"
alias critic='svnperl | xargs perlcritic -p ~/.perlcriticrc.local --statistics --verbose "%f:%l:%c:[%p] %m\n"'
alias svngrep='find . -type f -not -path "*.svn/*" -not -path "*.git/*" -not -path "*testenv/*" -print0 | xargs -0 grep -InH'
alias lintperl="svnperl | xargs -I{} perl -cIlib {}"
alias emacs="emacs -nw"
alias grep="grep --color=auto"
alias benice="nice -n19 ionice -c 3"
alias ..="cd .."

# end aliases }}}

# FUNCTIONS - more complicated mojo {{{

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

function stash { # svn equivalent of "git stash" {{{
    STASH_STORE="${HOME}/stash"
    PATCH_STORE="${STASH_STORE}/patch"
    DONE_STORE="${STASH_STORE}/applied"
    mkdir -p ${PATCH_STORE}
    mkdir -p ${DONE_STORE}
    if [ "$1" == "pop" ] ; then
        echo "trying to pop"
        if [ "$2" == "" ] ; then
            PATCHFILE=`ls -t1 ${PATCH_STORE}/ | head -1`
        else
            PATCHFILE="$2"
        fi
        PATCHFULL="${PATCH_STORE}/${PATCHFILE}"
        echo "Applying ${PATCHFULL}"
        if [ -e "${PATCHFULL}" ] ; then
            patch -p0 < ${PATCHFULL} && mv ${PATCHFULL} ${DONE_STORE}/
        else
            echo "Failed to restore ${PATCHFULL}, file doesn't exist?"
        fi
    else
        # add to stash
        TS=`date '+%Y-%m-%d_%H.%M.%S'`
        sleep 1
        svn diff --diff-cmd=diff > ${PATCH_STORE}/${TS}
        svn revert -R .
        echo "Saved changes to $TS"
    fi
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

# end functions }}}

source ~/perl5/perlbrew/etc/bashrc

#eof

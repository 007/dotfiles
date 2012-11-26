#!/bin/bash
# add paths carefully - match on the path we're adding so we don't double-add
[[ "$PATH" =~ .*\/usr\/local\/git\/bin.* ]] || export PATH=/usr/local/git/bin:$PATH
[[ "$PATH" =~ .*\/usr\/local\/pear\/bin.* ]] || export PATH=/usr/local/pear/bin:$PATH
[[ "$PATH" =~ .*\/Applications\/Xcode.app\/Contents\/Developer\/usr\/bin.* ]] || export PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH
[[ "$PATH" =~ .*\/Users\/rmoore\/bin.* ]] || export PATH=/Users/rmoore/bin:$PATH

export SSH_ASKPASS="/usr/libexec/ssh-askpass"

# EXPORTS - swanky variables {{{

export SVNSERVER="svn+ssh://svn.polyvore.net/home/svn/repository"
export EDITOR="vim"
HISTFILESIZE=50000
HISTSIZE=50000

# end exports }}}

# ALIASES - one-liners and whatnot {{{

alias ll="ls -Gal"
alias jslint='jsl -nologo -nocontext -nofilelisting -nosummary -process'
alias fixdns='dscacheutil -flushcache'
alias lssub='find . -type f -not -path "*.svn/*" -print0 | xargs -0 stat -F'
alias fact="curl -s randomfunfacts.com | grep strong | cut -d\> -f5- | cut -d\< -f1"
alias htop="top -u"
alias p4merge="~/bin/p4merge.app/Contents/MacOS/p4merge"
alias critic="svn st | grep ^M | cut -c2- | xargs perlcritic --statistics --verbose '%f:%l:%c:[%p] %m\n'"
alias svngrep="find . -type f -not -path '*.svn/*' -not -path '*.git/*' -print0 | xargs -0 grep -InH"

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

# end functions }}}

#eof

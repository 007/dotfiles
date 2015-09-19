# ~/.bash_logout: executed by bash(1) when login shell exits.

# write history to file, just in case
history -a

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

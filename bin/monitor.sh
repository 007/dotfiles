#!/bin/bash

read -s -p "Sudo Password: " password

tmux new-session -d -A -s monitor htop -u rmoore -s PERCENT_CPU
tmux split-window -v watch -n 10 "free -h;df -h --output / /home /tmp /ephemeral"

# new sudo window, then switch to activate it and sendkeys password^M
tmux split-window -v sudo bash -c 'sysctl kernel.task_delayacct=1 && iotop -o -d5 -P; sysctl kernel.task_delayacct=0'
tmux select-pane -t 2
tmux send-keys "$password" C-m

tmux split-window -v watch -n 10 nvidia-smi

# because we can't resize to fixed elements - resize bottom window ALL THE WAY up
tmux select-pane -t 3
tmux resize-pane -U 999

# resize htop to fit 64 CPUs and 8 processes
tmux select-pane -t 0
tmux resize-pane -D 31

# Resize free/df to fit 4 filesystems
tmux select-pane -t 1
tmux resize-pane -D 15

# Resize iotop down to fit just the important bits of nvidia-smi
tmux select-pane -t 2
tmux resize-pane -D 10

# now attach, so we can run `ssh -t vdesk bin/monitor.sh` all-in-one
tmux -2 attach-session -t monitor


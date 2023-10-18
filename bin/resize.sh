#!/bin/bash
set -x


# because we can't resize to fixed elements - resize bottom window ALL THE WAY up
tmux select-pane -t 3
tmux resize-pane -U 999

# resize htop to fit 16 CPUs and 2 processes
tmux select-pane -t 0
tmux resize-pane -D 12
sleep 10

# Resize free/df to fit 4 filesystems
tmux select-pane -t 1
tmux resize-pane -D 10
sleep 10

# Resize iotop down to fit just the important bits of nvidia-smi
tmux select-pane -t 2
tmux resize-pane -D 10


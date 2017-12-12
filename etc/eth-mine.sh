#!/bin/bash

# Add to cron to start mining on reboot
# @reboot /home/USERNAME/eth-mine.sh

tmux new-session -d -s ethereum
tmux send-keys -t ethereum "cd /home/DIR/TO/MINER
"
tmux send-keys -t ethereum "./start.bash
"

#!/bin/bash
rm -f ~/triage_win.jsonl ~/triage_mac.jsonl ~/triage_win.log ~/triage_mac.log
nohup env JOBS=24 bash ~/triage_focused.sh ~/app-player/android-13 win ~/triage_win.jsonl > ~/triage_win.log 2>&1 &
echo WIN_PID=$!
nohup env JOBS=24 bash ~/triage_focused.sh ~/app-player-mac/android-mac mac ~/triage_mac.jsonl > ~/triage_mac.log 2>&1 &
echo MAC_PID=$!
sleep 1
ps -p $! -o pid,cmd | head

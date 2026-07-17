#!/bin/bash
rm -f ~/triage_ext_win.jsonl ~/triage_ext_mac.jsonl ~/triage_ext_win.log ~/triage_ext_mac.log
nohup env JOBS=16 bash ~/triage_external.sh ~/app-player/android-13 win ~/triage_ext_win.jsonl > ~/triage_ext_win.log 2>&1 &
echo WIN=$!
nohup env JOBS=16 bash ~/triage_external.sh ~/app-player-mac/android-mac mac ~/triage_ext_mac.jsonl > ~/triage_ext_mac.log 2>&1 &
echo MAC=$!

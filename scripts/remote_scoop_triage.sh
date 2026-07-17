#!/bin/bash
set -e
ps aux | grep -E '[t]riage_' | awk '{print $2}' | while read p; do kill "$p" 2>/dev/null || true; done
sleep 2
echo remaining:
ps aux | grep -E '[t]riage_' || echo none
WIN_TMP=$(ls -d /tmp/tmp.* 2>/dev/null | while read d; do ls "$d"/win-*.json >/dev/null 2>&1 && echo "$d"; done | head -1)
MAC_TMP=$(ls -d /tmp/tmp.* 2>/dev/null | while read d; do ls "$d"/mac-*.json >/dev/null 2>&1 && echo "$d"; done | head -1)
echo WIN_TMP=$WIN_TMP
echo MAC_TMP=$MAC_TMP
if [[ -n "$WIN_TMP" ]]; then cat "$WIN_TMP"/*.json 2>/dev/null | sort -u > ~/triage_win.partial.jsonl; fi
if [[ -n "$MAC_TMP" ]]; then cat "$MAC_TMP"/*.json 2>/dev/null | sort -u > ~/triage_mac.partial.jsonl; fi
wc -l ~/triage_win.partial.jsonl ~/triage_mac.partial.jsonl 2>/dev/null || true

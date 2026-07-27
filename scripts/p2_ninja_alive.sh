#!/bin/bash
# Check whether the main ninja process is making progress (ctxt/RSS delta).
set +u
N=$(pgrep -u markxu -f 'ninja -d keepdepfile.*combined-bst_x86_64' | head -1)
echo "ninja=$N"
if [ -z "$N" ]; then echo gone; exit 1; fi
# Prefer voluntary_ctxt_switches exact key (avoid matching nonvoluntary).
c1=$(awk '/^voluntary_ctxt_switches:/{print $2}' /proc/$N/status)
rss1=$(awk '/^VmRSS:/{print $2}' /proc/$N/status)
cpu1=$(ps -o pcpu= -p "$N" | tr -d ' ')
echo "t0 ctxt=$c1 rss=$rss1 cpu=$cpu1"
sleep 20
c2=$(awk '/^voluntary_ctxt_switches:/{print $2}' /proc/$N/status)
rss2=$(awk '/^VmRSS:/{print $2}' /proc/$N/status)
cpu2=$(ps -o pcpu= -p "$N" | tr -d ' ')
ch=$(pgrep -P "$N" 2>/dev/null | wc -l)
echo "t1 ctxt=$c2 rss=$rss2 cpu=$cpu2 children=$ch"
# integers only
c1=${c1:-0}; c2=${c2:-0}; rss1=${rss1:-0}; rss2=${rss2:-0}
echo "delta_ctxt=$((c2 - c1)) delta_rss=$((rss2 - rss1))"
if [ "$((c2 - c1))" -eq 0 ] && [ "$ch" -eq 0 ]; then
  echo "VERDICT=STUCK"
  exit 2
fi
echo "VERDICT=ALIVE"
free -h | head -2

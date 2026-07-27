#!/bin/bash
set +u
echo "=== ninja ==="
ps -o pid,etime,pcpu,rss,stat -p 2977059 2>/dev/null || ps -o pid,etime,pcpu,rss,stat -C ninja | head -5
echo "children=$(pgrep -P 2977059 2>/dev/null | wc -l)"
echo "=== Transitions brace check ==="
python3 - <<'PY'
from pathlib import Path
p=Path('/home/clouddev/bst/workspace/markxu/aosp16/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java')
t=p.read_text()
# naive brace balance in file
print('ENABLE line:', [l for l in t.splitlines() if 'ENABLE_SHELL_TRANSITIONS' in l and 'public static' in l][:2])
print('braces', t.count('{'), t.count('}'), 'diff', t.count('{')-t.count('}'))
PY
echo "=== await/build alive ==="
pgrep -u markxu -af 'g1_build_stable|await_v2|bin/m droid' | head -8
echo "=== any DONE yet ==="
rg 'DONE rc=|FAILED:|ninja: build stopped' ~/p2_cont22_mdroid.log | tail -10 || echo none
echo "=== error.log size ==="
wc -c ~/aosp16/out_nxt_Baklava64/error.log

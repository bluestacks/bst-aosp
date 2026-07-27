#!/bin/bash
set +u
echo "=== OPENGL env files ==="
rg -n 'BUILD_EMULATOR_OPENGL' ~/aosp16/out_nxt_Baklava64/soong/soong.environment.used.bst_x86_64.build 2>/dev/null | head -10
rg -n 'BUILD_EMULATOR_OPENGL' ~/aosp16/out_nxt_Baklava64/soong/ninja.environment 2>/dev/null | head -10
echo "=== services.jar intermediates ==="
find ~/aosp16/out_nxt_Baklava64/soong/.intermediates/frameworks/base/services -name 'services.jar' 2>/dev/null | head -15 | while read -r f; do ls -la "$f"; done
echo "=== DisplayRotation.class intermediate ==="
find ~/aosp16/out_nxt_Baklava64/soong/.intermediates/frameworks/base/services -name 'DisplayRotation.class' 2>/dev/null | head -5 | while read -r f; do ls -la "$f"; done
echo "=== ckati progress ==="
ps -o etime,pcpu,rss -p 2597239 2>/dev/null
rg -n 'regenerating|including |finishing Make|Starting ninja' ~/p2_cont21d_mdroid.log | tail -15

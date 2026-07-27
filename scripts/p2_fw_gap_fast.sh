#!/bin/bash
# Faster gap: compare BST-signal file lists a13 vs a16 (no full git diff --stat).
set +u
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base
OUT=~/p2_fw_gap_fast.txt
exec > >(tee "$OUT") 2>&1
echo "A16DBG:P2: fw gap FAST $(date -Is)"

PAT='BstHostCall|BstUtils|bluestacks|BlueStacks|isAppLaunchAllowed|BstFilterApps|sendOrientationToHost|setAppConfigDbParams|ActivityDisplayed|GRM'
echo '=== a13 BST-signal files ==='
rg -l "$PAT" "$A13" -g '*.java' -g '*.kt' -g '*.cpp' -g '*.h' 2>/dev/null | sed "s|$A13/||" | sort > /tmp/a13_bst_files.txt
wc -l /tmp/a13_bst_files.txt
echo '=== a16 BST-signal files ==='
rg -l "$PAT" "$A16" -g '*.java' -g '*.kt' -g '*.cpp' -g '*.h' 2>/dev/null | sed "s|$A16/||" | sort > /tmp/a16_bst_files.txt
wc -l /tmp/a16_bst_files.txt

echo '=== IN a13 NOT in a16 (missing port surface) ==='
comm -23 /tmp/a13_bst_files.txt /tmp/a16_bst_files.txt | tee /tmp/fw_missing.txt | head -80
echo "missing_count=$(wc -l </tmp/fw_missing.txt)"

echo '=== IN both (partially ported candidates) ==='
comm -12 /tmp/a13_bst_files.txt /tmp/a16_bst_files.txt | head -40

echo '=== subsystem buckets of missing ==='
awk -F/ '{
  if ($1=="services" && $2=="core") print "services/"$3"/"$4"/"$5;
  else if ($1=="packages") print $1"/"$2;
  else print $1"/"$2;
}' /tmp/fw_missing.txt | sort | uniq -c | sort -rn | head -40

echo '=== a13 vs a16 BstHostCall hit counts in key files ==='
for f in \
  services/core/java/com/android/server/wm/ActivityStarter.java \
  services/core/java/com/android/server/wm/WindowManagerService.java \
  services/core/java/com/android/server/wm/ActivityTaskManagerService.java \
  services/core/java/com/android/server/am/ActivityManagerService.java \
  core/java/android/util/BstUtils.java \
  core/java/com/bluestacks/os/BstFilterAppsManager.java
 do
  c13=$(rg -c 'BstHostCall|isAppLaunchAllowed|BstUtils|BstFilter' "$A13/$f" 2>/dev/null || echo 0)
  c16=$(rg -c 'BstHostCall|isAppLaunchAllowed|BstUtils|BstFilter' "$A16/$f" 2>/dev/null || echo 0)
  echo "$f a13=$c13 a16=$c16"
done

echo FAST_DONE

#!/bin/bash
set -euo pipefail
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base
CLASS=~/bst-aosp/patches/android-16/patches/p2-fw-classify
mkdir -p "$CLASS"
(cd "$A13" && git diff --numstat android-13.0.0_r49..HEAD -- . | awk '$1!="-" && $2!="-"{print $1+$2, $3}' | sort -n) > "$CLASS/a13_ns.txt"
: > "$CLASS/cont21_clean.txt"
: > "$CLASS/cont21_conflict.txt"
: > "$CLASS/cont21_missing.txt"
clean=0; conflict=0; missing=0
while read -r ns f; do
  [ -z "${f:-}" ] && continue
  case "$f" in
    core/java/android/util/BstUtils.java|core/java/android/util/Features.java|cmds/pagefusion/*|core/java/com/bluestacks/*) continue ;;
    libs/WindowManager/Shell/*) continue ;;
    libs/hwui/*) continue ;;
  esac
  if [ ! -f "$A16/$f" ]; then
    echo "$ns $f" >> "$CLASS/cont21_missing.txt"
    missing=$((missing+1))
    continue
  fi
  (cd "$A13" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/fw21.patch
  if (cd "$A16" && git apply --check /tmp/fw21.patch 2>/dev/null); then
    echo "$ns $f" >> "$CLASS/cont21_clean.txt"
    clean=$((clean+1))
  else
    echo "$ns $f" >> "$CLASS/cont21_conflict.txt"
    conflict=$((conflict+1))
  fi
done < "$CLASS/a13_ns.txt"
echo "clean=$clean conflict=$conflict missing=$missing"
echo "=== clean ns<=200 ==="
awk '$1<=200' "$CLASS/cont21_clean.txt" | head -50
echo "=== conflict interesting ==="
rg -n "DisplayRotation|ActivityStarter|GameResource|WindowManagerService|SystemUI|FilterApps|HostCall|Bst|Graphics" "$CLASS/cont21_conflict.txt" | head -40
echo "=== missing BST-ish ==="
rg -n "bluestacks|Bst|HostCall|FilterApps|pagefusion|GameResource" "$CLASS/cont21_missing.txt" | head -40

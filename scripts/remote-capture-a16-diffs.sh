#!/bin/bash
# Capture authoritative A16 tree modifications from the remote guest build host
# into ~/a16-archive on the remote, for later scp back to patches/android-16/.
# Captures, per dirty git project: `git diff HEAD` (tracked) + untracked files copy.
set -u

AOSP=~/aosp16
OUT=~/a16-archive
export OUT
rm -rf "$OUT"
mkdir -p "$OUT/patches" "$OUT/untracked" "$OUT/meta"

echo "=== base meta ==="
( cd "$AOSP" && cat .repo/manifest.xml 2>/dev/null | head -5
  echo "manifest_revision:"; grep -m1 revision .repo/manifests/default.xml 2>/dev/null ) > "$OUT/meta/base.txt" 2>&1

# --- aosp16 dirty projects ---
cd "$AOSP" || exit 1
: > "$OUT/dirty-projects.txt"
repo forall -c '
  st="$(git status --porcelain 2>/dev/null)"
  if [ -n "$st" ]; then
    safe="$(echo "$REPO_PATH" | tr "/" "_")"
    echo "$REPO_PATH" >> "$OUT/dirty-projects.txt"
    git --no-pager diff HEAD > "$OUT/patches/aosp16__$safe.patch" 2>/dev/null
    git status --porcelain > "$OUT/patches/aosp16__$safe.status" 2>/dev/null
    git rev-parse HEAD > "$OUT/patches/aosp16__$safe.base" 2>/dev/null
    unt="$(git ls-files --others --exclude-standard 2>/dev/null)"
    if [ -n "$unt" ]; then
      dest="$OUT/untracked/aosp16__$safe"
      echo "$unt" | while IFS= read -r f; do
        [ -f "$f" ] || continue
        mkdir -p "$dest/$(dirname "$f")"
        cp -a "$f" "$dest/$f" 2>/dev/null
      done
    fi
  fi
'
echo "aosp16 dirty projects captured: $(wc -l < "$OUT/dirty-projects.txt")"

# --- app-player (buildscripts + hd/guest) if it is a git repo ---
APP=~/app-player
if [ -d "$APP/.git" ]; then
  ( cd "$APP" && git --no-pager diff HEAD ) > "$OUT/patches/app-player.patch" 2>/dev/null
  ( cd "$APP" && git status --porcelain ) > "$OUT/patches/app-player.status" 2>/dev/null
  ( cd "$APP" && git rev-parse HEAD ) > "$OUT/patches/app-player.base" 2>/dev/null
  # untracked buildscripts / hd guest scripts
  ( cd "$APP" && git ls-files --others --exclude-standard buildscripts hd 2>/dev/null ) > "$OUT/meta/app-player-untracked.txt" 2>/dev/null
  echo "app-player captured"
else
  echo "app-player is not a git repo (skipped diff)" 
fi

# --- key BootImage / guest scripts snapshot (may not be tracked) ---
mkdir -p "$OUT/bootimage"
for f in \
  "$APP/hd/guest/BootImage/init.sh" \
  "$APP/hd/guest/BootImage/stage2.sh" \
  "$APP/hd/guest/BootImage/bstsetup.env" \
  "$APP/hd/guest/BootImage/bstsetconf.sh" \
  "$APP/hd/guest/BootImage/Makefile" \
  "$APP/hd/guest/Makefile" ; do
  [ -f "$f" ] && { mkdir -p "$OUT/bootimage/$(dirname "${f#$APP/}")"; cp -a "$f" "$OUT/bootimage/${f#$APP/}" 2>/dev/null; }
done
echo "bootimage snapshot done"

# --- kernel-a16 config + status ---
KDIR="$AOSP/kernel-a16"
[ -d "$KDIR" ] || KDIR=~/kernel-a16
if [ -d "$KDIR" ]; then
  mkdir -p "$OUT/kernel"
  [ -f "$KDIR/.config" ] && cp -a "$KDIR/.config" "$OUT/kernel/config" 2>/dev/null
  ( cd "$KDIR" && git rev-parse HEAD 2>/dev/null; git status --porcelain 2>/dev/null ) > "$OUT/kernel/git.txt" 2>&1
  echo "kernel meta done ($KDIR)"
fi

# --- goldfish-opengl-pie diff (guest graphics) ---
for GGL in "$AOSP/../ggl/goldfish-opengl-pie" ~/ggl/goldfish-opengl-pie "$APP/../ggl/goldfish-opengl-pie"; do
  if [ -d "$GGL/.git" ]; then
    ( cd "$GGL" && git --no-pager diff HEAD ) > "$OUT/patches/goldfish-opengl-pie.patch" 2>/dev/null
    ( cd "$GGL" && git rev-parse HEAD ) > "$OUT/patches/goldfish-opengl-pie.base" 2>/dev/null
    echo "goldfish-opengl-pie captured ($GGL)"
    break
  fi
done

# sizes
echo "=== patch sizes ==="
ls -la "$OUT/patches" | sed -n '1,80p'
du -sh "$OUT"
echo "CAPTURE_DONE"

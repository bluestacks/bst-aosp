#!/bin/bash
# Finalize A16 archive: app-player buildscripts/hd (scoped diffs), BootImage snapshot,
# kernel config, goldfish-opengl-pie diff. Avoids the full-repo submodule scan that hangs.
set -u
APP=~/app-player
OUT=~/a16-archive
mkdir -p "$OUT/patches" "$OUT/bootimage" "$OUT/kernel" "$OUT/meta"

cd "$APP" || exit 1
# scoped buildscripts diff (fast; avoids submodule status)
git --no-pager diff HEAD -- buildscripts > "$OUT/patches/app-player_buildscripts.patch" 2>/dev/null
git --no-pager diff --stat HEAD -- buildscripts > "$OUT/patches/app-player_buildscripts.stat" 2>/dev/null
git rev-parse HEAD > "$OUT/patches/app-player.base" 2>/dev/null
# untracked new files in buildscripts (e.g. build_Baklava64.sh)
git ls-files --others --exclude-standard buildscripts > "$OUT/meta/app-player-buildscripts-untracked.txt" 2>/dev/null
mkdir -p "$OUT/buildscripts-untracked"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  mkdir -p "$OUT/buildscripts-untracked/$(dirname "$f")"
  cp -a "$f" "$OUT/buildscripts-untracked/$f" 2>/dev/null
done < "$OUT/meta/app-player-buildscripts-untracked.txt"
rm -f "$OUT/patches/app-player.patch" "$OUT/patches/app-player.status"

# hd is a submodule; scoped diff on hd/guest if present
if [ -d "$APP/hd/guest" ]; then
  ( cd "$APP/hd" && git --no-pager diff HEAD -- guest ) > "$OUT/patches/hd-guest.patch" 2>/dev/null
  ( cd "$APP/hd" && git rev-parse HEAD ) > "$OUT/patches/hd-guest.base" 2>/dev/null
  ( cd "$APP/hd" && git ls-files --others --exclude-standard guest ) > "$OUT/meta/hd-guest-untracked.txt" 2>/dev/null
fi

# BootImage snapshot (init.sh/stage2.sh/bstsetup.env/Makefile - the boot-critical scripts)
for f in \
  "hd/guest/BootImage/init.sh" \
  "hd/guest/BootImage/stage2.sh" \
  "hd/guest/BootImage/bstsetup.env" \
  "hd/guest/BootImage/bstsetconf.sh" \
  "hd/guest/BootImage/bstsetconf.baklava64.sh" \
  "hd/guest/BootImage/Makefile" \
  "hd/guest/Makefile" ; do
  if [ -f "$APP/$f" ]; then
    mkdir -p "$OUT/bootimage/$(dirname "$f")"
    cp -a "$APP/$f" "$OUT/bootimage/$f" 2>/dev/null
  fi
done

# kernel-a16 config
for KDIR in ~/aosp16/kernel-a16 ~/kernel-a16 ~/aosp16/kernel-common-a13; do
  if [ -f "$KDIR/.config" ]; then
    cp -a "$KDIR/.config" "$OUT/kernel/config" 2>/dev/null
    ( cd "$KDIR" && git rev-parse HEAD 2>/dev/null; git --no-pager diff --stat HEAD 2>/dev/null ) > "$OUT/kernel/git.txt" 2>&1
    echo "kernel: $KDIR" >> "$OUT/kernel/git.txt"
    break
  fi
done

# goldfish-opengl-pie
for GGL in ~/ggl/goldfish-opengl-pie ~/aosp16/../ggl/goldfish-opengl-pie ~/app-player/../ggl/goldfish-opengl-pie ~/goldfish-opengl-pie; do
  if [ -d "$GGL/.git" ]; then
    ( cd "$GGL" && git --no-pager diff HEAD ) > "$OUT/patches/goldfish-opengl-pie.patch" 2>/dev/null
    ( cd "$GGL" && git rev-parse HEAD ) > "$OUT/patches/goldfish-opengl-pie.base" 2>/dev/null
    ( cd "$GGL" && git ls-files --others --exclude-standard ) > "$OUT/meta/goldfish-untracked.txt" 2>/dev/null
    echo "goldfish: $GGL" >> "$OUT/kernel/git.txt"
    break
  fi
done

echo "=== patch files ==="
ls -la "$OUT/patches" | grep -v '\.base$' | grep -v '\.status$'
du -sh "$OUT"
echo "APPPLAYER_CAPTURE_DONE"

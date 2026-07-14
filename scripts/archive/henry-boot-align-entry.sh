#!/bin/bash
# Align markxu clouddev app-player buildscripts to Henry Baklava64 entry.
set -euo pipefail

APP_PLAYER_DIR="${APP_PLAYER_DIR:-$HOME/app-player}"
PATCH_DIR="${PATCH_DIR:-$HOME/bst-aosp-patches}"
BS="$APP_PLAYER_DIR/buildscripts"

if [[ ! -d "$APP_PLAYER_DIR" ]]; then
  echo "APP_PLAYER_DIR missing: $APP_PLAYER_DIR" >&2
  exit 1
fi

mkdir -p "$PATCH_DIR"

# 1) Ensure Henry entry scripts exist with expected names.
if [[ -f "$PATCH_DIR/01-build_Baklava64.sh" ]]; then
  cp -f "$PATCH_DIR/01-build_Baklava64.sh" "$BS/build_Baklava64.sh"
  chmod +x "$BS/build_Baklava64.sh"
fi
if [[ -f "$PATCH_DIR/02-build_Baklava_common.sh" ]]; then
  cp -f "$PATCH_DIR/02-build_Baklava_common.sh" "$BS/build_Baklava_common.sh"
  chmod +x "$BS/build_Baklava_common.sh"
fi

# Backward-compatible aliases if only numbered files exist in buildscripts.
if [[ ! -f "$BS/build_Baklava64.sh" && -f "$BS/01-build_Baklava64.sh" ]]; then
  cp -f "$BS/01-build_Baklava64.sh" "$BS/build_Baklava64.sh"
  chmod +x "$BS/build_Baklava64.sh"
fi
if [[ ! -f "$BS/build_Baklava_common.sh" && -f "$BS/02-build_Baklava_common.sh" ]]; then
  cp -f "$BS/02-build_Baklava_common.sh" "$BS/build_Baklava_common.sh"
  chmod +x "$BS/build_Baklava_common.sh"
fi

# 2) Apply buildscripts patch once (idempotent check).
if [[ -f "$PATCH_DIR/00-buildscripts.patch" ]]; then
  cd "$BS"
  if git apply --check "$PATCH_DIR/00-buildscripts.patch" >/dev/null 2>&1; then
    git apply "$PATCH_DIR/00-buildscripts.patch"
    echo "applied 00-buildscripts.patch"
  elif git apply --reverse --check "$PATCH_DIR/00-buildscripts.patch" >/dev/null 2>&1; then
    echo "00-buildscripts.patch already applied"
  else
    echo "WARN: 00-buildscripts.patch check failed; leaving existing buildscripts state" >&2
  fi
fi

# 3) Readback.
test -x "$BS/build_Baklava64.sh"
test -x "$BS/build_Baklava_common.sh"
echo "ENTRY_OK build_Baklava64=$BS/build_Baklava64.sh"
echo "ENTRY_OK build_Baklava_common=$BS/build_Baklava_common.sh"

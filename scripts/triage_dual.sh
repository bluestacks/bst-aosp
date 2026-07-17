#!/usr/bin/env bash
# Dual-platform customization triage → JSON lines
# Usage: triage_dual.sh <tree_root> <platform>
set -euo pipefail
TREE="${1:?tree}"
PLATFORM="${2:?platform}"
OUT="${3:-/tmp/triage_${PLATFORM}.jsonl}"
: > "$OUT"

# Prefer projects that matter; fall back to .gitmodules paths + top-level dirs with .git
collect_projects() {
  local root="$1"
  if [[ -f "$root/.gitmodules" ]]; then
    git -C "$root" config -f .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}'
  fi
  # Always include key non-submodule paths if present
  for p in device/bst/qvirt device/generic/common device/generic/x86_64 \
           hardware/bst kernel frameworks/base frameworks/native system/core \
           build/make bionic art; do
    [[ -e "$root/$p" ]] && echo "$p"
  done
}

area_of() {
  case "$1" in
    device/*) echo device ;;
    kernel*|kernel/*) echo kernel ;;
    frameworks/*) echo frameworks ;;
    hardware/*) echo hardware ;;
    system/*) echo system ;;
    external/*) echo external ;;
    packages/*) echo packages ;;
    prebuilts/*) echo prebuilts ;;
    build/*) echo build ;;
    bionic*) echo bionic ;;
    art*) echo art ;;
    libcore*) echo libcore ;;
    *) echo other ;;
  esac
}

# Unique project list
mapfile -t PROJECTS < <(collect_projects "$TREE" | sort -u)

echo "TRIAGE_START platform=$PLATFORM tree=$TREE projects=${#PROJECTS[@]}" >&2

for proj in "${PROJECTS[@]}"; do
  dir="$TREE/$proj"
  [[ -d "$dir" ]] || continue
  # Need a git dir (submodule or nested)
  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    continue
  fi

  # Find best android-13.0.0_r* tag reachable or listed
  tag=$(git -C "$dir" tag -l 'android-13.0.0_r*' 2>/dev/null | sort -t_ -k2 -V | tail -1 || true)
  if [[ -z "$tag" ]]; then
    # try describe / merge-base with remotes — skip if no android-13 tag
    since=-1
    bst=0
    has_bst=false
  else
    since=$(git -C "$dir" rev-list --count "${tag}..HEAD" 2>/dev/null || echo 0)
    bst=$(git -C "$dir" rev-list --count "${tag}..HEAD" --author='bluestacks' --author='BlueStacks' --author='@bluestacks' 2>/dev/null || echo 0)
    # Broader bst signal: message keywords (catches non-bluestacks emails)
    kw=$(git -C "$dir" log --oneline "${tag}..HEAD" 2>/dev/null | grep -icE 'bluestacks|bst_|qvirt|bstvmsg|bstpgaipc' || true)
    if [[ "$bst" -gt 0 || "$kw" -gt 0 ]]; then has_bst=true; else has_bst=false; fi
    # If keyword hits but author miss, bump bst_count note via kw
    if [[ "$bst" -eq 0 && "$kw" -gt 0 ]]; then bst=$kw; fi
  fi

  # Also flag paths that clearly contain bst assets even if since=0
  if [[ "$has_bst" == false ]] && [[ -d "$dir" ]]; then
    if find "$dir" -maxdepth 3 \( -iname '*bluestacks*' -o -iname '*bst*' -o -path '*/device/bst/*' \) 2>/dev/null | head -1 | grep -q .; then
      has_bst=true
      confidence_hint=path-signal
    fi
  fi

  area=$(area_of "$proj")
  id="${PLATFORM}-$(echo "$proj" | tr '/.' '--')"

  # phase hint
  phase=P2
  case "$area" in
    device|kernel|hardware) phase=P1 ;;
    prebuilts) phase=P3 ;;
  esac

  confidence=low
  if [[ "$has_bst" == true && "${since:-0}" -gt 0 ]]; then confidence=high
  elif [[ "$has_bst" == true ]]; then confidence=medium
  elif [[ "${since:-0}" -gt 0 ]]; then confidence=low
  else
    # skip pure vanilla
    continue
  fi

  # emit json line (minimal escaping)
  proj_esc=${proj//\\/\\\\}; proj_esc=${proj_esc//\"/\\\"}
  echo "{\"id\":\"$id\",\"platform\":\"$PLATFORM\",\"project_path\":\"$proj_esc\",\"area\":\"$area\",\"base_tag\":\"${tag:-}\",\"since_count\":${since:--1},\"bst_count\":${bst:-0},\"has_bst\":$has_bst,\"confidence\":\"$confidence\",\"phase\":\"$phase\",\"temp_debt\":false,\"port_status\":\"pending\",\"host_compat\":\"unknown\",\"owner\":\"agent\"}" >> "$OUT"
done

echo "TRIAGE_DONE platform=$PLATFORM out=$OUT lines=$(wc -l < "$OUT")" >&2

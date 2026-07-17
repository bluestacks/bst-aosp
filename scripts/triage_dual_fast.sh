#!/usr/bin/env bash
# Fast parallel dual-platform triage → JSONL
# Usage: triage_dual_fast.sh <tree_root> <platform> <out.jsonl>
set -euo pipefail
TREE="${1:?tree}"
PLATFORM="${2:?platform}"
OUT="${3:?out}"
JOBS="${JOBS:-32}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

collect_projects() {
  local root="$1"
  if [[ -f "$root/.gitmodules" ]]; then
    git -C "$root" config -f .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}'
  fi
  for p in device/bst/qvirt device/generic/common device/generic/x86_64 \
           hardware/bst kernel frameworks/base frameworks/native system/core \
           build/make bionic art libcore; do
    [[ -e "$root/$p" ]] && echo "$p"
  done
}

triage_one() {
  local TREE="$1" PLATFORM="$2" proj="$3" outdir="$4"
  local dir="$TREE/$proj"
  [[ -d "$dir" ]] || return 0
  git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || return 0

  local tag since bst has_bst=false confidence area phase id kw=0
  tag=$(git -C "$dir" tag -l 'android-13.0.0_r*' 2>/dev/null | sort -t_ -k2 -V | tail -1 || true)

  if [[ -z "$tag" ]]; then
    # no android-13 tag: only keep if path is clearly bst-related
    case "$proj" in
      device/bst/*|hardware/bst/*|*/bluestacks*|kernel*|kernel-*)
        since=-1; bst=0; has_bst=true; confidence=medium
        ;;
      *) return 0 ;;
    esac
  else
    since=$(git -C "$dir" rev-list --count "${tag}..HEAD" 2>/dev/null || echo 0)
    [[ "$since" == "0" ]] && return 0
    bst=$(git -C "$dir" rev-list --count "${tag}..HEAD" --author='bluestacks' --author='BlueStacks' 2>/dev/null || echo 0)
    if [[ "$bst" -eq 0 ]]; then
      # cheap keyword skim (max 200 commits)
      kw=$(git -C "$dir" log --oneline -n 200 "${tag}..HEAD" 2>/dev/null | grep -icE 'bluestacks|bst_|qvirt|bstvmsg|bstpgaipc' || true)
      bst=$kw
    fi
    if [[ "$bst" -gt 0 ]]; then has_bst=true; confidence=high
    else has_bst=false; confidence=low
    fi
    # Critical areas with drift: keep even bst=0 for review
    case "$proj" in
      device/*|frameworks/*|hardware/*|system/core|system/sepolicy)
        : ;; # keep
      *)
        [[ "$has_bst" == false && "$confidence" == low ]] && return 0
        ;;
    esac
  fi

  case "$proj" in
    device/*) area=device ;;
    kernel*|kernel/*) area=kernel ;;
    frameworks/*) area=frameworks ;;
    hardware/*) area=hardware ;;
    system/*) area=system ;;
    external/*) area=external ;;
    packages/*) area=packages ;;
    prebuilts/*) area=prebuilts ;;
    build/*) area=build ;;
    bionic*) area=bionic ;;
    art*) area=art ;;
    libcore*) area=libcore ;;
    *) area=other ;;
  esac

  phase=P2
  case "$area" in
    device|kernel|hardware) phase=P1 ;;
    prebuilts) phase=P3 ;;
    build) phase=P1 ;;
  esac

  id="${PLATFORM}-$(echo "$proj" | tr '/.' '--')"
  local proj_esc=${proj//\\/\\\\}; proj_esc=${proj_esc//\"/\\\"}
  # safe filename
  local fn
  fn=$(echo "$id" | tr '/:' '__')
  printf '%s\n' "{\"id\":\"$id\",\"platform\":\"$PLATFORM\",\"project_path\":\"$proj_esc\",\"area\":\"$area\",\"base_tag\":\"${tag:-}\",\"since_count\":${since:--1},\"bst_count\":${bst:-0},\"has_bst\":$has_bst,\"confidence\":\"$confidence\",\"phase\":\"$phase\",\"temp_debt\":false,\"port_status\":\"pending\",\"host_compat\":\"unknown\",\"owner\":\"agent\"}" > "$outdir/$fn.json"
}

export -f triage_one
export TREE PLATFORM

mapfile -t PROJECTS < <(collect_projects "$TREE" | sort -u)
echo "TRIAGE_START platform=$PLATFORM tree=$TREE projects=${#PROJECTS[@]} jobs=$JOBS" >&2

printf '%s\n' "${PROJECTS[@]}" | xargs -P "$JOBS" -I{} bash -c 'triage_one "$@"' _ "$TREE" "$PLATFORM" {} "$TMP"

: > "$OUT"
cat "$TMP"/*.json 2>/dev/null >> "$OUT" || true
echo "TRIAGE_DONE platform=$PLATFORM out=$OUT lines=$(wc -l < "$OUT")" >&2

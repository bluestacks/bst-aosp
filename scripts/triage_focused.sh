#!/usr/bin/env bash
# Focused triage: high-value paths first; external with timeout + author-only
# Usage: triage_focused.sh <tree> <platform> <out.jsonl>
set -euo pipefail
TREE="${1:?}"
PLATFORM="${2:?}"
OUT="${3:?}"
JOBS="${JOBS:-24}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

HIGH_PREFIX='^(device/|frameworks/|hardware/|system/|packages/|build/|bionic|art|libcore|kernel|bootable/|cts|developers/|pdk|platform_testing|prebuilts/|tools/|toolchain/|development/|test/)'

collect() {
  local root="$1"
  if [[ -f "$root/.gitmodules" ]]; then
    git -C "$root" config -f .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}'
  fi
  for p in device/bst/qvirt device/generic/common device/generic/x86_64 hardware/bst kernel \
           frameworks/base frameworks/native system/core build/make bionic art; do
    [[ -e "$root/$p" ]] && echo "$p"
  done
}

triage_one() {
  local TREE="$1" PLATFORM="$2" proj="$3" outdir="$4"
  local dir="$TREE/$proj"
  [[ -d "$dir" ]] || return 0
  timeout 5 git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || return 0

  local is_ext=0
  [[ "$proj" == external/* ]] && is_ext=1

  local tag since=0 bst=0 has_bst=false confidence=low area phase
  tag=$(timeout 15 git -C "$dir" tag -l 'android-13.0.0_r*' 2>/dev/null | sort -t_ -k2 -V | tail -1 || true)
  [[ -z "$tag" ]] && {
    case "$proj" in
      device/bst/*|hardware/bst/*) since=-1; has_bst=true; confidence=medium ;;
      *) return 0 ;;
    esac
  }

  if [[ -n "$tag" ]]; then
    if [[ "$is_ext" -eq 1 ]]; then
      # external: author-only, hard timeout — skip if none
      bst=$(timeout 20 git -C "$dir" rev-list --count "${tag}..HEAD" --author=bluestacks --author=BlueStacks 2>/dev/null || echo 0)
      [[ "${bst:-0}" -eq 0 ]] && return 0
      since=$bst
      has_bst=true
      confidence=high
    else
      since=$(timeout 30 git -C "$dir" rev-list --count "${tag}..HEAD" 2>/dev/null || echo 0)
      [[ "${since:-0}" -eq 0 ]] && return 0
      bst=$(timeout 20 git -C "$dir" rev-list --count "${tag}..HEAD" --author=bluestacks --author=BlueStacks 2>/dev/null || echo 0)
      if [[ "${bst:-0}" -eq 0 ]]; then
        local kw
        kw=$(timeout 15 git -C "$dir" log --oneline -n 100 "${tag}..HEAD" 2>/dev/null | grep -icE 'bluestacks|bst_|qvirt|bstvmsg|bstpgaipc' || true)
        bst=${kw:-0}
      fi
      if [[ "${bst:-0}" -gt 0 ]]; then has_bst=true; confidence=high
      else
        has_bst=false; confidence=low
        case "$proj" in
          device/*|frameworks/*|hardware/*|system/core|system/sepolicy) : ;;
          *) return 0 ;;
        esac
      fi
    fi
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
  case "$area" in device|kernel|hardware|build) phase=P1 ;; prebuilts) phase=P3 ;; esac

  local id proj_esc fn
  id="${PLATFORM}-$(echo "$proj" | tr '/.' '--')"
  proj_esc=${proj//\\/\\\\}; proj_esc=${proj_esc//\"/\\\"}
  fn=$(echo "$id" | tr '/:' '__')
  printf '%s\n' "{\"id\":\"$id\",\"platform\":\"$PLATFORM\",\"project_path\":\"$proj_esc\",\"area\":\"$area\",\"base_tag\":\"${tag:-}\",\"since_count\":${since:--1},\"bst_count\":${bst:-0},\"has_bst\":$has_bst,\"confidence\":\"$confidence\",\"phase\":\"$phase\",\"temp_debt\":false,\"port_status\":\"pending\",\"host_compat\":\"unknown\",\"owner\":\"agent\"}" > "$outdir/$fn.json"
}
export -f triage_one

mapfile -t ALL < <(collect "$TREE" | sort -u)
# Split: high-value first, then external
mapfile -t HIGH < <(printf '%s\n' "${ALL[@]}" | grep -E "$HIGH_PREFIX" || true)
mapfile -t EXT < <(printf '%s\n' "${ALL[@]}" | grep -E '^external/' || true)

echo "TRIAGE_START platform=$PLATFORM high=${#HIGH[@]} ext=${#EXT[@]} jobs=$JOBS" >&2

printf '%s\n' "${HIGH[@]}" | xargs -P "$JOBS" -I{} bash -c 'triage_one "$@"' _ "$TREE" "$PLATFORM" {} "$TMP"
printf '%s\n' "${EXT[@]}" | xargs -P "$JOBS" -I{} bash -c 'triage_one "$@"' _ "$TREE" "$PLATFORM" {} "$TMP"

: > "$OUT"
cat "$TMP"/*.json 2>/dev/null | sort -u >> "$OUT" || true
echo "TRIAGE_DONE platform=$PLATFORM lines=$(wc -l < "$OUT")" >&2

#!/bin/bash
# Complete external/* triage (was under-covered due to short timeout).
# Usage: triage_external.sh <tree> <platform> <out.jsonl>
TREE="${1:?}"
PLATFORM="${2:?}"
OUT="${3:?}"
JOBS="${JOBS:-16}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mapfile -t EXT < <(git -C "$TREE" config -f .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}' | grep -E '^external/' | sort -u)

one() {
  local TREE="$1" PLATFORM="$2" proj="$3" outdir="$4"
  local dir="$TREE/$proj"
  [[ -d "$dir" ]] || return 0
  timeout 10 git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || return 0
  local tag bst kw=0
  tag=$(timeout 30 git -C "$dir" tag -l 'android-13.0.0_r*' 2>/dev/null | sort -t_ -k2 -V | tail -1)
  [[ -z "$tag" ]] && return 0
  bst=$(timeout 120 git -C "$dir" rev-list --count "${tag}..HEAD" --author=bluestacks --author=BlueStacks 2>/dev/null || echo 0)
  if [[ "${bst:-0}" -eq 0 ]]; then
    kw=$(timeout 60 git -C "$dir" log --oneline -n 150 "${tag}..HEAD" 2>/dev/null | grep -icE 'bluestacks|bst_|nowgg|now\.gg' || true)
    bst=${kw:-0}
  fi
  [[ "${bst:-0}" -eq 0 ]] && return 0
  local id fn proj_esc
  id="${PLATFORM}-$(echo "$proj" | tr '/.' '--')"
  fn=$(echo "$id" | tr '/:' '__')
  proj_esc=${proj//\"/\\\"}
  printf '{"id":"%s","platform":"%s","project_path":"%s","area":"external","base_tag":"%s","since_count":%s,"bst_count":%s,"has_bst":true,"confidence":"high","phase":"P2","temp_debt":false,"port_status":"pending","host_compat":"unknown","owner":"agent"}\n' \
    "$id" "$PLATFORM" "$proj_esc" "$tag" "${bst}" "${bst}" > "$outdir/$fn.json"
}
export -f one

echo "EXT_START $PLATFORM count=${#EXT[@]} jobs=$JOBS" >&2
printf '%s\n' "${EXT[@]}" | xargs -P "$JOBS" -I{} bash -c 'one "$@"' _ "$TREE" "$PLATFORM" {} "$TMP"
: > "$OUT"
cat "$TMP"/*.json 2>/dev/null | sort -u >> "$OUT"
echo "EXT_DONE $PLATFORM lines=$(wc -l < "$OUT")" >&2

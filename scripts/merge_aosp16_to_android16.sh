#!/bin/bash
# HISTORICAL PROMOTION EXECUTOR.
# This script records the cont.103 first-pass merge method. The completed
# promotion later expanded from 20 to 31 projects and resolved 25Q4 conflicts.
# Do not use it for mainline maintenance; use audit_android16_promotion.py and
# the reviewed project commits instead.
#
# Merge aosp16 BST changes into ~/android-16 (per-project), new branch aosp16-bst-merge.
# For each BST project: branch aosp16-bst-merge from current HEAD, apply --3way the aosp16 diff,
# auto-commit if clean, report if conflict (leave dirty for AI resolution).
if [ "${1:-}" != "--apply-historical" ]; then
  cat >&2 <<'EOF'
This is the historical cont.103 merge executor, not the current development path.
It is intentionally inert unless --apply-historical is supplied.
Read docs/development-history/android16-merge/promotion-record.md and run:
  python3 scripts/audit_android16_promotion.py audit --root ~/android-16
EOF
  exit 2
fi
shift
set +e
AOSP16=~/aosp16
DST=~/android-16
mkdir -p /tmp/a16merge

# All projects with BST commits in aosp16 (+ device/bst/qvirt scaffold handled separately)
PROJECTS=(
  frameworks/base frameworks/native frameworks/av frameworks/opt/telephony
  bionic system/core system/extras packages/inputmethods/LatinIME
  packages/modules/Wifi packages/modules/Connectivity packages/modules/adb
  hardware/interfaces build/soong build/make art system/security
  external/boringssl packages/apps/Launcher3 device/generic/goldfish kernel-a16
)

printf "%-32s %-10s %s\n" "PROJECT" "RESULT" "DETAIL"
printf "%-32s %-10s %s\n" "-------" "------" "------"
for p in "${PROJECTS[@]}"; do
  # base = first BST commit parent in aosp16
  first=$(git -C "$AOSP16/$p" log --oneline --grep="BlueStacks" 2>/dev/null | tail -1 | awk '{print $1}')
  if [ -z "$first" ]; then
    printf "%-32s %-10s %s\n" "$p" "SKIP" "no BST commits in aosp16"
    continue
  fi
  base=$(git -C "$AOSP16/$p" rev-parse "$first^" 2>/dev/null)
  n=$(git -C "$AOSP16/$p" log --oneline --grep="BlueStacks" 2>/dev/null | wc -l)

  # destination project must be a git repo
  if ! git -C "$DST/$p" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "%-32s %-10s %s\n" "$p" "MISSING" "not a git repo in android-16"
    continue
  fi

  # generate diff
  git -C "$AOSP16/$p" diff "$base..HEAD" > /tmp/a16merge/${p//\//_}.patch 2>/dev/null
  sz=$(wc -l < /tmp/a16merge/${p//\//_}.patch)

  # create fresh aosp16-bst-merge branch from current HEAD (idempotent: reset if exists)
  git -C "$DST/$p" checkout -q $(git -C "$DST/$p" rev-parse --abbrev-ref HEAD 2>/dev/null) 2>/dev/null
  cur=$(git -C "$DST/$p" rev-parse --abbrev-ref HEAD 2>/dev/null)
  git -C "$DST/$p" branch -qf aosp16-bst-merge HEAD 2>/dev/null
  git -C "$DST/$p" checkout -q aosp16-bst-merge 2>/dev/null

  # apply --3way
  if git -C "$DST/$p" apply --3way /tmp/a16merge/${p//\//_}.patch >/tmp/a16merge/${p//\//_}.log 2>&1; then
    git -C "$DST/$p" add -A
    git -C "$DST/$p" commit -q -m "merge aosp16 BST: $p ($n commits, base ${base:0:12})" 2>/dev/null
    printf "%-32s %-10s %s\n" "$p" "CLEAN" "$n commits, $sz lines"
  else
    printf "%-32s %-10s %s\n" "$p" "CONFLICT" "$n commits, $sz lines (see /tmp/a16merge/${p//\//_}.log)"
  fi
done
echo "=== DONE ==="

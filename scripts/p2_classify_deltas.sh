#!/bin/bash
# Classify win P2 external/bionic/art/native: empty vs real BST delta vs huge
set -euo pipefail
LOG=~/p2_classify_deltas.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:classify start $(date -Is)"
A13=~/app-player/android-13
OUT=~/bst-aosp/patches/android-16/patches/p2-inventory
mkdir -p "$OUT"
REPORT="$OUT/delta_classification.tsv"
echo -e "project\tfiles\tinsertions\tdeletions\tclass" > "$REPORT"

classify() {
  local rel="$1"
  local dir="$A13/$rel"
  if [ ! -d "$dir" ]; then
    echo -e "$rel\t-1\t0\t0\tmissing" >> "$REPORT"
    echo "MISSING $rel"
    return
  fi
  cd "$dir"
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "$rel\t-1\t0\t0\tnogit" >> "$REPORT"
    echo "NOGIT $rel"
    return
  fi
  local TAG
  TAG=$(git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1)
  if [ -z "$TAG" ]; then
    echo -e "$rel\t-1\t0\t0\tnotag" >> "$REPORT"
    echo "NOTAG $rel"
    return
  fi
  local files ins del
  files=$(git diff --name-only "$TAG"..HEAD 2>/dev/null | wc -l)
  # --numstat sum
  read -r ins del < <(git diff --numstat "$TAG"..HEAD 2>/dev/null | awk '{i+=$1;d+=$2} END{print i+0, d+0}')
  local cls=real
  if [ "$files" -eq 0 ]; then cls=empty
  elif [ "$files" -le 3 ] && [ "$ins" -le 20 ]; then cls=trivial
  elif [ "$files" -gt 100 ] || [ "$ins" -gt 5000 ]; then cls=large
  fi
  echo -e "$rel\t$files\t$ins\t$del\t$cls" >> "$REPORT"
  echo "CLASS $rel files=$files +$ins -$del => $cls (tag=$TAG)"
}

# Core non-external first
for p in frameworks/native bionic art; do
  classify "$p"
done

# All external dirs that exist as git projects under a13
while IFS= read -r -d '' g; do
  rel=${g#"$A13/"}
  rel=${rel%/.git}
  # only top-ish external
  case "$rel" in
    external/*) classify "$rel" ;;
  esac
done < <(find "$A13/external" -maxdepth 4 -type d -name .git -print0 2>/dev/null)

echo "=== SUMMARY ==="
cut -f5 "$REPORT" | sort | uniq -c
echo "A16DBG:P2:classify DONE $(date -Is)"

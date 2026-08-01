#!/bin/bash
# Rewrite only promotion commit subjects while proving that the resulting tree is unchanged.
set -euo pipefail

usage() {
  echo "usage: $0 <repository> [base-branch] [backup-ref]" >&2
  exit 2
}

[ "$#" -ge 1 ] && [ "$#" -le 3 ] || usage

repo="$1"
base="${2:-aosp16-bst}"
backup="${3:-backup/pre-a16-message-rewrite-$(date +%Y%m%d%H%M%S)}"
script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

amend_current() {
  local subject body
  subject="$(git log -1 --format=%s)"
  case "$subject" in
    "[A16] "*) return 0 ;;
  esac
  body="$(git log -1 --format=%b)"
  if [ -n "$body" ]; then
    printf '[A16] %s\n\n%s\n' "$subject" "$body" | git commit --amend -F - >/dev/null
  else
    git commit --amend -m "[A16] $subject" >/dev/null
  fi
}

if [ "${1:-}" = "--amend-current" ]; then
  amend_current
  exit 0
fi

repo="$(cd "$repo" && pwd -P)"
git -C "$repo" show-ref --verify --quiet "refs/heads/$base" || {
  echo "missing base branch '$base' in $repo" >&2
  exit 1
}
[ -z "$(git -C "$repo" status --porcelain --untracked-files=all)" ] || {
  echo "refusing to rewrite dirty repository: $repo" >&2
  exit 1
}
[ "$(git -C "$repo" branch --show-current)" = "aosp16-bst-merge" ] || {
  echo "refusing to rewrite non-promotion branch in $repo" >&2
  exit 1
}
[ "$(git -C "$repo" rev-list --count --merges "$base"..HEAD)" -eq 0 ] || {
  echo "merge commits require a separately reviewed rewrite: $repo" >&2
  exit 1
}

before_head="$(git -C "$repo" rev-parse HEAD)"
before_tree="$(git -C "$repo" rev-parse 'HEAD^{tree}')"
git -C "$repo" branch "$backup" "$before_head"

(
  cd "$repo"
  GIT_SEQUENCE_EDITOR=: git rebase "$base" --exec "'$script_path' --amend-current"
)

after_tree="$(git -C "$repo" rev-parse 'HEAD^{tree}')"
[ "$before_tree" = "$after_tree" ] || {
  echo "tree changed while rewriting $repo; recover from $backup" >&2
  exit 1
}

bad_subjects="$(git -C "$repo" log --format=%s "$base"..HEAD | grep -vc '^\[A16\] ' || true)"
[ "$bad_subjects" -eq 0 ] || {
  echo "nonconforming commit subjects remain in $repo" >&2
  exit 1
}

printf 'rewritten=%s\nbackup=%s\nbefore=%s\nafter=%s\ntree=%s\n' \
  "$repo" "$backup" "$before_head" "$(git -C "$repo" rev-parse HEAD)" "$after_tree"

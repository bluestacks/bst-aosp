#!/bin/bash
# Shared identity and safety checks for the promoted Android-16 workflow.

BST_ANDROID16_ROOT="${BST_ANDROID16_ROOT:-$HOME/android-16}"
BST_AOSP16_REFERENCE_ROOT="${BST_AOSP16_REFERENCE_ROOT:-$HOME/aosp16}"
BST_APP_PLAYER_ROOT="${BST_APP_PLAYER_ROOT:-$HOME/app-player}"
BST_HD_SOURCE_TOP="${BST_HD_SOURCE_TOP:-$BST_APP_PLAYER_ROOT/hd}"
BST_RELEASE_ROOT="${BST_RELEASE_ROOT:-$HOME/releases/Baklava64}"
BST_OUT_DIR_NAME="${BST_OUT_DIR_NAME:-out_nxt_Baklava64}"
BST_PRODUCT="${BST_PRODUCT:-bst_x86_64}"
BST_LUNCH_TARGET="${BST_LUNCH_TARGET:-bst_x86_64-trunk_staging-eng}"
BST_GOLDFISH_OPENGL_ROOT="${BST_GOLDFISH_OPENGL_ROOT:-$HOME/ggl/goldfish-opengl-pie}"
BST_ALLOWED_ANDROID16_BRANCHES="${BST_ALLOWED_ANDROID16_BRANCHES:-aosp16-bst-merge aosp16-bst}"
BST_BUILD_IDENTITY_FILE="${BST_BUILD_IDENTITY_FILE:-$HOME/g1_android16_build.identity}"

bst_realpath() {
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$1"
  else
    (cd "$1" 2>/dev/null && pwd -P)
  fi
}

bst_require_android16_root() {
  [ -d "$BST_ANDROID16_ROOT" ] || {
    echo "A16DBG:IDENTITY: missing Android-16 root: $BST_ANDROID16_ROOT" >&2
    return 1
  }
  [ -f "$BST_ANDROID16_ROOT/build/envsetup.sh" ] || {
    echo "A16DBG:IDENTITY: missing build/envsetup.sh under $BST_ANDROID16_ROOT" >&2
    return 1
  }
  git -C "$BST_ANDROID16_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "A16DBG:IDENTITY: not a Git work tree: $BST_ANDROID16_ROOT" >&2
    return 1
  }

  local target reference
  target="$(bst_realpath "$BST_ANDROID16_ROOT")" || return 1
  reference="$(bst_realpath "$BST_AOSP16_REFERENCE_ROOT" 2>/dev/null || true)"
  if [ -n "$reference" ] && {
    [ "$target" = "$reference" ] || [[ "$target" = "$reference/"* ]]
  }; then
    echo "A16DBG:IDENTITY: target resolves to forbidden AOSP16 development tree: $target" >&2
    return 1
  fi
}

bst_require_android16_branch() {
  local branch allowed
  branch="$(git -C "$BST_ANDROID16_ROOT" rev-parse --abbrev-ref HEAD)" || return 1
  [ "$branch" != "HEAD" ] || {
    echo "A16DBG:IDENTITY: Android-16 root is detached" >&2
    return 1
  }
  for allowed in $BST_ALLOWED_ANDROID16_BRANCHES; do
    [ "$branch" = "$allowed" ] && return 0
  done
  echo "A16DBG:IDENTITY: unexpected branch '$branch'; allowed: $BST_ALLOWED_ANDROID16_BRANCHES" >&2
  return 1
}

bst_require_android16_clean() {
  local status
  status="$(
    git -C "$BST_ANDROID16_ROOT" status \
      --porcelain=v1 --untracked-files=all --ignore-submodules=none
  )" || return 1
  [ -z "$status" ] || {
    echo "A16DBG:IDENTITY: Android-16 tree is dirty; commit or clean every project before build:" >&2
    printf '%s\n' "$status" | head -40 >&2
    return 1
  }
}

bst_print_android16_identity() {
  local root branch head
  root="$(bst_realpath "$BST_ANDROID16_ROOT")" || return 1
  branch="$(git -C "$BST_ANDROID16_ROOT" rev-parse --abbrev-ref HEAD)" || return 1
  head="$(git -C "$BST_ANDROID16_ROOT" rev-parse HEAD)" || return 1
  echo "A16DBG:IDENTITY: tree=$root"
  echo "A16DBG:IDENTITY: branch=$branch"
  echo "A16DBG:IDENTITY: head=$head"
  echo "A16DBG:IDENTITY: out=$root/$BST_OUT_DIR_NAME"
  echo "A16DBG:IDENTITY: product=$BST_PRODUCT lunch=$BST_LUNCH_TARGET"
}

bst_android16_preflight() {
  bst_require_android16_root
  bst_require_android16_branch
  bst_require_android16_clean
  bst_print_android16_identity
}

bst_write_identity_file() {
  local output="$1" artifact="${2:-}" artifact_hash=""
  local root branch head
  root="$(bst_realpath "$BST_ANDROID16_ROOT")" || return 1
  branch="$(git -C "$BST_ANDROID16_ROOT" rev-parse --abbrev-ref HEAD)" || return 1
  head="$(git -C "$BST_ANDROID16_ROOT" rev-parse HEAD)" || return 1
  if [ -n "$artifact" ] && [ -f "$artifact" ]; then
    artifact_hash="$(sha256sum "$artifact" | awk '{print $1}')"
  fi
  {
    printf 'tree=%s\n' "$root"
    printf 'branch=%s\n' "$branch"
    printf 'head=%s\n' "$head"
    printf 'out_dir=%s\n' "$root/$BST_OUT_DIR_NAME"
    printf 'product=%s\n' "$BST_PRODUCT"
    printf 'dirty=0\n'
    printf 'artifact=%s\n' "$artifact"
    printf 'artifact_sha256=%s\n' "$artifact_hash"
    printf 'recorded_at=%s\n' "$(date -Is)"
  } > "$output"
}

bst_verify_identity_file() {
  local identity="$1" artifact="${2:-}"
  local recorded_tree="" recorded_branch="" recorded_head="" recorded_out=""
  local recorded_product="" recorded_artifact_hash="" current_hash=""
  [ -f "$identity" ] || {
    echo "A16DBG:IDENTITY: missing identity file: $identity" >&2
    return 1
  }
  while IFS='=' read -r key value; do
    case "$key" in
      tree) recorded_tree="$value" ;;
      branch) recorded_branch="$value" ;;
      head) recorded_head="$value" ;;
      out_dir) recorded_out="$value" ;;
      product) recorded_product="$value" ;;
      artifact_sha256) recorded_artifact_hash="$value" ;;
    esac
  done < "$identity"
  [ "$recorded_tree" = "$(bst_realpath "$BST_ANDROID16_ROOT")" ] || {
    echo "A16DBG:IDENTITY: tree mismatch in $identity" >&2
    return 1
  }
  [ "$recorded_branch" = "$(git -C "$BST_ANDROID16_ROOT" rev-parse --abbrev-ref HEAD)" ] || {
    echo "A16DBG:IDENTITY: branch mismatch in $identity" >&2
    return 1
  }
  [ "$recorded_head" = "$(git -C "$BST_ANDROID16_ROOT" rev-parse HEAD)" ] || {
    echo "A16DBG:IDENTITY: HEAD mismatch in $identity" >&2
    return 1
  }
  [ "$recorded_out" = "$(bst_realpath "$BST_ANDROID16_ROOT")/$BST_OUT_DIR_NAME" ] || {
    echo "A16DBG:IDENTITY: OUT_DIR mismatch in $identity" >&2
    return 1
  }
  [ "$recorded_product" = "$BST_PRODUCT" ] || {
    echo "A16DBG:IDENTITY: product mismatch in $identity" >&2
    return 1
  }
  if [ -n "$artifact" ]; then
    [ -f "$artifact" ] || {
      echo "A16DBG:IDENTITY: missing artifact: $artifact" >&2
      return 1
    }
    current_hash="$(sha256sum "$artifact" | awk '{print $1}')"
    [ -n "$recorded_artifact_hash" ] &&
      [ "$recorded_artifact_hash" = "$current_hash" ] || {
        echo "A16DBG:IDENTITY: artifact SHA-256 mismatch in $identity" >&2
        return 1
      }
  fi
  echo "A16DBG:IDENTITY: verified $identity"
}

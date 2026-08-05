#!/bin/bash
# Shared identity and safety checks for the promoted Android-16 workflow.

BST_ANDROID16_ROOT="${BST_ANDROID16_ROOT:-$HOME/android-16}"
BST_AOSP16_REFERENCE_ROOT="${BST_AOSP16_REFERENCE_ROOT:-}"
BST_APP_PLAYER_ROOT="${BST_APP_PLAYER_ROOT:-$HOME/app-player}"
BST_HD_SOURCE_TOP="${BST_HD_SOURCE_TOP:-$BST_APP_PLAYER_ROOT/hd}"
BST_RELEASE_ROOT="${BST_RELEASE_ROOT:-$HOME/releases/Baklava64}"
BST_OUT_DIR_NAME="${BST_OUT_DIR_NAME:-out}"
BST_PRODUCT="${BST_PRODUCT:-android_x86_64}"
BST_LUNCH_TARGET="${BST_LUNCH_TARGET:-android_x86_64-trunk_staging-eng}"
BST_GOLDFISH_OPENGL_ROOT="${BST_GOLDFISH_OPENGL_ROOT:-$HOME/ggl/goldfish-opengl-pie}"
BST_GOLDFISH_OPENGL_MODULE_PATH="${BST_GOLDFISH_OPENGL_MODULE_PATH:-../ggl/goldfish-opengl-pie}"
BST_ALLOWED_ANDROID16_BRANCHES="${BST_ALLOWED_ANDROID16_BRANCHES:-aosp16-bst-merge aosp16-bst}"
BST_ALLOWED_GOLDFISH_BRANCHES="${BST_ALLOWED_GOLDFISH_BRANCHES:-aosp16-bst-merge aosp16-bst}"
BST_BUILD_IDENTITY_FILE="${BST_BUILD_IDENTITY_FILE:-$HOME/g1_android16_build.identity}"
BST_CLEAN_AUDIT_JOBS="${BST_CLEAN_AUDIT_JOBS:-16}"
BST_CLEAN_AUDIT_TOOL="${BST_CLEAN_AUDIT_TOOL:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/check_android16_worktree.py}"
BST_ALLOWED_ROOT_DIRTY_PATHS="${BST_ALLOWED_ROOT_DIRTY_PATHS:-}"

bst_realpath() {
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$1"
  else
    (cd "$1" 2>/dev/null && pwd -P)
  fi
}

bst_android16_graphics_module_path() {
  local candidate="$BST_ANDROID16_ROOT/$BST_GOLDFISH_OPENGL_MODULE_PATH"
  [ "$(bst_realpath "$candidate")" = "$(bst_realpath "$BST_GOLDFISH_OPENGL_ROOT")" ] || {
    echo "A16DBG:ANDROID16: graphics module path does not resolve to source root" >&2
    echo "  module=$BST_GOLDFISH_OPENGL_MODULE_PATH -> $(bst_realpath "$candidate")" >&2
    echo "  source=$BST_GOLDFISH_OPENGL_ROOT -> $(bst_realpath "$BST_GOLDFISH_OPENGL_ROOT")" >&2
    return 1
  }
  printf '%s\n' "$BST_GOLDFISH_OPENGL_MODULE_PATH"
}

bst_android16_graphics_preflight() {
  local root branch allowed status
  [ -d "$BST_GOLDFISH_OPENGL_ROOT" ] || {
    echo "A16DBG:IDENTITY: missing graphics source: $BST_GOLDFISH_OPENGL_ROOT" >&2
    return 1
  }
  git -C "$BST_GOLDFISH_OPENGL_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "A16DBG:IDENTITY: graphics source is not a Git work tree" >&2
    return 1
  }
  bst_android16_graphics_module_path >/dev/null || return 1
  root="$(bst_realpath "$BST_GOLDFISH_OPENGL_ROOT")" || return 1
  branch="$(git -C "$root" rev-parse --abbrev-ref HEAD)" || return 1
  [ "$branch" != "HEAD" ] || {
    echo "A16DBG:IDENTITY: graphics source is detached" >&2
    return 1
  }
  for allowed in $BST_ALLOWED_GOLDFISH_BRANCHES; do
    [ "$branch" = "$allowed" ] && break
  done
  [ "$branch" = "$allowed" ] || {
    echo "A16DBG:IDENTITY: unexpected graphics branch '$branch'" >&2
    return 1
  }
  status="$(git -C "$root" status --porcelain=v1 --untracked-files=normal)" || return 1
  [ -z "$status" ] || {
    echo "A16DBG:IDENTITY: graphics source is dirty:" >&2
    printf '%s\n' "$status" >&2
    return 1
  }
  echo "A16DBG:IDENTITY: graphics_tree=$root"
  echo "A16DBG:IDENTITY: graphics_branch=$branch"
  echo "A16DBG:IDENTITY: graphics_head=$(git -C "$root" rev-parse HEAD)"
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
  reference=""
  if [ -n "$BST_AOSP16_REFERENCE_ROOT" ]; then
    reference="$(bst_realpath "$BST_AOSP16_REFERENCE_ROOT" 2>/dev/null || true)"
  fi
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
  local path
  local audit_args=()
  [ -f "$BST_CLEAN_AUDIT_TOOL" ] || {
    echo "A16DBG:IDENTITY: missing clean audit tool: $BST_CLEAN_AUDIT_TOOL" >&2
    return 1
  }
  for path in $BST_ALLOWED_ROOT_DIRTY_PATHS; do
    audit_args+=(--allow-root-dirty "$path")
  done
  python3 "$BST_CLEAN_AUDIT_TOOL" "$BST_ANDROID16_ROOT" \
    --jobs "$BST_CLEAN_AUDIT_JOBS" "${audit_args[@]}"
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
  local root branch head graphics_root graphics_branch graphics_head
  root="$(bst_realpath "$BST_ANDROID16_ROOT")" || return 1
  branch="$(git -C "$BST_ANDROID16_ROOT" rev-parse --abbrev-ref HEAD)" || return 1
  head="$(git -C "$BST_ANDROID16_ROOT" rev-parse HEAD)" || return 1
  bst_android16_graphics_preflight >/dev/null || return 1
  graphics_root="$(bst_realpath "$BST_GOLDFISH_OPENGL_ROOT")" || return 1
  graphics_branch="$(git -C "$graphics_root" rev-parse --abbrev-ref HEAD)" || return 1
  graphics_head="$(git -C "$graphics_root" rev-parse HEAD)" || return 1
  if [ -n "$artifact" ] && [ -f "$artifact" ]; then
    artifact_hash="$(sha256sum "$artifact" | awk '{print $1}')"
  fi
  {
    printf 'tree=%s\n' "$root"
    printf 'branch=%s\n' "$branch"
    printf 'head=%s\n' "$head"
    printf 'out_dir=%s\n' "$root/$BST_OUT_DIR_NAME"
    printf 'product=%s\n' "$BST_PRODUCT"
    if [ -n "$BST_ALLOWED_ROOT_DIRTY_PATHS" ]; then
      printf 'dirty=allowed\n'
      printf 'dirty_paths=%s\n' "$BST_ALLOWED_ROOT_DIRTY_PATHS"
    else
      printf 'dirty=0\n'
      printf 'dirty_paths=\n'
    fi
    printf 'graphics_tree=%s\n' "$graphics_root"
    printf 'graphics_branch=%s\n' "$graphics_branch"
    printf 'graphics_head=%s\n' "$graphics_head"
    printf 'graphics_dirty=0\n'
    printf 'artifact=%s\n' "$artifact"
    printf 'artifact_sha256=%s\n' "$artifact_hash"
    printf 'recorded_at=%s\n' "$(date -Is)"
  } > "$output"
}

bst_verify_identity_file() {
  local identity="$1" artifact="${2:-}"
  local recorded_tree="" recorded_branch="" recorded_head="" recorded_out=""
  local recorded_product="" recorded_artifact_hash="" current_hash=""
  local recorded_graphics_tree="" recorded_graphics_branch="" recorded_graphics_head=""
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
      graphics_tree) recorded_graphics_tree="$value" ;;
      graphics_branch) recorded_graphics_branch="$value" ;;
      graphics_head) recorded_graphics_head="$value" ;;
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
  bst_android16_graphics_preflight >/dev/null || return 1
  [ "$recorded_graphics_tree" = "$(bst_realpath "$BST_GOLDFISH_OPENGL_ROOT")" ] || {
    echo "A16DBG:IDENTITY: graphics tree mismatch in $identity" >&2
    return 1
  }
  [ "$recorded_graphics_branch" = "$(git -C "$BST_GOLDFISH_OPENGL_ROOT" rev-parse --abbrev-ref HEAD)" ] || {
    echo "A16DBG:IDENTITY: graphics branch mismatch in $identity" >&2
    return 1
  }
  [ "$recorded_graphics_head" = "$(git -C "$BST_GOLDFISH_OPENGL_ROOT" rev-parse HEAD)" ] || {
    echo "A16DBG:IDENTITY: graphics HEAD mismatch in $identity" >&2
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

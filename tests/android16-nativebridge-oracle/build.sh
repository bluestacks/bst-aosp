#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 [--android-root PATH] --output APK" >&2
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ANDROID_ROOT=${ANDROID16_ROOT:-"$HOME/android-16"}
OUTPUT=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --android-root)
      ANDROID_ROOT=$2
      shift 2
      ;;
    --output)
      OUTPUT=$2
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done
[[ -n "$OUTPUT" ]] || { usage; exit 2; }

ANDROID_ROOT=$(realpath "$ANDROID_ROOT")
case "$ANDROID_ROOT" in
  *aosp16*) echo "refusing AOSP16 tree: $ANDROID_ROOT" >&2; exit 2 ;;
esac
GIT_ROOT=$(git -C "$ANDROID_ROOT" rev-parse --show-toplevel)
[[ "$(realpath "$GIT_ROOT")" == "$ANDROID_ROOT" ]] || {
  echo "Android root identity mismatch: $GIT_ROOT" >&2
  exit 2
}
[[ "$ANDROID_ROOT" == */android-16 ]] || {
  echo "expected Android-16 target root, got $ANDROID_ROOT" >&2
  exit 2
}
BRANCH=$(git -C "$ANDROID_ROOT" branch --show-current)
[[ "$BRANCH" == "aosp16-bst-merge" ]] || {
  echo "expected Android-16 promotion branch aosp16-bst-merge, got ${BRANCH:-detached}" >&2
  exit 2
}

ANDROID_JAR="$ANDROID_ROOT/prebuilts/sdk/current/public/android.jar"
AAPT2="$ANDROID_ROOT/prebuilts/sdk/tools/linux/bin/aapt2"
D8="$ANDROID_ROOT/prebuilts/r8/d8"
ZIPALIGN="$ANDROID_ROOT/prebuilts/sdk/tools/linux/bin/zipalign"
APKSIGNER="$ANDROID_ROOT/prebuilts/sdk/tools/linux/bin/apksigner"
mapfile -t CLANG_CANDIDATES < <(
  find "$ANDROID_ROOT/prebuilts/clang/host/linux-x86" -path '*/bin/clang' \
    -type f -print | sort -V
)
mapfile -t READOBJ_CANDIDATES < <(
  find "$ANDROID_ROOT/prebuilts/clang/host/linux-x86" -path '*/bin/llvm-readobj' \
    -type f -print | sort -V
)
[[ ${#CLANG_CANDIDATES[@]} -gt 0 ]] || {
  echo "missing Android-16 AArch64-capable clang" >&2
  exit 2
}
[[ ${#READOBJ_CANDIDATES[@]} -gt 0 ]] || {
  echo "missing Android-16 llvm-readobj" >&2
  exit 2
}
CLANG=${CLANG_CANDIDATES[-1]}
READOBJ=${READOBJ_CANDIDATES[-1]}
for input in "$ANDROID_JAR" "$AAPT2" "$D8" "$ZIPALIGN" "$APKSIGNER" \
    "$CLANG" "$READOBJ"; do
  [[ -e "$input" ]] || { echo "missing Android-16 prebuilt: $input" >&2; exit 2; }
done
for tool in javac keytool zip sha256sum; do
  command -v "$tool" >/dev/null || { echo "missing host tool: $tool" >&2; exit 2; }
done

OUTPUT=$(realpath -m "$OUTPUT")
case "$OUTPUT" in
  *aosp16*) echo "refusing AOSP16 output path: $OUTPUT" >&2; exit 2 ;;
  "$ANDROID_ROOT"/*) echo "refusing output inside Android source tree: $OUTPUT" >&2; exit 2 ;;
esac
mkdir -p "$(dirname "$OUTPUT")"
rm -f "$OUTPUT" "$OUTPUT.identity"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/a16-nativebridge-oracle.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/classes" "$WORK/dex" "$WORK/apk/lib/arm64-v8a"

"$CLANG" --target=aarch64-linux-android35 -fPIC -shared -nostdlib \
  -Wl,--build-id=sha1 -Wl,--no-undefined -Wl,-soname,liba16nativeoracle.so \
  -o "$WORK/apk/lib/arm64-v8a/liba16nativeoracle.so" \
  "$SCRIPT_DIR/native/oracle.c"
"$READOBJ" --file-headers "$WORK/apk/lib/arm64-v8a/liba16nativeoracle.so" |
  grep -q 'Arch: aarch64' || {
    echo "native oracle is not AArch64" >&2
    exit 2
  }

mapfile -t SOURCES < <(find "$SCRIPT_DIR/src" -type f -name '*.java' -print | sort)
[[ ${#SOURCES[@]} -gt 0 ]] || { echo "oracle Java sources missing" >&2; exit 2; }
javac -g:none -encoding UTF-8 -source 8 -target 8 -bootclasspath "$ANDROID_JAR" \
  -d "$WORK/classes" "${SOURCES[@]}"
mapfile -t CLASSES < <(find "$WORK/classes" -type f -name '*.class' -print | sort)
"$D8" --lib "$ANDROID_JAR" --min-api 30 --output "$WORK/dex" "${CLASSES[@]}"
"$AAPT2" link -I "$ANDROID_JAR" --manifest "$SCRIPT_DIR/AndroidManifest.xml" \
  --min-sdk-version 30 --target-sdk-version 35 --version-code 1 --version-name 1 \
  -o "$WORK/unsigned.apk"
cp "$WORK/dex/classes.dex" "$WORK/apk/classes.dex"
cp "$WORK/unsigned.apk" "$WORK/unaligned.apk"
(cd "$WORK/apk" && zip -q -r "$WORK/unaligned.apk" classes.dex lib)
"$ZIPALIGN" -f 4 "$WORK/unaligned.apk" "$WORK/aligned.apk"
keytool -genkeypair -keystore "$WORK/oracle.keystore" -storepass android \
  -keypass android -alias androiddebugkey -dname "CN=A16 Native Bridge Oracle" \
  -keyalg RSA -validity 10000 -noprompt >/dev/null 2>&1
"$APKSIGNER" sign --ks "$WORK/oracle.keystore" --ks-pass pass:android \
  --key-pass pass:android --out "$OUTPUT" "$WORK/aligned.apk"
"$APKSIGNER" verify "$OUTPUT"

APK_SHA=$(sha256sum "$OUTPUT" | awk '{print $1}')
NATIVE_SHA=$(sha256sum "$WORK/apk/lib/arm64-v8a/liba16nativeoracle.so" | awk '{print $1}')
SOURCE_SHA=$(
  find "$SCRIPT_DIR" -type f \( -name '*.java' -o -name '*.c' \
    -o -name 'AndroidManifest.xml' \) -print0 |
    sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
)
{
  echo "stage=android16-promotion"
  echo "tree=$ANDROID_ROOT"
  echo "branch=$BRANCH"
  echo "head=$(git -C "$ANDROID_ROOT" rev-parse HEAD)"
  echo "oracle_source_sha256=$SOURCE_SHA"
  echo "native_elf_sha256=$NATIVE_SHA"
  echo "apk_sha256=$APK_SHA"
} >"$OUTPUT.identity"
echo "A16DBG:ANDROID16: native-bridge oracle APK=$OUTPUT sha256=$APK_SHA"

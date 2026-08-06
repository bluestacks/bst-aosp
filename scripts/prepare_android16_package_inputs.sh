#!/bin/bash
# Assemble the Android-16 app-player payload from reviewable, immutable inputs.
set -euo pipefail

BST_A16_COMMIT="e7a61686ae5b7c599f0c1e650ea900ac922f97c7"
BST_A16_CONFIG_SHA256="cb82f64d7c5728e7b5ced336ec01e7dffca43a6f7ec973dc0f99fc199c670010"
SCRATCH_GAURAV_CHROME_COMMIT="fac0e983ac95f32510406e4bf1d2e9eb8eef3cbc"
LEGACY_ROOT_SHA256="6ed535717f89bdac8e6318924f39246fe10a95f1adb701f6096d13f43e7153b1"

APP_PLAYER_DIR="${APP_PLAYER_DIR:-$HOME/app-player}"
BUNDLE_DIR="${BST_A16_PACKAGE_BUNDLE:-$HOME/a16-package-inputs/bst-v5.22.210-A16-e7a61686}"
LEGACY_ROOT="${BST_A16_LEGACY_ROOT:-$HOME/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd.bak-054651}"
INSTALL=0
VERIFY_ONLY=0

usage() {
    cat <<'EOF'
Usage: prepare_android16_package_inputs.sh [--install | --verify-only]

Builds or verifies a deterministic external APK bundle. After app-player has
created its APK staging directory, --install points the ignored Baklava config
and staging paths at the verified bundle. --verify-only fails instead of
assembling a missing bundle.
EOF
}

while (($#)); do
    case "$1" in
        --install) INSTALL=1 ;;
        --verify-only) VERIFY_ONLY=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done
if ((INSTALL && VERIFY_ONLY)); then
    echo "--install and --verify-only are mutually exclusive" >&2
    exit 2
fi

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}

reject_henry_path() {
    local value=$1
    case "$value" in
        /home/henry|/home/henry/*)
            echo "Refusing external Henry path: $value" >&2
            exit 1
            ;;
    esac
}

for command in awk cp du find grep ionice ln nice readlink realpath rm sha256sum unzip wc; do
    require_command "$command"
done

APP_PLAYER_DIR=$(realpath -e "$APP_PLAYER_DIR")
reject_henry_path "$APP_PLAYER_DIR"
reject_henry_path "$LEGACY_ROOT"

case "$APP_PLAYER_DIR" in
    "$HOME"/app-player) ;;
    *) echo "Unexpected app-player root: $APP_PLAYER_DIR" >&2; exit 1 ;;
esac
case "$LEGACY_ROOT" in
    "$HOME"/releases/Baklava64/*) ;;
    *) echo "Unexpected legacy Root path: $LEGACY_ROOT" >&2; exit 1 ;;
esac
case "$BUNDLE_DIR" in
    "$HOME"/a16-package-inputs/*) ;;
    *) echo "Unexpected bundle path: $BUNDLE_DIR" >&2; exit 1 ;;
esac

config_name="baklava_appPlayerApksToInstall_nxt_baklava64"

verify_bundle() {
    local bundle=$1
    local config="$bundle/baklava/$config_name"
    [[ -d "$bundle/payload" && -f "$bundle/SOURCE.identity" && \
        -f "$bundle/SHA256SUMS" && -f "$config" ]] || {
        echo "Incomplete package bundle: $bundle" >&2
        exit 1
    }
    grep -Fxq "bst_commit=$BST_A16_COMMIT" "$bundle/SOURCE.identity"
    grep -Fxq "baklava_config_sha256=$BST_A16_CONFIG_SHA256" "$bundle/SOURCE.identity"
    grep -Fxq "scratch_gaurav_chrome_commit=$SCRATCH_GAURAV_CHROME_COMMIT" \
        "$bundle/SOURCE.identity"
    grep -Fxq "legacy_root_sha256=$LEGACY_ROOT_SHA256" "$bundle/SOURCE.identity"
    [[ $(sha256sum "$config" | awk '{print $1}') == "$BST_A16_CONFIG_SHA256" ]] || {
        echo "Existing bundle config identity mismatch" >&2
        exit 1
    }
    (cd "$bundle" && ionice -c3 nice -n 19 sha256sum --quiet -c SHA256SUMS)

    local missing=0
    local name
    while IFS= read -r name || [[ -n "$name" ]]; do
        name=${name%$'\r'}
        [[ -z "$name" ]] && continue
        case "$name" in
            System:|SystemPrivApp:|Data:|Priv-Downloads:|Downloads:) continue ;;
        esac
        if [[ ! -e "$bundle/payload/$name" ]]; then
            echo "Missing configured bundle payload: $name" >&2
            missing=$((missing + 1))
        fi
    done < "$config"
    for name in xp GameFrameworkSetting.dat admob_user_agent.xml; do
        if [[ ! -e "$bundle/payload/$name" ]]; then
            echo "Missing package bundle payload: $name" >&2
            missing=$((missing + 1))
        fi
    done
    ((missing == 0)) || exit 1

    VERIFIED_APK_COUNT=0
    while IFS= read -r -d '' apk; do
        ionice -c3 nice -n 19 unzip -tq "$apk" >/dev/null || {
            echo "Invalid APK/ZIP bundle payload: $apk" >&2
            exit 1
        }
        VERIFIED_APK_COUNT=$((VERIFIED_APK_COUNT + 1))
    done < <(find "$bundle/payload" -type f -name '*.apk' -print0)
    ((VERIFIED_APK_COUNT > 0)) || {
        echo "No APK payloads in package bundle" >&2
        exit 1
    }
}

install_bundle() {
    local config_link="$APP_PLAYER_DIR/bst/apks/baklava"
    local staging_config_link="$APP_PLAYER_DIR/bst/apks_Baklava64/baklava"
    local staging="$APP_PLAYER_DIR/bst/apks_Baklava64"
    [[ -d "$staging" ]] || {
        echo "Missing active APK staging directory: $staging" >&2
        exit 1
    }
    for link in "$config_link" "$staging_config_link"; do
        if [[ -L "$link" ]]; then
            local literal_target
            literal_target=$(readlink "$link")
            case "$literal_target" in
                /home/henry|/home/henry/*)
                    echo "Detaching external config link without reading its target: $link"
                    ;;
            esac
            rm -- "$link"
        elif [[ -e "$link" ]]; then
            echo "Refusing to replace non-symlink path: $link" >&2
            exit 1
        fi
        ln -s "$BUNDLE_DIR/baklava" "$link"
    done
    cp -a "$BUNDLE_DIR/payload/." "$staging/"

    for link in "$config_link" "$staging_config_link"; do
        local resolved
        resolved=$(readlink -f "$link")
        reject_henry_path "$resolved"
        [[ "$resolved" == "$BUNDLE_DIR/baklava" ]] || {
            echo "Unexpected installed config link: $link -> $resolved" >&2
            exit 1
        }
    done
    echo "INSTALLED_STAGING=$staging"
}

if [[ -e "$BUNDLE_DIR" ]]; then
    verify_bundle "$BUNDLE_DIR"
    echo "BUNDLE=$BUNDLE_DIR"
    echo "BUNDLE_STATUS=verified-existing"
    echo "BUNDLE_BYTES=$(du -sb "$BUNDLE_DIR" | awk '{print $1}')"
    echo "BUNDLE_FILES=$(find "$BUNDLE_DIR" -type f | wc -l)"
    echo "BUNDLE_APKS=$VERIFIED_APK_COUNT"
    ((INSTALL)) && install_bundle
    exit 0
fi
if ((VERIFY_ONLY)); then
    echo "Package bundle is absent: $BUNDLE_DIR" >&2
    exit 1
fi

for command in dd debugfs git ionice mktemp mv nice qemu-img sed sort stat tar xargs; do
    require_command "$command"
done
LEGACY_ROOT=$(realpath -e "$LEGACY_ROOT")
reject_henry_path "$LEGACY_ROOT"

legacy_sha=$(ionice -c3 nice -n 19 sha256sum "$LEGACY_ROOT" | awk '{print $1}')
if [[ "$legacy_sha" != "$LEGACY_ROOT_SHA256" ]]; then
    echo "Legacy Root identity mismatch: $legacy_sha" >&2
    exit 1
fi

work=$(mktemp -d "$HOME/.work-a16-package-inputs.XXXXXX")
cleanup() {
    case "$work" in
        "$HOME"/.work-a16-package-inputs.*) rm -rf -- "$work" ;;
    esac
}
trap cleanup EXIT INT TERM

clone="$work/bst-a16"
payload="$work/bundle/payload"
config_dir="$work/bundle/baklava"
mkdir -p "$payload" "$config_dir"

GIT_LFS_SKIP_SMUDGE=1 git clone --quiet --depth 1 \
    --branch bst-v5.22.210-A16 --filter=blob:none \
    git@github.com:bluestacks/bst.git "$clone"
bst_head=$(git -C "$clone" rev-parse HEAD)
[[ "$bst_head" == "$BST_A16_COMMIT" ]] || {
    echo "Unexpected bst A16 head: $bst_head" >&2
    exit 1
}

cp -a "$clone/apks/baklava/$config_name" "$config_dir/"
config_sha=$(sha256sum "$config_dir/$config_name" | awk '{print $1}')
[[ "$config_sha" == "$BST_A16_CONFIG_SHA256" ]] || {
    echo "Unexpected Baklava config hash: $config_sha" >&2
    exit 1
}

for name in \
    com.bluestacks.billing.service.apk \
    now.gg.billing.service.apk \
    gg.now.billing.service2.apk \
    gg.now.accounts.apk \
    gg.now.ads.service.apk \
    GameFrameworkSetting.dat \
    admob_user_agent.xml; do
    cp -a "$clone/apks/$name" "$payload/"
done

gapps="$APP_PLAYER_DIR/scratch-gaurav/gapps_tiramisu64"
for name in \
    com.google.android.configupdater.apk \
    com.google.android.backuptransport.apk \
    com.google.android.gsf.login.apk \
    com.google.android.partnersetup.apk \
    com.google.android.gsf.apk \
    com.android.vending \
    com.google.android.gms \
    com.google.android.feedback.apk \
    com.google.android.gms.setup.apk \
    com.google.android.onetimeinitializer.apk \
    com.google.android.apps.restore.apk \
    com.google.android.syncadapters.calendar.apk \
    com.google.android.syncadapters.contacts.apk \
    com.google.android.ext.shared.apk \
    com.google.android.play.games; do
    [[ -e "$gapps/$name" ]] || {
        echo "Missing A13-compatible GApps input: $gapps/$name" >&2
        exit 1
    }
    cp -a "$gapps/$name" "$payload/"
done

scratch="$APP_PLAYER_DIR/scratch-gaurav"
scratch_head=$(git -C "$scratch" rev-parse HEAD)
git -C "$scratch" cat-file -e "$SCRATCH_GAURAV_CHROME_COMMIT^{commit}"
mkdir -p "$work/chrome"
git -C "$scratch" archive "$SCRATCH_GAURAV_CHROME_COMMIT" \
    gapps_tiramisu64/com.android.chrome | tar -x -C "$work/chrome"
cp -a "$work/chrome/gapps_tiramisu64/com.android.chrome" "$payload/"

trichrome_path="gapps_tiramisu64/com.google.android.trichromelibrary/TrichromeLibrary.apk"
pointer=$(git -C "$scratch" show "$SCRATCH_GAURAV_CHROME_COMMIT:$trichrome_path")
trichrome_oid=$(sed -n 's/^oid sha256://p' <<<"$pointer")
trichrome_size=$(sed -n 's/^size //p' <<<"$pointer")
[[ "$trichrome_oid" =~ ^[0-9a-f]{64}$ && "$trichrome_size" =~ ^[0-9]+$ ]] || {
    echo "Invalid Trichrome LFS pointer" >&2
    exit 1
}
git -C "$scratch" lfs fetch --include="$trichrome_path" \
    origin "$SCRATCH_GAURAV_CHROME_COMMIT"
scratch_git_dir=$(git -C "$scratch" rev-parse --absolute-git-dir)
trichrome_object="$scratch_git_dir/lfs/objects/${trichrome_oid:0:2}/${trichrome_oid:2:2}/$trichrome_oid"
[[ -f "$trichrome_object" ]] || {
    echo "Trichrome LFS object was not fetched" >&2
    exit 1
}
[[ $(stat -c %s "$trichrome_object") == "$trichrome_size" ]] || {
    echo "Trichrome LFS size mismatch" >&2
    exit 1
}
[[ $(sha256sum "$trichrome_object" | awk '{print $1}') == "$trichrome_oid" ]] || {
    echo "Trichrome LFS hash mismatch" >&2
    exit 1
}
cp -a "$trichrome_object" "$payload/Trichromelibrary.apk"

raw="$work/root.raw"
partition="$work/root-partition.raw"
ionice -c3 nice -n 19 qemu-img convert -O raw -S 4096 "$LEGACY_ROOT" "$raw"
ionice -c3 nice -n 19 dd if="$raw" of="$partition" bs=1M skip=1 count=8191 \
    iflag=fullblock conv=sparse status=none

dump_guest_file() {
    local guest_path=$1
    local output_name=$2
    debugfs -R "dump -p $guest_path $payload/$output_name" "$partition" >/dev/null 2>&1
    [[ -s "$payload/$output_name" ]] || {
        echo "Failed to extract $guest_path" >&2
        exit 1
    }
}

for name in \
    com.bluestacks.bsxlauncher.apk \
    com.bluestacks.filemanager.apk \
    com.bluestacks.gamecenter.apk \
    com.bluestacks.home.apk \
    com.bluestacks.nowgg.apk \
    com.bluestacks.piggy.apk \
    com.location.provider.apk \
    com.bluestacks.quest.apk; do
    package=${name%.apk}
    dump_guest_file "/dataFS/downloads/$package/$name" "$name"
done
dump_guest_file \
    "/dataFS/downloads/com.uncube.launcher3/com.uncube.launcher3.apk" \
    "com.uncube.launcher3.apk"
dump_guest_file \
    "/dataFS/priv-downloads/gg.now.billing.interceptor/gg.now.billing.interceptor.apk" \
    "gg.now.billing.interceptor.apk"

mkdir -p "$work/xp"
debugfs -R "rdump /dataFS/downloads/.xp $work/xp" "$partition" >/dev/null 2>&1
if [[ -d "$work/xp/.xp" ]]; then
    mv "$work/xp/.xp" "$payload/xp"
elif [[ -d "$work/xp/lib" && -d "$work/xp/lib64" ]]; then
    mv "$work/xp" "$payload/xp"
else
    echo "Failed to extract the .xp directory" >&2
    exit 1
fi
find "$payload/xp" -type f -print -quit | grep -q . || {
    echo "Extracted .xp directory is empty" >&2
    exit 1
}

missing=0
while IFS= read -r name || [[ -n "$name" ]]; do
    name=${name%$'\r'}
    [[ -z "$name" ]] && continue
    case "$name" in
        System:|SystemPrivApp:|Data:|Priv-Downloads:|Downloads:) continue ;;
    esac
    if [[ ! -e "$payload/$name" ]]; then
        echo "Missing configured payload: $name" >&2
        missing=$((missing + 1))
    fi
done < "$config_dir/$config_name"
for name in xp GameFrameworkSetting.dat admob_user_agent.xml; do
    if [[ ! -e "$payload/$name" ]]; then
        echo "Missing packaging payload: $name" >&2
        missing=$((missing + 1))
    fi
done
((missing == 0)) || exit 1

apk_count=0
while IFS= read -r -d '' apk; do
    unzip -tq "$apk" >/dev/null || {
        echo "Invalid APK/ZIP payload: $apk" >&2
        exit 1
    }
    apk_count=$((apk_count + 1))
done < <(find "$payload" -type f -name '*.apk' -print0)
((apk_count > 0)) || {
    echo "No APK payloads were assembled" >&2
    exit 1
}

cat > "$work/bundle/SOURCE.identity" <<EOF
stage=android16-promotion
result=current-external-input
bst_repo=git@github.com:bluestacks/bst.git
bst_branch=bst-v5.22.210-A16
bst_commit=$BST_A16_COMMIT
baklava_config_sha256=$BST_A16_CONFIG_SHA256
scratch_gaurav_current_commit=$scratch_head
scratch_gaurav_chrome_commit=$SCRATCH_GAURAV_CHROME_COMMIT
trichrome_lfs_sha256=$trichrome_oid
legacy_root=$LEGACY_ROOT
legacy_root_sha256=$LEGACY_ROOT_SHA256
origin_tree=$APP_PLAYER_DIR
target_tree=$APP_PLAYER_DIR
preservation=generated
EOF
(
    cd "$work/bundle"
    find . -type f ! -name SHA256SUMS -print0 | LC_ALL=C sort -z | \
        xargs -0 sha256sum > SHA256SUMS
)

mkdir -p "$(dirname "$BUNDLE_DIR")"
if [[ -e "$BUNDLE_DIR" ]]; then
    echo "Bundle already exists; refusing to overwrite: $BUNDLE_DIR" >&2
    exit 1
fi
mv "$work/bundle" "$BUNDLE_DIR"
verify_bundle "$BUNDLE_DIR"
echo "BUNDLE=$BUNDLE_DIR"
echo "BUNDLE_STATUS=assembled"
echo "BUNDLE_BYTES=$(du -sb "$BUNDLE_DIR" | awk '{print $1}')"
echo "BUNDLE_FILES=$(find "$BUNDLE_DIR" -type f | wc -l)"
echo "BUNDLE_APKS=$VERIFIED_APK_COUNT"

if ((INSTALL)); then
    install_bundle
fi

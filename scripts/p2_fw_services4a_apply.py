#!/usr/bin/env python3
# P2-FW-SERVICES-4a: AudioService volume host sync + AppOpsService devicedetails (a13).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
MARKER = "A16DBG:P2:FW-SERVICES-4a"
ERRS = []
AUDIO = "services/core/java/com/android/server/audio/AudioService.java"
APPOPS = "services/core/java/com/android/server/appop/AppOpsService.java"


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
    if MARKER in src:
        print(f"SKIP {label} (already patched)")
        return
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:80]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:80]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


BST_VOLUME_METHOD = """
    // A16DBG:P2:FW-SERVICES-4a volume host sync (a13 bstSendVolumeToHost)
    private void bstSendVolumeToHost(int index) {
        int volume = index / 10;
        VolumeStreamState musicState = mStreamStates.get(AudioSystem.STREAM_MUSIC);
        boolean mute = musicState != null && musicState.mIsMuted;

        Log.d(TAG, "bstSendVolumeToHost: currentVolume = " + volume + " mute = " + mute);

        BstHostCallManager bstHostCallManagerSvc =
                (BstHostCallManager) mContext.getSystemService(Context.BST_HOST_CALL);
        if (bstHostCallManagerSvc == null) {
            return;
        }
        int rval = bstHostCallManagerSvc.onVolumeChanged(mute, volume);
        if (rval != 0) {
            Log.w(TAG, "ERROR in sending volume data request, rval = " + rval);
        }
    }

"""

patch(
    AUDIO,
    [
        (
            "import java.util.stream.Collectors;\n",
            "import java.util.stream.Collectors;\n\n"
            "import com.bluestacks.os.BstHostCallManager;\n",
        ),
        (
            "        if (streamType == AudioSystem.STREAM_MUSIC && isFullVolumeDevice(device)) {\n"
            "            flags &= ~AudioManager.FLAG_SHOW_UI;\n"
            "        }\n"
            "        mVolumeController.postVolumeChanged(streamType, flags);\n",
            "        if (streamType == AudioSystem.STREAM_MUSIC && isFullVolumeDevice(device)) {\n"
            "            flags &= ~AudioManager.FLAG_SHOW_UI;\n"
            "        }\n"
            "        // A16DBG:P2:FW-SERVICES-4a notify host on STREAM_MUSIC volume change\n"
            "        if (streamType == AudioSystem.STREAM_MUSIC) {\n"
            "            bstSendVolumeToHost(index);\n"
            "        }\n"
            "        mVolumeController.postVolumeChanged(streamType, flags);\n",
        ),
        (
            "    // Don't show volume UI when:\n"
            "    //  - Hdmi-CEC system audio mode is on and we are a TV panel\n"
            "    private int updateFlagsForTvPlatform(int flags) {\n",
            BST_VOLUME_METHOD
            + "    // Don't show volume UI when:\n"
            "    //  - Hdmi-CEC system audio mode is on and we are a TV panel\n"
            "    private int updateFlagsForTvPlatform(int flags) {\n",
        ),
    ],
    "AudioService",
)

patch(
    APPOPS,
    [
        (
            "            if (resolveNonAppUid(packageName) == uid\n"
            "                    || (isPackageExisted(packageName)\n"
            "                            && !filterAppAccessUnlocked(packageName, UserHandle.getUserId(uid)))) {\n"
            "                return AppOpsManager.MODE_ALLOWED;\n"
            "            }\n",
            "            if (resolveNonAppUid(packageName) == uid\n"
            "                    || (isPackageExisted(packageName)\n"
            "                            && !filterAppAccessUnlocked(packageName, UserHandle.getUserId(uid)))\n"
            "                    // A16DBG:P2:FW-SERVICES-4a synthetic package for device details (a13)\n"
            "                    || packageName.equals(\"com.bluestacks.devicedetails\")) {\n"
            "                return AppOpsManager.MODE_ALLOWED;\n"
            "            }\n",
        ),
    ],
    "AppOpsService",
)

if ERRS:
    for e in ERRS:
        print(f"ERROR {e}", file=sys.stderr)
    sys.exit(1)

for rel in (AUDIO, APPOPS):
    print(f"VERIFY {rel}:", MARKER in open(os.path.join(A16, rel)).read())

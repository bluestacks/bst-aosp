#!/usr/bin/env python3
"""R258: Henry — force isLockScreenDisabled()=true so keyguard cannot steal launcher focus."""
from pathlib import Path

PATH = Path.home() / (
    "aosp16/frameworks/base/core/java/com/android/internal/widget/LockPatternUtils.java"
)
MARKER = "R258 / Henry BS-A16: force lockscreen disabled"

OLD = """    @UnsupportedAppUsage
    public boolean isLockScreenDisabled(int userId) {
        if (isSecure(userId)) {
            return false;
        }
        boolean disabledByDefault = mContext.getResources().getBoolean(
                com.android.internal.R.bool.config_disableLockscreenByDefault);
        UserInfo userInfo = getUserManager().getUserInfo(userId);
        boolean isDemoUser = UserManager.isDeviceInDemoMode(mContext) && userInfo != null
                && userInfo.isDemo();
        return getBoolean(DISABLE_LOCKSCREEN_KEY, false, userId)
                || disabledByDefault
                || isDemoUser;
    }
"""

NEW = """    @UnsupportedAppUsage
    public boolean isLockScreenDisabled(int userId) {
        // R258 / Henry BS-A16: force lockscreen disabled
        // Without this, SystemUI keyguard steals window focus from the launcher
        // and blocks HCALL onActivityDisplayed -> HD overlay never clears.
        /*
        if (isSecure(userId)) {
            return false;
        }
        boolean disabledByDefault = mContext.getResources().getBoolean(
                com.android.internal.R.bool.config_disableLockscreenByDefault);
        UserInfo userInfo = getUserManager().getUserInfo(userId);
        boolean isDemoUser = UserManager.isDeviceInDemoMode(mContext) && userInfo != null
                && userInfo.isDemo();
        return getBoolean(DISABLE_LOCKSCREEN_KEY, false, userId)
                || disabledByDefault
                || isDemoUser;
        */
        return true;
    }
"""


def main() -> None:
    text = PATH.read_text()
    if MARKER in text:
        print(f"already patched: {PATH}")
        return
    if OLD not in text:
        raise SystemExit("isLockScreenDisabled block not found")
    PATH.write_text(text.replace(OLD, NEW, 1))
    print(f"patched: {PATH}")
    print("R258_PATCH_OK")


if __name__ == "__main__":
    main()

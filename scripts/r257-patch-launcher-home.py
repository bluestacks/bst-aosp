#!/usr/bin/env python3
"""R257: Henry 7AF — remove Launcher3 HOME + OverviewComponentObserver null-safe."""
from pathlib import Path

AOSP = Path.home() / "aosp16"
L3 = AOSP / "packages/apps/Launcher3"

MANIFEST_SNIPPET_OLD = """                <action android:name="android.intent.action.MAIN" />
                <action android:name="android.intent.action.SHOW_WORK_APPS" />
                <action android:name="android.intent.action.ALL_APPS" />
                <category android:name="android.intent.category.HOME" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.MONKEY"/>
                <category android:name="android.intent.category.LAUNCHER_APP" />
"""

MANIFEST_SNIPPET_NEW = """                <action android:name="android.intent.action.MAIN" />
                <action android:name="android.intent.action.SHOW_WORK_APPS" />
                <action android:name="android.intent.action.ALL_APPS" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.MONKEY"/>
                <!--
                R257 / Henry BS-A16: remove HOME so com.uncube.launcher3 is sole home.
                <category android:name="android.intent.category.HOME" />
                <category android:name="android.intent.category.LAUNCHER_APP" />
                -->
"""

# Variant without LAUNCHER_APP on same lines (AndroidManifest.xml root may differ slightly)
MANIFEST_ALT_OLD = """                <category android:name="android.intent.category.HOME" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.MONKEY"/>
                <category android:name="android.intent.category.LAUNCHER_APP" />
"""

MANIFEST_ALT_NEW = """                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.MONKEY"/>
                <!--
                R257 / Henry BS-A16: remove HOME so com.uncube.launcher3 is sole home.
                <category android:name="android.intent.category.HOME" />
                <category android:name="android.intent.category.LAUNCHER_APP" />
                -->
"""


def patch_manifest(path: Path) -> None:
    text = path.read_text()
    if "R257 / Henry BS-A16: remove HOME" in text:
        print(f"already patched: {path}")
        return
    if MANIFEST_SNIPPET_OLD in text:
        path.write_text(text.replace(MANIFEST_SNIPPET_OLD, MANIFEST_SNIPPET_NEW, 1))
    elif MANIFEST_ALT_OLD in text:
        path.write_text(text.replace(MANIFEST_ALT_OLD, MANIFEST_ALT_NEW, 1))
    else:
        # softer: comment HOME + LAUNCHER_APP if present
        if 'android.intent.category.HOME' not in text:
            raise SystemExit(f"no HOME category in {path}")
        text2 = text.replace(
            '<category android:name="android.intent.category.HOME" />',
            '<!-- R257 HOME removed <category android:name="android.intent.category.HOME" /> -->',
            1,
        )
        text2 = text2.replace(
            '<category android:name="android.intent.category.LAUNCHER_APP" />',
            '<!-- R257 LAUNCHER_APP removed <category android:name="android.intent.category.LAUNCHER_APP" /> -->',
            1,
        )
        if text2 == text:
            raise SystemExit(f"failed to patch {path}")
        path.write_text(text2)
    print(f"patched manifest: {path}")


def patch_observer(path: Path) -> None:
    text = path.read_text()
    if "R257 / Henry BS-A16 OverviewComponentObserver" in text:
        print(f"already patched: {path}")
        return

    old1 = """        ResolveInfo info = context.getPackageManager().resolveActivity(mMyPrimaryHomeIntent, 0);
        ComponentName myHomeComponent =
                new ComponentName(context.getPackageName(), info.activityInfo.name);
        mMyPrimaryHomeIntent.setComponent(myHomeComponent);

        mConfigChangesMap.append(myHomeComponent.hashCode(), info.activityInfo.configChanges);
"""
    new1 = """        // R257 / Henry BS-A16 OverviewComponentObserver
        // HOME category removed → resolveActivity may be null; hardcode QuickstepLauncher.
        ResolveInfo info = context.getPackageManager().resolveActivity(mMyPrimaryHomeIntent, 0);
        ComponentName myHomeComponent = new ComponentName(
                "com.android.launcher3", "com.android.launcher3.uioverrides.QuickstepLauncher");
        mMyPrimaryHomeIntent.setComponent(myHomeComponent);

        mConfigChangesMap.append(myHomeComponent.hashCode(),
                info != null ? info.activityInfo.configChanges : 0);
"""
    if old1 not in text:
        raise SystemExit("observer resolve block not found")
    text = text.replace(old1, new1, 1)

    old2 = """        mIsDefaultHome = Objects.equals(mMyPrimaryHomeIntent.getComponent(), defaultHome);

        // Set assistant visibility to 0 from launcher's perspective, ensures any elements that
"""
    new2 = """        mIsDefaultHome = Objects.equals(mMyPrimaryHomeIntent.getComponent(), defaultHome);

        // R257 / Henry: if defaultHome null at boot, point at BlueStacks/uncube home.
        if (defaultHome == null) {
            mIsDefaultHome = false;
            defaultHome = new ComponentName("com.uncube.launcher3",
                    "com.bluestacks.launcher.activity.HomeActivity");
        }

        // Set assistant visibility to 0 from launcher's perspective, ensures any elements that
"""
    if old2 not in text:
        raise SystemExit("observer defaultHome block not found")
    text = text.replace(old2, new2, 1)
    path.write_text(text)
    print(f"patched observer: {path}")


def main() -> None:
    patch_manifest(L3 / "AndroidManifest.xml")
    patch_manifest(L3 / "quickstep/AndroidManifest-launcher.xml")
    patch_observer(L3 / "quickstep/src/com/android/quickstep/OverviewComponentObserver.java")
    print("R257_PATCH_OK")


if __name__ == "__main__":
    main()

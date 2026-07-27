#!/usr/bin/env python3
# P2-FW-CORE-APP-16: ActivityThread default profile + UE HighFPS + StrictMode (a13->a16).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []
MARKER = "A16DBG:P2:FW-CORE-APP-16"


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
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


PROCESS_UE = """
    // A16DBG:P2:FW-CORE-APP-16 UE High FPS console commands (a13)
    private int mMaxFps = 60;

    private int processUEHighFPS(String processName, int fps) {
        try {
            WeakReference<LoadedApk> weakReference = (WeakReference) this.mPackages.get(processName);
            if (weakReference == null) {
                return 0;
            }
            ClassLoader classLoader = weakReference.get().getClassLoader();
            Class<?> clazz = null;
            try {
                clazz = classLoader.loadClass("com.epicgames.unreal.GameActivity");
            } catch (ClassNotFoundException e) {
                try {
                    clazz = classLoader.loadClass("com.epicgames.ue4.GameActivity");
                } catch (ClassNotFoundException ex) {
                    return 0;
                }
            }
            if (clazz == null) {
                return 0;
            }
            Method method = clazz.getMethod("nativeConsoleCommand", String.class);
            Object obj = clazz.getConstructor().newInstance();
            if (obj == null || method == null) {
                return 0;
            }
            method.setAccessible(true);
            method.invoke(obj, "t.MaxFPS " + fps);
            method.invoke(obj, "r.SetFramePace " + fps);
        } catch (Exception exception) {
            exception.printStackTrace();
        }
        return 0;
    }

"""

DEFAULT_PROFILE = """
        // A16DBG:P2:FW-CORE-APP-16 default profile file bootstrap (a13)
        BstFilterAppsManager bfam = (BstFilterAppsManager)
                getSystemContext().getSystemService(Context.BST_FILTER_APPS);
        if (bfam != null) {
            String bstPackageName = data.info.getPackageName();
            String appsProfile = bfam.getDefaultProfile(bstPackageName);
            if (appsProfile != null && appsProfile.length() > 1) {
                try {
                    String spFilename = appsProfile.substring(
                            appsProfile.indexOf('=') + 1, appsProfile.indexOf(','));
                    String spKeyValueSequences = appsProfile.substring(
                            appsProfile.indexOf(('='), spFilename.length()) + 1);
                    int scoreAbove = bfam.getPScoreAbove(bstPackageName);
                    File file = new File(spFilename);
                    if (!file.exists()
                            && SystemProperties.getInt("bst.pscore", 180) > scoreAbove) {
                        File parentDir = file.getParentFile();
                        if (parentDir != null && !parentDir.exists()) {
                            if (spFilename.startsWith("/sdcard/Android/data/")) {
                                ContextImpl.getImpl(appContext).getExternalFilesDir(null);
                            }
                            parentDir.mkdirs();
                            parentDir.setReadable(true, false);
                            parentDir.setWritable(true, false);
                        }
                        file.createNewFile();
                        FileOutputStream fos = new FileOutputStream(file);
                        fos.write(spKeyValueSequences.getBytes());
                        file.setReadable(true, false);
                        file.setWritable(true, false);
                        fos.close();
                    }
                } catch (Exception e) {
                    Slog.e(TAG, "A16DBG:P2:FW-CORE-APP-16 bst create default profile failed!");
                }
            }
        }

"""

UE_FPS_BLOCK = """
        // A16DBG:P2:FW-CORE-APP-16 UE High FPS loop for Unreal/UE4 apps (a13)
        if (!data.appInfo.isPrivilegedApp() && !data.appInfo.isSystemApp() && bfam != null) {
            do {
                final String className = data.appInfo.className;
                if (className == null) {
                    Log.w(TAG, "Empty className detected for process: " + data.processName);
                    break;
                }
                if (!className.equals("com.epicgames.unreal.GameApplication")
                        && !className.equals("com.epicgames.ue4.GameApplication")) {
                    break;
                }
                final int mode = bfam.getXperfMode(data.appInfo.uid);
                final int enableHighFps = SystemProperties.getInt("bst.enable_high_fps", 0);
                final boolean enable = (mode == 2) || (mode == 1 && enableHighFps > 0);
                if (!enable) {
                    break;
                }
                mMaxFps = SystemProperties.getInt("bst.max_fps", 60);
                if (mMaxFps > 120) {
                    mMaxFps = 120;
                } else if (mMaxFps < 60) {
                    Log.w(TAG, "Invalid fps range: " + mMaxFps);
                    break;
                }
                Log.i(TAG, "Applying fps optimization for " + className + ", target=" + mMaxFps);
                (new Thread(() -> {
                    while (!Thread.currentThread().isInterrupted()) {
                        new Handler(Looper.getMainLooper()).post(() -> {
                            ActivityThread.this.processUEHighFPS(data.processName, mMaxFps);
                        });
                        try {
                            Thread.sleep(1000);
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                        }
                    }
                })).start();
            } while (false);
        }

"""

patch(
    "core/java/android/app/ActivityThread.java",
    [
        (
            "        throw new ForegroundServiceDidNotStartInTimeException(message, inner);\n    }\n",
            "        throw new ForegroundServiceDidNotStartInTimeException(message, inner);\n    }\n"
            + PROCESS_UE,
        ),
        (
            """        } else {
            mInstrumentation = new Instrumentation();
            mInstrumentation.basicInit(this);
        }

        if ((data.appInfo.flags&ApplicationInfo.FLAG_LARGE_HEAP) != 0) {
""",
            """        } else {
            mInstrumentation = new Instrumentation();
            mInstrumentation.basicInit(this);
        }
"""
            + DEFAULT_PROFILE
            + """
        if ((data.appInfo.flags&ApplicationInfo.FLAG_LARGE_HEAP) != 0) {
""",
        ),
        (
            """        } finally {
            // If the app targets < O-MR1, or doesn't change the thread policy
            // during startup, clobber the policy to maintain behavior of b/36951662
            if (data.appInfo.targetSdkVersion < Build.VERSION_CODES.O_MR1
                    || StrictMode.getThreadPolicy().equals(writesAllowedPolicy)) {
                StrictMode.setThreadPolicy(savedPolicy);
            }
        }

        // Preload fonts resources
""",
            """        } finally {
            // If the app targets < O-MR1, or doesn't change the thread policy
            // during startup, clobber the policy to maintain behavior of b/36951662
            boolean isBstPkg = data.info.getPackageName().toLowerCase().startsWith("com.bluestacks.");
            if (!isBstPkg && (data.appInfo.targetSdkVersion < Build.VERSION_CODES.O_MR1
                    || StrictMode.getThreadPolicy().equals(writesAllowedPolicy))) {
                StrictMode.setThreadPolicy(savedPolicy);
            }
        }

        // Preload fonts resources
""",
        ),
        (
            """            } catch (RemoteException e) {
                throw e.rethrowFromSystemServer();
            }
        }

        try {
            mgr.finishAttachApplication(mStartSeq, timestampApplicationOnCreateNs);
""",
            """            } catch (RemoteException e) {
                throw e.rethrowFromSystemServer();
            }
        }
"""
            + UE_FPS_BLOCK
            + """
        try {
            mgr.finishAttachApplication(mStartSeq, timestampApplicationOnCreateNs);
""",
        ),
    ],
    "ActivityThread default profile + UE FPS",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")

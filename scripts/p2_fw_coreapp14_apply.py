#!/usr/bin/env python3
# P2-FW-CORE-APP-14: NativeLibraryHelper BST ABI override (a13->a16).
import os
import sys

A16_ROOT = os.path.expanduser("~/aosp16/frameworks/base")
A13_FILE = os.path.expanduser(
    "~/app-player/android-13/frameworks/base/core/java/com/android/internal/content/NativeLibraryHelper.java"
)
TARGET = "core/java/com/android/internal/content/NativeLibraryHelper.java"
MARKER = "A16DBG:P2:FW-CORE-APP-14"
ERRS = []


def a13_lines(start, end):
    with open(A13_FILE) as f:
        lines = f.readlines()
    return "".join(lines[start - 1 : end])


def patch(rel, replacements, label):
    full = os.path.join(A16_ROOT, rel)
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


ABI_RESPONSE = a13_lines(74, 93)

IMPORTS = """
import android.content.pm.PackageParser;
import android.os.FileUtils;
import android.os.SystemProperties;
import android.util.Features;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import com.bluestacks.os.IBstFilterAppsService;
import static com.bluestacks.os.BstFilterAppsManager.ABI_ERROR;
import static com.bluestacks.os.BstFilterAppsManager.ARM_MODE;
import static com.bluestacks.os.BstFilterAppsManager.X86_MODE;
import static com.bluestacks.os.BstFilterAppsManager.ARM_32_MODE;
import static com.bluestacks.os.BstFilterAppsManager.X86_32_MODE;
import static com.bluestacks.os.BstFilterAppsManager.ARM_64_MODE;
import static com.bluestacks.os.BstFilterAppsManager.X86_64_MODE;
import static com.bluestacks.os.BstFilterAppsManager.XARM_MODE;
"""

BST_FIELDS = """
    // A16DBG:P2:FW-CORE-APP-14 BST native lib ABI override (a13)
    private static final boolean BST_DEBUG =
            SystemProperties.getInt("bst.debug.nativelibhelper", 0) > 0;
    private static boolean is32BitArch = Build.SUPPORTED_64_BIT_ABIS.length == 0;
    private static final String cpuAbiX86_64 = "x86_64";
    private static final String cpuAbiX86 = "x86";
    private static final String cpuAbiArmv8_64 = "arm64-v8a";
    private static final String cpuAbiArmv7 = "armeabi-v7a";
    private static final String cpuAbiArm = "armeabi";

    static IBstFilterAppsService bstfilter;
"""

FIND_ABI_WRAPPER = a13_lines(259, 297)

SUM_ABI_METHOD = a13_lines(401, 424)

COPY_ABI_WRAPPER = a13_lines(426, 470)

BST_HELPERS = a13_lines(471, 555)

TAIL_HELPERS = a13_lines(799, 1168)

patch(
    TARGET,
    [
        (
            "import java.util.List;\n",
            "import java.util.List;\n" + IMPORTS,
        ),
        (
            "/**\n * Native libraries helper.\n *\n * @hide\n */\npublic class NativeLibraryHelper {",
            ABI_RESPONSE
            + "\n/**\n * Native libraries helper.\n *\n * @hide\n */\npublic class NativeLibraryHelper {",
        ),
        (
            '    public static final String CLEAR_ABI_OVERRIDE = "-";\n',
            '    public static final String CLEAR_ABI_OVERRIDE = "-";\n' + BST_FIELDS,
        ),
        (
            "        final boolean pageSizeCompatDisabled;\n\n        public static Handle create(File packageFile)",
            "        final boolean pageSizeCompatDisabled;\n        final String pkgName;\n        final String apkDir;\n\n        public static Handle create(File packageFile)",
        ),
        (
            """            return create(lite.getAllApkPaths(), lite.isMultiArch(), lite.isExtractNativeLibs(),
                    lite.isDebuggable(), isPageSizeCompatDisabled);
        }

        public static Handle create(List<String> codePaths, boolean multiArch,
                boolean extractNativeLibs, boolean debuggable, boolean isPageSizeCompatDisabled)
                throws IOException {
""",
            """            return create(lite.getAllApkPaths(), lite.isMultiArch(), lite.isExtractNativeLibs(),
                    lite.isDebuggable(), isPageSizeCompatDisabled, lite.getPackageName(), lite.getPath());
        }

        public static Handle create(List<String> codePaths, boolean multiArch,
                boolean extractNativeLibs, boolean debuggable, boolean isPageSizeCompatDisabled,
                String pkgName, String apkDir)
                throws IOException {
""",
        ),
        (
            """            return new Handle(apkPaths, apkHandles, multiArch, extractNativeLibs, debuggable,
                    isPageSizeCompatDisabled);
        }

        public static Handle createFd(PackageLite lite, FileDescriptor fd) throws IOException {
""",
            """            if (pkgName == null && apkDir == null && !codePaths.isEmpty()) {
                apkDir = codePaths.get(0);
                if (apkDir != null && apkDir.endsWith(".apk")) {
                    apkDir = new File(apkDir).getParent();
                }
            }
            return new Handle(apkPaths, apkHandles, multiArch, extractNativeLibs, debuggable,
                    isPageSizeCompatDisabled, pkgName, apkDir);
        }

        public static Handle create(List<String> codePaths, boolean multiArch,
                boolean extractNativeLibs, boolean debuggable, boolean isPageSizeCompatDisabled)
                throws IOException {
            return create(codePaths, multiArch, extractNativeLibs, debuggable,
                    isPageSizeCompatDisabled, null, null);
        }

        public static Handle createFd(PackageLite lite, FileDescriptor fd) throws IOException {
""",
        ),
        (
            """            return new Handle(new String[]{path}, apkHandles, lite.isMultiArch(),
                    lite.isExtractNativeLibs(), lite.isDebuggable(), isPageSizeCompatDisabled);
        }

        Handle(String[] apkPaths, long[] apkHandles, boolean multiArch,
                boolean extractNativeLibs, boolean debuggable, boolean isPageSizeCompatDisabled) {
            this.apkPaths = apkPaths;
            this.apkHandles = apkHandles;
            this.multiArch = multiArch;
            this.extractNativeLibs = extractNativeLibs;
            this.debuggable = debuggable;
            this.pageSizeCompatDisabled = isPageSizeCompatDisabled;
            mGuard.open("close");
        }
""",
            """            return new Handle(new String[]{path}, apkHandles, lite.isMultiArch(),
                    lite.isExtractNativeLibs(), lite.isDebuggable(), isPageSizeCompatDisabled,
                    lite.getPackageName(), lite.getPath());
        }

        Handle(String[] apkPaths, long[] apkHandles, boolean multiArch,
                boolean extractNativeLibs, boolean debuggable, boolean isPageSizeCompatDisabled,
                String pkgName, String apkDir) {
            this.apkPaths = apkPaths;
            this.apkHandles = apkHandles;
            this.multiArch = multiArch;
            this.extractNativeLibs = extractNativeLibs;
            this.debuggable = debuggable;
            this.pageSizeCompatDisabled = isPageSizeCompatDisabled;
            this.pkgName = pkgName;
            this.apkDir = apkDir;
            mGuard.open("close");
        }
""",
        ),
        (
            """    /**
     * Checks if a given APK contains native code for any of the provided
     * {@code supportedAbis}. Returns an index into {@code supportedAbis} if a matching
     * ABI is found, {@link PackageManager#NO_NATIVE_LIBRARIES} if the
     * APK doesn't contain any native code, and
     * {@link PackageManager#INSTALL_FAILED_NO_MATCHING_ABIS} if none of the ABIs match.
     */
    public static int findSupportedAbi(Handle handle, String[] supportedAbis) {
""",
            FIND_ABI_WRAPPER
            + """
    /**
     * Checks if a given APK contains native code for any of the provided
     * {@code supportedAbis}. Returns an index into {@code supportedAbis} if a matching
     * ABI is found, {@link PackageManager#NO_NATIVE_LIBRARIES} if the
     * APK doesn't contain any native code, and
     * {@link PackageManager#INSTALL_FAILED_NO_MATCHING_ABIS} if none of the ABIs match.
     */
    public static int findSupportedAbi(Handle handle, String[] supportedAbis) {
""",
        ),
        (
            """    private static long sumNativeBinariesForSupportedAbi(Handle handle, String[] abiList) {
        int abi = findSupportedAbi(handle, abiList);
        if (abi >= 0) {
            return sumNativeBinaries(handle, abiList[abi]);
        } else {
            return 0;
        }
    }

    public static int copyNativeBinariesForSupportedAbi(Handle handle, File libraryRoot,
            String[] abiList, boolean useIsaSubdir, boolean isIncremental) throws IOException {
""",
            SUM_ABI_METHOD
            + COPY_ABI_WRAPPER
            + """
    public static int copyNativeBinariesForSupportedAbi(Handle handle, File libraryRoot,
            String[] abiList, boolean useIsaSubdir, boolean isIncremental) throws IOException {
""",
        ),
        (
            """                String[] abiList = (cpuAbiOverride != null) ?
                        new String[] { cpuAbiOverride } : Build.SUPPORTED_ABIS;
                if (Build.SUPPORTED_64_BIT_ABIS.length > 0 && cpuAbiOverride == null &&
                        hasRenderscriptBitcode(handle)) {
                    abiList = Build.SUPPORTED_32_BIT_ABIS;
                }

                int copyRet = copyNativeBinariesForSupportedAbi(handle, libraryRoot, abiList,
                        true /* use isa specific subdirs */, isIncremental);
""",
            """                String[] bstAbiList = getBstAbiOverride(handle.apkDir, handle.pkgName);

                String[] abiList = (cpuAbiOverride != null) ?
                        new String[] { cpuAbiOverride } : Build.SUPPORTED_ABIS;
                if (Build.SUPPORTED_64_BIT_ABIS.length > 0 && cpuAbiOverride == null &&
                        hasRenderscriptBitcode(handle)) {
                    abiList = Build.SUPPORTED_32_BIT_ABIS;
                }

                int copyRet = copyNativeBinariesForSupportedAbi(handle, libraryRoot, abiList,
                        bstAbiList, true /* use isa specific subdirs */, isIncremental);
""",
        ),
        (
            """            sum += sumNativeBinariesForSupportedAbi(handle, abiList);
        }
        return sum;
    }

    /**
     * Configure the native library files managed by Incremental Service. Makes sure Incremental
     * Service will create native library directories and set up native library binary files in the
     * same structure as they are in non-incremental installations.
     *
     * @param handle The Handle object that contains all apk paths.
""",
            """            sum += sumNativeBinariesForSupportedAbi(handle, abiList);
        }
        return sum;
    }

"""
            + BST_HELPERS
            + TAIL_HELPERS
            + """
    /**
     * Configure the native library files managed by Incremental Service. Makes sure Incremental
     * Service will create native library directories and set up native library binary files in the
     * same structure as they are in non-incremental installations.
     *
     * @param handle The Handle object that contains all apk paths.
""",
        ),
    ],
    "NativeLibraryHelper BST hooks",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")

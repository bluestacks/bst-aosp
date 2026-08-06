package com.bluestacks.a16nativeoracle;

import android.app.Activity;
import android.os.Bundle;
import android.os.Process;
import android.util.Log;

import dalvik.annotation.optimization.CriticalNative;
import dalvik.annotation.optimization.FastNative;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public final class OracleActivity extends Activity {
    private static final String TAG = "A16NATIVE";
    private static final int REGULAR_EXPECTED = 0x16a64001;
    private static final long FAST_INPUT = 0x1020304050607080L;
    private static final long FAST_EXPECTED = FAST_INPUT ^ 0x55aa55aa55aa55aaL;

    private static native int regularProbe();

    @FastNative
    private static native long fastProbe(long value);

    @CriticalNative
    private static native int criticalProbe(int left, int right);

    private static void pass(String name, String detail) {
        Log.i(TAG, "A16NATIVE:PASS:" + name + ":" + detail);
    }

    private static void fail(String name, Throwable error) {
        Log.e(TAG, "A16NATIVE:FAIL:" + name + ":" + error, error);
    }

    private static String readText(String path) throws IOException {
        StringBuilder value = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line;
            while ((line = reader.readLine()) != null) {
                value.append(line).append('\n');
            }
        }
        return value.toString();
    }

    private static void require(boolean condition, String message) {
        if (!condition) {
            throw new IllegalStateException(message);
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            System.loadLibrary("a16nativeoracle");
            pass("load", "arm64-v8a library loaded");

            int regular = regularProbe();
            require(regular == REGULAR_EXPECTED,
                    "regular result=" + Integer.toHexString(regular));
            pass("regular", "result=" + Integer.toHexString(regular));

            long fast = fastProbe(FAST_INPUT);
            require(fast == FAST_EXPECTED, "fast result=" + Long.toHexString(fast));
            pass("fast", "result=" + Long.toHexString(fast));

            int critical = criticalProbe(1600, 64);
            require(critical == 1664, "critical result=" + critical);
            pass("critical", "result=" + critical);

            String maps = readText("/proc/self/maps");
            require(maps.contains("liba16nativeoracle.so"),
                    "translated library absent from maps");
            require(maps.contains("libhoudini.so"), "Houdini absent from maps");
            pass("maps", "oracle=true,houdini=true");

            String cpuinfo = readText("/proc/cpuinfo");
            require(cpuinfo.contains("ARMv8 processor")
                            && cpuinfo.contains("CPU architecture: 8"),
                    "arm64 cpuinfo view missing");
            pass("cpuinfo", "armv8=true,architecture=8");

            pass("process", "uid=" + Process.myUid() + ",is64Bit=" + Process.is64Bit()
                    + ",os.arch=" + System.getProperty("os.arch"));
        } catch (Throwable error) {
            fail("execution", error);
        } finally {
            Log.i(TAG, "A16NATIVE:DONE:uid=" + Process.myUid());
        }
    }
}

#!/usr/bin/env python3
"""Minimal gfxstream soong stubs after gfxstream.disabled (init-only rebuild unblock)."""
import os

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
STUB = os.path.join(AOSP, "hardware/google/gfxstream_soong_stubs")
os.makedirs(os.path.join(STUB, "include/renderdoc"), exist_ok=True)
os.makedirs(os.path.join(STUB, "proto"), exist_ok=True)

open(os.path.join(STUB, "include/renderdoc/renderdoc_app.h"), "w").write(
    "#pragma once\n/* gfxstream stub */\n"
)
open(os.path.join(STUB, "stub.cpp"), "w").write("/* gfxstream backend stub */\n")
open(os.path.join(STUB, "proto/GraphicsDetector.proto"), "w").write(
    'syntax = "proto3";\npackage gfxstream.stub;\nmessage Stub {}\n'
)

open(os.path.join(STUB, "Android.bp"), "w").write(
    """// BlueStacks: gfxstream stubs (full tree disabled for goldfish-opengl).
package {
    default_applicable_licenses: ["Android-Apache-2.0"],
}

cc_library_headers {
    name: "libgfxstream_thirdparty_renderdoc_headers",
    export_include_dirs: ["include"],
    host_supported: true,
    vendor_available: true,
}

cc_library {
    name: "libgfxstream_backend",
    host_supported: true,
    vendor_available: true,
    apex_available: [
        "com.android.virt",
    ],
    srcs: ["stub.cpp"],
    cflags: ["-Wno-unused-parameter"],
}

cc_library_host_static {
    name: "libgfxstream_graphics_detector_proto",
    proto: {
        export_proto_headers: true,
        type: "full",
    },
    srcs: ["proto/GraphicsDetector.proto"],
}
"""
)
print("Updated gfxstream soong stubs")

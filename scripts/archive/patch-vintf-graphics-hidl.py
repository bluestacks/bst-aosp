#!/usr/bin/env python3
"""Add HIDL graphics HAL VINTF fragments (allocator@2.0, composer@2.1, mapper@2.1).

Henry/BlueStacks uses goldfish-opengl HIDL services, not upstream A16 composer3/AIDL ranchu.
Empty vendor manifest (R191 minimal) left no graphics HAL entries → passthrough services exit 1.
"""
import os
import sys

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
RELEASE = os.path.expanduser(os.environ.get("RELEASE", "~/releases/Baklava64"))
PROP = os.path.expanduser(
    os.environ.get(
        "BST_PROP",
        "~/app-player/scratch-gaurav/misc_x86_64/baklava/baklava.bluestacks.prop.us",
    )
)

ALLOCATOR_XML = """<!--
    BlueStacks: goldfish-opengl HIDL gralloc path (manifest.xml.bst-full.bak graphics section)
-->
<manifest version="9.0" type="device">
    <hal format="hidl">
        <name>android.hardware.graphics.allocator</name>
        <transport>hwbinder</transport>
        <fqname>@2.0::IAllocator/default</fqname>
    </hal>
</manifest>
"""

COMPOSER_XML = """<!--
    BlueStacks: goldfish-opengl hwc2 + composer@2.1-service
-->
<manifest version="9.0" type="device">
    <hal format="hidl">
        <name>android.hardware.graphics.composer</name>
        <transport>hwbinder</transport>
        <fqname>@2.1::IComposer/default</fqname>
    </hal>
</manifest>
"""

MAPPER_XML = """<!--
    BlueStacks: passthrough mapper for gralloc.bst / gralloc.default
-->
<manifest version="9.0" type="device">
    <hal format="hidl">
        <name>android.hardware.graphics.mapper</name>
        <transport arch="32+64">passthrough</transport>
        <fqname>@2.1::IMapper/default</fqname>
    </hal>
</manifest>
"""

FRAGMENTS = {
    "android.hardware.graphics.allocator@2.0.xml": ALLOCATOR_XML,
    "android.hardware.graphics.composer@2.1.xml": COMPOSER_XML,
    "android.hardware.graphics.mapper@2.1.xml": MAPPER_XML,
}


def write_fragments(base: str) -> None:
    manifest_dir = os.path.join(base, "vendor/etc/vintf/manifest")
    os.makedirs(manifest_dir, exist_ok=True)
    for name, body in FRAGMENTS.items():
        path = os.path.join(manifest_dir, name)
        if os.path.isfile(path):
            open(path + ".bak", "w").write(open(path).read())
        open(path, "w").write(body)
        print(f"wrote {path}")


def patch_build_prop(prop_path: str) -> None:
    if not os.path.isfile(prop_path):
        print(f"skip build.prop: missing {prop_path}")
        return
    text = open(prop_path).read()
    needle = "ro.hardware.gralloc=bst"
    if needle in text:
        print(f"{prop_path}: ro.hardware.gralloc=bst already present")
        return
    if "ro.hardware.egl=emulation" in text:
        text = text.replace(
            "ro.hardware.egl=emulation",
            "ro.hardware.egl=emulation\nro.hardware.gralloc=bst",
            1,
        )
    else:
        text = text.rstrip() + "\nro.hardware.gralloc=bst\n"
    open(prop_path + ".bak", "w").write(open(prop_path).read())
    open(prop_path, "w").write(text)
    print(f"{prop_path}: added ro.hardware.gralloc=bst")


def main() -> int:
    release_system = os.path.join(RELEASE, "system")
    if os.path.isdir(release_system):
        write_fragments(release_system)
    else:
        print(f"warning: release system dir missing: {release_system}", file=sys.stderr)

    manifest_dir = os.path.join(AOSP, "device/generic/common/manifest")
    if os.path.isdir(os.path.join(AOSP, "device/generic/common")):
        os.makedirs(manifest_dir, exist_ok=True)
        for name, body in FRAGMENTS.items():
            path = os.path.join(manifest_dir, name)
            open(path, "w").write(body)
            print(f"aosp fragment {path}")

    patch_build_prop(PROP)
    if os.path.isfile(os.path.join(release_system, "build.prop")):
        patch_build_prop(os.path.join(release_system, "build.prop"))

    device_mk = os.path.join(AOSP, "device/generic/goldfish/product/generic.mk")
    if os.path.isfile(device_mk):
        mk = open(device_mk).read()
        insert_line = "DEVICE_MANIFEST_FILE += device/generic/common/manifest/android.hardware.graphics.allocator@2.0.xml"
        if insert_line not in mk:
            anchor = "DEVICE_MANIFEST_FILE += device/generic/goldfish/hals/audio/android.hardware.audio.effects@7.0.xml"
            if anchor in mk:
                mk = mk.replace(
                    anchor,
                    anchor
                    + "\nDEVICE_MANIFEST_FILE += device/generic/common/manifest/android.hardware.graphics.allocator@2.0.xml"
                    + "\nDEVICE_MANIFEST_FILE += device/generic/common/manifest/android.hardware.graphics.composer@2.1.xml"
                    + "\nDEVICE_MANIFEST_FILE += device/generic/common/manifest/android.hardware.graphics.mapper@2.1.xml",
                    1,
                )
                open(device_mk + ".bak", "w").write(open(device_mk).read())
                open(device_mk, "w").write(mk)
                print("generic.mk: added DEVICE_MANIFEST_FILE graphics fragments")
            else:
                print("generic.mk: audio manifest anchor not found", file=sys.stderr)
    print("VINTF_GRAPHICS_DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

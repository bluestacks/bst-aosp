# Binary Retention Assessment

> SHA-256 is an identity check, not storage. Local-only binaries are not
> authoritative project assets until they have a retrieval URI or a complete
> source/toolchain reconstruction recipe.

Local-only identities come from the committed observation manifest
[`binary-local-evidence.json`](binary-local-evidence.json); they are not
counted as repository files.

The deterministic pack/verify/restore workflow is defined in
[`binary-artifacts.md`](../development-workflow/binary-artifacts.md) and
implemented by [`manage_binary_artifacts.py`](../../scripts/manage_binary_artifacts.py).

## Decision Summary

- `drop-duplicate-layout`: **10** files, **7.69 MiB**
- `drop-generated-intermediate`: **7** files, **9.36 MiB**
- `external-artifact-required`: **16** files, **28.88 MiB**
- `keep-in-git`: **8** files, **8.61 MiB**
- `security-tombstone`: **1** files, **0.00 MiB**

## Required External Bundles

| Bundle | Required content | Current status |
|---|---|---|
| `henry-boot-baseline` | Boot kernel and boot initrd | Local bundle supported; artifact URI missing |
| `henry-fastboot-baseline` | Fastboot kernel, canonical initrd, and final fastboot image | Local bundle supported; artifact URI missing |
| `henry-initrd-runtime` | bstconf, bstchkdata, and nine kernel modules | Local bundle supported; artifact URI missing |

The 16 files in these bundles must be uploaded to an approved artifact
store or made reproducible from pinned source, kernel ABI, and toolchain
identities. Until then they are recovery blockers, not completed evidence.

## Per-File Decision

| Decision | Status | Path | Bytes | Canonical/bundle | Reason |
|---|---|---|---:|---|---|
| `drop-duplicate-layout` | `complete` | `.codex-tmp/videobuf-core.ko` | 43752 | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/videobuf-core.ko` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `keep-in-git` | `complete` | [`patches/android-16/a13-completion/root-ffmpeg-media-pipeline.patch.gz`](../../patches/android-16/a13-completion/root-ffmpeg-media-pipeline.patch.gz) | 3775872 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |
| `keep-in-git` | `complete` | [`patches/android-16/patches/p2-framework-rest/batchA-newfiles.tgz`](../../patches/android-16/patches/p2-framework-rest/batchA-newfiles.tgz) | 23439 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |
| `security-tombstone` | `complete` | `patches/android-16/untracked-src/aosp16__device_generic_common/apksigner/bluestacks-market.keystore` |  | `-` | Credential bytes must stay out of Git; retain identity and rotation record. |
| `keep-in-git` | `complete` | [`patches/android-16/untracked-src/g1_hal_fixes.tar.gz`](../../patches/android-16/untracked-src/g1_hal_fixes.tar.gz) | 7126 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/Boot/boot/bzImage` | 8328288 | `henry-boot-baseline` | Canonical boot input or final image is not available from Git and cannot be reconstructed from this repository alone. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/Boot/boot/initrd.img` | 1361200 | `henry-boot-baseline` | Canonical boot input or final image is not available from Git and cannot be reconstructed from this repository alone. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/bstchkdata` | 51760 | `henry-initrd-runtime` | Canonical boot input or final image is not available from Git and cannot be reconstructed from this repository alone. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/bstconf` | 68864 | `henry-initrd-runtime` | Canonical boot input or final image is not available from Git and cannot be reconstructed from this repository alone. |
| `keep-in-git` | `complete` | [`references/henry-hd-guest/BootImage/bstreport_32`](../../references/henry-hd-guest/BootImage/bstreport_32) | 342776 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |
| `keep-in-git` | `complete` | [`references/henry-hd-guest/BootImage/bstreport_64`](../../references/henry-hd-guest/BootImage/bstreport_64) | 368832 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |
| `keep-in-git` | `complete` | [`references/henry-hd-guest/BootImage/busybox-hvf`](../../references/henry-hd-guest/BootImage/busybox-hvf) | 2004888 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |
| `keep-in-git` | `complete` | [`references/henry-hd-guest/BootImage/busybox-ndk`](../../references/henry-hd-guest/BootImage/busybox-ndk) | 1215470 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |
| `drop-generated-intermediate` | `complete` | `references/henry-hd-guest/BootImage/fastboot/boot_bzImage.o` | 3268 | `-` | Object, padding, bootblock, or zero-fill output is derivable from source and the final image; record the toolchain instead of the bytes. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/fastboot/bzImage` | 8405840 | `henry-fastboot-baseline` | Canonical boot input or final image is not available from Git and cannot be reconstructed from this repository alone. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/fastboot/fastboot.img` | 9793711 | `henry-fastboot-baseline` | Canonical boot input or final image is not available from Git and cannot be reconstructed from this repository alone. |
| `drop-generated-intermediate` | `complete` | `references/henry-hd-guest/BootImage/fastboot/fastboot.img.padded` | 9794560 | `-` | Object, padding, bootblock, or zero-fill output is derivable from source and the final image; record the toolchain instead of the bytes. |
| `drop-generated-intermediate` | `complete` | `references/henry-hd-guest/BootImage/fastboot/fastboot_asm.o` | 1704 | `-` | Object, padding, bootblock, or zero-fill output is derivable from source and the final image; record the toolchain instead of the bytes. |
| `drop-generated-intermediate` | `complete` | `references/henry-hd-guest/BootImage/fastboot/fastboot_main.o` | 5612 | `-` | Object, padding, bootblock, or zero-fill output is derivable from source and the final image; record the toolchain instead of the bytes. |
| `drop-generated-intermediate` | `complete` | `references/henry-hd-guest/BootImage/fastboot/fastbootblock` | 512 | `-` | Object, padding, bootblock, or zero-fill output is derivable from source and the final image; record the toolchain instead of the bytes. |
| `drop-generated-intermediate` | `complete` | `references/henry-hd-guest/BootImage/fastboot/fastbootblock.o` | 6380 | `-` | Object, padding, bootblock, or zero-fill output is derivable from source and the final image; record the toolchain instead of the bytes. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/fastboot/initrd.img` | 1387183 | `references/henry-hd-guest/BootImage/initrd.img` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-generated-intermediate` | `complete` | `references/henry-hd-guest/BootImage/fastboot/zero.file` | 849 | `-` | Object, padding, bootblock, or zero-fill output is derivable from source and the final image; record the toolchain instead of the bytes. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd.img` | 1387183 | `henry-fastboot-baseline` | Canonical boot input or final image is not available from Git and cannot be reconstructed from this repository alone. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/bstchkdata` | 51760 | `references/henry-hd-guest/BootImage/bstchkdata` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/bstconf` | 68864 | `references/henry-hd-guest/BootImage/bstconf` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/bstreport` | 368832 | `references/henry-hd-guest/BootImage/bstreport_64` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/busybox` | 1215470 | `references/henry-hd-guest/BootImage/busybox-ndk` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/echo` | 1215470 | `references/henry-hd-guest/BootImage/busybox-ndk` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/insmod` | 1215470 | `references/henry-hd-guest/BootImage/busybox-ndk` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/recovery` | 1285004 | `references/henry-hd-guest/BootImage/recovery` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `drop-duplicate-layout` | `complete` | `references/henry-hd-guest/BootImage/initrd/boot/bin/sh` | 1215470 | `references/henry-hd-guest/BootImage/busybox-ndk` | Bytes duplicate the canonical input; preserve only the layout/copy relation in the initrd assembly manifest. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/bstaudio.ko` | 29104 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/bstcamera.ko` | 31632 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/bstinput.ko` | 30464 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/bstpgaipc.ko` | 22096 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/bstvmsg.ko` | 22560 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/hvmem.ko` | 12664 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/vboxguest.ko` | 582504 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/vboxsf.ko` | 115416 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `external-artifact-required` | `blocked-no-artifact-uri` | `references/henry-hd-guest/BootImage/initrd/boot/bstmods/videobuf-core.ko` | 43752 | `henry-initrd-runtime` | Kernel module bytes are required for exact historical initrd replay; source, kernel ABI, and toolchain are outside this repository. |
| `keep-in-git` | `complete` | [`references/henry-hd-guest/BootImage/recovery`](../../references/henry-hd-guest/BootImage/recovery) | 1285004 | `-` | Repository clones can retrieve and verify this canonical historical payload. Opaque executables still require provenance and license review. |

## Deletion Rule

Only `drop-cache`, `drop-generated-intermediate`, and
`drop-duplicate-layout` entries are deletion candidates. Delete them only
after canonical paths and initrd layout relations are committed. The
security tombstone remains in metadata, never as credential bytes.

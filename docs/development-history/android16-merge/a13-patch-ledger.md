# A13 Patch Ledger

This ledger contains one entry for every non-merge and merge commit found on the
A13 `bst-v5.22.210` component branches relative to their selected A13 baselines.
Automated dispositions are triage evidence, not final port or validation claims.
`reviewed-ported` requires a same-project commit or explicit cross-project mapping;
`reviewed-equivalent` requires structured target-state evidence where Android 16
already has the final behavior without a promotion commit. `reviewed-not-ported`
records an intentional, fully assessed exclusion rather than an unmapped omission.

## Counts

- Entries: 1342
- Patch commits: 796
- Merge commits: 512
- Unresolved baseline boundaries: 34
- Explicit A13-to-A16 commit candidates: 98
- Explicit cross-project target mappings: 6
- Source-head/root-gitlink mismatches: 166

| Automated disposition | Entries |
| --- | ---: |
| `baseline-unresolved` | 34 |
| `integration-merge` | 512 |
| `metadata-review` | 84 |
| `no-surviving-final-delta` | 1 |
| `semantic-review-required` | 419 |
| `superseded-in-a13` | 14 |
| `textually-complete` | 278 |

| Review status | Entries |
| --- | ---: |
| `reviewed-equivalent` | 10 |
| `reviewed-integration` | 548 |
| `reviewed-not-ported` | 260 |
| `reviewed-ported` | 524 |

## Semantic Review Queue

| Project | Pending entries |
| --- | ---: |
| `frameworks/base` | 133 |
| `device/generic/common` | 20 |
| `system/core` | 18 |
| `frameworks/av` | 15 |
| `art` | 14 |
| `build/make` | 12 |
| `frameworks/native` | 9 |
| `bionic` | 8 |
| `external/deqp` | 7 |
| `packages/modules/Connectivity` | 6 |
| `packages/apps/Launcher3` | 4 |
| `packages/apps/Settings` | 4 |
| `build/soong` | 3 |
| `external/swiftshader` | 3 |
| `libcore` | 3 |
| `system/extras` | 3 |
| `external/icu` | 2 |
| `external/selinux` | 2 |
| `hardware/bst/audio` | 2 |
| `hardware/bst/camera` | 2 |
| `kernel` | 2 |
| `packages/modules/NetworkStack` | 2 |
| `packages/modules/Wifi` | 2 |
| `packages/modules/adb` | 2 |
| `tools/tradefederation/prebuilts` | 2 |
| `bootable/newinstaller` | 1 |
| `build` | 1 |
| `cts` | 1 |
| `device/generic/x86_64` | 1 |
| `device/google/cuttlefish` | 1 |
| `external/ImageMagick` | 1 |
| `external/OpenCL-CTS` | 1 |
| `external/alsa-lib` | 1 |
| `external/alsa-ucm-conf` | 1 |
| `external/alsa-utils` | 1 |
| `external/auto` | 1 |
| `external/bcc` | 1 |
| `external/boringssl` | 1 |
| `external/bpftool` | 1 |
| `external/brotli` | 1 |
| `external/capstone` | 1 |
| `external/chromium-webview` | 1 |
| `external/cpu_features` | 1 |
| `external/dagger2` | 1 |
| `external/deqp-deps/SPIRV-Headers` | 1 |
| `external/deqp-deps/SPIRV-Tools` | 1 |
| `external/deqp-deps/glslang` | 1 |
| `external/efibootmgr` | 1 |
| `external/efivar` | 1 |
| `external/flac` | 1 |
| `external/fmtlib` | 1 |
| `external/fonttools` | 1 |
| `external/fsverity-utils` | 1 |
| `external/go-cmp` | 1 |
| `external/golang-protobuf` | 1 |
| `external/google-benchmark` | 1 |
| `external/google-java-format` | 1 |
| `external/guava` | 1 |
| `external/harfbuzz_ng` | 1 |
| `external/jazzer-api` | 1 |
| `external/ktfmt` | 1 |
| `external/libbpf` | 1 |
| `external/libxkbcommon` | 1 |
| `external/libxml2` | 1 |
| `external/minijail` | 1 |
| `external/nanopb-c` | 1 |
| `external/nullaway` | 1 |
| `external/oboe` | 1 |
| `external/okio` | 1 |
| `external/oss-fuzz` | 1 |
| `external/python/asn1crypto` | 1 |
| `external/python/bumble` | 1 |
| `external/python/cachetools` | 1 |
| `external/python/cpython3` | 1 |
| `external/python/google-api-python-client` | 1 |
| `external/python/jinja` | 1 |
| `external/python/markupsafe` | 1 |
| `external/python/mobly` | 1 |
| `external/python/portpicker` | 1 |
| `external/python/pybind11` | 1 |
| `external/python/pyfakefs` | 1 |
| `external/python/pyopenssl` | 1 |
| `external/python/pyyaml` | 1 |
| `external/python/typing` | 1 |
| `external/robolectric` | 1 |
| `external/rust/crates/ahash` | 1 |
| `external/rust/crates/aho-corasick` | 1 |
| `external/rust/crates/android_logger` | 1 |
| `external/rust/crates/anyhow` | 1 |
| `external/rust/crates/arbitrary` | 1 |
| `external/rust/crates/async-trait` | 1 |
| `external/rust/crates/bitflags` | 1 |
| `external/rust/crates/byteorder` | 1 |
| `external/rust/crates/bytes` | 1 |
| `external/rust/crates/cast` | 1 |
| `external/rust/crates/cfg-if` | 1 |
| `external/rust/crates/chrono` | 1 |
| `external/rust/crates/clang-sys` | 1 |
| `external/rust/crates/combine` | 1 |
| `external/rust/crates/command-fds` | 1 |
| `external/rust/crates/coset` | 1 |
| `external/rust/crates/criterion` | 1 |
| `external/rust/crates/downcast-rs` | 1 |
| `external/rust/crates/enumn` | 1 |
| `external/rust/crates/flate2` | 1 |
| `external/rust/crates/gdbstub` | 1 |
| `external/rust/crates/grpcio` | 1 |
| `external/rust/crates/intrusive-collections` | 1 |
| `external/rust/crates/itertools` | 1 |
| `external/rust/crates/itoa` | 1 |
| `external/rust/crates/libfuzzer-sys` | 1 |
| `external/rust/crates/libloading` | 1 |
| `external/rust/crates/libm` | 1 |
| `external/rust/crates/libz-sys` | 1 |
| `external/rust/crates/log` | 1 |
| `external/rust/crates/memoffset` | 1 |
| `external/rust/crates/minimal-lexical` | 1 |
| `external/rust/crates/no-panic` | 1 |
| `external/rust/crates/num_cpus` | 1 |
| `external/rust/crates/once_cell` | 1 |
| `external/rust/crates/parking_lot` | 1 |
| `external/rust/crates/paste` | 1 |
| `external/rust/crates/plotters` | 1 |
| `external/rust/crates/proc-macro-hack` | 1 |
| `external/rust/crates/proc-macro2` | 1 |
| `external/rust/crates/quickcheck` | 1 |
| `external/rust/crates/quote` | 1 |
| `external/rust/crates/regex-automata` | 1 |
| `external/rust/crates/remain` | 1 |
| `external/rust/crates/rustc-demangle` | 1 |
| `external/rust/crates/rusticata-macros` | 1 |
| `external/rust/crates/rustversion` | 1 |
| `external/rust/crates/ryu` | 1 |
| `external/rust/crates/semver` | 1 |
| `external/rust/crates/serde-xml-rs` | 1 |
| `external/rust/crates/serde_json` | 1 |
| `external/rust/crates/shared_child` | 1 |
| `external/rust/crates/shlex` | 1 |
| `external/rust/crates/smallvec` | 1 |
| `external/rust/crates/spin` | 1 |
| `external/rust/crates/termcolor` | 1 |
| `external/rust/crates/thiserror` | 1 |
| `external/rust/crates/tinytemplate` | 1 |
| `external/rust/crates/tinyvec` | 1 |
| `external/rust/crates/unicode-bidi` | 1 |
| `external/rust/crates/unicode-normalization` | 1 |
| `external/rust/crates/unicode-segmentation` | 1 |
| `external/rust/crates/vsock` | 1 |
| `external/rust/crates/walkdir` | 1 |
| `external/rust/crates/weak-table` | 1 |
| `external/rust/crates/which` | 1 |
| `external/rust/crates/xml-rs` | 1 |
| `external/rust/crates/zip` | 1 |
| `external/rust/cxx` | 1 |
| `external/skia` | 1 |
| `external/subsampling-scale-image-view` | 1 |
| `external/syslinux` | 1 |
| `external/tensorflow` | 1 |
| `external/tinyxml2` | 1 |
| `external/toybox` | 1 |
| `external/turbine` | 1 |
| `external/v86d` | 1 |
| `external/volley` | 1 |
| `external/zstd` | 1 |
| `frameworks/opt/telephony` | 1 |
| `hardware/bst/lights` | 1 |
| `hardware/interfaces` | 1 |
| `hardware/libhardware` | 1 |
| `packages/inputmethods/LatinIME` | 1 |
| `packages/modules/Bluetooth` | 1 |
| `packages/modules/BootPrebuilt/5.10/arm64` | 1 |
| `packages/modules/BootPrebuilt/5.4/arm64` | 1 |
| `packages/providers/DownloadProvider` | 1 |
| `packages/services/Telephony` | 1 |
| `prebuilts/abi-dumps/ndk` | 1 |
| `prebuilts/abi-dumps/platform` | 1 |
| `prebuilts/abi-dumps/vndk` | 1 |
| `prebuilts/android-emulator` | 1 |
| `prebuilts/bazel/darwin-x86_64` | 1 |
| `prebuilts/bazel/linux-x86_64` | 1 |
| `prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8` | 1 |
| `prebuilts/gcc/linux-x86/host/x86_64-w64-mingw32-4.8` | 1 |
| `prebuilts/go/darwin-x86` | 1 |
| `prebuilts/go/linux-x86` | 1 |
| `prebuilts/gradle-plugin` | 1 |
| `prebuilts/jdk/jdk8` | 1 |
| `prebuilts/maven_repo/android` | 1 |
| `prebuilts/maven_repo/bumptech` | 1 |
| `prebuilts/module_sdk/IPsec` | 1 |
| `prebuilts/module_sdk/Permission` | 1 |
| `prebuilts/module_sdk/art` | 1 |
| `prebuilts/vndk/v28` | 1 |
| `prebuilts/vndk/v29` | 1 |
| `prebuilts/vndk/v30` | 1 |
| `prebuilts/vndk/v31` | 1 |
| `prebuilts/vndk/v32` | 1 |
| `system/vold` | 1 |
| `tools/dexter` | 1 |

The machine-readable per-commit identity, file list, evidence classes, target
commit mapping and validation fields are in `a13-patch-ledger.json`.

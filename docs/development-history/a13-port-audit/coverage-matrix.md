# A13 Port Coverage Matrix

> Generated evidence. Classification is a triage signal, not a port decision.

## Scope

- A13 projects: **1056**
- Projects with a final custom delta: **177**
- Files in those deltas: **1623**
- Baseline-boundary projects: **38**
- Root non-gitlink files: **1485**

Legend: `E` exact, `H` high line coverage, `P` partial, `L` low, `M` file missing,
`PM` project missing, `D` deletion/metadata review, `AD` deleted in final A13.

## Projects Requiring Semantic Review

| Project | Commits | Files | AOSP16 | Android-16 |
|---|---:|---:|---|---|
| `art` | 14 | 5 | H:1 L:3 M:1 | L:4 M:1 |
| `bionic` | 13 | 16 | E:2 H:4 L:5 M:5 | E:2 H:4 L:5 M:5 |
| `device/generic/common` | 44 | 182 | E:57 H:9 P:1 L:1 M:85 AD:29 | E:55 H:10 P:1 L:1 M:86 AD:29 |
| `device/generic/x86_64` | 1 | 5 | E:2 L:1 M:2 | H:2 L:1 M:2 |
| `external/boringssl` | 2 | 2 | M:1 D:1 | M:1 D:1 |
| `external/deqp` | 7 | 109 | M:109 | M:109 |
| `external/libxml2` | 1 | 2 | L:1 M:1 | L:1 M:1 |
| `external/skia` | 1 | 1 | M:1 | M:1 |
| `external/swiftshader` | 4 | 55 | E:30 H:10 P:6 L:5 M:3 AD:1 | E:30 H:10 P:6 L:6 M:2 AD:1 |
| `frameworks/av` | 12 | 50 | P:5 L:14 M:29 D:2 | P:5 L:14 M:29 D:2 |
| `frameworks/base` | 224 | 186 | E:21 H:32 P:40 L:70 M:16 D:7 | E:21 H:32 P:40 L:70 M:16 D:7 |
| `frameworks/native` | 54 | 28 | E:4 H:11 P:1 L:9 M:3 | E:4 H:11 P:1 L:9 M:3 |
| `frameworks/opt/telephony` | 1 | 4 | P:2 L:1 M:1 | P:2 L:1 M:1 |
| `hardware/interfaces` | 2 | 4 | L:3 D:1 | L:3 D:1 |
| `hardware/libhardware` | 2 | 2 | L:1 M:1 | L:1 M:1 |
| `libcore` | 7 | 4 | L:4 | L:4 |
| `packages/apps/Launcher3` | 4 | 6 | P:1 L:3 M:2 | P:1 L:3 M:2 |
| `packages/apps/Settings` | 7 | 14 | P:7 L:5 M:2 | P:7 L:5 M:2 |
| `packages/inputmethods/LatinIME` | 1 | 6 | L:6 | L:6 |
| `packages/modules/Bluetooth` | 1 | 1 | L:1 | L:1 |
| `packages/modules/Connectivity` | 7 | 5 | P:1 L:3 M:1 | P:1 L:3 M:1 |
| `packages/modules/NetworkStack` | 2 | 1 | L:1 | L:1 |
| `packages/modules/Wifi` | 2 | 1 | L:1 | L:1 |
| `packages/modules/adb` | 2 | 4 | H:1 P:1 L:1 D:1 | H:1 P:1 L:1 D:1 |
| `packages/providers/DownloadProvider` | 1 | 4 | P:1 L:3 | P:1 L:3 |
| `packages/services/Telephony` | 1 | 1 | L:1 | L:1 |
| `prebuilts/build-tools` | 6 | 129 | M:26 D:103 | M:26 D:103 |
| `prebuilts/clang-tools` | 1 | 4 | M:3 D:1 | L:1 M:2 D:1 |
| `prebuilts/clang/host/linux-x86` | 1 | 30 | E:5 M:25 | E:5 L:1 M:24 |
| `prebuilts/jdk/jdk11` | 1 | 17 | PM:17 | PM:17 |
| `prebuilts/jdk/jdk17` | 1 | 22 | PM:22 | PM:22 |
| `prebuilts/jdk/jdk9` | 1 | 11 | PM:11 | PM:11 |
| `prebuilts/misc` | 1 | 46 | E:27 M:17 D:2 | E:27 L:1 M:16 D:2 |
| `prebuilts/qemu-kernel` | 1 | 20 | M:20 | M:20 |
| `prebuilts/remoteexecution-client` | 1 | 96 | E:5 M:91 | E:5 L:1 M:90 |
| `prebuilts/runtime` | 1 | 14 | E:1 M:8 D:5 | E:1 M:8 D:5 |
| `prebuilts/rust` | 56 | 137 | M:137 | L:1 M:136 |
| `system/core` | 26 | 21 | H:4 P:6 L:8 M:3 | H:4 P:6 L:8 M:3 |
| `system/extras` | 6 | 17 | E:4 M:12 AD:1 | E:4 M:12 AD:1 |
| `system/vold` | 2 | 2 | L:1 D:1 | L:1 D:1 |
| `tools/dexter` | 1 | 17 | E:16 M:1 | E:16 L:1 |
| `tools/tradefederation/prebuilts` | 2 | 3 | M:1 D:2 | M:1 D:2 |

## Covered Custom Projects

These projects have a final custom delta but no file classified weak in both targets.

| Project | Commits | Files | AOSP16 | Android-16 |
|---|---:|---:|---|---|
| `device/google/cuttlefish` | 1 | 36 | AD:36 | AD:36 |
| `external/ImageMagick` | 1 | 4 | AD:4 | AD:4 |
| `external/OpenCL-CTS` | 1 | 1 | AD:1 | AD:1 |
| `external/angle` | 1 | 29 | AD:29 | AD:29 |
| `external/auto` | 1 | 1 | AD:1 | AD:1 |
| `external/bcc` | 1 | 2 | AD:2 | AD:2 |
| `external/bpftool` | 1 | 1 | AD:1 | AD:1 |
| `external/brotli` | 1 | 1 | AD:1 | AD:1 |
| `external/capstone` | 1 | 3 | AD:3 | AD:3 |
| `external/cpu_features` | 1 | 2 | AD:2 | AD:2 |
| `external/crosvm` | 1 | 1 | AD:1 | AD:1 |
| `external/dagger2` | 1 | 1 | AD:1 | AD:1 |
| `external/deqp-deps/SPIRV-Headers` | 1 | 1 | AD:1 | AD:1 |
| `external/deqp-deps/SPIRV-Tools` | 1 | 1 | AD:1 | AD:1 |
| `external/deqp-deps/glslang` | 1 | 3 | AD:3 | AD:3 |
| `external/flac` | 1 | 1 | AD:1 | AD:1 |
| `external/fmtlib` | 1 | 1 | AD:1 | AD:1 |
| `external/fonttools` | 1 | 2 | AD:2 | AD:2 |
| `external/freetype` | 1 | 2 | AD:2 | AD:2 |
| `external/fsverity-utils` | 1 | 1 | AD:1 | AD:1 |
| `external/go-cmp` | 1 | 1 | AD:1 | AD:1 |
| `external/golang-protobuf` | 1 | 1 | AD:1 | AD:1 |
| `external/google-benchmark` | 1 | 4 | AD:4 | AD:4 |
| `external/google-java-format` | 1 | 2 | AD:2 | AD:2 |
| `external/guava` | 1 | 1 | AD:1 | AD:1 |
| `external/harfbuzz_ng` | 1 | 6 | AD:6 | AD:6 |
| `external/icu` | 2 | 2 | E:1 H:1 | L:2 |
| `external/jazzer-api` | 1 | 3 | AD:3 | AD:3 |
| `external/ktfmt` | 1 | 2 | AD:2 | AD:2 |
| `external/libbpf` | 1 | 6 | AD:6 | AD:6 |
| `external/libxkbcommon` | 1 | 1 | AD:1 | AD:1 |
| `external/minijail` | 1 | 3 | AD:3 | AD:3 |
| `external/nanopb-c` | 1 | 1 | AD:1 | AD:1 |
| `external/nullaway` | 1 | 1 | AD:1 | AD:1 |
| `external/oboe` | 1 | 1 | AD:1 | AD:1 |
| `external/okio` | 1 | 1 | AD:1 | AD:1 |
| `external/oss-fuzz` | 1 | 3 | AD:3 | AD:3 |
| `external/python/asn1crypto` | 1 | 1 | AD:1 | AD:1 |
| `external/python/bumble` | 1 | 2 | AD:2 | AD:2 |
| `external/python/cachetools` | 1 | 1 | AD:1 | AD:1 |
| `external/python/cpython3` | 1 | 5 | AD:5 | AD:5 |
| `external/python/google-api-python-client` | 1 | 1 | AD:1 | AD:1 |
| `external/python/jinja` | 1 | 1 | AD:1 | AD:1 |
| `external/python/markupsafe` | 1 | 2 | AD:2 | AD:2 |
| `external/python/mobly` | 1 | 1 | AD:1 | AD:1 |
| `external/python/portpicker` | 1 | 1 | AD:1 | AD:1 |
| `external/python/pybind11` | 1 | 5 | AD:5 | AD:5 |
| `external/python/pyfakefs` | 1 | 10 | AD:10 | AD:10 |
| `external/python/pyopenssl` | 1 | 2 | AD:2 | AD:2 |
| `external/python/pyyaml` | 1 | 2 | AD:2 | AD:2 |
| `external/python/typing` | 1 | 3 | AD:3 | AD:3 |
| `external/robolectric` | 1 | 5 | AD:5 | AD:5 |
| `external/rust/crates/ahash` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/aho-corasick` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/android_logger` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/anyhow` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/arbitrary` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/async-trait` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/bitflags` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/byteorder` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/bytes` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/cast` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/cfg-if` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/chrono` | 1 | 3 | AD:3 | AD:3 |
| `external/rust/crates/clang-sys` | 1 | 2 | AD:2 | AD:2 |
| `external/rust/crates/combine` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/command-fds` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/coset` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/criterion` | 1 | 2 | AD:2 | AD:2 |
| `external/rust/crates/downcast-rs` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/enumn` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/flate2` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/gdbstub` | 1 | 2 | AD:2 | AD:2 |
| `external/rust/crates/grpcio` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/intrusive-collections` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/itertools` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/itoa` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/libfuzzer-sys` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/libloading` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/libm` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/libz-sys` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/log` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/memoffset` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/minimal-lexical` | 1 | 5 | AD:5 | AD:5 |
| `external/rust/crates/no-panic` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/num_cpus` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/once_cell` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/parking_lot` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/paste` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/plotters` | 1 | 2 | AD:2 | AD:2 |
| `external/rust/crates/proc-macro-hack` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/proc-macro2` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/quickcheck` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/quote` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/regex-automata` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/remain` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/rustc-demangle` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/rusticata-macros` | 1 | 3 | AD:3 | AD:3 |
| `external/rust/crates/rustversion` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/ryu` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/semver` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/serde-xml-rs` | 1 | 2 | AD:2 | AD:2 |
| `external/rust/crates/serde_json` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/shared_child` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/shlex` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/smallvec` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/spin` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/termcolor` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/thiserror` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/tinytemplate` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/tinyvec` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/unicode-bidi` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/unicode-normalization` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/unicode-segmentation` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/vsock` | 1 | 2 | AD:2 | AD:2 |
| `external/rust/crates/walkdir` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/weak-table` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/which` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/xml-rs` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/crates/zip` | 1 | 1 | AD:1 | AD:1 |
| `external/rust/cxx` | 1 | 2 | AD:2 | AD:2 |
| `external/selinux` | 2 | 4 | D:1 AD:3 | D:1 AD:3 |
| `external/tensorflow` | 1 | 2 | AD:2 | AD:2 |
| `external/tinyxml2` | 1 | 1 | AD:1 | AD:1 |
| `external/toybox` | 1 | 1 | AD:1 | AD:1 |
| `external/turbine` | 1 | 1 | AD:1 | AD:1 |
| `external/volley` | 1 | 1 | AD:1 | AD:1 |
| `external/zstd` | 1 | 3 | AD:3 | AD:3 |
| `hardware/bst/audio` | 2 | 3 | E:2 H:1 | E:2 H:1 |
| `hardware/bst/camera` | 3 | 55 | E:53 H:2 | E:51 H:4 |
| `hardware/bst/lights` | 1 | 1 | H:1 | H:1 |
| `hardware/bst/memtrack` | 1 | 2 | E:1 H:1 | E:1 H:1 |
| `hardware/bst/power` | 1 | 2 | E:1 H:1 | E:1 H:1 |
| `prebuilts/cmdline-tools` | 1 | 3 | D:3 | D:3 |
| `system/security` | 1 | 1 | D:1 | D:1 |

## Baseline Boundaries

These projects have no usable `android-13.0.0_r49` or fallback A13 tag.
They require direct tree/provenance review and are not counted as omissions.

| Project | A13 HEAD | Error |
|---|---|---|
| `bootable/newinstaller` | `dbdcad74329b9a8beea426849f5a3d8894b73f98` | no-a13-baseline |
| `build` | `04a5a80b2c4a009a3220e982d2056835c69bc90a` | no-a13-baseline |
| `cts` | `7156e7b7e15e75add58cafdfb6ceaba8d92c4bb8` | no-a13-baseline |
| `external/alsa-lib` | `b881b3666a245f9eae7472be05064a6908f32416` | no-a13-baseline |
| `external/alsa-ucm-conf` | `a4cd64da90d01dc801b1887a7f835420512d0f17` | no-a13-baseline |
| `external/alsa-utils` | `2e0c01ee6018d8246857ab93a5bc8b056ffe815e` | no-a13-baseline |
| `external/chromium-webview` | `b4a573b867f40347b674bd1c7471bd9cbc8e2ea6` | no-a13-baseline |
| `external/efibootmgr` | `51bceba8fd58c3c8ba5d6bc560165af0ec98ca68` | no-a13-baseline |
| `external/efivar` | `ce2bcd246d0a51c6d1c72514051acc7f47520852` | no-a13-baseline |
| `external/ffmpeg` | `5caa26d67340b43aebef124bcb7e968ba37f6cb6` | no-a13-baseline |
| `external/stagefright-plugins` | `0b53a655eef7a8be53bfbcaefaca06d1a52a6add` | no-a13-baseline |
| `external/syslinux` | `c0fa5092499c12364c1bf7702ed5d9f255cad867` | no-a13-baseline |
| `external/v86d` | `bf5f11a175a6740dd29cd224c804e03b2ac80558` | no-a13-baseline |
| `kernel` | `686f860abf3a5c7117d6a784ef0360ac99bfcef0` | no-a13-baseline |
| `packages/modules/BootPrebuilt/5.10/arm64` | `95cfa206c00dd5fcc72991f80ddfe383e76095ad` | no-a13-baseline |
| `packages/modules/BootPrebuilt/5.4/arm64` | `3130a05a2f71e6c43892db92148956af0b05a406` | no-a13-baseline |
| `prebuilts/abi-dumps/ndk` | `584d53e8ad6f446cf7cc89e2e48d40124ac7f367` | no-a13-baseline |
| `prebuilts/abi-dumps/platform` | `d6b0c88d60559039689798e0cf98bc59e0004a26` | no-a13-baseline |
| `prebuilts/abi-dumps/vndk` | `36af21f036162f6a786462511856b56e868614d2` | no-a13-baseline |
| `prebuilts/android-emulator` | `5e1fc30217c92be22f9404ce96a54b9786ea12de` | no-a13-baseline |
| `prebuilts/bazel/darwin-x86_64` | `0400af455aa89098cec5c1c99b8121145586e507` | no-a13-baseline |
| `prebuilts/bazel/linux-x86_64` | `55f107c5a0a9e9d72c9f3d405ff59b8af1932a8c` | no-a13-baseline |
| `prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8` | `488a9ea2b491ed8ecaafda9e7d55c67abdd991a3` | no-a13-baseline |
| `prebuilts/gcc/linux-x86/host/x86_64-w64-mingw32-4.8` | `3a5548ba2161bed6592cd2e2f258f622d55a838b` | no-a13-baseline |
| `prebuilts/go/darwin-x86` | `34885daa93a0301203fbfcd9bef6edefce518c96` | no-a13-baseline |
| `prebuilts/go/linux-x86` | `75bd966582b037a3e1dd7b7ad2a487fbce8df7b4` | no-a13-baseline |
| `prebuilts/gradle-plugin` | `ec137ef90752aa47dbf6ac1068feb87194c1a6f9` | no-a13-baseline |
| `prebuilts/jdk/jdk8` | `2180e7b1d5a672381dac1cf8b4ce7aa3f9b03f8d` | no-a13-baseline |
| `prebuilts/maven_repo/android` | `00ce84cd4f79a463e42938dccf65f1dcda1fb360` | no-a13-baseline |
| `prebuilts/maven_repo/bumptech` | `41ea898873a189e9d1329c7d6fa5f8d125b4eef6` | no-a13-baseline |
| `prebuilts/module_sdk/IPsec` | `4eafd76b0c78eec3c99b9099181d15200bec42eb` | no-a13-baseline |
| `prebuilts/module_sdk/Permission` | `eb1dc8c6e74e529db2380e8f8dde33b4b97b63a1` | no-a13-baseline |
| `prebuilts/module_sdk/art` | `bf73da0e3ca89fd286b06e148f0891ff070d8943` | no-a13-baseline |
| `prebuilts/vndk/v28` | `eee529862cfb9b4044acb0c31011759ca7e1b392` | no-a13-baseline |
| `prebuilts/vndk/v29` | `4786f717853e546573df80da7eb39f7a47dd7f85` | no-a13-baseline |
| `prebuilts/vndk/v30` | `7415958739c1f064a0db2c70fd805a525077d889` | no-a13-baseline |
| `prebuilts/vndk/v31` | `1bcad36b5a54a770bf71ecff2b259fbd753016d3` | no-a13-baseline |
| `prebuilts/vndk/v32` | `7a9a808c5ed7e7b77ca1f733f0ceb0999d61df6c` | no-a13-baseline |

## Root Payload Groups

| Path group | Files | Missing AOSP16 | Missing Android-16 |
|---|---:|---:|---:|
| `hardware/intel/common` | 1156 | 1156 | 1156 |
| `external/arm-runtime/inc` | 86 | 86 | 86 |
| `packages/apps/BstSettings` | 85 | 85 | 85 |
| `packages/apps/BstCommandProcessor` | 39 | 0 | 0 |
| `packages/apps/BstFolder` | 15 | 15 | 15 |
| `external/bluestacks/bstshutdown` | 5 | 0 | 0 |
| `external/bluestacks/sensors` | 3 | 0 | 0 |
| `external/bluestacks/bstfolder` | 2 | 0 | 0 |
| `external/bluestacks/bstgps` | 2 | 0 | 0 |
| `external/bluestacks/bstsyncfs` | 2 | 0 | 0 |
| `hardware/intel/audio_media` | 2 | 2 | 2 |
| `hardware/qcom/sdm845` | 2 | 2 | 2 |
| `hardware/qcom/sm7150` | 2 | 2 | 2 |
| `hardware/qcom/sm7250` | 2 | 2 | 2 |
| `hardware/qcom/sm8150` | 2 | 2 | 2 |
| `hardware/qcom/sm8150p` | 2 | 2 | 2 |
| `.gitignore` | 1 | 1 | 0 |
| `.gitmodules` | 1 | 1 | 0 |
| `Android.bp` | 1 | 0 | 0 |
| `Makefile` | 1 | 1 | 1 |
| `README` | 1 | 1 | 1 |
| `bootstrap.bash` | 1 | 0 | 0 |
| `external/arm-runtime/Android.mk.bak` | 1 | 1 | 1 |
| `external/arm-runtime/arm-core.xml` | 1 | 1 | 1 |
| `external/arm-runtime/arm-dis.c` | 1 | 1 | 1 |
| `external/arm-runtime/arm-neon.xml` | 1 | 1 | 1 |
| `external/arm-runtime/arm-semi.c` | 1 | 1 | 1 |
| `external/arm-runtime/arm-vfp.xml` | 1 | 1 | 1 |
| `external/arm-runtime/arm-vfp3.xml` | 1 | 1 | 1 |
| `external/arm-runtime/cache-utils.c` | 1 | 1 | 1 |
| `external/arm-runtime/config-host.ld` | 1 | 1 | 1 |
| `external/arm-runtime/config-target.mak` | 1 | 1 | 1 |
| `external/arm-runtime/cpu-exec.c` | 1 | 1 | 1 |
| `external/arm-runtime/cpu-uname.c` | 1 | 1 | 1 |
| `external/arm-runtime/custom_syscall.c` | 1 | 1 | 1 |
| `external/arm-runtime/cutils.c` | 1 | 1 | 1 |
| `external/arm-runtime/disas.c` | 1 | 1 | 1 |
| `external/arm-runtime/double_cpdo.c` | 1 | 1 | 1 |
| `external/arm-runtime/elfload.c` | 1 | 1 | 1 |
| `external/arm-runtime/elflookup.c` | 1 | 1 | 1 |
| `external/arm-runtime/envlist.c` | 1 | 1 | 1 |
| `external/arm-runtime/exec.c` | 1 | 1 | 1 |
| `external/arm-runtime/extended_cpdo.c` | 1 | 1 | 1 |
| `external/arm-runtime/feature_to_c.sh` | 1 | 1 | 1 |
| `external/arm-runtime/flatload.c` | 1 | 1 | 1 |
| `external/arm-runtime/fpa11.c` | 1 | 1 | 1 |
| `external/arm-runtime/fpa11.inl` | 1 | 1 | 1 |
| `external/arm-runtime/fpa11_cpdo.c` | 1 | 1 | 1 |
| `external/arm-runtime/fpa11_cpdt.c` | 1 | 1 | 1 |
| `external/arm-runtime/fpa11_cprt.c` | 1 | 1 | 1 |
| `external/arm-runtime/fpopcode.c` | 1 | 1 | 1 |
| `external/arm-runtime/gdbstub-xml.c` | 1 | 1 | 1 |
| `external/arm-runtime/gdbstub.c` | 1 | 1 | 1 |
| `external/arm-runtime/helper.c` | 1 | 1 | 1 |
| `external/arm-runtime/host-utils.c` | 1 | 1 | 1 |
| `external/arm-runtime/i386-dis.c` | 1 | 1 | 1 |
| `external/arm-runtime/i386.ld` | 1 | 1 | 1 |
| `external/arm-runtime/iwmmxt_helper.c` | 1 | 1 | 1 |
| `external/arm-runtime/lib_bypass.c` | 1 | 1 | 1 |
| `external/arm-runtime/linuxload.c` | 1 | 1 | 1 |
| `external/arm-runtime/main.c` | 1 | 1 | 1 |
| `external/arm-runtime/mmap.c` | 1 | 1 | 1 |
| `external/arm-runtime/neon_helper.c` | 1 | 1 | 1 |
| `external/arm-runtime/op_helper.c` | 1 | 1 | 1 |
| `external/arm-runtime/optimize.c` | 1 | 1 | 1 |
| `external/arm-runtime/osdep.c` | 1 | 1 | 1 |
| `external/arm-runtime/oslib-posix.c` | 1 | 1 | 1 |
| `external/arm-runtime/parse_jni_native_interface.py` | 1 | 1 | 1 |
| `external/arm-runtime/parse_logs.py` | 1 | 1 | 1 |
| `external/arm-runtime/parse_logs.sh` | 1 | 1 | 1 |
| `external/arm-runtime/path.c` | 1 | 1 | 1 |
| `external/arm-runtime/perf-header.h` | 1 | 1 | 1 |
| `external/arm-runtime/perf-server.c` | 1 | 1 | 1 |
| `external/arm-runtime/perf-server.h` | 1 | 1 | 1 |
| `external/arm-runtime/perf_mon.c` | 1 | 1 | 1 |
| `external/arm-runtime/qemu-malloc.c` | 1 | 1 | 1 |
| `external/arm-runtime/qemu-thread-posix.c` | 1 | 1 | 1 |
| `external/arm-runtime/signal.c` | 1 | 1 | 1 |
| `external/arm-runtime/single_cpdo.c` | 1 | 1 | 1 |
| `external/arm-runtime/softfloat.c` | 1 | 1 | 1 |
| `external/arm-runtime/strace.c` | 1 | 1 | 1 |
| `external/arm-runtime/strace.list` | 1 | 1 | 1 |
| `external/arm-runtime/syscall.c` | 1 | 1 | 1 |
| `external/arm-runtime/tcg-runtime.c` | 1 | 1 | 1 |
| `external/arm-runtime/tcg-target.c` | 1 | 1 | 1 |
| `external/arm-runtime/tcg.c` | 1 | 1 | 1 |
| `external/arm-runtime/thunk.c` | 1 | 1 | 1 |
| `external/arm-runtime/translate-all.c` | 1 | 1 | 1 |
| `external/arm-runtime/translate.c` | 1 | 1 | 1 |
| `external/arm-runtime/uaccess.c` | 1 | 1 | 1 |
| `external/arm-runtime/user-exec.c` | 1 | 1 | 1 |
| `system/bstime/Android.mk` | 1 | 1 | 1 |
| `system/bstime/Main.cpp` | 1 | 1 | 1 |
| `tools/bazel` | 1 | 1 | 1 |

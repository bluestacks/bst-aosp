# Houdini 16 Integration Record

## Scope and authority

This record covers the externally supplied Android 16 Houdini package used by
the Windows `android_x86_64` product. Android 13 remains the authority for
BlueStacks native-bridge behavior. The Intel Android 16 delivery is the
authority only for the version-specific translator payload and its Android 16
platform requirements.

The payload and integration guide are restricted external inputs. They are not
stored in this repository, copied into patch artifacts, or published through a
component fork. The remote build tree provisions the payload as ignored content
at `vendor/intel/houdini`.

## Delivered identities

| Item | Size | SHA-256 | Preservation |
| --- | ---: | --- | --- |
| `Houdini_16.0.0.bluestacks_com1.0.tar.gz` | 51,525,444 bytes | `a190542e489de340881c67e535faba5d40c726a24992d5ce598c8f48688f40ea` | external-secret |
| `Intel_Bridge_Technology_Integration_Guide_AOSP-16_v1.0.0.docx` | 65,366 bytes | `e82d4830edbf607f293cc585cf775e7c1e05ed82f4b52a9eb119c560c4e85d0f` | external-secret |
| guide attachment: integration patch | 3,010 bytes | `10d34ea2bc085e724c678be1f0018486454cded547566628b1ec57be062320bc` | external-secret |
| guide attachment: SELinux policy | 1,952 bytes | `3293db7190349e2825cc6f23c604ac1a70bfbd03e73a148d09a8f23498594a45` | external-secret |
| guide attachment: patch helper | 639 bytes | `7c32b14d77ed5480927f57d9aa48dc9472b2843122fbd39f64e8ccc21c3f2e18` | external-secret |

The extracted translator contains 395 files and occupies 147,035,756 bytes.
Its executable and native-bridge library are stripped x86-64 ELF files. The
package provides arm64 translation only and exports `NativeBridgeItf` version 8.

## A13 behavior mapping

The final A13 native-bridge behavior is not represented by one commit. The
following chain must be read as an evolution whose final tree is authoritative:

| A13 commit | Purpose | Android 16 disposition |
| --- | --- | --- |
| `5cb77e7887322aeb20b98ceb668b24d197d0d6fa` | Initial Houdini integration and `libnb` dispatcher | Preserved through `device/generic/common/nativebridge`; payload replaced by the supplied 16.0.0 package. |
| `5021d06dc7c0f9c2439417f06ddeafb5df53f4a0` | Common binary patch framework | Preserved in `libnb.cpp`. |
| `af84dfbd9ad6890f64793a54f441add4a08f73ba` | Houdini 13.0.0a repair | Superseded in A13; not applied to the 16.0.0 binary. |
| `9baff1b8c154e7d106093c7adb892071e17a28e0` | Temporary 13.0.0a_y repair | Superseded in A13; not applied to the 16.0.0 binary. |
| `f7d4e66403301f26cda4c184a2558d0c8bc3d5fd` | AMD CPU lag repair | Its surviving framework is preserved; version-specific offsets do not match 16.0.0. |
| `3d950593dd200a2a68f8828dc31862c182ccff30` | Consolidated patch framework, zygote guard and callback synchronization | Preserved, with Android 16 callback-field adaptation. |
| `3a577844158f1efe295c9e215ac286e8c78a5816` | Register repair | Preserved in the final A13-derived source; version-specific execution remains gated by binary identity. |
| `7026ade8e96d75ba0c37591aeabf50e9c4c8abb8` | Package-name export consumer and app compatibility patch | Preserved together with the ART `bst_nbpname` export. |
| `a9b7f226ea9186e0f476bbc5abb0ff71ca2ce1de` | `/proc/<pid>/maps` compatibility | Preserved in the version-gated patch framework. |
| `881da8c5c92d38b661772eb5b3f790ab7c35c02d` | Remove a broken 13.0.0ab_z patch call | Final removal preserved. |
| `215ef21accfdf5a87666094e671959a225691ce8` | Replace maps patch and remove obsolete repairs | Final A13 implementation preserved. |
| `76143e920d5496dbbbd68b47b009bceee5e45817` | Per-app NDK translation selection | Preserved; Android 16 keeps both the NDK translation backend and Houdini backend behind `libnb`. |

The A13 `libnb` source advertised interface version 6. Houdini 16 advertises
version 8, so Android 16 adds explicit v7/v8 callback forwarding and caps
compatibility at the loaded backend's declared version. This prevents the
runtime from calling absent callback slots while retaining safe behavior for an
older translation backend.

## Android 16 integration decisions

- The target remains `android_x86_64`; no goldfish or `emu64x` board settings
  are imported from the example patch.
- `libnb.so` remains `ro.dalvik.vm.native.bridge` so A13 per-app translator
  selection and BlueStacks hooks are retained. Houdini is a backend, not a
  replacement for the dispatcher.
- Only `arm64-v8a` is advertised because both supplied translator payloads are
  64-bit. Advertising `armeabi-v7a` without a 32-bit backend would select an
  unavailable `/system/lib/libhoudini.so`.
- Device-specific init mounts `binfmt_misc`, registers the two arm64 handlers,
  and bind-mounts the supplied arm64 library directory. Global `system/core`
  init behavior is unchanged.
- ART checks the package's canonical
  `/system/etc/houdini/cpuinfo.arm64.txt` before legacy BlueStacks fallback
  locations.
- `PRODUCT_PACKAGES` uses `+=`; the A13 `:= libnb` assignment would erase
  packages accumulated earlier in the Android 16 product inheritance chain.

## Performance, security and necessity

The init work occurs once during boot. The bind mount and binfmt registration
do not add an application hot-path cost. `libnb` adds one dispatcher layer to
native-bridge calls; this is necessary for per-app backend selection and the
existing BlueStacks compatibility hooks. Translation itself has an unavoidable
runtime and memory cost that must be measured with representative arm64 apps.

The package is licensed external material. It must remain outside Git history,
component forks, generated patches and public build logs. Only hashes and
derived integration decisions are retained here. No version-specific binary
offsets are derived for Houdini 16.

## Validation state

| Gate | State | Evidence |
| --- | --- | --- |
| Package identity | passed | Local and remote archive SHA-256 match. |
| Static ELF identity | passed | `houdini64` and `libhoudini.so` are x86-64; the library exports v8 `NativeBridgeItf`. |
| `libnb` and Houdini module build | pending | Must be built from `~/android-16` with the android-x86_64 target. |
| Product image presence and properties | pending | Verify all package files, ABI properties and ignored-input hash after image build. |
| SELinux | pending | Compile policy, boot enforcing, and check for Houdini/binfmt denials. |
| Binfmt registration | pending | Verify `arm64_dyn` and `arm64_exe` with `P` flag after boot. |
| Native arm64 application | pending | Load JNI, execute a native binary, and exercise regular/fast/critical native callbacks. |
| A13 compatibility oracles | pending | Verify package selection, AMD behavior, package-specific hooks and `/proc/<pid>/maps`. |

The integration is not boot-verified until every pending gate has bound tree,
branch, commit, output directory and artifact hashes.

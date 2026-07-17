# Summary — G1 Phase 1 完成（统一板 device/bst/qvirt / bst_x86_64）

> checkpoint of the G1 Phase 1 work unit（boot 到 launcher，host oracle 全绿，2026-07-17 porting-log cont.4）。
> 权威详情：[`patches/android-16/checkpoints/G1.md`](../patches/android-16/checkpoints/G1.md) · 时间线 [`progress/porting-log.md`](../progress/porting-log.md) cont.1~cont.4。

## 定制 / 改动（id）

| registry id | 角色 | temp_debt | 正式化 |
|---|---|---|---|
| `boot-device-generic-common` / `-x86_64` | M1 boot 板配置（已 ported 进 G1） | false | — |
| `g1-apks-preinstall` | BST launcher/gamecenter/bsxlauncher 预装 priv-app（g1_copy_bst_apks.sh） | false | — |
| `g1-pack-pipeline` | pack 对齐 buildscripts（r228 create_vdi 分区+UUID + fastboot KDIR + boot_verify oracle） | false | — |
| `g1-verify-ready-tag` | boot_verify ready oracle 对齐 [Ready] tag | false | — |
| `g1-property-gralloc-egl` | ro.hardware.gralloc=bst / egl=emulation（build.prop append） | **true** | 正式 = init.sh init_hal_gralloc()（Phase 2） |
| `g1-hwservicemanager-service-bypass` | service.cpp if(false) bypass HIDL 自杀 | **true** | 正式 = libhidl_vintf VINTF level patch（Phase 2） |
| `boot-vndservicemanager` | m systemimage 不构建 → 现 m droid 原生解决（overlay 弃用） | true | G9 build-config 显式装进 system |

## 源 commit / patch（已捕获入 patches/android-16/patches/）
- `aosp16__system_hwservicemanager.patch`（Android.bp + hwservicemanager.rc + **service.cpp DIAG bypass**，temp_debt）
- `aosp16__system_libhidl_vintf.patch`（framework manifest hidl.manager/allocator/token max-level=8，**VINTF level 正式解**）
- `aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch`（temp_debt，P2-TEMP-BLAST）
- `untracked-src/aosp16__device_bst_qvirt/`（bst_x86_64.mk 含 `PRODUCT_PACKAGES += hwservicemanager`，G9）
- M1 boot patches（frameworks_base/native/build_make/system_core/...）+ device_generic_common overlay

## 冲突解决（rebase / fork-diff overlay，跨 android-13→16）
- packaging：早期 `qemu-img convert -O vpc` 绕过 create_vdi → 无分区表（无 sda1）→ kernel panic。改 r228 create_vdi（parted msdos + mke2fs）+ sethduuid 54e9ad31。
- hwservicemanager：build_make `system_image_defaults` deps 对 Make systemimage 路径不触发编译 → 不产出 → HAL SIGABRT。改 PRODUCT_PACKAGES（device 层）。
- hwservicemanager 自杀：A16 `getTransport(IServiceManager)==EMPTY`（VINTF level 过滤 hidl.manager）→ 自杀。DIAG bypass（temp）+ VINTF level patch（正式）。
- gralloc：init.sh init_hal_gralloc() 漏设 ro.hardware.gralloc + prune 删 gralloc.default.so → hw_get_module NULL → hwcomposer SIGSEGV。build.prop append（temp）。
- launcher：APPCONFFILE 归 Priv-Downloads（dataFS 首启装），G1 删 dataFS → launcher 缺 → FallbackHome → host 不 Ready。force 预装 priv-app。

## upstream delta（android-13 → android-16.0.0_r4）
- A16 hwservicemanager 加了「HIDL 不支持则自杀」（commit 523130f）→ 需 VINTF level 声明或 bypass。
- A16 Shell Transitions 默认开 → goldfish BLAST commit callback 不返回 → r262 关（temp）。
- A16 SF `trackPendingFrame: Invalid present fence` 日志（非致命，M1 同样有）。

## verification（readback，非声称）
- Layer1：`m droid` rc=0，VINTF patch applied。
- Layer2（**boot 到 launcher**，Root.vhd `2a7a497a` + fastboot `8ebe81e7` + 干净 Data_orig 首启）：host boot oracle 全绿 —— `Player state: ready` + `fUiHideBootProgressBar` + `plrOnActivityDisplayedHcall`；`GlueStartVM failed=0`；`hwcomposer SIGSEGV=0`；adb `topResumedActivity=com.uncube.launcher3/...HomeActivity`。用户视觉确认：界面正常显示。

## host-compat
- win：smoke（boot 到 launcher）✅。
- mac：bst_arm64 基于同码 + arm64 BoardConfig，Phase 3 host 阶段集中验（win-first）。

## Rule changes（本工作单元）
- validation-gate.md：补 stale-oracle 教训（oracle 字符串要先验真格式，见今日 porting-log）。
- completion-loop.md：修「Phase 1 仅 Layer1」与「G1 必须 Layer2」的矛盾。

## Follow-ups（本次登记不实施）
- **J1（verify oracle 集）**：`g1_boot_verify.ps1` 有 7 oracle（4 guest 字符串 + 3 host），break 条件要求 7/7；但 summary/G1.md 把「全绿」圈定为 3 条 host 侧。guest 4 条经 bs_bootlog→Player.log 确可命中（cont.4 实测 system mounted=8/init second=8/odsign=4/boot_completed=5），但未跑完整 `g1_boot_verify.ps1` 到 7/7 早退确认。Phase 2：要么跑一次完整 verify 确认 7/7，要么把 oracle 集裁到 host-verifiable 3 条 + 加 `adb getprop sys.boot_completed`。
- temp_debt 正式化（service.cpp→VINTF、gralloc→init.sh、r262、P2-APKS-DATAFS、vndservicemanager G9）。
- mac bst_arm64（Phase 3 host 阶段验）；buildscripts Makefile 接 bst_x86_64；CI。

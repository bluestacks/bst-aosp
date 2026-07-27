# Summary — Phase 2 D8+D9 关门（2026-07-26 cont.101-102）

## 权威状态

| 项 | 值 |
|---|---|
| 当前 Root.vhd | **`02690d11`**（MD5 02690D1182FF507FAEDB1C5E438806F4，uuid 54e9ad31）|
| system.img | **`a878d3c8`**（OUT_DIR=out_nxt_Baklava64）|
| Layer2 | **7/7 @161s**（system_mounted/init_second/odsign/boot_completed/activity/ready/hide_boot），干净 Data `wipe20260717` |
| core/java | **22/22** ✅ |
| deferred | **8/9 done**（D1/D2/D5/D6/D7/D8/D9 + ActiveServices）；D3 截图 defer 到虚拟化 port |
| frameworks/base | 全 commit（source-vs-commit drift 清零）|

## 本会话 cont.96-102 完成

- **D9 binder C++**（`c581b1bae8` frameworks/native/libs/binder）：3670 行真实现替换 fail-open stub。6 个 a13→a16 机械修：①header VNDK guard+String16 ②manual-interface allowlist b/64223827 ③exit-time-dtor ④LIBBINDER_EXPORTED visibility ⑤vendor PermissionController guard ⑥(void)uid。camera/SF 等 C++ BST hooks 现 runtime 连真 Java BST service。
- **D8 subscription**（`00274255beb7` frameworks/base telephony）：`getActiveSubscriptionInfoCount()→1`（绕过 @RequiresPermission 阻塞）。
- **pagefusion**（`2cf8a0cf64c5` frameworks/base cmds/pagefusion）：a16 bionic `-D__BIONIC_NO_PAGE_SIZE_MACRO` → 本地 `#define PAGE_SIZE 4096`（latent gap，被 .intermediates 全量重编暴露）。
- **frameworks/base 16 文件 drift 清零**：4 组 commit（BstUtils core `99b551f2` / FW-WM `db4ffd98` / core hooks `8de1d186` / config `3bc7e67e`）。
- **D3 截图**：defer 到虚拟化 port（design `progress/d3-redesign.md`，注入 ScreenshotController.kt:508；块 C `/mnt/windows` 挂载需 vbox/qvm port）。

## 验证回环（readback）

- Layer1：`m droid` rc=0 + goldfish mmm done（g1_build.sh，`~/p2_def9_fullbuild3.log`）。
- Pack：g1_stage_system.sh（fold vendor473/system_ext70/product114）→ g1_copy_bst_apks.sh（launcher3+gralloc=bst）→ r228-pack-root.sh（Root.vhd uuid 54e9ad31，R228_ROOT_PACK_DONE）。
- Deploy：g1_win_deploy.ps1 → Root.vhd MD5 readback 一致。
- Layer2：g1_boot_verify.ps1 + 干净 Data → 7/7 @161s。

## Rule changes / 教训

- **铁律入 memory**：build 一旦发起**绝不 `pkill -9 soong_ui`**（中断会腐蚀 ninja 图 + 丢 `.intermediates` → 全量重编数小时）。本会话早段失误致全量重编，后用增量恢复。详见 [[a16-phase2-fw-iteration-mechanics]]。
- **a16 libbinder C++ 移植 6 坑**入 memory [[a16-libbinder-cpp-porting-gotchas]]（+ pagefusion PAGE_SIZE macro 禁用坑）。

## 本地 patches（compliance #5，字节校验）

- `aosp16__frameworks_native_libs_binder.patch`（3898 行，base `fcbde2bcff`）
- `aosp16__frameworks_base.patch`（22924 行全 delta，base `45034f06`）+ `__d8-subscription`（39 行）+ `__pagefusion`（3041 行）
- registry.json synced（199 patches：16 ported / 1 deferred / 22 boot-archived / 155 dropped）

## 下一会话恢复

- 远程两 project（frameworks/base、frameworks/native）均 clean（全 commit）。
- 本地 bst-aosp clean（commits `c29c743` + `f5da3dd`）。
- guest 主线 win 路径 boot 到 launcher 全绿。剩余：D3（虚拟化 port 阶段）、mac `bst_arm64` 同码、Phase 2 gate 收尾。

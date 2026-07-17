# Plan — G1 Phase 1（统一板 device/bst/qvirt / bst_x86_64，boot 到 launcher）

> 本工作单元的 accepted plan + 执行结果。状态：**✅ 完成（2026-07-17 porting-log cont.4）**。

## 目标
把 M1 boot 的 `device/generic/*` overlay 并入统一板 `device/bst/qvirt`，新增 win 产品 `bst_x86_64`（与 mac `bst_arm64` 同板、arch 差异下沉 BoardConfig），**boot 到 launcher**（Layer2 boot 回归 gate）。无 M1 系统产物；M1 为权威（行为/结构对齐，不搬二进制）。正式改动为主，temp_debt 显式标注。

## 执行（逐层 readback，非假设）
1. **统一板脚手架** `device/bst/qvirt/{AndroidProducts,BoardConfig,bst_x86_64}.mk`（薄壳继承 generic，身份 override）+ `g1_equiv_check.sh` → EQUIVALENT。
2. **Layer1** `m droid`（非 m systemimage —— 后者系统性缺 vendor/system_ext）rc=0，VINTF patch applied。
3. **packaging** r228-pack-root.sh（= buildscripts create_vdi：msdos 分区 sda1 + clonehd VHD + sethduuid 54e9ad31），替代 qemu-img 绕过（无分区 → kernel panic）。
4. **hwservicemanager** PRODUCT_PACKAGES（G9）→ HAL SIGABRT 清零；service.cpp DIAG bypass 自杀（temp，正式=VINTF level）。
5. **fastboot** KDIR=~/aosp16/kernel-a16 make build_fastboot（修 r245 No rule bzImage）→ bs_bootlog 修部署。
6. **gralloc=bst** build.prop append（temp，正式=init.sh）→ hwcomposer SIGSEGV 清零。
7. **BST launcher 预装** g1_copy_bst_apks.sh（apks_Baklava64 prebuilt → priv-app + native lib）→ launcher 成 HOME → host [Ready]。

## 结果
G1 boot 到 launcher（可见可交互），host boot oracle 全绿，Root.vhd `2a7a497a`。Phase 1 gate 达成。

## 未做（Phase 2 收口 / 后续组）
- temp_debt 正式化：service.cpp DIAG → libhidl_vintf；gralloc build.prop → init.sh；r262 BLAST；P2-APKS-DATAFS；vndservicemanager G9 build-config。
- mac bst_arm64（win-first，Phase 3 host 阶段验）。
- G2-G10 余项有序移植；buildscripts Makefile 把 bst_x86_64 接入 `make vbox`（彻底整合）。
- CI / pre-commit（后续阶段）。

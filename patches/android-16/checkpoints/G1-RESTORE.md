# G1 RESTORE — Phase 1 可恢复存档

> 仅凭本目录即可在一台干净的 android-16 构建机上把 G1 恢复到 **boot 到 launcher（host oracle 全绿）** 态。  
> 基准：M1 RESTORE (`patches/android-16/RESTORE.md`) + G1 checkpoint (`G1.md`) + `progress/porting-log.md` cont.4。  
> 存档时间：2026-07-17（cont.4 readback）。远程 guest 构建机 `markxu@172.16.6.191`。

## 0. Patches（在 aosp16 树上 apply 所有 G1 patch）

```bash
# 0a. VINTF fix（framework manifest 声明 hidl.allocator/manager/token）
(cd $AOSP/system/libhidl && git apply $ARC/patches/android-16/patches/aosp16__system_libhidl_vintf.patch)

# 0b. Shell Transitions TEMP（G1 基线；Phase 2 P2-TEMP-BLAST 收口）
#     根因：goldfish BLAST/SF commit callback 不返回 → Shell Transitions 卡死 Settings
#     影响：关闭 shell transitions（ENABLE_SHELL_TRANSITIONS=false）；Settings 界面可操作
#     Phase 2 修好后删本 patch + 恢复 ENABLE_SHELL_TRANSITIONS=true
(cd $AOSP/frameworks/base && git apply $ARC/patches/android-16/patches/aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch)

# 0c. 其余 M1 boot patches（build_make, system_core, frameworks_base, frameworks_native,
#     hardware_interfaces, hardware_libhardware, system_security, art, boringssl, etc.）
#     详见 RESTORE.md §3（如果树是干净的 android-16.0.0_r4）
```

## 1. Build（构建 AOSP + libs）

```bash
# 远程 guest 构建机 markxu@172.16.6.191，env 与 g1_build.sh 一致（增量，勿 clean）
cd ~/aosp16
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
m droid -j24          # Layer1 全量（含 vendor/system_ext fold 进 OUT system/ 目录）；VINTF patch applied → rc=0
# hd guest native + goldfish 图形链（m droid 默认闭包不含，须显式 mmm，对齐 buildscripts hostcall_gcall_libs + goldfish_opengl）
mmm ~/ggl/goldfish-opengl-pie BUILD_EMULATOR_OPENGL=true -j24
bash ~/bst-aosp/scripts/g1_build_libs.sh   # 10 个 hd 模块 + goldfish hwc2 mmm
# patches apply 顺序见 §0：VINTF fix + service.cpp DIAG(temp_debt) + r262 TEMP + M1 boot patches
# 关键源码改动：device/bst/qvirt/bst_x86_64.mk 加 PRODUCT_PACKAGES += hwservicemanager（G9，已在 untracked-src 同步）
```
> 调试期禁 `m clean`（用 installclean）+ 禁 apk 重编（apk 是 prebuilt，见 §3 g1_copy_bst_apks）。回读：`out_nxt_Baklava64/target/product/qvirt/system.img` md5 + installed-files + `system/vendor/bin/vndservicemanager` 在（m droid fold）。

## 2. Stage（暂存 —— OUT 目录折叠）

`g1_stage_system.sh` 把 OUT `qvirt/system/`（含 vendor/system_ext/product 子目录 = fold）直接 rsync 进 `releases/Baklava64/system`。**不使用 `system.img` mount**（mount 会丢失子目录）。

```bash
bash ~/bst-aosp/scripts/g1_stage_system.sh
# 回读：vendor 479 files, system_ext 75 files, product 114 files
```

## 3. 分区内容 — M1 参考文件（148 件 vendor/system_ext/etc）

`bst_x86_64`/`qvirt` 不做 system_ext 独立分区；vendor/system_ext 内容需从 M1 参考镜像 **手工合进** `releases/Baklava64/system`（= 复刻 M1 Henry 装配）。严格**排除** system 件（priv-app/launcher、bin/adbd、lib/、out_*），不覆盖 G1 构建产出的 system 内容。

```bash
# 3a. 提取 M1 system.sfs → system.img（若尚未）
[ -f /tmp/m1_sfs/system.img ] || {
  mkdir -p /tmp/m1_sfs
  scp <win>:"/c/ProgramData/BlueStacks_nxt/Engine/Tiramisu64/Root.vhd.bak-r262b-20260714-180837" ~/m1_r262b.Root.vhd
  sudo qemu-nbd -c /dev/nbd6 ~/m1_r262b.Root.vhd
  sudo debugfs -R "dump android/system.sfs /tmp/m1_system.sfs" /dev/nbd6p1
  sudo qemu-nbd -d /dev/nbd6
  sudo unsquashfs -d /tmp/m1_sfs -f /tmp/m1_system.sfs
}

# 3b. 仅 vendor/system_ext/etc（不含 priv-app/bin/lib/framework/out_）
SYS=~/releases/Baklava64/system
M=$(mktemp -d); sudo mount -o ro,loop /tmp/m1_sfs/system.img $M
[ -d $M/system ] && MR=$M/system || MR=$M
for rel in $(grep -vE "^(priv-app/|bin/|lib/|lib64/|framework/|app/|out_)" /tmp/missing_in_g1.txt); do
  sudo mkdir -p "$(dirname "$SYS/$rel")"
  sudo cp -a "$MR/$rel" "$SYS/$rel"
done
sudo umount $M; sudo chown -R $(id -u):$(id -g) $SYS
# 回读：148 files copied, vendor=479, system_ext=75, product=114
```

## 4. Pack（打包 —— qemu-img 直出 VHD，绕过 qemu-nbd）

```bash
OD=~/releases/Baklava64
PKG=$OD/bst-v5.22.210_Baklava64-local
mkdir -p $PKG

# 4a. system.sfs（squashfs）
bash ~/app-player/buildscripts/make-baklava-system-sfs.sh "$OD"

# 4b. Root.fs (ext4) → VHD
dd if=/dev/zero of=/tmp/bst_root.raw bs=1M count=6144
mkfs.ext4 -m 1 -L root -F /tmp/bst_root.raw
M=$(mktemp -d); sudo mount -o loop /tmp/bst_root.raw $M
sudo mkdir -p $M/android
sudo cp $OD/system.sfs $M/android/
sudo cp ~/aosp16/out_nxt_Baklava64/target/product/qvirt/ramdisk.img $M/android/
sudo umount $M
qemu-img convert -f raw -O vpc /tmp/bst_root.raw $PKG/Root.vhd

# 4c. VBox UUID（若可用 VBoxManage）
VBoxManage internalcommands sethduuid $PKG/Root.vhd 54e9ad31-a169-4d5b-a0e0-705d62e96e71 2>/dev/null || true
```

## 5. Deploy（部署 → Windows）

```powershell
# win host
powershell -File scripts\g1_win_deploy.ps1
```

## 6. Boot oracle（验证）

```powershell
# win host：部署后跑（g1_win_deploy.ps1 已部署 Root.vhd；fastboot.vdi 部署见 §0）
powershell -File scripts\g1_boot_verify.ps1 -TimeoutSec 600
```

**实测（2026-07-17 porting-log cont.4，Root.vhd `2a7a497a` + 干净 Data_orig 首启）**：boot 到 launcher，host oracle 全绿 —— `Player state: ready` + `fUiHideBootProgressBar` + `plrOnActivityDisplayedHcall`；`GlueStartVM failed=0`；`hwcomposer SIGSEGV=0`。adb `topResumedActivity=com.uncube.launcher3/...HomeActivity`。（旧「期望 245s」是误记，见 porting-log cont.1 订正；fresh 首启因 ART/odsign/package scan 较慢，~600s+，迭代 boot 更快。）

> **gotcha（必读）**：① 部署后用 **干净 data** —— `Data_orig.vhdx → Data.vhdx`（copy 一份），**勿删 Data.vhdx**（VBox 需文件存在，否则 `Could not open medium Data.vhdx` → GlueStartVM fail → 卡 [Initializing]）。② 验 Root.vhd UUID 看 VHD **footer**（hexdump offset 64），**不信 `VBoxManage showhdinfo`**（显示注册表缓存值，非文件实际；r228 远程 sethduuid 也曾报成功但没真改 footer）。

## 7. 产物身份

| 项 | 值 |
|---|---|
| Root.vhd（G1 final，cont.4） | `2a7a497afd48a595758bba026faf55ae` |
| system.sfs（stage fold） | `5e151f429b2677b895b2464a8b7f6a57` |
| system.img（m droid） | `fd910a81595badb92b0de83072a82ee1` |
| Root.vhd UUID | `54e9ad31-a169-4d5b-a0e0-705d62e96e71` |
| fastboot.vdi UUID | `91b80c95-aa7d-459d-93e4-c479f5babbb7` |

## 8. temp_debt / Phase 2 待办

| 项 | 说明 |
|---|---|
| P2-PACK-148 | 148 M1 vendor/system_ext 文件 → 非 temp_debt；BlueStacks 单镜像打包模型（M1 相同）。Phase 2 从 fold 迁到正式 buildscripts 打包集成 |
| P2-TEMP-BLAST | r262 shell transitions 禁用 → 需 goldfish BLAST 修复后再开启 |
| P2-APKS-DATAFS | launcher apk + GMS → buildscripts apks 目标恢复 |
| P2-TEMP-SEPOLICY | SELinux permissive → BST sepolicy 定义后改 enforcing |
| bs_bootlog-feedback | bs_bootlog.sh kmsg↔logcat 反馈环 → 已修（grep -v A16DBG:），待测 |

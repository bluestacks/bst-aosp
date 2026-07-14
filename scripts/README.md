# scripts/ — A16 boot 脚本索引

> 作用于远程 guest 构建机 `~/aosp16` / `~/app-player`（idempotent patch + pack/deploy）。
> 问题背景：[`../progress/android-16-boot-guide.md`](../progress/android-16-boot-guide.md)
> 恢复流程：[`../patches/android-16/RESTORE.md`](../patches/android-16/RESTORE.md)

**顶层 = 最终可运行流水线**（约 70 个）。历史一次性脚本在 [`archive/`](archive/)（溯源用，不进日常流水线）。

---

## 1. 日常流水线（最常用）

| 脚本 | 用途 |
|---|---|
| `r228-pack-root.sh` | system.sfs → Root.fs → create_vdi → Root.vhd（UUID `54e9ad31-…`） |
| `make-baklava-system-sfs.sh` | staged system → mkuserimg(+file_contexts) → simg2img → mksquashfs |
| `prune-vendor-gralloc-hw.sh` | 打包前清理 vendor gralloc 冲突（被 r228 调用） |
| `r245-rebuild-fastboot.sh` / `r246` / `r247` | 重建 fastboot.vdi（kernel-a16 + initrd）|
| `r247-pack-root.sh` | 含 installd early-start 的 Root 打包（避免冲掉 r247） |
| `r254b-pack-gcall.sh` / `r250-pack-llndk.sh` | 增量打 libgcall_jni / llndk 进 Root |
| `r242-pack-selinux-root.sh` / `r243-audio-vintf-pack.sh` | SELinux xattr + audio VINTF 打包 |
| `win-replace-tiramisu64.ps1` | Windows 替换 `Engine\Tiramisu64\{Root.vhd,fastboot.vdi}` |
| `remote-capture-a16-*.sh` | 从远程抓权威 diff → `patches/android-16/` |
| `restore-a16-from-scratch.sh` | 干净树恢复辅助（配合 RESTORE.md） |

## 2. 最终产物补丁（R245–R261，仍可幂等重打）

| 阶段 | patch | rebuild |
|---|---|---|
| bstsetup / keystore data | `r245-fix-bstsetup-*.py`、`r245-wipe-keystore-data.sh` | `r245-rebuild-fastboot.sh` |
| `/metadata` tmpfs | `r246-patch-stage2-metadata.sh` | `r246-rebuild-fastboot.sh` |
| installd early-start | `r247-patch-init-installd.py` | `r247-rebuild-fastboot.sh` / `r247-pack-root.sh` |
| HintManager / Biometric skip | `r248-patch-systemserver.py` | `r248-rebuild-services.sh` |
| `/proc/config.gz` 容错 | `r249-patch-debug-configgz.py` | `r249-rebuild-runtime.sh` |
| SystemUI biometric NPE | `r251-patch-securelock.py`、`r253-patch-authcontroller.py` | `r251-rebuild-services.sh`、`r253-rebuild-systemui.sh` |
| gcall Baklava64 | `r254-patch-gcall-baklava.py` | `r254-rebuild-gcall-jni.sh` |
| WMS ActivityDisplayed | `r255-patch-wms-*.py`、`r255c-fix-wms-method.py`、**`r259-patch-activity-resumed.py`** | `r255/r259-rebuild-services.sh` |
| launcher / lockscreen | `r256`–`r258-patch-*.py` | 各自 rebuild |
| AuthService 恢复（Settings） | **`r261-patch-auth-service.py`** | `r261-rebuild-services.sh` |
| 优雅关机 | **`r260-patch-henry-shutdown.py`** | `r260-rebuild-init-shutdown.sh` |

## 3. 图形 / init / soong 支撑补丁

| 脚本 | 用途 |
|---|---|
| `patch-goldfish-emuhwc2-vsync-sp.py` | HWC2 VsyncThread → `sp<>` |
| `patch-goldfish-gl2encoder-getinternalformat-a16.py` / `patch-goldfish-glutils-a16-params.py` | GLES 3.1 查询放宽 |
| `patch-device-init-x86-renderengine-a16.py` | skiaglthreaded |
| `patch-ueventd-bluestacks-devices.py` / `patch-initsh-bstpgaipc-mknod.py` | `/dev/bstpgaipc` |
| `fix-hwsm-soong.py` / `toggle-gfxstream-soong.py` | hwservicemanager 路径冲突 / 禁 gfxstream |
| `patch-ldconfig-bs-bringup.py` | namespace `search.paths += /system/${LIB}` |
| `patch-init-henry-path.py` / `patch-init-selinux-tail.py` / `restore-init-do-exec-start.py` / `manual-relink-init.py` | init second-stage 路径 / 绕 soong relink |

## 4. 回读 oracle

| 脚本 | 用途 |
|---|---|
| `bs_bootlog.sh` | guest 串口 boot log |
| `check_logs*.ps1` / `check_state.ps1` / `check_timeline.ps1` / `check_vbox_logs.ps1` | host Player.log / BstkCore.log |
| `parse-minidump-exception.py` | host minidump（NVIDIA nvoglv64 等） |

---

## archive/ 放了什么

约 240 个历史脚本，包括：

- `patch-round*`、round8–10、henry-*（早期 bringup）
- 多轮 `patch-initsh-*` / `patch-stage2-*` / `patch-selinux-*`（已被 bootimage 快照与 AOSP diff 固化）
- NVIDIA-only 图形规避（已回退，最终用 Intel GPU）
- staging-era ART/odrefresh（`gen-boot-framework*`、`stage2-good-vhd.sh` 等）
- 被后续回合取代的 `r229`–`r244` 增量 pack/rebuild、`r252`（AuthService 误关，由 r261 纠正）

需要追溯某次回合时去 `archive/` 按文件名找即可。

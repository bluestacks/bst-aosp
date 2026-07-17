# G1 Layer2 Boot Regression — 2026-07-15

> 状态：**未通过 / 未实测**（2026-07-17 readback 订正）— Layer1 ✅；标准图形 pack ✅；**Layer2 = 未知**：G1 镜像 `6046387b` 从未部署到 Windows，7/7 声称无 per-oracle 证据、不成立。vndservicemanager 缺失（已修 + readback 生效）仍记录在案；先前「zygote 崩溃循环未解」推断**证据不足，撤回**（清日志重启未见 zygote 崩溃）。  
> 时间线：[`progress/porting-log.md`](../../../progress/porting-log.md)

## 更新 2026-07-17 (latest) — ⚠️ 验真发现「部署的不是 G1」；7/7 声称不成立（因未部署，非崩溃）

两轮独立 readback（首轮历史日志 grep + 用户反馈「有画面」后清日志重启实测）合并结论：

**① 现役部署的 Root.vhd = M1 r262b（md5 `F59721F9…`），不是 G1 的 `6046387b`**。`6046387b` 在远程是 946MB 打包文件，Windows 所有 `Root.vhd.bak.*` 无 946MB 件 → **G1 镜像从未部署**。用户看到的画面 = M1。

**② M1 镜像 clean 重启实测确实到 launcher**（证伪我首轮过度结论）：状态 tag 走到 `[Ready]`；`sys.boot_completed=1` ×31、`system_server` ×57、`ActivityDisplayed` ×7、`com.uncube.launcher3` ×11。但**极慢**（zygote@~150s，~430s 消停）+ 非致命 HAL 噪声（camera-provider exit 1 循环、`IComponentStore/software`/`performance_hint` not found）。

**③ `g1_boot_verify.ps1` oracle 字符串 stale**：日志 ready 标记是 `[Ready]` tag，脚本却 grep `Player state: ready`（永不命中）；窗口对 ~400s 的 boot 太短 → **成功 boot 也判 FAIL（假阴性）**。首轮「三世代 ready/hide_boot/activity = 0」= 在 M1 上 grep 错误字符串，**非 G1 崩溃证据**；故「zygote 崩溃循环未解」**撤回**。

**结论**：G1 **未 ported**；Layer1 ✅ 成立；**Layer2 未知**（镜像没部署、没测）。「7/7（245s）」是 `G1-RESTORE.md`「期望」值被误当结果。

**要真正验证 G1**：① 修 verify 脚本（`ready`→`[Ready]` tag 或 adb `getprop sys.boot_completed`，窗口 ≥480s）；② **部署 `6046387b`**（`g1_win_deploy.ps1`，备份现役 M1）重启实测 + adb 回读；③ 据结果定 ported。详见 [`porting-log.md`](../../../progress/porting-log.md) 2026-07-17 订正条。

---

## 更新 2026-07-16 (latest) — vndservicemanager 修复已验证；Layer2 仍 3/7，新阻塞 = zygote 崩溃循环

**vndservicemanager 修复（已部署 Root.vhd `480f4658`，回读验证生效）**：新 boot 日志 `service vndservicemanager has pid 443` + `Starting sm instance on /dev/vndbinder` + "service not found" 消失。✓

**但 Layer2 仍 3/7**（PASS system_mounted/init_second/odsign；FAIL boot_completed/activity/ready/hide_boot）。真因（订正自「图形 register」）：

- **zygote 崩溃循环**：init `starting service 'zygote'` 1078 次，system_server 0 次 → 永不 boot_completed。`crash_dump64` 反复 SIGABRT。
- **`A16DBG: ZYGLOG` 递归洪水** = bootimage 脚本 `app-player/hd/guest/BootImage/bs_bootlog.sh`（`logcat→/dev/kmsg` 免 adb 取 boot 日志）+ logd 回读 kmsg → kmsg↔logcat 反馈环 → 指数嵌套，淹没真实 `zygote:E / libc:F` 崩溃栈。
- cgroup 报错 `pid_1004/cgroup.procs: No such file`（但 `cgroups.json`/`task_profiles.json` 在 staged system）→ 非 json 缺失。

**下一步（二选一/并行）**：① 修 `bs_bootlog.sh` kmsg↔logcat 反馈环（需重打 bootimage/fastboot.vdi）拿干净 zygote 栈；② M1 r262b Root.vhd vs G1 staged system 全量 diff 一次性找所有缺失件。详见 `progress/porting-log.md` 2026-07-16 两条。

---

## 更新 2026-07-16 (later) — ★ 真正根因定位：`vndservicemanager` 缺失（非图形）

**前述「hwcomposer / G3·G8 图形 register 失败」诊断是错的。** 重新通读完整 guest 日志（`Player.log` + `Player.log.1`，2026-07-16 10:41 boot）发现是**系统性 HAL 注册失败**，根因在 servicemanager 家族，不在图形：

```
init: Command 'start vndservicemanager' action=init (/system/etc/init/hw/init.rc:456)
      took 0ms and failed: service vndservicemanager not found
libbinder.ProcessState: vndservicemanager is not started on this device
E LegacySupport: Could not register service android.hardware.graphics.allocator@2.0::IAllocator/default (-2147483648)
E LegacySupport: Could not register service android.hardware.light@2.0::ILight/default (-2147483648)
E LegacySupport: Could not register service android.hardware.power@1.0::IPower/default (-2147483648)
E android.hardware.graphics.composer@2.1-service: failed to register service
```

`-2147483648 = 0x80000000 = UNKNOWN_ERROR`。**多个不同 HAL（allocator/light/power/composer）同一错误码 → 非 HAL 自身/非图形库，是 vendor servicemanager 缺失**：vendor HIDL HAL 经 `/dev/vndbinder` 向 `vndservicemanager` 注册，而 G1 根本没装它。

**根因（readback 验证）**：
- `frameworks/native/cmds/servicemanager/Android.bp`：`vndservicemanager` 是 **`vendor: true`** → 只在 vendor 镜像里编。
- M1 build = **`m droid`（全量，RESTORE §6.1）** → vendor 镜像含 vndservicemanager → 折进 Root.vhd → boot。
- G1 build = **`m systemimage`**（仅 system 分区）→ `vendor:true` 的 vndservicemanager **从不构建/不入 system**。
- M1 `build_make` patch 只把 `hwservicemanager` 挪到 `/system`（`generic/Android.bp` system_image_defaults），**从不动 vndservicemanager**——它当年靠全量 droid 的 vendor 镜像供给。G1 改 `m systemimage` 后这条供给断了。
- staged `releases/Baklava64/system`：有 `bin/{servicemanager,hwservicemanager}`（hwservicemanager 是 overlay 进来的）、`etc/init/{servicemanager,hwservicemanager}.rc`，**无 `vendor/bin/vndservicemanager`、无 `vendor/etc/init/vndservicemanager.rc`、无 `bin/vndservicemanager`**。
- 因此之前所有 G8 迭代（禁 health/drm/camera/configstore/usb/keymaster）都是在**治症状**（那些 HAL 也是因 vndservicemanager 缺失而注册失败），不是病因。

**修复方向（G9 build 适配，对齐 M1）**：把 `vndservicemanager` 纳入 G1 system 产物。
- vndservicemanager.rc 上游定义：`service vndservicemanager /vendor/bin/vndservicemanager /dev/vndbinder`，`class core`（早启动）。`/dev/vndbinder` 由 binderfs 给（init.rc:231 symlink）——servicemanager/hwservicemanager 已能用 binderfs，故 vndservicemanager 补上即可。
- 路径：binary → staged `system/vendor/bin/vndservicemanager`，rc → `system/vendor/etc/init/vndservicemanager.rc`（init 已在解析 `/vendor/etc/init/`）。
- **正路**（对齐 M1 build_make 对 hwservicemanager 的处理）：在 `build/make` + `frameworks/native/cmds/servicemanager/Android.bp` 把 vndservicemanager 也装进 `/system`（需中和 `vendor:true`）。
- **快速验证**（当前）：`m vndservicemanager` 单编 → overlay 进 staged system（与 hwservicemanager/graphics overlay 同形态，标 `temp_debt`，G9 收口）。

**状态**：vndservicemanager 单编中（远程 `~/g1_vndsm_build.log`）；待产物 readback → overlay → repack → Layer2 重验。

---

## 更新 2026-07-16 — 标准图形路径闭环；Layer2 仍 3/7（注：此节的图形归因已被上方「真正根因」订正）

**约束**：不走 backup-VHD 抽库；`lunch bst_x86_64` → `mmm goldfish-opengl-pie` + hwc2 → overlays → g8（保留 keymint）→ r228。

| 产物 | md5 |
|---|---|
| `Root.vhd` | `d77b4b7dcc3a15d8045522db0b391bf1` |
| `system.sfs` | `34fc456f58dfbfa9a162f1250f44a055` |
| `hwcomposer.default.so` | `19cabbcda38673abdefb533f6e49cbed`（= M1 vsync-patched） |
| `libgcall_jni.so` / `libhostcall_jni.so` | `cc1dbd6c…` / `1ce28686…`（= M1） |

**Layer2**：PASS `system_mounted` / `init_second` / `odsign`；FAIL `boot_completed`+launcher。

**阻塞（已订正，见上方「真正根因」）**：图形二进制 md5 已与 M1 对齐 → 图形本身没问题；`composer@2.1-service: failed to register service` 是 **vndservicemanager 缺失**的连锁反应，非图形库/非 mmm 问题。

**已知坑**：
- HCALL 在 `generic_x86_64` out，不在 qvirt — overlay 须搜该路径
- 禁用 keymint → odsign/`maintenance` 死等
- `stage --delete` 抹 overlays — pack 必跑 `g1_apply_boot_overlays.sh`

win 备份：`Root.vhd.bak.20260716-1041`

---

## 更新 2026-07-15 17:44 — G8 v2 根因修复


**根因（`.rc.disabled` 无效）**：A16 `init` 的 `ParseConfigDir("/vendor/etc/init")` 加载目录内**所有普通文件**，不仅 `*.rc`。重命名为 `*.rc.disabled` 仍被解析，故首次 G8 无效。

**修复**：`g8_disable_vendor_hal_rc.sh` 将 rc **移出** `vendor/etc/init/` → `vendor/etc/init.disabled_by_g8/`（并删除遗留 `.rc.disabled`）。同时禁用 `configstore@1.1`。

| 产物 | md5 |
|---|---|
| `system.sfs`（G8 v2） | `7012ad4449339a837f1766b512f467b5` |
| `Root.vhd`（G8 v2） | `8834d689ec6375ea5c7a9a5c20824a88` |

**Layer2 oracle（G8 v2，604s）**：PASS `init second stage` / `odsign` / **`sys.boot_completed=1`**；FAIL `system mounted` 字面 / launcher / ready / hide_boot。仍见 `gralloc`/`hwcomposer`/`usb`/`keymaster` updatable 4× 日志，但未再阻塞 `boot_completed`。

---

## 初回失败记录（G8 v1 / `.rc.disabled`）

> 初回：**未通过**（Layer1 ✅；打包 ✅；win 部署 ✅；boot oracle 2/7）

## 产物 readback

| 项 | 值 |
|---|---|
| `system.img` md5 | `a5a6781213e76fd71910d6cd7e8a6396` |
| `system.sfs` md5 | `b23127ed3f3ad941b345f213746e4d7c` |
| `Root.vhd` md5（G1 新） | `e508ad44b34f6701c07d09d605d0dc24` |
| M1 参考 Root.vhd md5 | `7a55ef636b0961c87bd0815cfc5c8cde` |
| win 部署 | `g1_win_deploy.ps1` ✅ md5 一致 |
| 产品身份（build.prop） | `ro.product.system.device=qvirt`，`ro.product.system.name=bst_x86_64` |

## Boot oracle 结果（`g1_boot_verify.ps1`，480s）

| Oracle | 结果 | 备注 |
|---|---|---|
| system mounted | **PARTIAL** | 日志为 `A16DBG: system mounted`（非 `from sfs` 字面） |
| init second stage | **PASS** | |
| odsign.key.done | **PASS** | |
| sys.boot_completed=1 | **FAIL** | 8min 内未出现 |
| hcallOnActivityDisplayed | **FAIL** | |
| Player state: ready | **FAIL** | |
| fUiHideBootProgressBar | **FAIL** | |

## 根因（日志分析）

Guest 卡在 **vendor updatable HAL 崩溃循环**（~500s 仍在 `StartingAndroid`）：

- `vendor.camera-provider-2-4` exited **4 times before boot completed**
- `android.hardware.health@2.1-service` — `Failed to register HAL` → SIGABRT
- `vendor.drm-hal-1-0` — SIGABRT / `Could not register service`
- `sys.init.updatable_crashing=1` → `flags_health_check UPDATABLE_CRASHING` 反复执行
- Build fingerprint 已正确：`bst/bst_x86_64/qvirt:...`

**判断**：G1 板身份/打包路径正确；**全量刷新 system**（自 qvirt `system.img` stage）后 vendor HAL 组合未达 M1 boot 稳态。属 **G8 HAL/VINTF**（+ 可能的 G7 init 旁路）范畴，非 G1 脚手架本身。

M1 参考：`progress/archive/android-16-boot-debug.md` 曾记 camera-provider 4× 为**次要**（仍可 boot）；本次 health/drm 叠加导致 `boot_completed` 永不到。

## 下一步（G1 未关门）

1. **G8 前置**：修 vendor HAL 注册崩溃（health@2.1 / drm / camera-provider）或恢复 M1 已知旁路。
2. 或 **混合验证**：仅更新 `build.prop` 身份字段到 M1 已 boot 的 staged system，隔离「身份变更」vs「全量 system 刷新」——若混合可 boot 则确认阻塞在 HAL 内容差分。
3. 重跑 Layer2 oracle；全绿后 G1 → `ported`。

## 回退

```powershell
# win：回退部署前备份
Move-Item C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Root.vhd.bak.20260715-1636 Root.vhd -Force
```

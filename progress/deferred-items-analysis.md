# Deferred 移植项详细分析

> 生成于 2026-07-25 cont.87。每条含：原始 patch、用途、新方案设计、影响评估、是否可不做。

---

## D1. frameworks/base services/core 热路径（ATS/PMS/AM/WM）

### 涉及文件 + a13 改动
| 文件 | a13 行数 | BST 功能 |
|---|---|---|
| ActivityTaskSupervisor.java | 164 | `bstSpecialAppKeyboardHandlingEnabled`（特殊 app 键盘处理开关）；`_removeTask`/`_removeTaskById` 贯穿 `isBstRequest`/`isBstForceKill` 参数（task 强杀）；`BstFilterAppsManager.isForceKillApp()` 查询 |
| PackageManagerService.java | 204 | `mBstfilter` 初始化（BST_FILTER_APPS service）；`firstBootAfterUpgradeFile`（升级后首次启动检测）；`bstUninstallPkgList`（BST 卸载包列表）；BST referrer 统计上报 |
| ActivityManagerService.java | ~60 | BST referrer/GPStats 上报标签；`getMemoryInfo`/`onLocaleChanged` BST hooks（cont.23 AM-1 revert）|
| ActiveServices.java | ~15 | 隐藏 BST 内部 service 不暴露给第三方 app 的 `getServices` 查询 |
| DisplayContent.java | ~20 | `mBstFilterApps` 旋转策略（cont.23 WM-2 revert；cont.21 APP-17 Display rotation kill-switch 已部分解决）|

### 用途
- **task 强杀**：BST host (hd.exe) 通过 `removeTaskWrapper(taskId, isBstRequest=true)` 强制杀 app 进程（绕过 Android 正常 task removal 流程，确保 app 完全关闭）
- **PM 升级检测**：首次启动后升级标记（控制 dexopt/权限重置等）
- **PM BST 包卸载列表**：BST 预装 app 的卸载管理
- **AM referrer 上报**：Google Play install referrer 上报到 BST cloud
- **ActiveServices 隐藏**：防止第三方 app 通过 `getServices` 枚举 BST 后台 service
- **DisplayContent 旋转**：per-app 旋转覆盖（cont.21 APP-17 Display.java kill-switch 已部分 port）

### a16 阻塞
- **ATS**: a16 `removeTask` 重构为 `callingUid/callingPid` 参数签名（a13 `isBstRequest/isBstForceKill` 不映射）；`cleanUpRemovedTaskLocked` 在 a16 不存在（重构为 `removeTask` 内联）
- **PMS**: a16 PMS 拆分为 `PackageManagerService` + `ComputerEngine`/`InitAppsHelper`/`InstallPackageHelper`/`RemovePackageHelper`/`PermissionManagerServiceImpl`/`DexOptHelper`/`PackageAbiHelperImpl`（a13 全在一个类）
- **AM**: a16 AM lifecycle 重构（cont.23 AM-1 getMemoryInfo/onLocaleChanged 实测 Layer2 3/7 回归 → revert）
- **DisplayContent**: a16 DisplayContent + DisplayRotation 重构（cont.23 WM-2 实测 Layer2 3/7 → revert）

### 新方案设计
1. **ATS task 强杀**: a16 `removeTask` 新增 `isBstRequest` 透传参数，或用 `persist.bst.force_kill_task=<taskId>` property + init trigger 实现（避改 ATS 签名）
2. **PM 升级/卸载**: a16 用 `ComputerEngine`/`RemovePackageHelper` 新类替代 PMS 内联逻辑，BST 逻辑下沉到 helper 层
3. **AM referrer**: a16 用 `BroadcastReceiver` 监听 install referrer 替代 AMS 内联 hook
4. **ActiveServices 隐藏**: 已有 `BstUtils.hideBlueStacksPkg`（FW-WM-1 ported）；ActiveServices 补充枚举过滤
5. **DisplayContent 旋转**: cont.21 APP-17 Display.java kill-switch 已部分 port（`bst.enable_display_rotation` property gate）；剩余 DisplayContent 层 hook 用 kill-switch 方式

### 影响评估
- **不做 task 强杀**: BST host 无法强制杀 app → 用户关 app 后残留进程 → 内存泄漏风险（中影响）
- **不做 PM 升级检测**: 升级后首次启动行为可能异常（低影响，G1 未用此功能 boot）
- **不做 AM referrer**: BST cloud 缺少 install referrer 数据（低影响，analytics only）
- **不做 ActiveServices 隐藏**: 第三方 app 可枚举 BST service（低-中影响，反检测）
- **不做 DisplayContent**: 已有 Display.java kill-switch 覆盖核心旋转（低影响）

### **是否可不做**: **部分可不做**。task 强杀（中影响，建议做）；其余低影响，可暂不做。

---

## D2. PointerIcon（鼠标指针显示控制）

### 原始 patch
```java
// a13 core/java/android/view/PointerIcon.java
boolean showTouches = Settings.System.getInt(..., SHOW_TOUCHES, 0) == 1;
boolean showNativeMousePointer = SystemProperties.getBoolean("bst.config.show_mouse_ptr", false);
if (showTouches || showNativeMousePointer) {
    if (type == TYPE_NULL) { return gNullIcon; }
} else { /* 不返回 null icon，显示 Android 默认指针 */ }
```

### 用途
BST host 控制是否显示 Android 原生鼠标指针（`bst.config.show_mouse_ptr`）。当 BST 自己画鼠标指针时，隐藏 Android 原生指针（返回 null icon）。

### a16 阻塞
a16 `getSystemIcon(int type)` 用 **SYSTEM_ICONS 缓存**（static map）替代 a13 的 `if(type==TYPE_NULL) return gNullIcon`。a16 无 `gNullIcon` 静态变量；逻辑反转（a13：默认 null，条件不 null；a16：默认缓存 icon）。

### 新方案设计
在 a16 `getSystemIcon` 中加 `bst.config.show_mouse_ptr` gate：
- 当 `show_mouse_ptr=true` → TYPE_NULL 返回缓存 icon（显示）
- 当 `show_mouse_ptr=false` → TYPE_NULL 返回 null/透明 icon（隐藏，BST 自己画）

### 影响评估
- **不做**: BST 鼠标指针可能双重显示（Android 原生 + BST 自画）→ 视觉异常（低-中影响，UI only）

### **是否可不做**: **可以暂不做**。纯 UI 视觉问题，不影响功能。

---

## D3. SystemUI 截图保存到共享文件夹

### 原始 patch
```java
// a13 SaveImageInBackgroundTask.java
private void bstSaveFileInSharedFolder(String fileName, Uri uri) {
    File dest = new File("/mnt/windows/BstSharedFolder/" + fileName);
    // copy screenshot to Windows shared folder
}
BstHostCallManager hcallManager = getSystemService(BST_HOST_CALL);
hcallManager.onScreenshotSaved(result.fileName);
```

### 用途
截图后自动复制到 Windows 共享文件夹 `/mnt/windows/BstSharedFolder/`，并通知 BST host。

### a16 阻塞
a14-a16 SystemUI 截图管线完全重写（`SaveImageInBackgroundTask` 无 `result.fileName`/`doInBackground` 结构；新架构用 `ScreenshotController` + coroutine pipeline）。

### 新方案设计
在 a16 新截图管线的 `ScreenshotController.onFinish` 回调中注入 BST 保存逻辑 + `onScreenshotSaved` hostcall。

### 影响评估
- **不做**: 截图不自动保存到 Windows 文件夹；用户需手动导出（低影响，便利性 feature）

### **是否可不做**: **可以不做**。便利性功能，不影响核心运行。

---

## D4. ActivityManager.removeTaskWrapper（aidl 契约）

### 原始 patch
```java
// a13 ActivityManager.java (client)
public void removeTaskWrapper(int taskId, boolean isBstRequest) {
    getService().removeTaskWrapper(taskId, isBstRequest);
}
// a13 IActivityManager.aidl
void removeTaskWrapper(int taskId, boolean isBstRequest);
// a13 ActivityTaskSupervisor.java (server)
void _removeTask(..., boolean isBstRequest) { ... }
```

### 用途
BST host 通过 binder 调用 `removeTaskWrapper(taskId, true)` 强制杀 app（普通 `removeTask` 不杀进程，`isBstRequest=true` 杀进程）。

### a16 阻塞
需要修改 `IActivityManager.aidl`（添加 binder 方法）+ AMS 实现 + ATS 实现。ATS 在 a16 重构（见 D1）。

### 新方案设计
方案 A（改 aidl）：加 `removeTaskWrapper` 到 aidl + 实现（需 ATS re-arch 配合）。
方案 B（property trigger）：用 `persist.bst.force_kill_task=<taskId>` property + init `on property` trigger 调用 `am force-stop`（不碰 aidl）。

### 影响评估
- **不做**: BST host 无法强制杀 app 进程（同 D1 task 强杀；中影响）

### **是否可不做**: **与 D1 绑定**。D1 做了则此项也做；D1 不做则此项也不做。

---

## D5. IMMS setBstIME（aidl 契约）

### 原始 patch
```java
// a13 InputMethodManagerService.java
private String mBstImeId;
private void setBstIME() {
    setInputMethodEnabledLocked(mBstImeId, true);
    updateFromSettingsLocked(true);
    setInputMethodLocked(mBstImeId, -1);
}
public void setBstIMEFromClient(String imeId) {
    mBstImeId = imeId;
    mHandler.sendEmptyMessage(MSG_SET_IME);
}
```

### 用途
BST host 动态切换 IME（如 LatinIME ↔ BST IME）。

### a16 阻塞
需要修改 `IInputMethodManager.aidl`（添加 `setBstIMEFromClient` binder 方法）+ IMMS 实现 + MSG_SET_IME handler。已 port 的 onImeChange（cont.53）+ text-edit-mode（cont.54）覆盖了核心键盘映射功能，setBstIME 是额外的动态 IME 切换。

### 新方案设计
方案 A（改 aidl）：加 `setBstIMEFromClient` 到 aidl + IMMS handler。
方案 B（property trigger）：`persist.bst.ime=<imeId>` + IMMS `onPropertyChange` 监听切换。

### 影响评估
- **不做**: BST host 无法动态切换 IME；onImeChange + text-edit-mode 已覆盖键盘映射核心（低影响）

### **是否可不做**: **可以暂不做**。核心键盘映射已 port，setBstIME 是补充功能。

---

## D6. build/make mk config（PRODUCT_PACKAGES 修改）

### 原始 patch
```makefile
# a13 build/make/core/binary.mk
# 注释掉 C_INCLUDES 检查（允许 hd/ 目录 include）
#my_outside_includes := $(filter-out $(OUT_DIR)/%,$(filter /%,$(my_c_includes)))
#ifneq ($(my_outside_includes),)
#  ... pretty-error ...
#endif

# a13 build/make/target/product/handheld_system.mk
# 删除 BasicDreams/BluetoothMidiService/BuiltInPrintService/ManagedProvisioning/MmsService

# a13 build/make/target/product/runtime_libart.mk
PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false
```

### 用途
1. binary.mk：允许 hd 模块（在 AOSP 树外部）的 include 路径
2. handheld_system.mk：精简镜像（删除不需要的 app）
3. runtime_libart.mk：关闭 ART debug build（减小镜像体积）
4. security keys：BST 签名密钥

### a16 阻塞
a16 release-config 框架对 product-definition mk 文件改动敏感——PRODUCT_PACKAGES 增删触发 release config 重新求值，dumpvars 找不到 release mapping（cont.68 实测）。

### 新方案设计
1. binary.mk C_INCLUDES：a16 已有 `BUILD_BROKEN_OUTSIDE_INCLUDE_DIRS=true` 等效机制（在 device mk 设）
2. PRODUCT_PACKAGES 删除：改用 `PRODUCT_PACKAGES_REMOVE := BasicDreams ...`（a16 新机制）
3. ART debug：在 device mk 设 `PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false`
4. security keys：放到 `device/bst/qvirt` 层（不碰 build/make 上游）

### 影响评估
- **不做**: 镜像体积略大（含不需要的 app + ART debug）；签名用默认 key（低影响）

### **是否可不做**: **可以暂不做**。核心功能不受影响，只是镜像不够精简。

---

## D7. SF Scheduler bst.max_fps

### 原始 patch
```cpp
// a13 frameworks/native/services/surfaceflinger/Scheduler/Scheduler.cpp
char prop[PROP_VALUE_MAX] = {0};
property_get("bst.max_fps", prop, "0");
int fps = atoi(prop);
if (fps > 0) {
    setVsyncPeriod((nsecs_t)1e9 / fps);
    return;
}
```

### 用途
BST host 通过 `bst.max_fps` property 限制 guest 最大帧率（省电/性能控制）。

### a16 阻塞
a16 Scheduler 完全重构：`setVsyncPeriod(nsecs_t)` 不存在（a13 API）。a16 用 mode-based 的 `onDisplayModeChanged(modePtr)` + `setVsyncConfig(VsyncConfig, Period)` 体系。

### 新方案设计
在 a16 `resyncToHardwareVsyncLocked` 中：
1. 读 `bst.max_fps` property
2. 如 > 0，构造 `DisplayMode` with `fps = Fps(max_fps)` 覆盖 `modePtr`
3. 调用 `schedulePtr->onDisplayModeChanged(modified_modePtr)`

需理解 a16 `DisplayMode`/`DisplayModePtr` 构造方式。

### 影响评估
- **不做**: 无法通过 property 限制帧率（guest 以默认 60fps 运行）（低影响，性能优化 feature）

### **是否可不做**: **可以暂不做**。性能优化 feature，不影响功能。

---

## D8. TM subscription（fake-SIM 基础）

### 原始 patch
```java
// a13 TelephonyManager.java
public static SubscriptionInfo mBstSubscriptionInfo = null;
private void createSubInfoInstance() {
    // 从 BST properties 构造 fake SubscriptionInfo
    mBstSubscriptionInfo = new SubscriptionInfo(1, iccId, 0, "SIM 1", "T-Mobile", ...);
}
```

### 用途
构造一个 fake SIM 订阅记录，让第三方 app 看到「有 SIM 卡」（反检测）。

### a16 阻塞
a16 `getActiveSubscriptionInfoList()` 在 `SubscriptionManager`（非 TelephonyManager）+ `SubscriptionController` 类在 a16 重构（不存在）+ metalava `@RequiresPermission` API 契约约束（cont.58 PERIPH-8 实测 check_current_api fail）。

### 新方案设计
方案 A：在 `SubscriptionController` 替代类（a16 `SubscriptionManagerService`）中注入 fake subscription（需理解 a16 subscription 架构）。
方案 B：用已有的 telephony 反检测（operator + LTE + device-id + PhoneSubInfoController + UiccProfile SIM READY）覆盖核心需求；subscription 级别的 fake 用 property-based approach（`getActiveSubscriptionInfoCount` 返回 1）。

### 影响评估
- **不做**: 第三方 app 检测到「无 SIM 卡」→ 某些 app 限制功能（中影响，但已有 operator/LTE/device-id/IMEI/SIM-READY 反检测覆盖大部分检测）

### **是否可不做**: **可以暂不做**。已有 6 层 telephony 反检测（operator/LTE/device-id/IMEI/UiccProfile-READY/PhoneSubInfoController），subscription fake 是第 7 层补充。

---

## D9. frameworks/native binder C++ 实现（3670 行）

### 原始 patch
```
BstFilterAppsManager.cpp (683行) + IBstFilterAppsService.cpp (2498行)
BstUtilsManager.cpp (58行) + IBstUtilsService.cpp (109行)
IBstFilterAppsService.h (268行) + IBstUtilsService.h (54行)
```

### 用途
C++ binder 客户端，连接 framework 层 Java BST service（BstFilterAppsService/BstUtilsService）。允许 native 代码（frameworks/av camera、SurfaceFlinger 等）通过 binder 调用 BST 服务（获取 per-app 配置、app 名称等）。

### a16 阻塞
a13→a16 binder 协议变更（a16 用 binderndk / ABinder 新协议）。3670 行 C++ binder 代码（含生成的 proxy/stub）跨版本移植非机械。

### 当前替代方案
已创建 **stub 头文件**（BstFilterAppsManager.h + BstUtilsManager.h），所有方法 fail-open 返回 false/空（MECH-9/10）。frameworks/av camera 旋转等 C++ BST hooks 编译通过但运行时 no-op（stub 不连接 Java service）。

### 新方案设计
方案 A：用 a16 binderndk 重新生成 IBstFilterAppsService/IBstUtilsService 的 C++ proxy/stub（需要 Java AIDL 定义 → aidl-cpp 生成）。
方案 B：用 property-based IPC 替代 binder（BST Java service 写 property，C++ 读 property；已有先例：bst.config.* property 体系）。

### 影响评估
- **不做（stub 维持）**: camera 旋转 per-app 无效（所有 app 用默认旋转）；IMediaSource multi-read 无法 per-game 禁用；其他 native BST hooks no-op（低-中影响，影响特定游戏兼容）

### **是否可不做**: **可以暂不做**。stub fail-open 保证 boot + 基本功能；per-app camera/media 定制是游戏兼容优化，非核心。

---

## 总结优先级

| Deferred 项 | 影响 | 建议优先级 |
|---|---|---|
| D1+D4 ATS task 强杀 | **中**（host 无法强杀 app） | **建议做** |
| D9 binder C++ 实现 | **低-中**（per-app camera/media no-op） | 可暂不做 |
| D8 TM subscription fake-SIM | **低**（已有 6 层反检测） | 可暂不做 |
| D2 PointerIcon | **低**（UI 双指针） | 可暂不做 |
| D3 SystemUI 截图共享 | **低**（便利性） | 可暂不做 |
| D5 IMMS setBstIME | **低**（核心键盘映射已 port） | 可暂不做 |
| D6 build/make mk | **低**（镜像不够精简） | 可暂不做 |
| D7 SF bst.max_fps | **低**（性能优化） | 可暂不做 |
| D1 其余（PM/AM/ActiveServices） | **低**（analytics/反检测） | 可暂不做 |

---

## 状态更新 (2026-07-26 cont.101) — D8/D9 已 PORTED，D3 已设计

| 项 | 状态 | commit / 产物 | 验证 |
|---|---|---|---|
| **D8** TM subscription | ✅ **PORTED** | `00274255beb7` frameworks/base telephony (getActiveSubscriptionInfoCount→1 when enable_telephony) | Layer2 7/7 @161s, system.img a878d3c8 |
| **D9** binder C++ | ✅ **PORTED** | `c581b1bae8` frameworks/native/libs/binder (3670行真实现替换 stub，6 机械修) | Layer2 7/7 @161s |
| **D3** 截图共享 | 📐 **DESIGN ONLY** | `progress/d3-redesign.md`（注入点 ScreenshotController.kt:508；三块 A/B/C；hostcall/挂载待决策） | 未实施（待用户决策） |
| pagefusion (bonus) | ✅ PORTED | `2cf8a0cf64c5` frameworks/base cmds/pagefusion (PAGE_SIZE 本地 define) | Layer2 7/7 @161s |

**D8 解阻塞**：原 BLOCKED 因 `getActiveSubscriptionInfoList` drop `@RequiresPermission` → check_current_api fail。新方案用 `getActiveSubscriptionInfoCount`（int 返回、无注解）返回 1，绕过。
**D9 解阻塞**：原 BLOCKED 因「a16 binder protocol」。实测 libbinder C++ API 仍在（binderndk 是并行非替代）；6 机械修闭环（详见 porting-log cont.97-99）。camera/SF 等 C++ BST hooks 现 runtime 连真 Java BST service。
**patch（本地）**：`aosp16__frameworks_native_libs_binder.patch` + `aosp16__frameworks_base__d8-subscription.patch` + `aosp16__frameworks_base__pagefusion.patch`（patches/android-16/patches/）。

**⚠️ 附带发现（escalation）**：frameworks/base 16 个 BST 文件（ActivityStarter/ATMS/WMS/SystemServer/Transitions/BstUtils/dimens 等）在 verified root 6cbb275f 里但**源码从未 commit**（pre-existing source-vs-commit drift）。本次只选择性 commit 了 D8+pagefusion（我的工作）。需各自 owner 收口。

---

## D3 决策（2026-07-26 cont.102）：**DEFER 到虚拟化 port 阶段**

用户决策：D3（SystemUI 截图→Windows 共享文件夹）**延迟**到虚拟化 port 阶段再做。
- 理由：D3 的块 C（`/mnt/windows/BstSharedFolder` 挂载点）依赖 host 虚拟化（win `vbox`/mac `qvm`）暴露给 guest 的共享文件夹，当前 Phase 2 不含虚拟化 port（[[host-guest-contract]]：vbox/qvm 暂不纳入）。
- 现在做 guest 侧（块 A+B）= 门控默认关的 no-op 代码（host 挂载未就绪前 copy 必失败、catch 吞异常），价值低。
- 设计文档 `progress/d3-redesign.md` 保留，待虚拟化 port 阶段直接落地块 A+B（property 门控开启即生效）。
- registry 标 `port_status: deferred`、`host_compat: pending`（虚拟化侧）。

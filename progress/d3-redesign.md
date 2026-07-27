# D3 重设计方案 — SystemUI 截图保存到 Windows 共享文件夹

> 生成于 2026-07-25 cont.96。用户要求 D3「重新设计方案」。本文是**设计计划**，非实施记录。
> 状态：**DESIGN ONLY**（待 D8/D9 收敛后实施）。当前未改任何 a16 源码。

---

## 1. a13 原始意图（要 port 什么）

a13 在 `SaveImageInBackgroundTask.java` 里做两件事（见 [deferred-items-analysis.md](deferred-items-analysis.md) §D3）：

```java
// a13 SaveImageInBackgroundTask.java (截图管线旧架构，a14 起被移除)
private void bstSaveFileInSharedFolder(String fileName, Uri uri) {
    File dest = new File("/mnt/windows/BstSharedFolder/" + fileName);
    // 把刚保存的截图复制到 Windows 共享文件夹
}
BstHostCallManager hcallManager = getSystemService(BST_HOST_CALL);
hcallManager.onScreenshotSaved(result.fileName);  // 通知 BST host
```

**目的**：截图后自动复制到 Windows 共享文件夹 `/mnt/windows/BstSharedFolder/`，并通知 BST host（hd.exe）做后续处理（如弹通知/同步）。

## 2. a16 阻塞（为何旧 patch 不能直接 apply）

- a14–a16 SystemUI 截图管线**完全重写**：`SaveImageInBackgroundTask` 类已删除。
- 新架构（Kotlin）：`ScreenshotController.kt` + `ImageExporter.java` + coroutine/`ListenableFuture` pipeline。
- 旧 patch 的锚点（`SaveImageInBackgroundTask` 的 `doInBackground` / `result.fileName` 字段）全部不存在。

## 3. a16 新架构调研结果（已 readback）

### 3.1 保存路径
- **`ImageExporter.java`**（`frameworks/base/packages/SystemUI/src/com/android/systemui/screenshot/`）：
  - `export(executor, requestId, bitmap, ...) → ListenableFuture<Result>`
  - 内部 `Task` 把 bitmap 写入 MediaStore（ContentResolver insert + openOutputStream + compress）。
  - **`Result` 类（ImageExporter.java:241）含 `public Uri uri`（:242）+ `public String fileName`（:244）** —— 保存成功后这两个字段就是 BST 要的。

### 3.2 注入点（已定位，精确）
- **`ScreenshotController.kt:508` `saveScreenshotInBackground(...)`**：
  ```kotlin
  val future = imageExporter.export(bgExecutor, requestId, screenshot.bitmap, ...)
  future.addListener({
      val result = future.get()              // <-- Result 到手，uri + fileName 可用
      Log.d(TAG, "Saved screenshot: $result")
      logScreenshotResultStatus(result.uri, screenshot.userHandle)
      onResult.accept(result)
      // <<< BST 注入点：在此之后 >>>
  }, ...)
  ```
- `ScreenshotController.kt:458` 另一处 `result: ImageExporter.Result ->` 分支（toast 路径）同理。

### 3.3 hostcall / 共享文件夹基础设施（已 readback：a16 树中**不存在**）
- grep `BstSharedFolder|/mnt/windows` 在 `frameworks/base/{services,core}`、`system/core/init`、`device/bst` —— **0 命中**。
- grep `BstHostCall|BST_HOST_CALL|onScreenshotSaved` —— **0 命中**。
- 结论：a16 树**没有** `BstHostCallManager` 类，也**没有** `/mnt/windows` FUSE 挂载点。这两者是 a13 BST 的 host 侧设施，本仓库（guest）尚未 port。

## 4. 重设计方案（三块，按依赖顺序）

### 块 A — guest 侧截图复制（最小可做，本仓库范围）
在 `ScreenshotController.kt` 注入点加 BST 块，**property 门控**（默认关，避免破坏未配 host 的镜像）：

```kotlin
// future.addListener 内，onResult.accept(result) 之后：
// A16DBG:P2:DEF BST screenshot → Windows shared folder (a13; gated)
if (result.uri != null && android.os.SystemProperties
        .getBoolean("bst.config.screenshot_shared_folder", false)) {
    bgExecutor.execute {
        try {
            val fileName = result.fileName ?: "screenshot.png"
            val src = context.contentResolver.openInputStream(result.uri)
            val dest = java.io.File("/mnt/windows/BstSharedFolder", fileName)
            dest.parentFile?.mkdirs()
            src?.use { it.copyTo(dest.outputStream()) }
            android.util.Log.i("A16DBG", "P2:DEF screenshot copied to $dest")
            // host 通知（见块 B）
        } catch (e: Exception) {
            android.util.Log.w("A16DBG", "P2:DEF screenshot copy failed: ${e.message}")
        }
    }
}
```
- 门控 `bst.config.screenshot_shared_folder`（默认 false）→ 不配 host 时不执行、不影响 boot。**temp_debt**：host 设施未就绪前是死代码（路径不存在→copy 抛异常→catch 吞掉→no-op），须双重标注。

### 块 B — host 通知机制（设计抉择，需决策）
a13 用 `BstHostCallManager.onScreenshotSaved(fileName)`。a16 树无此类。两条路：

| 方案 | 做法 | 代价 | 取舍 |
|---|---|---|---|
| **B1 广播**（推荐） | guest 发 `bst.intent.SCREENSHOT_SAVED` 广播带 `fileName`；host 侧 hd 监听 | 低，纯 guest 改 + host 加 receiver | 不依赖 binder hostcall 类；与已 port 的 `bst.intent.SET_IME`（DEF-4 cont.91）同模式 |
| B2 property | `SystemProperties.set("bst.status.last_screenshot", fileName)` + host 轮询 | 极低 | 轮询有延迟，不优雅 |
| B3 复刻 BstHostCallManager | 在 frameworks/base 重建 a13 hostcall binder 类 | 高 | 过度工程，hostcall 本就是 binder 包装，B1 广播更轻 |

**推荐 B1**：与现有 DEF-4 IMMS broadcast 模式一致，最小 guest 改动，host 侧后续在 `hd` 加 receiver。

### 块 C — `/mnt/windows` 挂载（host/虚拟化侧，本仓库外）
`/mnt/windows/BstSharedFolder` 是 BST host 通过虚拟化（win `vbox` / mac `qvm`）暴露给 guest 的共享文件夹挂载点。这属 **host-guest 契约**（[host-guest-contract.md](../.claude/rules/host-guest-contract.md)）：
- 当前 Phase 2 范围**不含**虚拟化设备模型 port（`vbox`/`qvm` 暂不纳入）。
- 因此块 C = **显式挂账**，标 `host_compat: pending`，等虚拟化 port 阶段。
- 在那之前，块 A 的 copy 会因路径不存在而 no-op（catch 吞异常），不破坏 boot。

## 5. 影响评估 + 是否值得做

| 维度 | 评估 |
|---|---|
| 不做 | 截图不自动进 Windows 文件夹；用户手动导出（**低影响**，便利性 feature） |
| 做块 A+B1 | guest 侧 ~20 行 Kotlin + 1 个广播；host 侧 receiver 后续；**门控默认关**，零 boot 风险 |
| 块 C 阻塞 | 虚拟化未 port → 路径不存在 → 即使做了也是 no-op（**功能不可用直到 host 侧就绪**） |

**结论**：D3 是**便利性 feature，非核心**。块 C（共享文件夹挂载）依赖虚拟化 port，Phase 2 不做。**建议**：仅落地块 A+B1 的 guest 侧代码（门控默认关 + temp_debt 标注 + host_compat pending），让功能在 host 侧就绪后可一键开启；或**整体 defer 到虚拟化 port 阶段**。→ **需用户决策**（见下）。

## 6. 待决策（escalation）

1. **D3 现在做 guest 侧（块 A+B1，门控默认关）还是整体 defer 到虚拟化阶段？**
   - 现在做：~20 行，零 boot 风险，但功能在 host 就绪前不可用（no-op）。
   - defer：省工作量，等 `/mnt/windows` 挂载 port 进来再做（功能立即可用）。
2. host 通知用 **B1 广播**（推荐）还是 B2 property？

## 7. 验证计划（实施时）

- Layer 1：`m droid` 编译过 SystemUI（SystemUI 是大模块，编译慢但 Layer1 强制）。
- Layer 2：截图后 `logcat` grep `A16DBG:P2:DEF screenshot copied`（路径不存在时 grep `screenshot copy failed`）。host 挂载就绪前功能 no-op 属预期。
- 因门控默认关 + catch 吞异常 → **不构成 boot 风险**，Layer2 只验「不破坏现有 7/7」。

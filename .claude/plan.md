# Plan — Phase 2 guest 全量功能对齐（2026-07-22 cont.25 — 基线 7/7 恢复）

> 唯一活跃阶段；host / Phase 3 **暂不规划**。权威：`progress/phase2-port-plan.md` · `progress/porting-log.md`。

## 目标
按 `patch-porting.md` 把 a13 定制 **功能对齐**到 a16（非机械子集关门）。win Layer1+Layer2；mac 同码不独立验。

## 已完成（证据）
1. **Shell Transitions / r262**：补 `android.hardware.power-service.example` + 恢复 HintManager；Root **`840137ca`** Layer2 7/7；registry r262 → `removed`。
2. **SELinux**：对齐 a13 permissive；`enabled.c→0` **blocked**。
3. **FW-WM-1**：ActivityStarter `hideBlueStacksPkg` + ATM `getGlVersion`；patch 存档；树内保留；曾 Layer2 7/7（Root `4571efb3`）。
4. **P3 prebuilts**：dropped。

## 阻断 / 进行中
1. ~~Win Data 污染~~：**已解** — Root `eb309e6c` + Data `wipe20260717` → **Layer2 7/7 @118s**（cont.25）。热路径回归是 Data 污染，非 WM-1 代码。
2. **frameworks**：`win-frameworks-base` = `in_progress`；gap≈55（core/java 22 / services/core 25 含 PM 族 8 / SystemUI·SettingsProvider·telephony·accessibility·core/jni 共 8）。FW-WM-2 / FW-AM-1 **revert + escalate**。

## 下一步（基线已恢复，开始 port）
1. **FW-CORE-APP**：core/java 22 文件 app 框架 BST hooks（Activity/ActivityThread/ContextImpl/View/ViewRootImpl/TextView/Editor/InputManager/Environment/Settings/NativeLibraryHelper…）。a13 fork-diff（base `android-13.0.0_r49`）→ surgical apply a16 → Layer1 `m framework` → 灌 systemimage → Layer2 7/7。
2. 每次失败 boot **先 cp `wipe20260717`→Data.vhdx 恢复**再继续（Data 污染是已知陷阱）。
3. 热路径（FW-AM/FW-WM-2/GRM/PM 族）基线稳固后带 persist.bst.* kill-switch 小切片重做。

## 权威 Root（md5 前缀）
| md5 | 备注 |
|---|---|
| `840137ca` | cont.22b 绿 |
| `4571efb3` | FW-WM-1 曾绿（后被 Data 掩盖） |
| `eb309e6c` | 当前权威（WM-1 only） |
| `4e144a82` / `2d2a3f80` | 坏（勿用） |

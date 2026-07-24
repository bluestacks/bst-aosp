# Summary — Phase 2「guest 功能对齐」维度关门（2026-07-24 cont.63）

## 权威状态

| 项 | 值 |
|---|---|
| 权威 Root | **`848e9737`**（11 ports，Layer2 **7/7 @136s**）|
| commit | MECH-1: hw/interfaces `23fb8db6` + system/core `65a7b230` |
| core/java | **22/22** ✅ |
| services/core peripheral | **9/21** + IMMS 键盘映射核心 |
| extra peripheral | **8**（a11y 三层 / telephony 反检测齐全 / vibrator / codec / telephony-perms）|

## Phase 2 功能对齐关门（已达成）
core/java 22/22 + a11y hide 三层 + telephony 反检测(operator/LTE/device-id) + IMMS 键盘映射 + peripheral app hooks + services/core peripheral。

## 剩余统一 defer 挂账（cont.63，需 design-investment）
- **A defer**：boot-critical 热路径 PM族/AM/WM（kill-switch design + 干净基线小切片）
- **B defer**：aidl 契约 ActivityManager.removeTaskWrapper / IMMS setBstIME
- **C defer**：re-arch PointerIcon/SystemUI 截图/ATS force-kill/TM subscription（a16 重构，须重设计落点）
- **D dropped**：WallpaperManager msi5（缺资产）
- **E defer**：SystemUI TunerServiceImpl（deps 缺）
- **F blocked**：external/selinux（intentional permissive）

机械+安全移植阶段正式关门。剩余按风险/契约/资产分类显式挂账，后续逐项 design 启动。

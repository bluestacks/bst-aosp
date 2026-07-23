# Summary — Phase 2 进行中（2026-07-24 cont.61 — FW-PERIPH-7 ✅，a11y hide 三层）

## 权威状态

| 项 | 值 |
|---|---|
| 权威 Root | **`848e9737`**（叠 至 PERIPH-7，Layer2 **7/7 @136s**）|
| commit | `776749bcfac3` |
| core/java | **22/22** ported ✅（+ 8 extra peripheral）|
| services/core | **9/21** gap ported（IMMS onImeChange + text-edit-mode = 键盘映射核心）|

## 本 session 完成（cont.50-61，11 verified ports + 1 reverted→fixed）

- SERVICES-5 AccessibilityManagerService（a11y hide service-list）@153s
- PERIPH-1 SystemVibrator + MediaCodecInfo @131s
- PERIPH-2 TelephonyPermissions @123s
- SERVICES-6/6b IMMS onImeChange + text-edit-mode（键盘映射核心）
- PERIPH-3/4/5 telephony 反检测齐全（operator+LTE+device-id-uid-gated）
- PERIPH-6/7 SettingsProvider + SettingsService a11y hide（setting 单读 + bulk-read，三层）
- ❌→✅ PERIPH-3b/5 device-id（无条件破 boot→uid-gated 修复）

## Phase 2 下一主体（机械 peripheral 已尽）

- **剩余 drift（dedicated）**：PointerIcon(TYPE_NULL 重排，re-arch)、WallpaperManager(缺 msi 资源)、SystemUI TunerServiceImpl(deps 缺)
- **escalate（规则：热路径/IPC/契约 判断性）**：PM族/AM/WM boot-critical、ActivityManager(aidl 契约)、TM subscription(re-arch)、IMMS setBstIME(aidl)
- **Recents orientation** escalate；Display rotation 功能验证 `bst.enable_display_rotation=1`

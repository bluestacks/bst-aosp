# Summary — Phase 2 进行中（2026-07-24 cont.60 — FW-PERIPH-6 ✅）

## 权威状态

| 项 | 值 |
|---|---|
| 权威 Root | **`02c94d60`**（叠 至 PERIPH-6，Layer2 **7/7 @126s**）|
| commit | `6022b14e0e73` |
| core/java | **22/22** ported ✅（+ 7 extra peripheral）|
| services/core | **9/21** gap ported（IMMS onImeChange + text-edit-mode = 键盘映射核心）|

## 本 session 完成（cont.50-60，10 verified ports + 1 reverted→fixed）

- SERVICES-5 AccessibilityManagerService（hide a11y service-list）@153s `89f7d262`
- PERIPH-1 SystemVibrator + MediaCodecInfo @131s `7c1801fb`
- PERIPH-2 TelephonyPermissions @123s `9160b488`
- SERVICES-6/6b IMMS onImeChange + text-edit-mode（键盘映射核心）@131/123s `d63b9c98`/`990813b3`
- PERIPH-3/4/5 telephony 反检测齐全（operator+LTE+device-id-uid-gated）@197/169/126s
- ❌→✅ PERIPH-3b/5 device-id（无条件破 boot→uid-gated 修复）
- PERIPH-6 SettingsProvider a11y setting 过滤（drift 适配，a11y hide 双层）@126s `6022b14e`

## Phase 2 下一主体

- **剩余 drift**：PointerIcon(TYPE_NULL 重排)、WallpaperManager(缺 msi 资源)、SystemUI TunerServiceImpl(deps 缺)
- **escalate（规则：热路径/IPC/契约 判断性）**：PM族/AM/WM boot-critical、ActivityManager(aidl 契约)、TM subscription(re-arch)、IMMS setBstIME(aidl)
- **Recents orientation** escalate；Display rotation 功能验证 `bst.enable_display_rotation=1`

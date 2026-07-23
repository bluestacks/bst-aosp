# Summary — Phase 2 进行中（2026-07-23 cont.58 — FW-PERIPH-5 ✅，telephony 反检测齐全）

## 权威状态

| 项 | 值 |
|---|---|
| 权威 Root | **`45bf8e14`**（叠 至 PERIPH-5，Layer2 **7/7 @126s**）|
| commit | `76c0a7930b55` |
| core/java | **22/22** ported ✅（+ 6 extra peripheral）|
| services/core | **9/21** gap ported（IMMS onImeChange + text-edit-mode = 键盘映射核心）|

## 本 session 完成（cont.50-58，9 verified ports + 1 reverted→fixed）

- FW-SERVICES-5 AccessibilityManagerService（hide a11y）@153s `89f7d262`
- FW-PERIPH-1 SystemVibrator + MediaCodecInfo @131s `7c1801fb`
- FW-PERIPH-2 TelephonyPermissions（phone-state bypass）@123s `9160b488`
- FW-SERVICES-6 IMMS onImeChange @131s `d63b9c98`
- FW-SERVICES-6b IMMS text-edit-mode（键盘映射核心）@123s `990813b3`
- FW-PERIPH-3 TelephonyManager operator 伪装 @197s `09ecb823`
- ❌→✅ PERIPH-3b/5 TM device-id（3b 无条件破 boot→revert；5 uid-gated boot-safe）@126s `76c0a793`
- FW-PERIPH-4 ServiceState LTE @169s `078ef5ce`

**telephony 反检测齐全**：operator + LTE + device-id(uid-gated)

## Phase 2 下一主体

- **TM subscription**（createSubInfoInstance）：消费者移 SubscriptionManager，re-arch defer
- **IMMS 余量**（aidl）：setBstIME + MSG_SET_IME
- defer：WallpaperManager（缺资源）、PointerIcon/InputManager/SettingsProvider（drift）、SystemUI TunerServiceImpl（deps 缺）
- **Recents orientation** escalate；热路径 PM/AM/WM 谨慎 kill-switch slice；Display rotation 功能验证 `bst.enable_display_rotation=1`

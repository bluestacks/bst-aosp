# Summary — Phase 2 进行中（2026-07-23 cont.57 — FW-PERIPH-4 ✅）

## 权威状态

| 项 | 值 |
|---|---|
| 权威 Root | **`1ccc2a81`**（叠 至 PERIPH-4，Layer2 **7/7 @169s**）|
| commit | `078ef5ce084f` |
| core/java | **22/22** ported ✅（+ 5 extra peripheral）|
| services/core | **9/21** gap ported（IMMS onImeChange + text-edit-mode = 键盘映射核心）|

## 本 session 完成（cont.50-57，8 verified ports + 1 reverted）

- FW-SERVICES-5 AccessibilityManagerService（hide a11y）@153s `89f7d262`
- FW-PERIPH-1 SystemVibrator + MediaCodecInfo（whatsapp h264）@131s `7c1801fb`
- FW-PERIPH-2 TelephonyPermissions（phone-state bypass）@123s `9160b488`
- FW-SERVICES-6 IMMS onImeChange host 通知 @131s `d63b9c98`
- FW-SERVICES-6b IMMS text-edit-mode（键盘映射核心）@123s `990813b3`
- FW-PERIPH-3 TelephonyManager operator 伪装（反检测）@197s `09ecb823`
- ❌ FW-PERIPH-3b TM device-id "01"（regression 3/7，reverted，cont.56）
- FW-PERIPH-4 ServiceState getDataNetworkType→LTE（反检测 gated）@169s `078ef5ce`

## Phase 2 下一主体

- **telephony 反检测**：operator（PERIPH-3）+ LTE（PERIPH-4）在位；device-id 须 conditional（PERIPH-3b 教训）；subscription 需 re-arch（消费者移 SubscriptionManager）
- **IMMS 余量**（低优先，aidl）：setBstIME + MSG_SET_IME
- defer：WallpaperManager（缺资源）、PointerIcon/InputManager/SettingsProvider（drift）、SystemUI TunerServiceImpl（deps 缺）
- **Recents orientation** escalate；热路径 PM/AM/WM 谨慎 kill-switch slice；Display rotation 功能验证 `bst.enable_display_rotation=1`

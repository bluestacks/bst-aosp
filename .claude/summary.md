# Summary — Phase 2 进行中（2026-07-23 cont.54 — FW-SERVICES-6b ✅）

## 权威状态

| 项 | 值 |
|---|---|
| 权威 Root | **`74592b9f`**（叠 至 SERVICES-6b，Layer2 **7/7 @123s**）|
| commit | `990813b39f9a` |
| core/java | **22/22** ported ✅（+ SystemVibrator/MediaCodecInfo/TelephonyPermissions extra peripheral）|
| services/core | **9/21** gap ported（IMMS onImeChange + text-edit-mode 两子集在位 = 键盘映射核心功能）|

## 本 session 完成（cont.50-54）

- **FW-SERVICES-5** AccessibilityManagerService filterHiddenServices → 7/7 @153s；`89f7d262`
- **FW-PERIPH-1** SystemVibrator + MediaCodecInfo（whatsapp h264）→ 7/7 @131s；`7c1801fb`
- **FW-PERIPH-2** TelephonyPermissions（phone-state bypass）→ 7/7 @123s；`9160b488`
- **FW-SERVICES-6** IMMS onImeChange host 通知（bounded）→ 7/7 @131s；`d63b9c98`
- **FW-SERVICES-6b** IMMS text-edit-mode（bstSendSetInputMapperStatusAsync + show/hide，键盘映射核心）→ 7/7 @123s；`990813b3`

## Phase 2 下一主体

- **IMMS 余量**（低优先）：setBstIME/setBstIMEFromClient + MSG_SET_IME（需 aidl 加方法）；@4076 auto-show 分支 drift
- defer：WallpaperManager（缺资源）、PointerIcon/InputManager（drift）、SettingsProvider（drift）、SystemUI TunerServiceImpl（deps 缺）
- **Recents orientation** escalate；热路径 PM/AM/WM 谨慎 kill-switch slice；Display rotation 功能验证 `bst.enable_display_rotation=1`

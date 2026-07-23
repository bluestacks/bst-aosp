# Summary — Phase 2 进行中（2026-07-23 cont.53 — FW-SERVICES-6 ✅）

## 权威状态

| 项 | 值 |
|---|---|
| 权威 Root | **`43895325`**（叠 至 SERVICES-6，Layer2 **7/7 @131s**）|
| commit | `d63b9c983ac1` |
| core/java | **22/22** ported ✅（+ SystemVibrator/MediaCodecInfo/TelephonyPermissions extra peripheral）|
| services/core | **9/21** gap ported（+ IMMS onImeChange bounded）|

## 本 session 完成（cont.50-53）

- **FW-SERVICES-5** AccessibilityManagerService filterHiddenServices（hide BST a11y）→ 7/7 @153s；commit `89f7d262`
- **FW-PERIPH-1** SystemVibrator + MediaCodecInfo（whatsapp h264）→ 7/7 @131s；commit `7c1801fb`
- **FW-PERIPH-2** TelephonyPermissions（phone-state bypass: wog + devicedetails）→ 7/7 @123s；commit `9160b488`
- **FW-SERVICES-6** InputMethodManagerService onImeChange host 通知（bounded 子集，lazy-init）→ 7/7 @131s；commit `d63b9c98`

## Phase 2 下一主体

- **IMMS 续做**（dedicated）：bstSendSetInputMapperStatusAsync（text-edit-mode/password）+ setBstIME + MSG_SET_IME + show/hide call site（deps 全在位，需逐 hunk 适配 a16 bindingController）
- defer：WallpaperManager（缺 default_wallpaper_msi 资源）、PointerIcon（drift）、InputManager（逻辑移 InputManagerGlobal）、SettingsProvider（drift）、SystemUI TunerServiceImpl（deps 缺）
- **Recents orientation** escalate；热路径 PM/AM/WM 谨慎 kill-switch slice；Display rotation 功能验证 `bst.enable_display_rotation=1`

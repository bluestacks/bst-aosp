# Plan — Phase 2 FW-SERVICES（2026-07-23 cont.49）

## 已完成

1. **FW-CORE-APP**：22/22 core/java ✅（APP-1~17；Root `4bf3f4ad` → APP-17 `437704b9`）
2. **FW-SERVICES 1a~4a**：services/core **7/21** gap ✅
   - 1a Clipboard / 1b Location / 2b NMS / 2a ComponentResolver / 3 AccountManager / 4a Audio+AppOps
3. Layer2 工具：`g1_boot_verify.ps1` 增扫 `Player.log.1`；Data `wipe20260717` 纪律

## 进行中

- services/core 余 **14 gap**（InputMethod/InputManager → PM 族 → AM/WM 热路径）
- FW-WM-2 / FW-AM-1：revert + escalate（热路径）

## 下一批（FW-SERVICES-5）

- InputMethodManagerService：IME 切换 host 通知、password input、keyboard mapper
- InputManagerService：pan enable/disable、`bstReloadPointerIcon`

## defer / escalate

- RecentsAnimationController：a16 refactor，orientation hook 待 research
- Display rotation 功能验证：`bst.enable_display_rotation=1` 单独 Layer2

## 权威 Root

| md5 | 内容 |
|---|---|
| **`a551d823`** | SERVICES 1a/1b/2a/2b/3/4a（当前绿基线）|
| `3d3a7997` | SERVICES-3 AccountManager |
| `4bf3f4ad` | APP-17 完成 core/java 22/22 |
| `840137ca` | performance_hint / Shell Transitions |

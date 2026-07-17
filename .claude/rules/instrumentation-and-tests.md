# 埋点与测试（每次修改）

# 每次改动有意识加入**可独立回读的埋点**和**测试/断言**，避免「改了但看不见、
# 只能靠猜」。对齐核心原则：Verify by readback, not by acknowledgement。

## Trigger

写任何 guest/host 脚本、init、framework、HAL、打包脚本、或调试补丁时。

## 埋点约定

1. **日志前缀**：guest bringup / boot 路径用 `A16DBG:`（已在 boot-guide 使用）；子系统可用 `A16DBG:<area>:`（如 `A16DBG:sfs:`、`A16DBG:hcall:`）。
2. **埋点位置**：关键分支点（mount 成功/失败、exec 前后、HAL 注册、ActivityDisplayed、关机 trigger）。
3. **可 grep**：埋点字符串必须能在串口 / `bs_bootlog` / host `Player.log` / `BstkCore.log` 中用固定模式搜到。
4. **成对**：成功与失败各一条（或显式 rc），禁止只打「开始」不打结果。
5. **临时债**：`temp_debt` 相关 bypass 必须打 WARNING 级埋点（便于 Phase 2 收口时盘点）。

## 测试 / 断言

每个 patch-group 至少满足：

| 层 | 最小要求 |
|---|---|
| Layer 1 | 远程 build exit code + 产物存在（mtime/size/md5 任一） |
| Layer 2（并入 boot 时） | boot oracle 子集，见下 |

**Boot 回归 oracle（权威清单）**——来自 `progress/android-16-boot-guide.md` / `patches/android-16/RESTORE.md` §7：

1. `A16DBG: system mounted from sfs`
2. `init second stage started!`
3. `odsign.key.done` + `odrefresh ... returned 80`
4. bootanim exit 0 + `sys.boot_completed=1`
5. `hcallOnActivityDisplayed com.uncube.launcher3` → `Player state: ready` → `fUiHideBootProgressBar`
6. `service check auth` → found（Settings 可起）
7. Settings 可见：SF `Transition Root`=0 或 TEMP R262 说明仍在位
8. 优雅关机：`bst.config.start_shutdown=1` → `Exiting err: 0`，无 20s `Forcing power down`

adb / 属性回读断言优先于「看起来启动了」。UI 验证不做单像素；见 `validation-gate.md`。

## 记录

埋点字符串与 oracle 结果写入该组的 registry `verification` 字段 + `progress/porting-log.md`。跳过某测须说明原因与补救步骤——**绝不未跑就声称 gate 通过**。

# 构建命令（Build Commands）

> Phase 0 探测（2026-06-17）部分填实；manifest URL / lunch 目标待人类确认。

## guest 完整 AOSP 树（远程 `markxu@172.16.6.191`，root `~/aosp16`）

- **manifest**：上游 `https://android.googlesource.com/platform/manifest` `-b android-16.0.0_r4`（revision `android-16.0.0_r4`，247G）。
- **sync 状态**：✅ 完成（`repo sync -c -j4`，`SYNC_EXIT=0`）。首次 `-j8` 因 googlesource 配额失败，降 `-j4` 重试成功。
- **lunch 目标（统一板方案，已采纳）**：两端共用 BlueStacks 板 `device/bst/qvirt`，仅 arch 不同：
  - **mac** → `lunch bst_arm64-userdebug`（arm64；板源 `android-mac/device/bst/qvirt`）。
  - **win** → `lunch bst_x86_64-userdebug`（x86_64；新增 product 变体；win 不再用 cuttlefish/generic）。
  - 依据：两端虚拟化均实现 qvirt 设备（mac `qvm`、win `hd/Source/{vmsg,hst,gr}`）+ `hardware/bst/*` HAL 两端都有。Phase 1 = port 单一 `device/bst/qvirt` 到 android-16（arm64+x86_64 双 product）。详见 architecture.md。

```bash
# 状态检查（无 sleep，快速）
ssh markxu@172.16.6.191 'cat ~/aosp16_sync_exit 2>/dev/null && echo DONE || echo RUNNING; pgrep -af "repo sync" | head -1; tail -n 12 ~/aosp16_sync.log'

# 构建（sync 完成后）—— lunch 目标待定制清单
ssh markxu@172.16.6.191 'cd ~/aosp16 && bash -lc "source build/envsetup.sh && lunch <target> && m <module>"'
# 全量镜像: m dist → out/dist/*.img；迭代清理: installclean
```

- 产物：`~/aosp16/out/target/product/<device>/*.img`、`~/aosp16/out/dist/`。

## guest kernel（已 checkout）

- **win**：`~/kernel-common-a13/`（remote `bluestacks/kernel-common-a13.git`，分支 `aosp13-sync`）。
- **mac**：`~/kernel-mac/`（remote `bluestacks/kernel-mac.git`，分支 `bst-v5.0.0-nxt_mac2`）。
- 内核构建命令（`build.config.*` + `build.sh`）待确认（按 Android GKI/common kernel 流程）。

## host 使用的镜像产出（guest 就绪后）

参考 `C:\workspace\app-player` 仓库编译脚本，把 AOSP 构建产物产出 host 使用的镜像（格式/打包以 app-player 脚本为准）。【Phase 2 填具体步骤】

## host 构建（本地）

- **win**：`C:\workspace\app-player`（完整）/ `app-player-dev`（最小）—— `build.bat` / `build_simple.bat`。
- **mac**：`C:\workspace\qvm`（QEMU fork）——【Phase 2 填构建命令】。

## 验证 gate（见 ../.claude/rules/validation-gate.md）

- Layer 1：readback exit code + `ls -la out/target/product/<device>/*.img`。
- Layer 2：见 [boot-oracles.md](boot-oracles.md)（需虚拟化就位）。

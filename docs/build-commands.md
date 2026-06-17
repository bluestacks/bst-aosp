# 构建命令（Build Commands）

> Phase 0 探测（2026-06-17）部分填实；manifest URL / lunch 目标待人类确认。

## guest 完整 AOSP 树（远程 `markxu@172.16.6.191`）

**状态：完整 AOSP 树尚未拉取**（HOME 下目前只有两个 kernel）。Phase 0 待 `repo init`/`sync`。

```bash
# 拉代码（首次）—— manifest URL / branch 待人类确认
ssh markxu@172.16.6.191 'cd ~ && repo init -u <manifest-url> -b <branch> && repo sync -j8'
# （跟进 android-16 r5/r6 时人工触发 fetch）

# 构建（完整 AOSP 树）—— lunch 目标 / 设备待人类确认
ssh markxu@172.16.6.191 'cd <remote-root> && bash -lc "source build/envsetup.sh && lunch <target> && m <module>"'
# 全量镜像: m dist → out/dist/*.img
# 迭代清理: installclean（比 m clean 轻）
```

- **manifest URL / branch / lunch 目标 / 设备**：【待确认——自定义板形态？goldfish/cuttlefish？】
- 产物：`out/target/product/<device>/*.img`、`out/dist/`。

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

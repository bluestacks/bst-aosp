---
description: 远程 lunch + m 构建，后台化 + 回读日志/exit code/产物
allowed-tools: Bash(ssh:*), Bash(scp:*), Read, Write, CronCreate, CronDelete, CronList
---
在远程 Ubuntu 主机跑 AOSP 构建，按 `.claude/rules/remote-build.md` 后台化、断线可恢复。

## 步骤

1. **选主机**：从 `docs/remote-topology.md` 取 guest 构建机（`<host>`）与远程根（`<remote-root>`）、lunch 目标（`<target>`）、设备（`<device>`）。Phase 0 未填则先确认（escalate）。

2. **发起后台构建**（单次 `bash -lc` 保证 envsetup 持久）：
   ```bash
   ssh <host> 'cd <remote-root> && nohup bash -lc "source build/envsetup.sh && lunch <target> && m <module>; echo EXIT=\$? > /tmp/build_exit" > /tmp/build.log 2>&1 & echo PID=$!'
   ```
   记下 PID 与 `/tmp/build.log`、`/tmp/build_exit` 路径到 summary。

3. **轮询**：用 `CronCreate` 排程（如每 10 分钟）：
   ```bash
   ssh <host> 'ps -p <pid> >/dev/null && echo RUNNING || echo DONE; tail -n 50 /tmp/build.log; cat /tmp/build_exit 2>/dev/null'
   ```

4. **完成回读**（readback，非信任）：读 `/tmp/build_exit` 的真实 exit code + `ls -la out/target/product/<device>/*.img`（mtime）+ `tail -n 100 build.log`。**EXIT=0 且产物存在才算 Layer 1 过。**

5. **断线恢复**：SSH 断了不杀 nohup 进程；重连先 `ps -p <pid>` + `tail` 恢复观测，不重发命令。

## 注意

- 全量 `m dist` 走 prompt 确认（耗时巨大）。
- 迭代清理用 `installclean`（比 `m clean` 轻）；全量 `m clean` 需用户确认。
- 大镜像**不**回传本体，只回传 log + `ls -la` + 远程路径。

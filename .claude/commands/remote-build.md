---
description: 远程 lunch + m 构建，后台化 + 回读日志/exit code/产物
allowed-tools: Bash(ssh:*), Bash(scp:*), Read, Write
---
在远程 Ubuntu 主机跑 AOSP 构建，按 `.claude/rules/remote-build.md` 后台化、断线可恢复。

## 步骤

1. **选阶段和主机**：默认 current mainline，`<remote-root>=~/android-16`。
   只有明确 historical replay 才能选择 `~/aosp16`。从
   `docs/remote-topology.md` 取 guest 构建机、lunch 目标和设备。

2. **身份预检**：
   ```bash
   ssh <host> 'bash ~/bst-aosp/scripts/g1_build_android16.sh --check'
   ```
   保存 resolved tree、branch、HEAD、OUT_DIR 和 product；任一不符即停止。

3. **发起后台增量构建**（单次 `bash -lc` 保证 envsetup 持久）：
   ```bash
   ssh <host> 'nohup sh -c '\''bash ~/bst-aosp/scripts/g1_build_app_player.sh --incremental --jobs 8; rc=$?; printf "%s\n" "$rc" > ~/android16-incremental.rc; exit "$rc"'\'' > ~/android16-incremental.log 2>&1 < /dev/null & echo PID=$!'
   ```
   记下 PID 与 log/rc 路径到 summary。保留
   `out_nxt_Baklava64`，不允许默认 clean/installclean。

4. **轮询**：手动回读已记录的 PID/log/rc，不建立定时任务：
   ```bash
   ssh <host> 'ps -p <pid> >/dev/null && echo RUNNING || echo DONE; tail -n 50 /tmp/build.log; cat /tmp/build_exit 2>/dev/null'
   ```

5. **完成回读**（readback，非信任）：读 `/tmp/build_exit` 的真实 exit
   code、产物、SHA-256 和 identity sidecar。**EXIT=0、产物存在且 sidecar
   HEAD 与预检一致才算 Layer 1 过。**

6. **断线恢复**：SSH 断了不杀 nohup 进程；重连先 `ps -p <pid>` + `tail` 恢复观测，不重发命令。

## 注意

- 当前主线仅运行增量入口，不设启动时间门槛或编译完成超时。
- `installclean`、`m clean`、删除 OUT 和全量 `m dist` 都需用户单独明确授权。
- 大镜像**不**回传本体，只回传 log + `ls -la` + 远程路径。

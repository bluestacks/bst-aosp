# 远程 SSH 构建/同步（Remote Build）

# guest 源码与编译都在远程 Ubuntu 主机。远程构建是常态、断线是常态。规则把「后台化 +
# log 落盘 + 断线恢复」作为一等公民，避免 SSH 会话挂掉丢掉数小时的构建。

## Trigger

任何需要 build / `repo sync` / 取产物 / 跑设备命令的时刻。

## Check

1. **主机选择**：从 [docs/remote-topology.md](../../docs/remote-topology.md) 选对主机（guest AOSP 全量构建机 ≠ host 构建机 ≠ 调试/启动机）。目标不可达 → **立即 escalate**，不切到错误主机凑数。
2. **后台化**：超过 ~3 分钟的命令（几乎所有 `m`、`repo sync`、`m dist`）一律
   ```bash
   ssh <host> 'cd <remote-root> && nohup bash -lc "...cmd..." > <abs-log> 2>&1 & echo $!'
   ```
   记下返回的 **PID + log 绝对路径**到 summary。
3. **断线恢复**：SSH 断开**不杀**远程 nohup 进程。重连第一步永远是恢复观测，而非重发命令：
   ```bash
   ssh <host> 'ps -p <pid> && tail -n 50 <abs-log>'
   ```
4. **轮询**：用 `CronCreate` 排程周期 `ssh <host> 'tail -n 50 <log>; ps -p <pid>'`；进程退出后回读 exit code（`wait`/日志末尾）+ 产物 `ls -la`。
5. **环境持久性**：`source build/envsetup.sh && lunch <target>` 必须在**同一个** `bash -lc` 调用里——SSH 每次开新 shell，envsetup 不跨调用持久。
6. **产物**：大镜像（GB 级）**不回传本体**，只回传 log + `ls -la` + 远程路径；小产物（patch diff、单模块产物）可 scp。
7. **清理**：迭代用 `installclean`；全量 `m clean` 极慢，需用户确认。

## 反模式（禁止）

- 在交互式 SSH 会话里前台跑 `m`（会话断了就丢）。
- 不记 PID/log，靠「再跑一次」恢复。
- 切到一台不确定角色的主机凑数。
- 把 GB 级镜像 scp 回本地。

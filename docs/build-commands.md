# 构建命令（Build Commands）

> Phase 0 待填 lunch 目标 / 设备 / manifest。以下为模板。

## guest 完整 AOSP 树（远程）

```bash
# 拉代码（首次 / 跟进）
ssh <host> 'cd <remote-root> && repo init -u <manifest-url> -b <branch> && repo sync -j8'
# （跟进 android-16 r5/r6 时人工触发 fetch）

# 构建
ssh <host> 'cd <remote-root> && bash -lc "source build/envsetup.sh && lunch <target> && m <module>"'
# 全量镜像: m dist → out/dist/*.img
# 迭代清理: installclean（比 m clean 轻）
```

- **lunch 目标 / 设备 / manifest**：【Phase 0 确认——goldfish? cuttlefish? 自定义板?】
- 产物：`out/target/product/<device>/*.img`、`out/dist/`。

## host 使用的镜像产出（guest 就绪后）

参考 `C:\workspace\app-player` 仓库编译脚本，了解如何把 AOSP 构建产物产出 host 使用的镜像（镜像格式 / 打包方式以 app-player 脚本为准）。【Phase 2 填具体步骤】

## host 构建

- **win**：`C:\workspace\app-player`（完整）/ `app-player-dev`（最小）—— `build.bat` / `build_simple.bat`。
- **mac**：`qvm`（QEMU fork）——【Phase 2 填构建命令】。

## 验证 gate（见 rules/validation-gate.md）

- Layer 1：readback exit code + `ls -la out/target/product/<device>/*.img`。
- Layer 2：见 [boot-oracles.md](boot-oracles.md)（需虚拟化就位）。

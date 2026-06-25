# kernel-a16 reset 记录

## 操作（2026-06-25）
- markxu `~/aosp16/kernel-a16` 从 henry worktree 副本（含本地修改）**reset 到干净树**。
- `git reset --hard HEAD` → HEAD `686f860abf3a` (bst-v5.22.210)，`git status` 完全干净。
- 代码文件 `arch/x86/kernel/setup.c`、`fs/bst_hooks.h` 恢复为 HEAD 版本（henry 的本地修改已剥离到 patch）。

## henry 本地修改保存位置（reset 前抓取）
- **本目录 `20-kernel-a16-working.patch`**（6.0K，159 行）：含 setup.c + bst_hooks.h 真实代码 diff + prebuilts/configs/tests gitlink 指针变化。
- clouddev 双保险：`~/kernel-a16-local-changes.patch` + `~/kernel-a16-status-before-reset.txt`。

## 恢复 henry 修改（需要时）
```bash
cd ~/aosp16/kernel-a16
git apply references/android-16-boot-patches/20-kernel-a16-working.patch
# 或 patch -p1 < 20-kernel-a16-working.patch
```

## 当前 kernel-a16 状态
- 分支：`bst-v5.22.210` @ `686f860abf3a`（与 henry HEAD 一致）
- worktree：干净（无本地修改）
- 完整 git：源码 1.3G + gitdir `.git_kernel` 3.1G（自包含，core.worktree 已修正）

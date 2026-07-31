---
description: AOSP16 绿基线 promotion 到 Android-16 主线：freeze→audit→compare→target validate→publish
allowed-tools: Bash(ssh:*), Bash(scp:*), Read, Write, Edit, Agent, Grep, Glob, WebFetch
---

按 `docs/development-workflow/promotion.md` 执行。Promotion 是已验证开发线
合入主线，不是重新从 Android 13 做零散 port。

## 1. Freeze

只读冻结 AOSP16 的项目 branch、HEAD、dirty 和 patch identity。dirty 或
缺项目时停止；不得边 merge 边继续改 development 线。

## 2. Audit Target

```bash
python3 scripts/audit_android16_promotion.py audit \
  --root ~/android-16 --enforce-recorded-baseline
```

初始 promotion 基线要求 1016/1016 初始化、985 × `aosp16-bst`、
31 × `aosp16-bst-merge`、无 detached/dirty/gitlink mismatch。

## 3. Compare and Review

逐项目比较 freeze 与 target。每个冲突记录：双方语义、选择、必要性、
性能、兼容性和验证方式。25Q4 mainline 基础设施与 r4 workaround 冲突时
必须按 judgment finding 升级，禁止机械覆盖整文件。

## 4. Target-Only Gate

先跑 `g1_build_android16.sh --check`，再从同一 HEAD build、stage、pack、
deploy、boot。任何 identity HEAD 不一致或 `~/aosp16/out*` 输入都失败。

## 5. Publish Readback

先推组件 `mark-bst:aosp16-bst-merge`，校验远程 branch tip 等于根 gitlink；
再更新根仓并提交到 `bluestacks/android-16:aosp16-bst` PR。回读 PR 的 root
SHA、组件 SHA、changed files、conflicts 和验证 identity 后才完成。

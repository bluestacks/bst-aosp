# AOSP16 Development Timeline

> Generated index over the original porting and boot-debug records. Source records remain unchanged.

Indexed records: **645**.

| Source | Line | Date | Cont | Rounds | Record |
|---|---:|---|---:|---|---|
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1) | 1 |  |  |  | 移植时间线（Porting Log） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L7) | 7 |  |  |  | YYYY-MM-DD — <patch-id> (<platform>) |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L20) | 20 | 2026-06-18 |  |  | 2026-06-18 — Phase 0 定制 triage 完成（win+mac） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L30) | 30 | 2026-06-18 |  |  | 2026-06-18 — lunch target / 板：win 与 mac 不可统一（已确认） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L37) | 37 | 2026-06-18 |  |  | 2026-06-18 — 采纳统一板方案 device/bst/qvirt（bst_arm64 + bst_x86_64） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L45) | 45 | 2026-06-18 |  |  | 2026-06-18 — 路线修订 + 环境设置（三端） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L53) | 53 | 2026-06-22 |  |  | 2026-06-22 — Phase 1 启动：win android-13 基线构建发起 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L62) | 62 | 2026-06-22 |  |  | 2026-06-22 — 子模块版本对齐 .1033(win)/.7526(mac) + 构建重启 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L69) | 69 | 2026-06-22 |  |  | 2026-06-22 — win android-13 基线构建失败（soong bootstrap，sqlite 模块重复） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L76) | 76 | 2026-06-22 |  |  | 2026-06-22 — 树状态根因定位 + 对齐 ~/android-13 到 .1033 pin |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L83) | 83 | 2026-06-22 |  |  | 2026-06-22 — 同时对齐 android-mac 到 .7526 pin + 清单推迟 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L89) | 89 | 2026-06-23 |  |  | 2026-06-23 — 干净重置：app-player 分支 + android-13 子模块（全本地 objects） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L105) | 105 | 2026-06-23 |  |  | 问题 1：recursive init 卡在 `packages/modules/BootPrebuilt/5.4/arm64`（2026-06-23） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L111) | 111 | 2026-06-23 |  |  | 问题 2：`build/envsetup.sh` 不存在 → 构建立即失败（2026-06-23） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L117) | 117 |  |  |  | 规则：子模块 init 后需切到对应分支 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L121) | 121 | 2026-06-22 |  |  | 2026-06-22 — 阻塞：submodule update 遇不可访问仓库（Repository not found） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L131) | 131 | 2026-06-22 |  |  | 2026-06-22 — `-a13` 根因 + 容忍式 update（跳过无 bst fork） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L139) | 139 | 2026-06-23 |  |  | 2026-06-23 — win android-13 编译全过程（问题与修复记录） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L143) | 143 |  |  |  | 问题 A：`build/envsetup.sh` 不存在（构建立即失败） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L147) | 147 |  |  |  | 问题 B：`device/generic/common/x86_64.mk` 缺失（22s 失败） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L152) | 152 |  |  |  | 问题 C：sqlite 模块重复定义（soong bootstrap） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L156) | 156 |  |  |  | 问题 D：arm64 内核预编译 Android.bp 缺源 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L160) | 160 |  |  |  | 问题 E：ggl/goldfish-opengl-pie 等 8 个子模块未 init |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L164) | 164 |  |  |  | 问题 F：内核编译 pahole 被 PATH 限制拦截（核心编译阻塞） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L170) | 170 |  |  |  | 问题 G：子模块在 detached HEAD（非分支） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L174) | 174 |  |  |  | 关键经验 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L181) | 181 | 2026-06-24 |  |  | 2026-06-24 — ✅ Root.vdi + fastboot.vdi 打包成功 + Windows 替换 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L197) | 197 | 2026-06-24 |  |  | 2026-06-24 — ✅ APK 编译三问题全部解决 + launcher 注入镜像重打包 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L199) | 199 |  |  |  | 三个 APK 问题的真正根因与修复 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L216) | 216 |  |  |  | 镜像 apk 完整性 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L220) | 220 |  |  |  | ⚠️ 坑：make Root.vdi 全量重编 → 改用 `make -o` 定向重打包 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L227) | 227 |  |  |  | ⚠️ 启动风险（未闭环） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L230) | 230 | 2026-06-25 |  |  | 2026-06-25 — ✅✅ Win Tiramisu64 镜像启动到 launcher（里程碑） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L234) | 234 |  |  |  | 关键根因：VBox Power up failed = UUID 不匹配（非 guest 问题） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L243) | 243 |  |  |  | make_vdi_file 的 clonehd 偶发失败 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L247) | 247 |  |  |  | 固化脚本（防重复踩坑） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L253) | 253 |  |  |  | 全流程命令（固化后） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L255) | 255 |  |  |  | clouddev: 全量重编(android 变了, ~4h) |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L259) | 259 |  |  |  | Windows: 替换 + 启动 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L264) | 264 | 2026-06-24 |  |  | 2026-06-24 — app-player-mac 子模块初始化（clouddev，并行 win 重打包） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L274) | 274 | 2026-06-25 |  |  | 2026-06-25 — android-16 win 编译启动准备：henry boot patches 抓取 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L278) | 278 |  |  |  | 关键：必须用 henry 身份跑 repo diff |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L282) | 282 |  |  |  | 抓取结果 → `references/android-16-boot-patches/`（commit 56cab66） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L292) | 292 |  |  |  | kernel-a16 复制到 markxu `~/aosp16/kernel-a16` |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L297) | 297 |  |  |  | 下一步（kernel gitdir 复制完成后） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L303) | 303 | 2026-07-14 |  |  | 2026-07-14 — ✅✅ M1：android-16 win boot 到 launcher + 优雅关机 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L313) | 313 | 2026-07-15 |  |  | 2026-07-15 — 回归结构化主线 · 进入 Phase 1 清单融合移植 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L326) | 326 | 2026-07-15 |  |  | 2026-07-15 — 计划 review · 修正 6 项问题（开 G1 前） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L339) | 339 | 2026-07-15 |  |  | 2026-07-15 — G1 启动 · 统一板脚手架（进行中） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L353) | 353 | 2026-07-15 |  |  | 2026-07-15 — G1 Layer1 构建 + 配置等价验证 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L364) | 364 | 2026-07-15 |  |  | 2026-07-15 — G1 Layer1 成功 + HAL 修复 + Layer2 打包进行中 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L382) | 382 | 2026-07-15 |  |  | 2026-07-15 — G1 Layer2 boot 回归 ❌（vendor HAL 崩溃循环） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L392) | 392 | 2026-07-15 |  |  | 2026-07-15 — G8 v2：vendor rc 移出 init 目录 → `boot_completed` ✅ |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L407) | 407 | 2026-07-15 |  |  | 2026-07-15 — M1 隔离测试：参考镜像仍可 boot（非 host 回归） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L422) | 422 | 2026-07-15 |  |  | 2026-07-15 — G8 v3：补齐 `.rc.disabled` 清扫 + usb-hal |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L430) | 430 | 2026-07-15 |  |  | 2026-07-15 — G8 v3 打包 + 根因：stage 清空 M1 overlay |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L447) | 447 | 2026-07-15 |  |  | 2026-07-15 — 图形根因：G1 缺 goldfish 图形链（M1 有） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L470) | 470 | 2026-07-16 |  |  | 2026-07-16 — 标准图形构建/打包路径（拒 VHD 捷径）+ Layer2 3/7 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L474) | 474 |  |  |  | 脚本定型 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L486) | 486 |  |  |  | 本轮产物（readback） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L500) | 500 |  |  |  | Layer2（`g1_boot_verify.ps1`，≥600s） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L514) | 514 | 2026-07-16 |  |  | 2026-07-16 — ★ G1 真正根因定位（订正）：`vndservicemanager` 缺失（非图形） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L530) | 530 | 2026-07-16 |  |  | 2026-07-16 — G1 Layer2 仍 3/7：第二阻塞 = zygote 崩溃循环（+ bs_bootlog ZYGLOG 洪水） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L546) | 546 | 2026-07-16 |  |  | 2026-07-16 — ★ M1 vs G1 全量 system diff（用户「参考可 boot 最小 patch 看差异」） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L563) | 563 | 2026-07-16 |  |  | 2026-07-16 — ★ 决策（用户）：G1 改用 `m droid` 构建（弃 m systemimage + 手 overlay） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L576) | 576 | 2026-07-16 |  |  | 2026-07-16 — m droid VINTF 编译失败 → 已修（rc=0）；但 m droid 仍 system-only（不 fold） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L590) | 590 | 2026-07-16 |  |  | 2026-07-16 — ✅✅ G1 Layer2 boot 回归 7/7（Phase 1 里程碑） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L611) | 611 | 2026-07-16 |  |  | 2026-07-16 — ✅✅ Phase 1 完成 · Phase 2 开始 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L630) | 630 | 2026-07-17 |  |  | 2026-07-17 — ⚠️ 订正：上条「G1 Layer2 7/7（245s）」未经回读证实；验真发现「部署的压根不是 G1 镜像」 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L662) | 662 | 2026-07-17 |  |  | 2026-07-17 (later) — ★ 重打包（buildscripts 对齐 + 无 M1）成功：G1 越过 panic 跑到 init/boot_completed；新阻塞 = hwservicemanager 缺失（G9 build 缺口） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L690) | 690 | 2026-07-17 |  |  | 2026-07-17 (cont.) — 逐层打通 G1 boot 阻塞链到 G3 图形 HAL；当前卡点 = hwcomposer.default.so SIGSEGV |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L721) | 721 | 2026-07-17 | 2 |  | 2026-07-17 (cont.2) — ★★ G3 gralloc 修复大成功：G1 boot 到 system_server + launcher3 运行；当前卡 launcher 窗口 displayed |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L737) | 737 | 2026-07-17 | 3 |  | 2026-07-17 (cont.3) — 最终阻塞精确定位：hwcomposer present-fence 无效 → SF present 循环 → 黑屏 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L753) | 753 | 2026-07-17 | 4 |  | 2026-07-17 (cont.4) — ✅✅ G1 Phase 1 真正达成（readback 证实，boot 到 launcher 可见） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L772) | 772 | 2026-07-20 | 5 |  | 2026-07-20 (cont.5) — 合规化整改 P1a/P1b 验证：VINTF④ 不足（DIAG 留）+ init.sh gralloc 无效（build.prop append 才可靠） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L792) | 792 | 2026-07-20 | 6 |  | 2026-07-20 (cont.6) — Phase 2 启动:service.cpp DIAG 正式修方向找到(target-level 8→legacy build bug) |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L810) | 810 | 2026-07-20 | 7 |  | 2026-07-20 (cont.7) — Phase 2: service.cpp DIAG 正式修实施(PRODUCT_SHIPPING_API_LEVEL=34 + m droid rebuild 进行中) |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L824) | 824 | 2026-07-20 | 8 |  | 2026-07-20 (cont.8) — rebuild 完成,PRODUCT_SHIPPING_API_LEVEL=34 未改 target-level(假设推翻) |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L843) | 843 | 2026-07-20 | 9 |  | 2026-07-20 (cont.9) — ★ target-level 真源找到；target-level=8 假设实测推翻 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L880) | 880 | 2026-07-20 | 10 |  | 2026-07-20 (cont.10) — ✅✅ DIAG 正式收口：hidl.manager **@1.2**（非 target-level / 非 DIAG） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L903) | 903 | 2026-07-20 | 11 |  | 2026-07-20 (cont.11) — Phase 2 全面推进启动 + P2-TEMP-SEPOLICY **escalate** |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L907) | 907 |  |  |  | P2-TEMP-SEPOLICY → escalate（判断性边界） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L917) | 917 |  |  |  | 进行中 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L921) | 921 | 2026-07-20 | 12 |  | 2026-07-20 (cont.12) — gralloc bake ✅ + Batch A Layer1/Layer2 ✅ |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L923) | 923 |  |  |  | P0 gralloc bake 收口 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L928) | 928 |  |  |  | P2-FRAMEWORK-REST Batch A |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L934) | 934 |  |  |  | P2-TEMP-BLAST |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L937) | 937 |  |  |  | Batch B |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L940) | 940 | 2026-07-20 | 13 |  | 2026-07-20 (cont.13) — Batch B surgical hostcall hooks Layer1 ✅ |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L952) | 952 | 2026-07-20 | 14 |  | 2026-07-20 (cont.14) — Batch AB jar 热替换 Layer2 **回归**；回滚 Root `85f5a862` |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L954) | 954 |  |  |  | 回归 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L958) | 958 |  |  |  | 处置 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L961) | 961 | 2026-07-20 | 15 |  | 2026-07-20 (cont.15) — P2 external 大清洗 + 剩余清单收敛到 7 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L963) | 963 |  |  |  | External triage |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L969) | 969 |  |  |  | Mac |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L972) | 972 |  |  |  | P2 pending 现为 7（win） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L975) | 975 | 2026-07-20 | 16 |  | 2026-07-20 (cont.16) — 纠正：须 `m droid` + 完整 g1_build_pack 流程 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L990) | 990 | 2026-07-21 | 17 |  | 2026-07-21 (cont.17) — `m droid` 修通 + Batch A/B Layer2 回归；surgical 收敛 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L992) | 992 |  |  |  | Layer1 阻塞（已修） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L997) | 997 |  |  |  | Layer2（Root `5b252308`） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1002) | 1002 |  |  |  | Surgical remaining（进行中） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1008) | 1008 | 2026-07-21 | 18 |  | 2026-07-21 (cont.18) — surgical bionic/art/icu Layer2 **7/7** |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1010) | 1010 |  |  |  | 产物 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1014) | 1014 |  |  |  | 已 ported |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1022) | 1022 |  |  |  | 仍 pending / blocked（Phase 2 未关门） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1030) | 1030 |  |  |  | VINTF 正式态（保留） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1033) | 1033 | 2026-07-21 | 19 |  | 2026-07-21 (cont.19) — P2 frameworks BatchC/D + native surgical；registry 机械项关门 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1035) | 1035 |  |  |  | Batch C（Root `97eca87d` → 迭代 `00c31065`）Layer2 **7/7 @176–178s** |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1042) | 1042 |  |  |  | Native |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1045) | 1045 |  |  |  | Registry P2 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1053) | 1053 | 2026-07-21 | 20 |  | 2026-07-21 (cont.20) — BstUtils metalava + bst_arm64；Layer2 绿 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1055) | 1055 |  |  |  | frameworks/base |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1059) | 1059 |  |  |  | P2-MAC-ARM64 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1063) | 1063 |  |  |  | 验证 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1067) | 1067 |  |  |  | Registry / Gate |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1072) | 1072 | 2026-07-21 | 21 |  | 2026-07-21 (cont.21) — DisplayRotation + selinux 回归/回退 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1074) | 1074 |  |  |  | 落地 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1079) | 1079 |  |  |  | 回归（Root `3b1e5b8d`） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1085) | 1085 |  |  |  | 进行中 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1090) | 1090 | 2026-07-21 |  |  | 2026-07-21 — 人类决策（Phase 2 方向刷新） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1101) | 1101 | 2026-07-21 | 22 |  | 2026-07-21 (cont.22) — performance_hint HAL + Shell Transitions |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1103) | 1103 |  |  |  | 研究（readback） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1108) | 1108 |  |  |  | 落地（完成 · cont.22b） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1114) | 1114 | 2026-07-21 | 23 |  | 2026-07-21 (cont.23) — Phase2 纪律复位 + P2-FW-WM-1 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1116) | 1116 |  |  |  | 盘点（readback） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1121) | 1121 |  |  |  | P2-FW-WM-1 ✅ |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1127) | 1127 |  |  |  | P2-FW-AM-1 ❌ → revert（+ Data 污染恢复） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1133) | 1133 |  |  |  | 清单纪律（同会话） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1137) | 1137 |  |  |  | P2-FW-WM-2 ❌ → revert |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1140) | 1140 | 2026-07-22 | 24 |  | 2026-07-22 (cont.24) — Data 污染 / 恢复与文档收口 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1142) | 1142 |  |  |  | 权威产物（远程树） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1147) | 1147 |  |  |  | Win Data 事故（readback） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1154) | 1154 |  |  |  | Data 备用策略（人类确认可用） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1159) | 1159 |  |  |  | 移植纪律结论 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1164) | 1164 | 2026-07-22 | 25 |  | 2026-07-22 (cont.25) — ✅✅ Win Layer2 7/7 基线恢复（Root `eb309e6c` + Data `wipe20260717`） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1186) | 1186 | 2026-07-22 | 26 |  | 2026-07-22 (cont.26) — P2 FW-CORE-APP-1：3 app-framework BST hook 外科移植（Layer1 ✅，Layer2 进行中） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1207) | 1207 | 2026-07-22 | 27 |  | 2026-07-22 (cont.27) — ✅✅ FW-CORE-APP-1 Layer2 7/7 @124s（3 app-framework hook 完整验证） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1224) | 1224 | 2026-07-22 | 28 |  | 2026-07-22 (cont.28) — ✅✅ FW-CORE-APP-2 Layer2 7/7 @383s（View Roblox + ApkLiteParseUtils Pokemon 完整验证） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1244) | 1244 | 2026-07-22 | 29 |  | 2026-07-22 (cont.29) — FW-CORE-APP-3（Instrumentation+ContextImpl foundation）：metalava @hide 修 + 因 env 争用 deferred（已 revert 干净态） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1259) | 1259 | 2026-07-22 | 30 |  | 2026-07-22 (cont.30) — ✅✅ FW-CORE-APP-3 Layer2 7/7 @534s（Instrumentation+ContextImpl foundation 完整验证；cont.29 deferred 转 done） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1280) | 1280 | 2026-07-22 | 31 |  | 2026-07-22 (cont.31) — ✅✅ FW-CORE-APP-4 Layer2 7/7 @597s（ViewRootImpl FreeFireMax + InputDevice 反检测） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1305) | 1305 | 2026-07-22 | 32 |  | 2026-07-22 (cont.32) — ✅✅ FW-CORE-APP-5 Layer2 7/7 @154s（Settings 反检测 + Environment sdcard_emul） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1330) | 1330 | 2026-07-22 | 33 |  | 2026-07-22 (cont.33) — ✅✅ FW-CORE-APP-6 Layer2 7/7 @216s（Editor cursor + TextView GIAP） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1353) | 1353 | 2026-07-22 | 34 |  | 2026-07-22 (cont.34) — ❌ FW-CORE-APP-7 Display 回滚（Layer2 3/7）；绿基线恢复 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1366) | 1366 | 2026-07-22 | 35 |  | 2026-07-22 (cont.35) — FW-CORE-APP-8 进行中（PaymentRedirect IAP + ActivityThread redirect） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1380) | 1380 | 2026-07-23 | 35 |  | 2026-07-23 (cont.35 done) — ✅✅ FW-CORE-APP-8 Layer2 7/7 @274s（PaymentRedirect IAP） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1392) | 1392 | 2026-07-23 | 36 |  | 2026-07-23 (cont.36) — ✅✅ FW-CORE-APP-9 Layer2 7/7 @209s（InputManagerGlobal ROB-18338） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1411) | 1411 | 2026-07-23 | 37 |  | 2026-07-23 (cont.37) — ✅✅ FW-CORE-APP-10 Layer2 7/7 @269s（Display metrics-only） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1431) | 1431 | 2026-07-23 | 38 |  | 2026-07-23 (cont.38) — ✅✅ FW-CORE-APP-11 Layer2 7/7 @242s（ResourcesImpl custom DPI + status_bar） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1449) | 1449 | 2026-07-23 | 39 |  | 2026-07-23 (cont.39) — ✅✅ FW-CORE-APP-12 Layer2 7/7 @302s（SharedPreferencesImpl game defaults） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1467) | 1467 | 2026-07-23 | 40 |  | 2026-07-23 (cont.40) — ✅✅ FW-CORE-APP-13 Layer2 7/7 @126s（Activity GIAP purchase tracking） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1485) | 1485 | 2026-07-23 | 41 |  | 2026-07-23 (cont.41) — ✅✅ FW-CORE-APP-14 Layer2 7/7 @376s（NativeLibraryHelper BST ABI override） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1502) | 1502 | 2026-07-23 | 42 |  | 2026-07-23 (cont.42) — ✅✅ FW-CORE-APP-15 Layer2 7/7 @401s（BaseBundle affiliate/referral hack） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1519) | 1519 | 2026-07-23 | 43 |  | 2026-07-23 (cont.43) — ✅✅ FW-CORE-APP-16 Layer2 7/7 @247s（ActivityThread profile/UE/StrictMode） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1537) | 1537 | 2026-07-23 | 44 |  | 2026-07-23 (cont.44) — ✅✅ FW-CORE-APP-17 Layer2 7/7 @421s（Display rotation kill-switch）→ **core/java 22/22 完成** |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1555) | 1555 | 2026-07-23 | 45 |  | 2026-07-23 (cont.45) — FW-SERVICES-1a ✅ Layer2 7/7 @167s（Clipboard host sync） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1573) | 1573 | 2026-07-23 | 46 |  | 2026-07-23 (cont.46) — ✅ FW-SERVICES-1b Layer2 7/7 @235s（Location GMS network popup） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1591) | 1591 | 2026-07-23 | 47 |  | 2026-07-23 (cont.47) — ✅ FW-SERVICES-2 Layer2 7/7 @184s（NMS + hide BST resolve） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1610) | 1610 | 2026-07-23 | 48 |  | 2026-07-23 (cont.48) — ✅ FW-SERVICES-3 Layer2 7/7 @169s（AccountManager host 账户回调） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1628) | 1628 | 2026-07-23 | 49 |  | 2026-07-23 (cont.49) — ✅ FW-SERVICES-4a Layer2 7/7 @199s（Audio volume + AppOps devicedetails） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1647) | 1647 | 2026-07-23 | 50 |  | 2026-07-23 (cont.50) — ✅ FW-SERVICES-5 Layer2 7/7 @153s（AccessibilityManagerService hide BST a11y） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1666) | 1666 | 2026-07-23 | 51 |  | 2026-07-23 (cont.51) — ✅✅ FW-PERIPH-1 Layer2 7/7 @131s（SystemVibrator + MediaCodecInfo） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1688) | 1688 | 2026-07-23 | 52 |  | 2026-07-23 (cont.52) — ✅✅ FW-PERIPH-2 Layer2 7/7 @123s（TelephonyPermissions phone-state bypass） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1706) | 1706 | 2026-07-23 | 53 |  | 2026-07-23 (cont.53) — ✅✅ FW-SERVICES-6 Layer2 7/7 @131s（IMMS onImeChange bounded 子集） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1726) | 1726 | 2026-07-23 | 54 |  | 2026-07-23 (cont.54) — ✅✅ FW-SERVICES-6b Layer2 7/7 @123s（IMMS text-edit-mode 键盘映射核心） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1747) | 1747 | 2026-07-23 | 55 |  | 2026-07-23 (cont.55) — ✅✅ FW-PERIPH-3 Layer2 7/7 @197s（TelephonyManager operator 伪装） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1767) | 1767 | 2026-07-23 | 56 |  | 2026-07-23 (cont.56) — ❌ FW-PERIPH-3b 回退（TM device-id "01" override 破 boot）+ 基线复验 7/7 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1783) | 1783 | 2026-07-23 | 57 |  | 2026-07-23 (cont.57) — ✅✅ FW-PERIPH-4 Layer2 7/7 @169s（ServiceState LTE 反检测） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1802) | 1802 | 2026-07-23 | 58 |  | 2026-07-23 (cont.58) — ✅✅ FW-PERIPH-5 Layer2 7/7 @126s（TM device-id uid-gated — PERIPH-3b 教训修复） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1821) | 1821 | 2026-07-24 | 59 |  | 2026-07-24 (cont.59) — 移植盘点：InputManager netease 已在 InputManagerGlobal；机械 peripheral 尽 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1836) | 1836 | 2026-07-24 | 60 |  | 2026-07-24 (cont.60) — ✅✅ FW-PERIPH-6 Layer2 7/7 @126s（SettingsProvider a11y setting 过滤，drift 适配） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1858) | 1858 | 2026-07-24 | 61 |  | 2026-07-24 (cont.61) — ✅✅ FW-PERIPH-7 Layer2 7/7 @136s（SettingsService a11y bulk-read 过滤） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1873) | 1873 | 2026-07-24 | 62 |  | 2026-07-24 (cont.62) — 终判：机械 peripheral 移植耗尽（SystemUI 截图 re-arch） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1887) | 1887 | 2026-07-24 | 63 |  | 2026-07-24 (cont.63) — Phase 2 功能对齐维度关门 + 剩余统一 defer 挂账 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1911) | 1911 | 2026-07-24 | 64 |  | 2026-07-24 (cont.64) — ✅✅ MECH-1 Layer2 7/7 @185s（首个 frameworks/base 外机械 port：audio + BatteryMonitor） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1936) | 1936 | 2026-07-24 | 65 |  | 2026-07-24 (cont.65) — ✅✅ MECH-2 Layer2 7/7 @157s（Launcher3 HOME category 移除） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1948) | 1948 | 2026-07-24 | 66 |  | 2026-07-24 (cont.66) — ✅✅ MECH-3 Layer2 7/7 @161s（getprop BST prop 过滤 — 反检测） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1961) | 1961 | 2026-07-24 | 67 |  | 2026-07-24 (cont.67) — ✅✅ MECH-4 Layer2 7/7 @130s（start.cpp BST state reset on stop） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1980) | 1980 | 2026-07-24 | 68 |  | 2026-07-24 (cont.68) — ❌ MECH-5 build/make defer（mk 改动破坏 a16 release-config） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L1992) | 1992 | 2026-07-24 | 69 |  | 2026-07-24 (cont.69) — registry 清理：device/generic false positive + hardware/bst 闭环 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2009) | 2009 | 2026-07-24 | 70 |  | 2026-07-24 (cont.70) — ✅ registry 全量闭环：pending 17→0 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2024) | 2024 | 2026-07-24 | 71 |  | 2026-07-24 (cont.71) — ✅✅ MECH-6 Layer2 7/7 @132s（packages/modules/adb — 全量扫描发现的遗漏模块） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2042) | 2042 | 2026-07-24 | 72 |  | 2026-07-24 (cont.72) — ✅✅ MECH-7 Layer2 7/7 @135s（Connectivity Ethernet BST static IP — 第 2 个全量扫描发现的遗漏模块） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2055) | 2055 | 2026-07-24 | 73 |  | 2026-07-24 (cont.73) — ✅✅ MECH-8 Layer2 7/7 @128s（Settings BST_CHANGES_ENABLED gate — 第 3 个遗漏模块 port） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2068) | 2068 | 2026-07-24 | 74 |  | 2026-07-24 (cont.74) — 非 fw/base 机械 port 完成盘点 + 剩余 5 模块阻塞分析 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2092) | 2092 | 2026-07-24 | 75 |  | 2026-07-24 (cont.75) — ✅✅ MECH-9 Layer2 7/7 @131s（IMediaSource + BstUtilsManager.h C++ stub unblock） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2108) | 2108 | 2026-07-25 | 76 |  | 2026-07-25 (cont.76) — ✅✅ MECH-10 Layer2 7/7 @152s（CameraService + CameraProviderManager BST 旋转 — frameworks/av 关门） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2127) | 2127 | 2026-07-25 | 77 |  | 2026-07-25 (cont.77) — ✅✅ MECH-11 Layer2 7/7 @159s（Wifi fake WiFi state — 第 6 个遗漏模块 port） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2139) | 2139 | 2026-07-25 | 78 |  | 2026-07-25 (cont.78) — 剩余 3 模块最终阻塞分析（全量扫描遗漏模块 port 收尾） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2161) | 2161 | 2026-07-25 | 79 |  | 2026-07-25 (cont.79) — LatinIME 终态：Soong build-system API 分区约束（须 build-system engineering） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2181) | 2181 | 2026-07-25 | 80 |  | 2026-07-25 (cont.80) — ✅✅ MECH-13 Layer2 7/7 @233s（system/extras su/report_daemon — 第 7 个遗漏模块 port） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2202) | 2202 | 2026-07-25 | 81 |  | 2026-07-25 (cont.81) — LatinIME reflection 7/7 @167s（26 ports，剩余 1 模块） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2206) | 2206 | 2026-07-25 | 82 |  | 2026-07-25 (cont.82) — MECH-14 PhoneSubInfoController BST device-id — 7/7 @134s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2211) | 2211 | 2026-07-25 | 83 |  | 2026-07-25 (cont.83) — ✅✅ MECH-15 Layer2 7/7 @207s（UiccProfile SIM READY + GsmCdmaPhone fake IMEI — 全量遗漏模块关门） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2236) | 2236 | 2026-07-25 | 84 |  | 2026-07-25 (cont.84) — ✅✅ MECH-16 property_service BST prop loading — 7/7 @126s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2245) | 2245 | 2026-07-25 | 85 |  | 2026-07-25 (cont.85) — ✅✅ MECH-17 init.rc BST triggers — 7/7 @134s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2254) | 2254 | 2026-07-25 | 86 |  | 2026-07-25 (cont.86) — ✅✅ MECH-18 property_service serialno + ueventd.rc bstvmsg — 7/7 @155s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2265) | 2265 | 2026-07-25 | 87 |  | 2026-07-25 (cont.87) — ✅✅ MECH-19 bionic system_property_set BST 反检测 — 7/7 @171s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2283) | 2283 | 2026-07-25 | 88 |  | 2026-07-25 (cont.88) — ✅ DEF-1 PointerIcon BST mouse pointer — 7/7 @214s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2293) | 2293 | 2026-07-25 | 89 |  | 2026-07-25 (cont.89) — ✅ DEF-2 ATS BST force-kill — 7/7 @250s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2298) | 2298 | 2026-07-25 | 90 |  | 2026-07-25 (cont.90) — ✅ DEF-3 SF Scheduler bst.max_fps — 7/7 @171s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2303) | 2303 | 2026-07-25 | 91 |  | 2026-07-25 (cont.91) — ✅ DEF-4 IMMS setBstIME broadcast — 7/7 @180s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2311) | 2311 | 2026-07-25 | 92 |  | 2026-07-25 (cont.92) — D3 SystemUI 截图确认 BLOCKED + 最终状态 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2333) | 2333 | 2026-07-25 | 93 |  | 2026-07-25 (cont.93) — ✅ DEF-5 build/make app removal via device layer — 7/7 @171s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2337) | 2337 | 2026-07-25 | 94 |  | 2026-07-25 (cont.94) — ActiveServices 尝试失败（编译错，reverted）+ /loop 取消 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2345) | 2345 | 2026-07-25 | 95 |  | 2026-07-25 (cont.95) — ✅ DEF-6 ActiveServices BST service hiding — 7/7 @155s |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2350) | 2350 | 2026-07-25 | 96 |  | 2026-07-25 (cont.96) — D8/D9 移植中 + D3 重设计完成 (build 进行中, 跨会话) |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2377) | 2377 | 2026-07-25 | 97 |  | 2026-07-25 (cont.97) — ✅ D9 binder C++ 编译通过（3 机械修）+ build 重启（~9-10h） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2389) | 2389 | 2026-07-25 | 98 |  | 2026-07-25 (cont.98) — ✅ D9 binder 链接通过（fix #4 visibility export）+ build 续跑 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2399) | 2399 | 2026-07-26 | 99 |  | 2026-07-26 (cont.99) — ✅ D9 fix #5 vendor-variant PermissionController + build 增量续跑 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2409) | 2409 | 2026-07-26 | 100 |  | 2026-07-26 (cont.100) — ⚠️ pagefusion PAGE_SIZE 修复（非 D8/D9，阻塞 image 的 latent gap） |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2419) | 2419 | 2026-07-26 | 101 |  | 2026-07-26 (cont.101) — ✅✅ D8 + D9 PORTED + COMMITTED (Layer2 7/7 @161s) |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2491) | 2491 |  |  |  | Submodule 与分支审计 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2498) | 2498 |  |  |  | qvirt 与 graphics VINTF |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2505) | 2505 |  |  |  | system_server 约 200 秒死亡根因 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2511) | 2511 |  |  |  | 宿主长期停在 StartingKernel 根因 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2519) | 2519 |  |  |  | fastboot 打包流程缺口 |
| [`progress/porting-log.md`](../../../progress/porting-log.md#L2526) | 2526 |  |  |  | 最终验证 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L5) | 5 |  |  |  | 调试方法论 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L21) | 21 | 2026-07-08 |  | R177 | 当前状态（@ R177，2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L50) | 50 |  |  | R176, R177 | R176–R177 已排除的假说 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L82) | 82 |  |  |  | 回合索引 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L110) | 110 |  |  | R1 | Debug 回合 1：init FirstStageMain 崩溃 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L154) | 154 |  |  | R2 | Debug 回合 2：15秒 ACPI Reset 定位 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L175) | 175 |  |  | R3 | Debug 回合 3：boot 脚本系统性修复 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L195) | 195 |  |  | R4 | Debug 回合 4：init 启动后 44 秒主动 reboot |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L216) | 216 |  |  | R5 | Debug 回合 5：patched init 替换成功 — VM 稳定运行 76+ 秒 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L242) | 242 |  |  | R6 | Debug 回合 6：linkerconfig 路径 + init 执行失败 + OOM |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L272) | 272 |  |  | R7 | Debug 回合 7：crash_dump64 OOM + second stage exec 失败 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L294) | 294 |  |  | R8 | Debug 回合 8：SELinux 跳过 + henry reference 对齐 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L325) | 325 | 2026-06-29 |  | R12–19 | Debug 回合 12–19：servicemanager → zygote-start（2026-06-29 14:40–15:03） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L337) | 337 |  |  | R19 | 验证里程碑（Round 19 @ 15:02） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L364) | 364 | 2026-06-29 |  | R20 | Debug 回合 20：zygote linker/environ（2026-06-29 15:17–15:26） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L366) | 366 |  |  | R19 | 根因（Round 19 续） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L374) | 374 |  |  | R20 | 修复（Round 20） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L385) | 385 |  |  | R20 | 部署陷阱（Round 20 实测） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L388) | 388 |  |  | R20 | Round 20 冷启动验证（15:27, PID 31208） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L395) | 395 | 2026-06-29 |  | R21–22 | Debug 回合 21–22：ADB 回归 henry 路径（2026-06-29 16:03–16:17） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L397) | 397 |  |  | R21 | Round 21 偏离（已废弃） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L401) | 401 |  |  | R22 | Round 22：对齐 henry |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L426) | 426 |  |  | R21 | 下一步（Round 21 原稿，已由上表替代） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L432) | 432 | 2026-06-29 |  | R23–29 | Debug 回合 23–29：增量 Root + system 镜像路径（2026-06-29 17:00–18:10） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L434) | 434 |  |  | R23 | Round 23：apexd getfilecon skip |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L438) | 438 |  |  | R24 | Round 24–27：stage2 / apex / bind mount 尝试 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L445) | 445 |  |  | R26 | 根因（Round 26–27） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L450) | 450 |  |  | R28 | Round 28：system.sfs 打包（增量，无全量 AOSP） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L455) | 455 |  |  | R29 | Round 29：system.sfs → kernel panic（CONFIG_SQUASHFS 未开） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L460) | 460 |  |  | R29b | Round 29b（进行中）：直接挂 `android/system.img`（ext4） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L465) | 465 | 2026-06-29 |  | R29c | Round 29c：sparse system.img → loop EINVAL（2026-06-29 18:54–19:03） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L490) | 490 |  |  | R29d | Round 29d（进行中）：raw system.img VDI 重打 + 冷启动验证 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L494) | 494 | 2026-06-29 |  | R29e | Round 29e：>2GB loop 硬限制 → 改走 system.sfs + CONFIG_SQUASHFS（2026-06-29 20:46–） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L527) | 527 | 2026-06-29 |  | R29f | Debug 回合 29f–30：raw system.sfs + mount -o loop 内层（2026-06-29 21:49–00:05） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L529) | 529 |  |  | R29f | Round 29f：sparse 内层 system.img → EINVAL |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L538) | 538 |  |  | R29g | Round 29g：内层 losetup 失败链 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L547) | 547 |  |  | R29h | Round 29h：init.sh 语法错误 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L552) | 552 |  |  | R30 | Round 30：/system 挂载成功 + Android init 启动（PID 15260 @ 23:54，26224 @ 00:01） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L584) | 584 |  |  | R31 | 当前阻塞 / 下一步（Round 31） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L590) | 590 | 2026-06-30 |  | R31–37 | Debug 回合 31–37：/data ext4 + system staging + zygote 推进（2026-06-30 01:41–02:05） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L592) | 592 |  |  | R31 | Round 31：sdb1 节点 + apexd tmpfs fallback + runtime 预挂 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L602) | 602 |  |  | R32 | Round 32：保留 ext4 /data + loop 节点 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L609) | 609 |  |  | R33 | Round 33–34：`/system/{bin,lib64}` staging（squashfs 嵌 loop stat 损坏） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L618) | 618 |  |  | R35 | Round 35–36：app_process symlink + apex 别名 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L625) | 625 |  |  | R37 | Round 37：`bs-apex-symlinks.sh` + UUID 修复 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L652) | 652 |  |  | R38 | 下一步（Round 38+） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L659) | 659 | 2026-06-30 |  | R38–76 | Debug 回合 38–76：art apex / app_process / odsign 链（2026-06-30 02:09–） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L661) | 661 |  |  | R38 | Round 38：apexd-wrapper（失败） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L669) | 669 |  |  | R39 | Round 39：bs-apex-symlinks-wait + 恢复直接 apexd |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L676) | 676 |  |  | R40 | Round 40：`exec_start bs_apex_symlinks`（同步） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L686) | 686 |  |  | R41 | Round 41：`losetup` + `erofs` + `cat` 复制 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L692) | 692 |  |  | R42 | Round 42（进行中）：`losetup -f` 动态分配 loop |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L698) | 698 |  |  | R43 | Round 43：跳过 loop0–9，扫描空闲 loop |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L706) | 706 |  |  | R44 | Round 44–44b：initrd `app_process64` + `linker64` + bind 前 cat |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L711) | 711 |  |  | R45 | Round 45–47：art-payload.img + init.sh 预挂 i18n/tzdata/art |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L718) | 718 |  |  | R48 | Round 48–51：bs-apex remount + linkerconfig rebound |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L726) | 726 |  |  | R52 | Round 52–54：Henry 7P/7O |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L734) | 734 |  |  | R55 | Round 55：★ linkerconfig 跳过 + golden ld.config ★ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L742) | 742 |  |  | R56 | Round 56（进行中）：Henry 7R — odsign / boot.art 链 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L752) | 752 |  |  | R57 | Round 57–59：build.prop 热改 + odsign 清理 + system_bin v4 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L762) | 762 |  |  | R59 | Round 59 readback（PID 35124 @ 10:12, md5 `b18dad991c9bedfb8124d4c0bdd78717`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L773) | 773 |  |  | R60 | Round 60 readback（PID 31264 @ 10:35, md5 `48eaec7f3b8fc5425cd22e0c1a7d9fc0`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L782) | 782 |  |  | R61 | Round 61 readback（PID 35756 @ 10:37, md5 `4aa362052e7178e3b8b719202b674ecc`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L790) | 790 |  |  | R62 | Round 62 readback（PID 30296 @ 10:40, md5 `33155884584fe7ae70cb3c23125589d4`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L797) | 797 |  |  | R63 | Round 63–64 readback |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L803) | 803 |  |  | R65 | Round 65 readback（md5 `2f9a6f...`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L810) | 810 |  |  | R68 | Round 68 readback（md5 `e9ff29e...` / `1ccb129...`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L821) | 821 | 2026-06-30 |  | R69 | Round 69–76 readback（2026-06-30，fastboot.vdi 迭代） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L844) | 844 | 2026-06-30 |  | R77–80 | Debug 回合 77–80：zygote 启动链（归档，2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L855) | 855 | 2026-06-30 |  | R81 | Debug 回合 81：ld.config namespace patch（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L857) | 857 |  |  | R81a | R81a：错误锚点 → ld.config 损坏 ❌ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L860) | 860 |  |  | R81b | R81b：修正 patch 锚点 ✅ linker 链突破 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L869) | 869 | 2026-06-30 |  | R82 | Debug 回合 82：apex bind + 清除 stale boot.art（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L871) | 871 |  |  | R82 | R82 回读（PID 13168，md5 `ad990fbc...` @ 12:53） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L880) | 880 | 2026-06-30 |  | R83 | Debug 回合 83：7AE art-libs 自包含 + statspull（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L887) | 887 |  |  | R83b | R83b 回读（PID 24052，md5 `6af71ed...` @ 13:17） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L893) | 893 | 2026-06-30 |  | R84 | Debug 回合 84：class main 连带 SIGKILL 根因 + stub（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L895) | 895 |  |  | R83b | 根因（R83b 独立回读 PID 24052） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L899) | 899 |  |  | R84a | R84a：7AF netd stub — `henry-7AF netd stub start` ✅；surfaceflinger 仍杀 zygote |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L901) | 901 |  |  | R84b | R84b：7AG surfaceflinger + 7AH audioserver stub ✅ zygote 可跑完 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L911) | 911 |  |  | R85 | 下一步（Round 85） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L916) | 916 | 2026-06-30 |  | R85 | Debug 回合 85：A16 boot.art + 7AI/7AJ 诊断（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L918) | 918 |  |  | R85 | R85 独立回读（PID 28404 @ 13:44，md5 `a35601f70ed81e95859bb70ecb024879`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L931) | 931 |  |  | R86 | 下一步（Round 86） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L936) | 936 | 2026-06-30 |  | R86–88 | Debug 回合 86–88：诊断链修复 + logd 打通（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L938) | 938 |  |  | R86 | R86 回读（PID 35356，md5 `44c5f946...`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L945) | 945 |  |  | R87 | R87 回读（PID 33452，md5 `28ec37c9...`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L951) | 951 |  |  | R88 | R88 回读（PID 25224，md5 `76ecf9d95b0b5a4b21264acdd68debbf`）— **logd 里程碑** |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L962) | 962 | 2026-06-30 |  | R89–91 | Debug 回合 89–91：logcat 链修复 + **SIGABRT 根因捕获**（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L964) | 964 |  |  | R89 | R89 回读（PID 18040，md5 `78a5ab89...`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L970) | 970 |  |  | R90 | R90 回读（PID 13648，md5 `6a0a1bc0...`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L976) | 976 |  |  | R91 | R91 回读（PID 27284，md5 `731d0642...`）— **诊断里程碑** |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L983) | 983 |  |  | R91 | R91 根因链（独立回读 ZYGLOG @ PID 27284） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1003) | 1003 |  |  | R92 | Round 92 方向 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1011) | 1011 | 2026-06-30 |  | R92 | Debug 回合 92：boot-image 链修复（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1022) | 1022 |  |  | R92, R92c | R92 回读（PID 35336，md5 `964c6b74...` R92c） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1031) | 1031 | 2026-06-30 |  | R93–97 | Debug 回合 93–97：apex shim javalib + GC/boot.oat 对齐（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1033) | 1033 |  |  | R93 | R93–95：javalib 供应链 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1042) | 1042 |  |  | R96 | R96–97：GC 对齐 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1048) | 1048 |  |  | R93 | 脚本（R93–97） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1054) | 1054 | 2026-06-30 |  | R98 | Debug 回合 98：uffd/cache-info 对齐 + boot-framework 阻塞（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1056) | 1056 |  |  | R98 | R98（7BA/7BB 初版 — 删 cache-info）❌ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1065) | 1065 |  |  | R98b | R98b（7BB 修正 — 写入 cache-info）✅ read barrier 打通 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1073) | 1073 |  |  | R98b | R98b 新阻塞链 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1083) | 1083 | 2026-06-30 |  | R99 | Debug 回合 99：真实 odsign + boot-framework 生成（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1085) | 1085 |  |  | R98b | 根因确认（R98b 后远程探针） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1090) | 1090 |  |  | R99 | R99 变更（7BD/7BF/7BE） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1098) | 1098 |  |  | R99 | R99 回读（PID 32348，md5 `5415dbbb6468ba6c9b321cde8ca61022` @ 16:44） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1109) | 1109 |  |  | R99b | R99b（7BG vdc wrapper）回读（PID 31580，md5 `488e416d23a7d93e410d4b589e26bf93` @ 16:47） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1118) | 1118 | 2026-06-30 |  | R100–102 | Debug 回合 100–102：vold 打通 + odsign_key SELinux 收敛（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1120) | 1120 |  |  | R100 | R100（7BG+ 证据增强） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1129) | 1129 |  |  | R101 | R101（7BH 初版 — bionic sidecar） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1135) | 1135 |  |  | R102 | R102（7BH 修正 — refresh + rm stale） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1147) | 1147 | 2026-06-30 |  | R103–105 | Debug 回合 103–105：keystore2 bringup bypass + zygote 推进（2026-06-30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1149) | 1149 |  |  | R103 | R103（odsign_key rebind） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1156) | 1156 |  |  | R104 | R104–105（boot-stage super-key） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1162) | 1162 |  |  | R105 | R105 回读（PID 26520，md5 `ea9cc738c7cb0bedde185ce7daa739c4` @ 17:35） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1174) | 1174 |  |  | R106 | R106（adbconnection sidecar） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1185) | 1185 |  |  | R99 | 脚本（R99–106） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1199) | 1199 |  |  | R77 | 脚本索引（R77–106） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1217) | 1217 |  |  | R107, R118 | R107–R118：odsign / earlyBootEnded 调试 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1238) | 1238 |  |  | R118 | 当前证据（R118） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1258) | 1258 | 2026-06-30 |  | R119, R122 | Debug 回合 R119–R122：namespace 清障 + earlyBootEnded 回正 + 越过 BOOT_LEVEL_EXCEEDED（2026-06-30 21:xx） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1262) | 1262 |  |  | R119 | R119：i18n namespace libbase（henry-7BM）✅ 打通 libicu_jni |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1268) | 1268 |  |  | R120 | R120：art namespace libz（ld.config /system search）✅ 打通 libjavacore |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1274) | 1274 |  |  | R121 | R121：恢复 stock earlyBootEnded（henry §7R）✅ earlyBootEnded 跑通 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1280) | 1280 |  |  | R122 | R122：重试 earlyBootEnded 等 maintenance 就绪 ⚠️ bs-earlyboot rc=0 是假成功 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1287) | 1287 |  |  | R122 | 当前阻塞链（@ R122） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1299) | 1299 |  |  | R123 | 下一步（R123）— 需决策 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1301) | 1301 |  |  | R119, R122 | 脚本（R119–R122） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1307) | 1307 |  |  | R119, R122 | 部署产物（R119–R122 fastboot.vdi md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1310) | 1310 |  |  | R123 | Debug 回合 R123：gate odsign 等 bs-earlyboot（timing vs functional 诊断）⚠️ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1326) | 1326 |  |  | R124 | 下一步（R124 候选） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1331) | 1331 |  |  | R124 | Debug 回合 R124：bs-odsign 等 180s ★ definitive = 功能性 keymint 缺口 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1354) | 1354 |  |  | R125 | Debug 回合 R125：抓 keystore2 内部错 ★ 根因 = maintenance SYSTEM_ERROR @ check_keystore_permission |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1375) | 1375 |  |  | R126 | 下一步（R126，问题迭代，自有镜像上解）— 不借用 henry 产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1386) | 1386 |  |  | R119, R125 | 本会话总结（R119–R125） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1396) | 1396 |  |  | R126 | Debug 回合 R126：keystore2 绕过 check_keystore_permission ★ 跨过 BOOT_LEVEL_EXCEEDED |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1398) | 1398 |  |  | R125, R126 | 根因（R125 定）+ 修复（R126） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1404) | 1404 |  |  | R126 | 回读（R126 fastboot `5436c775…`）★ 跨过 BOOT_LEVEL_EXCEEDED |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1409) | 1409 |  |  | R127, R128 | Debug 回合 R127–R128：odrefresh ENOENT → art APEX @ odsign 时已 gone |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1420) | 1420 |  |  | R129 | 下一步（R129，问题迭代） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1423) | 1423 |  |  | R126, R128 | 部署产物（R126–R128 fastboot md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1426) | 1426 |  |  | R126, R128 | 脚本（R126–R128） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1432) | 1432 | 2026-07-01 |  | R129, R131 | Debug 回合 R129–R131：art APEX remount + odrefresh linker（2026-07-01） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1434) | 1434 |  |  | R129 | R129：bs-odsign art-payload remount（loop0 失败） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1439) | 1439 |  |  | R130 | R130：direct erofs mount ★ art remount 成功，新阻塞 libarttools |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1444) | 1444 |  |  | R131 | R131：payload-enrich art-libs before bind ⚠️ 文件在 art-libs 但 namespace 仍找不到 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1448) | 1448 |  |  | R132, R134 | R132–R134：skip bind / wrapper 路线 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1452) | 1452 |  |  | R135 | R135：odsign LD_LIBRARY_PATH 含 art lib64（已写入 stage2，待验） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1456) | 1456 |  |  | R126, R135 | 部署产物（R126–R135 fastboot md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1459) | 1459 |  |  | R129, R131 | 脚本（R129–R131） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1467) | 1467 | 2026-07-01 |  | R137, R144 | Debug 回合 R137–R144：odrefresh pre-run + apex-info + dex2oat linker（2026-07-01） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1469) | 1469 |  |  | R137, R138 | R137–R138：odrefresh 经 linker64 预跑 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1473) | 1473 |  |  | R139 | R139：apex-info-list printf + bind + --force-compile ★ apex-info 修复 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1477) | 1477 |  |  | R140, R141 | R140–R141：ld.config bionic 路径（未单独解决 dex2oat） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1481) | 1481 |  |  | R142, R143 | R142–R143：dex2oat64 bin/ overlay wrapper ★ libc 突破 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1490) | 1490 |  |  | R144 | R144：dex2oat+dex2oat64 双 wrapper + 保留 boot.art + 加长 odrefresh log |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1498) | 1498 |  |  | R139, R144 | 部署产物（R139–R144 fastboot md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1501) | 1501 |  |  | R139, R144 | 脚本（R139–R144） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1509) | 1509 |  |  | R145 | 下一步（R145） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1514) | 1514 | 2026-07-01 |  | R145, R149 | Debug 回合 R145–R149：mainline BCP javalib 链（2026-07-01） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1516) | 1516 |  |  | R145, R146 | R145–R146：i18n + dex2oat wrapper ★ primary boot.art |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1520) | 1520 |  |  | R147 | R147：adservices APEX remount ★ adservices jar 就位 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1524) | 1524 |  |  | R148 | R148：batch mainline-javalib ★ 24 模块 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1528) | 1528 |  |  | R149 | R149：apex alias btservices→bt ★ 越过 bt，新阻塞 statsd |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1532) | 1532 |  |  | R150 | R150：补 os.statsd + extservices 等 ⚠️ mainline 可能越过，fw-oat 仍 0 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1542) | 1542 |  |  | R145, R150 | 部署产物（R145–R150 fastboot md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1545) | 1545 |  |  | R145, R150 | 脚本（R145–R150） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1551) | 1551 |  |  | R151 | 下一步（R151+） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1557) | 1557 | 2026-07-01 |  | R151, R154 | Debug 回合 R151–R154：odsign rc=0 + boot 链路径 + read barrier（2026-07-01） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1559) | 1559 |  |  | R151 | R151：odrefresh bin/ wrapper ★ odsign rc=0 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1563) | 1563 |  |  | R152 | R152：boot.art backup + framework bind 尝试 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1568) | 1568 |  |  | R153 | R153：完整 boot 链 + framework dir overlay ★ primary BCP 链就位 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1577) | 1577 |  |  | R154 | R154：cache-info 存活 + barrier-safe recompile ★ 越过 read barrier |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1584) | 1584 |  |  | R155 | R155：direct dex2oat boot-framework ⚠️ Aborted |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1591) | 1591 |  |  | R156 | R156：dex2oat wrapper + BCP runtime-args ⚠️ Aborted 持续 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1598) | 1598 |  |  | R157 | R157：odrefresh `--only-boot-images` + mainline oracles ★ 模型纠正 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1613) | 1613 |  |  | R158 | R158：framework overlay 同步 mainline boot-* ★ overlay 就位，zygote 仍 SIGSEGV |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1620) | 1620 |  |  | R159 | R159：tzdata ICU @ zygote（henry-7CG）⚠️ bind overlay 0B |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1629) | 1629 |  |  | R160 | R160：tzdata direct cat-copy + direct-erofs ★ ICU 链打通 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1641) | 1641 |  |  | R151, R160 | 部署产物（R151–R160 fastboot md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1644) | 1644 |  |  | R151, R160 | 脚本（R151–R160） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1650) | 1650 |  |  | R161 | R161：crash_dump64 + §7j boringssl ★ 部分成功 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1663) | 1663 |  |  | R151, R161 | 部署产物（R151–R161 fastboot md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1666) | 1666 |  |  | R151, R161 | 脚本（R151–R161） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1672) | 1672 |  |  | R162 | 下一步（R162+） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1676) | 1676 |  |  | R162 | R162：com_android_runtime ld.config /system search（修 crash_dump64 link 以取 backtrace） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1690) | 1690 |  |  | R163 | 下一步（R163，问题迭代） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1696) | 1696 |  |  | R163, R164 | Debug 回合 R163–R164：libart 跳过 NULL dex_cache（ZygoteVerificationTask）★ 推进 zygote |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1698) | 1698 |  |  | R163 | R163：libart patch |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1702) | 1702 |  |  | R164 | R164：强制 libart 重 staging ★ patch 生效，zygote 推进 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1708) | 1708 |  |  | R165 | 下一步（R165） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1716) | 1716 |  |  | R164, R165 | Debug 回合 R165：read barrier mismatch（★ R164 scattered crashes 根因） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1723) | 1723 |  |  | R165b | 修复（R165b） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1729) | 1729 |  |  | R165b | R165b 回读（fastboot `19db89d9…`）★ read barrier 修复 + 新阻塞 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1735) | 1735 |  |  | R166 | R166：全 art APEX non-CC 重编（一致 art-libs） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1738) | 1738 |  |  | R166 | R166 回读（fastboot `a38ad311d15baebdbc8fa04ecbab6653`）★ plugin 修，仍 0x278 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1751) | 1751 |  |  | R167 | 下一步（R167） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1756) | 1756 |  |  | R167 | R167 诊断：disasm 确认 Runtime::Current() == NULL |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1762) | 1762 |  |  | R167 | 路线判断（R167 时点） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1767) | 1767 |  |  | R168 | R168：全 art APEX 一致 CC 重建（解 non-CC Runtime::Current() NULL） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1770) | 1770 |  |  | R169 | R169：移除 force_disable_uffd ⚠️ read barrier mismatch 仍存 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1775) | 1775 |  |  | R163, R169 | R163–R169 总结（read barrier/GC 深坑） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1787) | 1787 |  |  | R170, R170c | R170–R170c：skip odrefresh（用 initrd CC boot.art）❌ boot stall |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1793) | 1793 |  |  | R163, R170c | R163–R170c 总结（read barrier/GC 配置深坑，~8 轮未解） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1798) | 1798 | 2026-07-01 |  | R163, R171b | R163–R171b 总结（read barrier/GC 配置 → art-payload 提取 bug → dex2oat 缺库，2026-07-01~02） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1822) | 1822 |  |  | R171b | 当前阻塞链（@ R171b） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1832) | 1832 |  |  | R171c | 下一步（R171c） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1845) | 1845 |  |  | R163, R171b | 部署产物（R163–R171b fastboot md5） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1848) | 1848 |  |  | R163, R171b | 脚本（R163–R171b） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1859) | 1859 |  |  | R171 | art-payload 提取脚本（R171 新增） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1871) | 1871 | 2026-07-07 |  | R171b, R172 | Debug 回合 R172：恢复 R171b 权威状态（对齐文档，2026-07-07） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1875) | 1875 |  |  | R171b | 摸清实际状态 vs 文档 R171b |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1882) | 1882 |  |  | R171b | 回归根因：部署的是 Jul 3 超 R171b 的实验构建（已坏） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1891) | 1891 |  |  | R171b | 修复（手术式，保留已构建的 R171b staging） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1899) | 1899 |  |  | R172 | R172 教训（init panic 0x200） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1905) | 1905 |  |  | R172 | R172 结果：boot 越过 heartbeat-hang，推进到 init-patched ★ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1913) | 1913 |  |  | R172 | R172 新阻塞（Phase 2 入口）：cgroup 未初始化 → ueventd critical fail → reboot loop |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1927) | 1927 |  |  | R172 | R172 下一步（Phase 2） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1932) | 1932 |  |  | R172 | R172 部署产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1937) | 1937 | 2026-07-07 |  | R173 | Debug 回合 R173：init command-tracing 定位 hang = wait_for_coldboot_done（2026-07-07） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1945) | 1945 |  |  | R173 | R173 方法：init ExecuteCommand 加 command-tracing |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1950) | 1950 |  |  | R173 | R173 ★ hang 点定位 = `wait_for_coldboot_done` |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1962) | 1962 |  |  | R173 | R173 根因待定（下一回合） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1968) | 1968 |  |  | R173 | R173 下一步 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1973) | 1973 |  |  | R173 | R173 部署产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1978) | 1978 | 2026-07-07 |  | R173b, R173e | Debug 回合 R173b–R173e：ueventd coldboot 定位 + bypass ★ 越过 wait_for_coldboot_done（2026-07-07） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1980) | 1980 |  |  | R173b | R173b：ueventd_main 进入（entry log）→ coldboot 完成但 cold_boot_done 没信号 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1987) | 1987 |  |  | R173c | R173c：★ 机械 bypass wait_for_coldboot_done → init 越过！boot 到 late-init |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1992) | 1992 |  |  | R173, R173d | R173d：R173 init overwrite（stage2 灌 patched init 到 /data/system_bin/init） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L1997) | 1997 |  |  | R173e | R173e：新阻塞 = logd restart 循环 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2009) | 2009 |  |  | R173 | R173 下一步 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2013) | 2013 |  |  | R173e | R173e 部署产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2018) | 2018 | 2026-07-07 |  | R173f, R173i | Debug 回合 R173f–R173i：bypass 链推进到 post-fs-data/apexd，确认 upstream system 服务全面失效（2026-07-07） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2022) | 2022 |  |  | R173f | R173f：vold fstab 缺失 → do_exec skip vdc |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2026) | 2026 |  |  | R173g | R173g：keystore2 critical reboot → CheckMacPerms bypass |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2031) | 2031 |  |  | R173h | R173h：lmkd critical reboot → 跳过 LOG(FATAL) |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2035) | 2035 |  |  | R173i | R173i：★ 卡 apexd.status activated（apexd 全/bs 都失效） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2040) | 2040 |  |  | R173 | ★ 战略结论（R173 终点） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2045) | 2045 |  |  | R173 | R173 累计 bypass（已部署，boot 稳定到 post-fs-data/apexd） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2059) | 2059 |  |  | R173 | R173 下一步（需战略决策） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2064) | 2064 | 2026-07-07 |  | R174 | Debug 回合 R174：bypass 链推进到 zygote start + surfaceflinger REAL（2026-07-07） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2068) | 2068 |  |  | R174a | R174a：Root.vhd 重建（Jul 3 Root.fs → qemu-img VHD） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2073) | 2073 |  |  | R174b | R174b：bypass 链完整列表（部署在 init `builtins.cpp`/`property_service.cpp`/`service.cpp` + stage2） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2088) | 2088 |  |  | R174c | R174c：boot 推进到 zygote start + surfaceflinger REAL ★ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2096) | 2096 |  |  | R174d | R174d：当前阻塞 = 图形链（hwservicemanager.ready + boot.art） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2106) | 2106 |  |  | R174 | R174 部署产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2111) | 2111 | 2026-07-07 |  | R175 | Debug 回合 R175：goldfish-opengl-pie 编译 + henry 参考对比（2026-07-07 ~ 2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2115) | 2115 |  |  | R175a | R175a：hd / goldfish 切换到 henry 的正确分支 bst-v5.22.210 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2119) | 2119 |  |  | R175b | R175b：henry 参考 patch 分析（10-aosp-repo-diff.patch） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2130) | 2130 |  |  | R175c | R175c：goldfish-opengl-pie 依赖链 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2156) | 2156 |  |  | R175d | R175d：A16 编译适配（6 类修改，11 文件） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2171) | 2171 |  |  | R175e | R175e：编译状态（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2177) | 2177 |  |  | R175f | R175f：henry 参考 patch 中需应用的关键修改 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2181) | 2181 | 2026-07-08 |  | R175g | R175g：★ goldfish-opengl-pie 编译成功（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2220) | 2220 | 2026-07-08 |  | R175h | R175h：qemu-nbd 灌入 goldfish .so + boot 验证（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2230) | 2230 |  |  | R175 | R175 下一步 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2234) | 2234 | 2026-07-08 |  | R176 | Debug 回合 R176：zygote 链修复尝试（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2238) | 2238 |  |  | R176a | R176a：当前 zygote 状态 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2243) | 2243 | 2026-07-08 |  | R176b | R176b：★ 新诊断 — hwservicemanager.ready 依赖 framework HAL + libart 外部依赖（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2253) | 2253 | 2026-07-08 |  | R176c | R176c：★ 发现 libart 外部依赖缺失 → statsd-libs 补全 + hwc2 加入编译（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2270) | 2270 |  |  | R176 | R176 部署产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2276) | 2276 | 2026-07-08 |  | R176d | R176d：部署就绪（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2279) | 2279 | 2026-07-08 |  | R176e | R176e：★ 里程碑 — odrefresh 生成 boot.art + 备份修复 + zygote 找到 boot.art（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2297) | 2297 | 2026-07-08 |  | R176h | R176h–k：zygote "Aborted" 根因追踪（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2317) | 2317 |  |  | R176 | R176 结论与下一步 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2324) | 2324 | 2026-07-08 |  | R177 | Debug 回合 R177：henry 脚本直接应用 + 完整对比（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2326) | 2326 |  |  | R177a | R177a：henry 全量 boot 脚本部署 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2331) | 2331 |  |  | R177b | R177b：henry vs bst-aosp 完整对比 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2344) | 2344 |  |  | R177 | R177 结论 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2349) | 2349 | 2026-07-08 |  | R178 | Debug 回合 R178：路线纠偏执行（strict reference，2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2351) | 2351 |  |  | R178a | R178a：冻结偏航增量（runtime-staging stop-line） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2356) | 2356 |  |  | R178b | R178b：执行入口 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2360) | 2360 | 2026-07-08 |  | R179 | Debug 回合 R179：Henry boot 对齐执行（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2362) | 2362 |  |  | R179a | R179a：远程构建入口对齐 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2371) | 2371 |  |  | R179b | R179b：Henry AOSP boot patches 应用 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2380) | 2380 |  |  | R179c | R179c：Henry BootImage 同步 + fastboot 产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2393) | 2393 |  |  | R179d | R179d：完整 system 重编（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2400) | 2400 | 2026-07-08 |  | R179 | Debug 回合 R179：Henry boot 对齐执行（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2402) | 2402 |  |  | R179a | R179a：远程构建入口对齐 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2411) | 2411 |  |  | R179b | R179b：Henry AOSP boot patches 应用 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2418) | 2418 |  |  | R179c | R179c：Henry BootImage 同步 + fastboot 产物 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2423) | 2423 |  |  | R179d | R179d：完整 system 重编（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2427) | 2427 | 2026-07-08 |  | R180, R182 | Debug 回合 R180–R182：Henry 完整编译环境闭环（2026-07-08） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2429) | 2429 |  |  | R180 | R180：lunch target 纠偏 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2435) | 2435 |  |  | R181 | R181：Henry export_env 缺失变量 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2441) | 2441 |  |  | R182 | R182：完整 `m droid` 后台编译（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2454) | 2454 | 2026-07-09 |  | R183, R184 | Debug 回合 R183–R184：BstUtils 缺失补全（2026-07-09） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2456) | 2456 |  |  | R183 | R183：BstUtils 初版 + 增量重编 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2463) | 2463 |  |  | R184 | R184：增量 `m droid` 重编（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2469) | 2469 |  |  | R185 | R185：去掉 WITHOUT_CHECK_API 重编（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2477) | 2477 |  |  | R186 | R186：allowlist 修复后增量重编 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2482) | 2482 |  |  | R187 | R187：VINTF manifest 修复 + 重编（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2497) | 2497 |  |  | R193 | R193：Root.vhd 打包（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2502) | 2502 |  |  | R194 | R194：Makefile shell-if 修复 + 重打包 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2507) | 2507 |  |  | R195 | R195：清理 ghost mount + CRLF 脚本修复 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2512) | 2512 |  |  | R196 | R196：system.sfs 产出 + 手动完成 rootfs |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2520) | 2520 |  |  | R197 | R197：create_vdi → Root.vhd 部署（完成） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2529) | 2529 | 2026-07-09 |  | R198, R205 | R198–R205：Henry 对齐 — finder.go + libs + fastboot.vdi（2026-07-09） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2539) | 2539 |  |  | R206, R207 | R206–R207：init.sh PATH + bstsetup.env + boot L1 验证 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2553) | 2553 | 2026-07-09 |  | R208, R209 | R208–R209：Henry buildscripts Root 重打包 + init Henry 路径（2026-07-09） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2555) | 2555 |  |  | R208a | R208a：init 源码回退 Henry 路径 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2561) | 2561 |  |  | R208b | R208b：按 Henry `Makefile` Root 链重打 Root.vhd（非 ad-hoc convertfromraw） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2576) | 2576 |  |  | R209 | R209：boot L1–L2 验证（PID 26712 @ 17:50:23） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2590) | 2590 | 2026-07-09 |  | R210 | R210：严格 Henry 路线重打包 + 复测（2026-07-09 18:10） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2605) | 2605 | 2026-07-09 |  | R211 | R211：完整 Henry `make vbox` 打包链（2026-07-09 18:21–19:04） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2619) | 2619 | 2026-07-09 |  | R212 | R212：init.sh `system.sfs` APEX 预挂载 + fastboot 重建（2026-07-09 19:21–19:44） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2632) | 2632 | 2026-07-09 |  | R214, R216 | R214–R216：Henry 标准链恢复 + L3 根因收敛（2026-07-09 19:51–20:59） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2636) | 2636 |  |  | R214 | R214：完整 Henry `make vbox` + fastboot 重建 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2641) | 2641 |  |  | R214b | R214b–f：init.sh / BootImage Henry A16 适配（非 bringup bypass） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2649) | 2649 |  |  | R215, R216 | R215–R216：Root 重打 + init.rc 时序修复尝试 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2653) | 2653 |  |  | R216 | 当前 boot 分层（R216 @ 20:58, PID 24584） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2674) | 2674 |  |  | R217 | R217：下一步（Henry 路径，未闭环） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2683) | 2683 | 2026-07-09 |  | R218 | R218：init.rc 回正 + init 二进制 bringup 根因确认（2026-07-09 21:00–21:50） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2693) | 2693 |  |  | R218b | R218b 冷启动 readback（PID 30928 @ 21:39，新 Root.vhd） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2708) | 2708 |  |  | R218 | 部署产物（R218 Root） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2714) | 2714 | 2026-07-09 |  | R221 | R221：init 重链 + Root 重打 + L3 过关（2026-07-09 22:00–23:22） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2737) | 2737 |  |  | R221 | R221 冷启动 readback（PID 33912 @ 23:19） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2747) | 2747 |  |  | R222 | R222 下一步（Henry 路径） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2754) | 2754 | 2026-07-10 |  | R222, R223 | R222–R223：goldfish mmm 成功 + Root 重打 + L4 仍阻塞（2026-07-10 00:32–01:18） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2775) | 2775 |  |  | R223 | R223 冷启动 readback（HD-Player PID **35972** @ 01:16） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2785) | 2785 |  |  | R224 | R224 下一步（仍在 Henry 路径内） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2793) | 2793 | 2026-07-10 |  | R224 | R224：VINTF graphics HIDL + Root 重打（2026-07-10 01:22–01:43） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2807) | 2807 | 2026-07-10 |  | R225 | R225：ueventd bstpgaipc + Root 重打（2026-07-10 02:05–03:17） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2815) | 2815 |  |  | R225 | R225 冷启动 readback（HD-Player PID **36348** @ 03:27） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2825) | 2825 |  |  | R226 | R226 下一步（Henry 路径，L4 剩余阻塞） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2833) | 2833 | 2026-07-10 |  | R226, R228 | R226–R228：fastboot+bs_bootlog+bstpgaipc mknod + Root 重打（2026-07-10 03:51–05:15） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2835) | 2835 |  |  | R226 | R226 完成：fastboot Henry 路径重建 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2845) | 2845 |  |  | R227 | R227 完成：`init.sh` bstpgaipc mknod（Henry bstvmsg 同型） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2856) | 2856 |  |  | R228 | R228 进行中：Root 重打 + vendor gralloc 去重 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2864) | 2864 |  |  | R228 | R228 下一步 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2871) | 2871 | 2026-07-10 |  | R229 | R229：goldfish EmuHWC2 VsyncThread sp 修复 + Henry mmm 重编（2026-07-10 06:00–06:35） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2873) | 2873 |  |  | R228 | 根因（R228 ZYGLOG 回读） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2892) | 2892 |  |  | R229 | R229 冷启动 PID **35408** @ 06:35（Layer 状态） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2903) | 2903 |  |  | R229 | R229 新阻塞 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2910) | 2910 |  |  | R229 | R229 下一步（Henry 路径） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2915) | 2915 | 2026-07-10 |  | R230 | R230：干净单实例复现 host 崩溃（2026-07-10 06:49） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2924) | 2924 | 2026-07-10 |  | R231 | R231：minidump 根因 + guest GLES 补丁 + host NVIDIA 规避（2026-07-10 07:00–07:33） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2957) | 2957 |  |  | R231 | R231 冷启动 PID **38892** @ 07:32（guest-only 部署） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2964) | 2964 |  |  | R231 | R231 下一步（Henry 路径） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2971) | 2971 | 2026-07-10 |  | R232 | R232：guest egl `rcGLHostInfo` fixDrawBuffer + OpenglCodecCommon 强制重编（2026-07-10 07:42–07:56） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2988) | 2988 |  |  | R232 | R232 冷启动 PID **15064** @ 07:57 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L2996) | 2996 | 2026-07-10 |  | R233 | R233：host `libOpenglRender.dll` NVIDIA SF fixDrawBuffer 部署（2026-07-10 08:05–08:07） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3005) | 3005 |  |  | R232, R233 | R233 冷启动 PID **39696** @ 08:06（R232 Root.vhd + 新 libOpenglRender） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3020) | 3020 |  |  | R233 | R233 根因假设（待验证） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3025) | 3025 |  |  | R233 | R233 下一步（Henry 路径） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3033) | 3033 | 2026-07-10 |  | R234 | R234：device `init.x86.rc` 补齐 ranchu RenderEngine 属性（2026-07-10 08:26–08:38） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3051) | 3051 |  |  | R234 | R234 冷启动 PID **40100** @ 08:49 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3057) | 3057 | 2026-07-10 |  | R235 | R235：PGA GL trace 定位崩溃点（2026-07-10 08:53–08:54） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3070) | 3070 |  |  | R235 | R235 结论 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3075) | 3075 | 2026-07-10 |  | R236 | R236：NVIDIA 专用图形 workaround 回退 + Intel 验证（2026-07-10 09:46–09:49） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3105) | 3105 |  |  | R236 | R236 结论 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3109) | 3109 | 2026-07-10 |  | R238 | R238：`libhostcall_jni.so` Henry 构建链补齐（2026-07-10 10:06–10:52） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3136) | 3136 |  |  | R238 | R238 冷启动 PID **89204** @ 10:48（Intel Iris Xe） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3144) | 3144 |  |  | R238 | R238 结论 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3148) | 3148 | 2026-07-10 |  | R239 | R239：audio HAL 7.1 passthrough 修复尝试（2026-07-10 11:40–12:15） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3150) | 3150 |  |  | R238 | 根因（R238 日志） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3159) | 3159 |  |  | R239 | R239 修复 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3170) | 3170 |  |  | R239 | R239 冷启动 PID **6224** @ 12:13 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3178) | 3178 |  |  | R239 | R239 结论 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3181) | 3181 | 2026-07-10 |  | R240 | R240：Henry `hardware/bst/audio` 标准链路补齐（2026-07-10 13:28–14:48） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3190) | 3190 |  |  | R240 | scripts/r240-henry-bst-audio-copy.sh — copy hardware/bst from app-player/android-13 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3192) | 3192 |  |  | R240 | scripts/r240-pack-bst-audio-root.sh — stage HAL + alsa conf + system.sfs + Root.vhd |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3202) | 3202 |  |  | R240 | R240 冷启动 PID **28764** @ 14:46 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3211) | 3211 |  |  | R240 | R240 结论 / 下一阻塞 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3216) | 3216 | 2026-07-10 |  | R241 | R241：真 `audio@7.1-impl` + HIDL 传输库（2026-07-10 15:00–15:30） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3227) | 3227 | 2026-07-10 |  | R242 | R242：Henry pack — `file_contexts` → `mkuserimg`/`e2fsdroid`（2026-07-10 16:00–16:36） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3240) | 3240 |  |  | R242 | R242 冷启动 PID **30912** @ 16:36 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3248) | 3248 |  |  | R242 | R242 结论 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3251) | 3251 | 2026-07-10 |  | R243 | R243：Henry VINTF — 恢复 `audio@7.0` + `effect@7.0`（2026-07-10 16:40–17:03）✅ audio 阻塞解除 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3281) | 3281 |  |  | R243 | R243 冷启动 PID **29488** @ 16:57（回读） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3291) | 3291 |  |  | R243 | R243 结论 / 下一阻塞 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3295) | 3295 | 2026-07-10 |  | R243b | R243b：无 boot_completed / 有 bootanim 无桌面 — 主因诊断（2026-07-10 17:06） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3326) | 3326 | 2026-07-10 |  | R244 | R244：恢复 Henry 7R init 控制流（去 bringup skip）→ odsign 真跑（2026-07-10 17:13–18:05） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3362) | 3362 |  |  | R244 | R244 冷启动 PID **9596** @ 17:56（回读，仅 marker 之后） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3387) | 3387 |  |  | R244b | R244b 尝试：`Data_orig.vhdx` 清 keystore 状态 ❌ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3392) | 3392 |  |  | R245 | 下一 Henry 步（R245） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3397) | 3397 | 2026-07-10 |  | R245 | R245：清陈旧 keystore → Henry 7R 全链打通（2026-07-10 18:08–18:49）✅ odrefresh exit(80) |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3399) | 3399 |  |  | R244 | 根因（R244 续） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3412) | 3412 |  |  | R245 | R245 冷启动 PID **2872** @ 18:41（回读） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3429) | 3429 |  |  | R246 | 下一 Henry 步（R246） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3434) | 3434 | 2026-07-13 |  | R246 | R246：PMS 卡点诊断 — `/metadata` 只读 + aconfig art 缺图（2026-07-13） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3436) | 3436 |  |  | R245 | 背景（R245 续） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3439) | 3439 |  |  | R245 | R245 日志回读（独立证据） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3456) | 3456 |  |  | R246 | 动作（R246，Henry 对齐） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3463) | 3463 |  |  | R246 | 成功判据（R246 冷启动） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3473) | 3473 |  |  | R247 | 下一 Henry 步（R247） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3478) | 3478 | 2026-07-13 |  | R246 | R246 冷启动回读（2026-07-13 10:07，PID **6816**） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3519) | 3519 |  |  | R247 | 下一 Henry 步（R247） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3525) | 3525 | 2026-07-13 |  | R247 | R247：Henry 7X-2 — `start installd` 提前到 `on boot`（2026-07-13） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3554) | 3554 |  |  | R248 | 新阻塞（→ R248） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3563) | 3563 |  |  | R248 | R248：Henry 7W-2 + 7X-1 — 禁用 HintManagerService / BiometricService（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3572) | 3572 |  |  | R248 | R248 冷启动回读（PID 14872，`=== R248 HintManager disable boot ===`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3582) | 3582 |  |  | R249 | 新阻塞（→ R249 = Henry §7Y） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3590) | 3590 |  |  | R249 | R249：Henry 7Y — `/proc/config.gz` CHECK → ALOGW（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3597) | 3597 |  |  | R249 | R249 冷启动回读（PID 17304，`=== R249 config.gz ALOGW boot ===`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3611) | 3611 |  |  | R250 | R250：Henry 7AA-1 — `llndk.libraries.txt` chmod 644（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3621) | 3621 |  |  | R250 | R250 冷启动（PID 14140） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3629) | 3629 |  |  | R251 | R251：SecureLockDeviceService null-safe（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3636) | 3636 |  |  | R251 | R251 冷启动（PID 15988，Root `615fb07c…`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3644) | 3644 |  |  | R252 | R252：禁用 AuthService + AuthenticationPolicyService（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3648) | 3648 |  |  | R252 | R252：禁用 AuthService + AuthenticationPolicyService（回读） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3655) | 3655 |  |  | R252 | R252 冷启动 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3658) | 3658 |  |  | R253 | R253：SystemUI AuthController null-safe（VERIFIED） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3665) | 3665 |  |  | R253 | R253 冷启动回读（PID 10104，Root `cc7c2f70e0ec439641dbaacf03f26cb6`，`=== R253 AuthController null-safe boot ===`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3678) | 3678 |  |  | R254 | R254：Henry 7h — `libgcall_jni.so` Baklava64 `BUILD_T` + 打包（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3688) | 3688 |  |  | R254 | R254：Henry 7h — `libgcall_jni.so` Baklava64 `BUILD_T`（VERIFIED） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3703) | 3703 |  |  | R254 | R254 冷启动回读（PID **18600**） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3713) | 3713 |  |  | R255 | R255：WMS `bstSendTopDisplayedOnFocusChange`（进行中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3722) | 3722 |  |  | R255b | R255b 回读（PID 8452，Root `c09b4ba7…`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3732) | 3732 |  |  | R255c | R255c：owningPackage fallback（打包中） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3735) | 3735 |  |  | R255c | R255c 冷启动回读（PID **21196**，Root `5795ed5cf1279d3a3cf344c559c37b4a`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3746) | 3746 |  |  | R256 | R256：Henry WidgetManagerHelper AppWidget null-guard（VERIFIED 部分） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3753) | 3753 |  |  | R256 | R256 冷启动（PID 33924，Root `2c71942f…`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3761) | 3761 |  |  | R257 | R257：Henry 去 Launcher3 HOME + 系统化 `com.uncube.launcher3` |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3769) | 3769 |  |  | R257 | R257 冷启动：uncube 成为 top-activity，但 `libflutter.so` 缺失（priv-app 未抽出 `lib/x86_64`）→ crash-loop。 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3771) | 3771 |  |  | R257b | R257b：uncube `lib/x86_64/{libflutter,libapp}.so` 旁路抽出（VERIFIED 部分） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3775) | 3775 |  |  | R258 | R258：Henry `LockPatternUtils.isLockScreenDisabled()→true` |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3784) | 3784 |  |  | R259 | R259：ActivityRecord RESUMED → `bstNotifyActivityDisplayed`（VERIFIED ✅） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3791) | 3791 |  |  | R259 | R259 冷启动回读（PID **13808**，Root `204309a41599d2b161f5c335e49a077d`，`=== R259 RESUMED ActivityDisplayed boot ===`） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3801) | 3801 |  |  | R260 | R260：Henry 优雅关机闭环（`A16-init-bringup-notes` P0+P1） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3832) | 3832 | 2026-07-14 |  | R260 | R260 部署（2026-07-14 11:37） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3840) | 3840 |  |  | R260 | R260 冷启动回读（PID **22152**，~11:38–13:31）— overlay 未消失 |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3854) | 3854 |  |  | R247, R260b | R260b：恢复 R247 `start installd` + 重打 Root（已部署） |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3866) | 3866 |  |  | R260b | R260b 冷启动 + 关机回读（PID **15688**，Root `a01efe96…`）— VERIFIED ✅ |
| [`progress/archive/android-16-boot-debug.md`](../../../progress/archive/android-16-boot-debug.md#L3876) | 3876 |  |  | R261 | R261：恢复 AuthService → Settings 白屏（VERIFIED ✅） |

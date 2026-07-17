# Registry JSON Schema v2

权威文件：[`registry.json`](registry.json)。机器可读进度；人类汇总见 [`registry.md`](registry.md)。

## 顶层字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `schema_version` | number | `2` |
| `base_from` | string | `"android-13"` |
| `base_to` | string | `"android-16.0.0_r4"` |
| `generated_at` | string | ISO 日期 |
| `win_tree` | string | 远程路径 |
| `mac_tree` | string | 远程路径 |
| `platform_priority` | string | `"win 先行验证, mac 同码复用"` |
| `method_note` | string | 生成方法说明 |
| `phase_groups` | object | `G1`…`G10` 等组元数据（title/phase/deps） |
| `patches` | array | 条目列表 |

## 每条 patch 字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | Y | 唯一 id，如 `win-device-generic-common` 或 `boot-aosp16-system-core` |
| `platform` | string | Y | `win` \| `mac` \| `both` |
| `project_path` | string | Y | AOSP/相对路径，如 `device/bst/qvirt` |
| `area` | string | Y | `device`/`kernel`/`frameworks`/`hardware`/`system`/`external`/`build`/`packages`/`prebuilts`/`bootimage`/`other` |
| `unify_group` | string\|null | Y | 跨平台统一组名；无可统一对应则 null |
| `related_group` | string\|null | Y | patch-group id：`G1`…`G10` 或 `P2-...`；临时债可用 `TEMP` |
| `phase` | string | Y | `P1` \| `P2` \| `P3` |
| `temp_debt` | boolean | Y | 临时 bringup hack / 待收口 |
| `source_commit` | string\|null | | fork 上的源 commit（短或长 SHA） |
| `base_tag` | string\|null | | 相对上游 android-13 tag |
| `since_count` | number\|null | | tag..HEAD 提交数（参考） |
| `bst_count` | number\|null | | 作者过滤命中数（参考，不可唯一权威） |
| `has_bst` | boolean\|null | | |
| `confidence` | string | | `high` \| `medium` \| `low` \| `boot-proven` |
| `purpose` | string | | 用途说明 |
| `quality` | string | | 质量评估（清晰度/接缝/是否 hack） |
| `impact` | string | | 影响评估（构建/启动/契约/依赖） |
| `port_status` | string | Y | `pending` \| `in-progress` \| `ported` \| `blocked` \| `dropped` \| `boot-archived` |
| `host_compat` | string | Y | `unknown` \| `ok` \| `broken` \| `pending` |
| `verification` | string\|null | | Layer1/Layer2 证据摘要 |
| `checkpoint_ref` | string\|null | | 如 `patches/android-16/RESTORE.md` 或 `patches/android-16/checkpoints/G1.md` |
| `boot_artifact` | string\|null | | 对应 `aosp16__*.patch` / untracked 路径 |
| `owner` | string | | 默认 `agent` |
| `notes` | string\|null | | |

## `phase_groups` 示例

```json
{
  "G1": {
    "title": "统一板 device/bst/qvirt (x86_64+arm64)",
    "phase": "P1",
    "deps": [],
    "layer2_required": true
  }
}
```

## 迁移说明

- v1（457 项 triage，错位树）→ **作废**，保留只读备份 `registry.v1.backup.json`（若存在）。
- v2 由：① 远程双端重生成；② boot 存量（`patches/android-16/`）映射 合并而成。
- `port_status=boot-archived`：已在 M1 boot 树中、待 Phase 1 融合转正的条目。

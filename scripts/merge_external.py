import json
from pathlib import Path
from collections import Counter

PATCHES = Path(r'c:/workspace/bst-aosp/patches')
reg = PATCHES / 'registry.json'
d = json.loads(reg.read_text(encoding='utf-8'))
by_id = {x['id']: x for x in d['patches']}
existing_ext = {(x['platform'], x['project_path']) for x in d['patches'] if x.get('area') == 'external'}

def load(p):
    rows = []
    if not p.exists():
        return rows
    for ln in p.read_text(encoding='utf-8').splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            rows.append(json.loads(ln))
        except json.JSONDecodeError:
            pass
    return rows

added = 0
for r in load(PATCHES / 'triage_ext_win.jsonl') + load(PATCHES / 'triage_ext_mac.jsonl'):
    key = (r.get('platform'), r.get('project_path'))
    if key in existing_ext or r['id'] in by_id:
        # refresh stats on existing
        if r['id'] in by_id:
            e = by_id[r['id']]
            e['base_tag'] = r.get('base_tag') or e.get('base_tag')
            e['bst_count'] = r.get('bst_count')
            e['confidence'] = r.get('confidence') or e.get('confidence')
        continue
    e = {
        'id': r['id'], 'platform': r['platform'], 'project_path': r['project_path'],
        'area': 'external', 'unify_group': 'external', 'related_group': None,
        'phase': 'P2', 'temp_debt': False, 'source_commit': None,
        'base_tag': r.get('base_tag'), 'since_count': r.get('since_count'),
        'bst_count': r.get('bst_count'), 'has_bst': True, 'confidence': r.get('confidence', 'high'),
        'purpose': f"fork 偏离上游 android-13（{r['project_path']}）",
        'quality': '高置信 bst 信号', 'impact': '待 Phase2 评估', 'port_status': 'pending',
        'host_compat': 'unknown', 'verification': None, 'checkpoint_ref': None,
        'boot_artifact': None, 'owner': 'agent', 'notes': 'external 补采 (triage_external.sh)',
    }
    d['patches'].append(e)
    by_id[e['id']] = e
    existing_ext.add(key)
    added += 1

# unify: external present in both platforms
from collections import defaultdict
proj = defaultdict(set)
for x in d['patches']:
    if x.get('area') == 'external':
        proj[x['project_path']].add(x['platform'])
for x in d['patches']:
    if x.get('area') == 'external' and proj[x['project_path']] >= {'win', 'mac'}:
        x['notes'] = (x.get('notes') or '') + ' | dual-platform candidate'

d['method_note'] = d.get('method_note', '') + ' | external 补采完成 (win+mac)。'
reg.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('added external', added, 'total', len(d['patches']))
print('phase', dict(Counter(x['phase'] for x in d['patches'])))
print('external win', sum(1 for x in d['patches'] if x['area']=='external' and x['platform']=='win'))
print('external mac', sum(1 for x in d['patches'] if x['area']=='external' and x['platform']=='mac'))

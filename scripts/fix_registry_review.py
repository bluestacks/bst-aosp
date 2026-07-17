import json
from pathlib import Path
p = Path(r'c:/workspace/bst-aosp/patches/registry.json')
d = json.loads(p.read_text(encoding='utf-8'))
by = {x['id']: x for x in d['patches']}

# --- P0: whole-project large feature carriers → P2 (boot-* stays P1 minimal) ---
demote_p2 = {
    'win-frameworks-base': 'P2-FRAMEWORK-REST',
    'mac-frameworks-base': 'P2-FRAMEWORK-REST',
    'win-frameworks-native': 'P2-FRAMEWORK-REST',
    'mac-frameworks-native': 'P2-FRAMEWORK-REST',
}
for pid, grp in demote_p2.items():
    if pid in by:
        e = by[pid]
        e['phase'] = 'P2'
        e['related_group'] = grp
        e['unify_group'] = 'bst-framework'
        e['notes'] = (e.get('notes') or '') + (
            ' | P0-fix: 全项目特性集属 P2；boot-minimal 子集由 boot-frameworks-* 在 P1/G5 承担'
        )

# --- P2: mac Pixel / physical-device HALs irrelevant to qvirt emulator → dropped/P3 ---
pixel_drop = [
    'mac-hardware-google-pixel', 'mac-hardware-google-gchips',
    'mac-hardware-google-graphics-common', 'mac-hardware-google-graphics-gs101',
    'mac-hardware-google-graphics-gs201', 'mac-hardware-google-camera',
    'mac-hardware-google-interfaces', 'mac-hardware-google-pixel-sepolicy',
    'mac-hardware-nxp-nfc', 'mac-hardware-st-nfc', 'mac-hardware-st-secure_element',
    'mac-hardware-qcom-wlan', 'mac-hardware-broadcom-wlan',
]
dropped = []
for pid in pixel_drop:
    if pid in by:
        e = by[pid]
        e['phase'] = 'P3'
        e['related_group'] = None
        e['unify_group'] = None
        e['port_status'] = 'dropped'
        e['confidence'] = 'low'
        e['notes'] = (e.get('notes') or '') + ' | P2-fix: Pixel/物理设备 HAL，与 qvirt 模拟器无关，排除'
        dropped.append(pid)

# --- P4: null bogus since_count (r83 tag mismatch) ---
for e in d['patches']:
    sc = e.get('since_count')
    if isinstance(sc, int) and sc > 5000:
        e['notes'] = (e.get('notes') or '') + f' | P4-fix: since={sc} 为 r83 tag 误配，置空（以 bst_count 为准）'
        e['since_count'] = None

# --- keep hardware/bst + interfaces/libhardware in G8 ---
d['generated_at'] = str(__import__('datetime').date.today())
d['method_note'] = d.get('method_note', '') + ' | review-fix 2026-07-15: frameworks 全项目降 P2、mac Pixel HAL 排除、bogus since 清理。'
d['patches'] = list(by.values())
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

from collections import Counter
print('total', len(d['patches']))
print('phase', dict(Counter(x['phase'] for x in d['patches'])))
print('status', dict(Counter(x['port_status'] for x in d['patches'])))
print('dropped pixel', len(dropped))
print('P1 pending non-boot now:', sum(1 for x in d['patches'] if x['phase']=='P1' and x['port_status']=='pending'))
print('G8 P1 pending:', sum(1 for x in d['patches'] if x.get('related_group')=='G8' and x['port_status']=='pending' and x['phase']=='P1'))

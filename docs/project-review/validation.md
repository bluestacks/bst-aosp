# Static Validation

> This validation reads only this repository. Historical Bash is normalized
> in memory for parsing so archived byte identity is not changed.

- Results: `expected-failure`=1, `pass`=622
- Allowlist: [`validation-allowlist.json`](validation-allowlist.json)

## Exceptions

| Status | Check | Path | Detail |
|---|---|---|---|
| expected-failure | `python-ast` | `scripts/p2_mech2_apply.py` | Historical cont.65 authoring residue: lines 20-21 are a truncated earlier comment-block attempt. The successful change is preserved in the canonical patch and Layer 2 record; rewriting this script would falsify the development record. |

Run:

```bash
python scripts/validate_project_files.py
python scripts/validate_project_files.py --check
```

# Binary Artifact Workflow

The repository records binary identity and retention decisions, but Git is not
the storage system for the 16 required external Henry boot artifacts. Their
canonical classification is generated in
[`binary-retention.json`](../project-review/binary-retention.json).

## Retention Boundary

- Keep the seven small, canonical historical payloads already tracked by Git.
- Keep the 16 non-reconstructable boot inputs in three external bundles.
- Do not retain the ten duplicate layout copies or seven generated
  intermediates as independent artifacts.
- Never restore signing credentials from history. The keystore record is a
  security tombstone and requires external rotation.
- For a source patch that mixes reviewable code with a restricted prebuilt,
  keep one `git format-patch --no-binary` record plus the source commit, Git
  blob, byte count and SHA-256. Do not duplicate the binary delta in patch
  archives; record its license/publication gate separately.

The three required bundles contain 28.88 MiB of member data:

| Bundle | Files | Member bytes | Purpose |
|---|---:|---:|---|
| `henry-boot-baseline` | 2 | 9.24 MiB | Boot kernel and boot initrd |
| `henry-fastboot-baseline` | 3 | 18.68 MiB | Fastboot kernel, canonical initrd, and final image |
| `henry-initrd-runtime` | 11 | 0.96 MiB | Runtime configuration and kernel modules |

## Local Packaging

The helper reads only entries classified as `external-artifact-required`. It
verifies every source byte against the committed size and SHA-256 before
writing an archive.

```bash
python scripts/manage_binary_artifacts.py plan
python scripts/manage_binary_artifacts.py pack
python scripts/manage_binary_artifacts.py verify
```

Archives and `.sha256` sidecars are written under
`artifacts/binary-retention/`, which is ignored by Git. Archives use
deterministic, uncompressed ZIP entries with fixed metadata. Repacking the same
members therefore produces the same archive SHA-256 and requires only about
29 MiB of additional local space. The expected archive sizes and hashes are
committed in
[`binary-artifact-staging.json`](../project-review/binary-artifact-staging.json).
The staging record binds to a canonical JSON digest of the retention manifest,
so LF/CRLF checkout policy cannot change its identity. The tool rejects an
archive that differs from this staging identity.

Use `--bundle NAME` to operate on one bundle or `--archive-dir PATH` to stage
archives directly in an approved upload area.

## Restore

```bash
python scripts/manage_binary_artifacts.py restore
```

Restore verifies the archive sidecar, embedded manifest, member list, member
sizes, and member SHA-256 values. It creates only missing files and refuses to
overwrite a path whose bytes differ. `--destination-root PATH` supports a clean
checkout or a temporary verification directory.

## Publication Gate

A bundle is not authoritative merely because a local ZIP exists. Before
closing the corresponding retention blocker:

1. Upload the ZIP and `.sha256` sidecar to an approved immutable artifact
   store.
2. Record the retrieval URI, access owner, archive SHA-256, source tree,
   branch, commit, kernel ABI, and applicable toolchain identity.
3. Download into a clean checkout, run `verify`, then run `restore` into a
   temporary root.
4. Confirm all restored members match
   [`binary-local-evidence.json`](../project-review/binary-local-evidence.json).

GitHub Release assets or an internal immutable artifact store are suitable for
this fixed historical baseline. Git LFS is unnecessary unless these binaries
become frequently changing development inputs.

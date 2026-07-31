# Aggregate and Candidate Snapshot Review

These five artifacts overlap later surgical patches. They are useful for intent
and coverage analysis, but they are not an ordered replay series.

### `aosp16__frameworks_base__P2-batchA-applied.diff`

- **Code/purpose:** expands `BstUtils` with package/profile, accessibility,
  property, serialization and helper behavior used by later framework hooks.
- **Review:** **P1/P0 ownership risk**. A single utility class accumulates file
  I/O, service lookup, caller classification, Base64/serialization and policy.
  This makes permission and StrictMode behavior hard to reason about.
- **Performance:** potentially `high` depending on which helpers are called from
  Display, Settings, accessibility and input paths.
- **Necessity/status:** `audit-only/superseded`; portions were later ported and
  metalava-adjusted through reviewed framework commits.
- **Recommendation:** split pure helpers from service-backed policy, document
  thread/permission contracts and unit-test each retained method.

### `aosp16__frameworks_base__P2-batchB-surgical.diff`

- **Code/purpose:** early ActivityStarter and WindowManagerService hostcall/GRM
  adaptation.
- **Review:** **P1 boot-critical**. This experiment helped identify launch and
  orientation hooks, but the initial Batch B deployment participated in a
  `system_server` regression.
- **Performance:** `medium/high` if hostcalls occur in launch/orientation hot
  paths.
- **Necessity/status:** `superseded` by
  `P2-FW-WM-1-ActivityStarter-ATM.diff` and later focused WMS commits.
- **Recommendation:** never apply after WM-1; use it only to compare omitted
  source intent.

### `p2_fw_batchA_gaps_only.patch`

- **Code/purpose:** imports pagefusion sources plus the `Sdk23` compatibility
  helper that were absent from the first framework overlay.
- **Review:** **P1**. Pagefusion is a self-contained native subsystem and should
  not share a replay unit with a Java compatibility helper. The original
  page-size assumption needed an Android 16 fix.
- **Performance:** pagefusion can have `high` invocation-time CPU/memory impact;
  `Sdk23` is negligible.
- **Necessity/status:** `superseded` by the dedicated pagefusion patch and final
  framework commits.
- **Recommendation:** preserve separate build/test ownership and do not replay
  this combined artifact.

### `p2_fw_batchA_upgrade.patch`

- **Code/purpose:** raw `diff -ruN` upgrade snapshot for `BstUtils` and the BST
  Java manager classes.
- **Review:** **P1 restore risk**. Timestamped non-git diff format and broad
  class replacement make three-way application and provenance weaker than
  project commits.
- **Performance:** manager behavior includes Binder and profile queries; cost
  depends on callers.
- **Necessity/status:** `audit-only`; final manager implementations are tracked
  by the merged frameworks/base history.
- **Recommendation:** use SHA-identified source commits or generated git
  patches, not this artifact, for recovery.

### `p2_fw_batchB_hooks.patch`

- **Code/purpose:** a 4.8 MiB candidate bundle spanning 25 framework/SystemUI/
  system_server files and thousands of hunks.
- **Review:** **P0 rejected**. The patch contains large Android 13 file deltas,
  including removal of Android 16 imports/APIs unrelated to BST. It is
  effectively an old-source overlay, not a surgical customization patch.
- **Performance:** impossible to assess as a unit; it touches activity, input,
  audio, clipboard, notification, account, SystemUI and WM hot paths.
- **Necessity/status:** `rejected/audit-only`. Later CORE-APP, SERVICES,
  PERIPH and WM patches capture the accepted behavior.
- **Recommendation:** never apply. Retain only until a coverage tool confirms
  every desired BST behavior is either ported or explicitly dropped.

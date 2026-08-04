#!/usr/bin/env python3
"""Generate the repository-wide review inventory and development timelines."""

from __future__ import annotations

import argparse
import ast
import hashlib
import io
import json
import mimetypes
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "docs" / "project-review"
HISTORY_DIR = ROOT / "docs" / "development-history"
AOSP16_HISTORY_DIR = HISTORY_DIR / "aosp16"
PROMOTION_HISTORY_DIR = HISTORY_DIR / "android16-merge"
LOCAL_BINARY_EVIDENCE_PATH = REVIEW_DIR / "binary-local-evidence.json"
EXCLUDED_PARTS = {".git", ".codex-tmp", ".triage_tmp", "__pycache__"}
EXCLUDED_PREFIXES = (".tmp-", ".work-", "tmp-")

GENERATED_PATHS = {
    "docs/project-review/README.md",
    "docs/project-review/findings.md",
    "docs/project-review/inventory.json",
    "docs/project-review/inventory.md",
    "docs/project-review/inventory.schema.json",
    "docs/project-review/validation.json",
    "docs/project-review/validation.md",
    "docs/project-review/binary-retention.json",
    "docs/project-review/binary-retention.md",
    "docs/android-16-patch-review/patch-inventory.json",
    "docs/android-16-patch-review/patch-inventory.md",
    "docs/development-history/timeline.json",
    "docs/development-history/aosp16/timeline.md",
    "docs/development-history/android16-merge/timeline.md",
    "docs/development-history/android16-merge/patch-traceability.md",
}
REMOVED_PATHS = {
    "patches/android-16/untracked-src/aosp16__device_generic_common/"
    "apksigner/bluestacks-market.keystore",
}

TEXT_SUFFIXES = {
    "",
    ".base",
    ".bp",
    ".cfg",
    ".conf",
    ".diff",
    ".go",
    ".gradle",
    ".h",
    ".hpp",
    ".idc",
    ".java",
    ".json",
    ".jsonl",
    ".log",
    ".md",
    ".mk",
    ".patch",
    ".properties",
    ".ps1",
    ".py",
    ".rc",
    ".remote",
    ".sh",
    ".status",
    ".txt",
    ".xml",
}

SCRIPT_TOKEN_RE = re.compile(
    r"(?<![\w.-])(?:scripts/)?([A-Za-z0-9_.-]+\.(?:sh|py|ps1))(?![\w.-])"
)
TIMELINE_TOKEN_RES = (
    re.compile(r"\bcont\.(\d+)\b", re.IGNORECASE),
    re.compile(r"\bR(\d+[a-z]?)\b", re.IGNORECASE),
    re.compile(r"\bRound\s+(\d+[a-z]?)\b", re.IGNORECASE),
    re.compile(r"\b(G\d+)\b"),
    re.compile(r"\b(P2-[A-Za-z0-9-]+)\b", re.IGNORECASE),
    re.compile(r"\b(20\d{2}-\d{2}-\d{2})\b"),
)
SECRET_NAME_RE = re.compile(
    r"(?i)(keystore|private[-_.]?key|credential|password|passwd|secret|token)"
)
SECRET_ARTIFACT_SUFFIXES = {".jks", ".key", ".keystore", ".p12", ".pfx", ".pem"}
EXPECTED_VALIDATION_FAILURES = {
    "scripts/p2_mech2_apply.py": (
        "accepted-historical",
        "patches/android-16/patches/p2-framework-rest/"
        "P2-MECH-2-launcher3-manifest.diff",
    )
}
PRIVATE_KEY_RE = re.compile(
    r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"
)
SECRET_ASSIGNMENT_RE = re.compile(
    r"(?i)\b(password|passwd|secret|token|api[_-]?key|private[_-]?key)\b\s*[:=]"
)
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
ANDROID16_ACTIVE_SCRIPTS = {
    "scripts/audit_a16_merge.sh",
    "scripts/audit_android16_promotion.py",
    "scripts/g1_apply_boot_overlays.sh",
    "scripts/g1_boot_verify.ps1",
    "scripts/g1_build_android16.sh",
    "scripts/g1_build_libs.sh",
    "scripts/g1_build_pack.sh",
    "scripts/g1_copy_bst_apks.sh",
    "scripts/g1_pack_root.sh",
    "scripts/g1_rebuild_graphics.sh",
    "scripts/g1_stage_system.sh",
    "scripts/g1_start_pack_remote.sh",
    "scripts/g1_win_deploy.ps1",
    "scripts/g8_disable_vendor_hal_rc.sh",
    "scripts/generate_android16_patch_inventory.py",
    "scripts/lib/android16_env.sh",
    "scripts/merge_aosp16_to_android16.sh",
    "scripts/patch-goldfish-emuhwc2-vsync-sp.py",
    "scripts/patch-goldfish-hwc2-bst-product.py",
}
SHARED_REPOSITORY_TOOLS = {
    "scripts/generate_project_review.py",
    "scripts/manage_binary_artifacts.py",
    "scripts/validate_project_files.py",
}


def git_lines(*args: str) -> list[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return [line for line in result.stdout.splitlines() if line]


def git_zpaths(*args: str) -> set[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return {
        item.decode("utf-8", errors="replace").replace("\\", "/")
        for item in result.stdout.split(b"\0")
        if item
    }


def git_state() -> tuple[set[str], set[str], set[str], dict[str, str]]:
    tracked = git_zpaths("ls-files", "-z")
    untracked = git_zpaths("ls-files", "--others", "--exclude-standard", "-z")
    ignored = git_zpaths(
        "ls-files", "--others", "--ignored", "--exclude-standard", "-z"
    )
    porcelain: dict[str, str] = {}
    for line in git_lines("status", "--porcelain=v1", "--untracked-files=all"):
        status = line[:2]
        raw_path = line[3:]
        if " -> " in raw_path:
            raw_path = raw_path.split(" -> ", 1)[1]
        porcelain[raw_path.replace("\\", "/")] = status
    return tracked, untracked, ignored, porcelain


def git_index_blobs(paths: list[str]) -> dict[str, bytes]:
    if not paths:
        return {}
    queries = b"".join(
        f":{path}\n".encode("utf-8", errors="surrogateescape")
        for path in paths
    )
    result = subprocess.run(
        ["git", "cat-file", "--batch"],
        cwd=ROOT,
        check=True,
        input=queries,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    stream = io.BytesIO(result.stdout)
    blobs: dict[str, bytes] = {}
    for path in paths:
        header = stream.readline().decode("utf-8", errors="replace").rstrip("\n")
        if header.endswith(" missing"):
            continue
        fields = header.rsplit(" ", 2)
        if len(fields) != 3 or fields[1] != "blob":
            raise RuntimeError(f"unexpected git cat-file response for {path}: {header}")
        size = int(fields[2])
        blobs[path] = stream.read(size)
        if stream.read(1) != b"\n":
            raise RuntimeError(f"invalid git cat-file delimiter after {path}")
    return blobs


def excluded(path: Path) -> bool:
    parts = path.relative_to(ROOT).parts
    return any(
        part in EXCLUDED_PARTS or part.startswith(EXCLUDED_PREFIXES)
        for part in parts
    )


def all_paths() -> list[str]:
    ignored = git_zpaths(
        "ls-files", "--others", "--ignored", "--exclude-standard", "-z"
    )
    paths = {
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and not excluded(path)
        and path.relative_to(ROOT).as_posix() not in ignored
    }
    paths.update(git_zpaths("ls-files", "-z"))
    paths.update(GENERATED_PATHS)
    paths.update(REMOVED_PATHS)
    return sorted(paths)


def decode_text(data: bytes, suffix: str) -> tuple[str | None, str]:
    if b"\0" in data[:8192] and suffix not in TEXT_SUFFIXES:
        return None, "binary"
    for encoding in ("utf-8-sig", "utf-8"):
        try:
            return data.decode(encoding), encoding
        except UnicodeDecodeError:
            pass
    return None, "binary"


def line_endings(data: bytes, text: str | None) -> str:
    if text is None:
        return "binary"
    crlf = data.count(b"\r\n")
    bare_cr = data.replace(b"\r\n", b"").count(b"\r")
    lf = data.count(b"\n") - crlf
    if crlf and (lf or bare_cr):
        return "mixed"
    if crlf:
        return "crlf"
    if lf:
        return "lf"
    return "none"


def first_description(path: str, text: str | None) -> str:
    if text is None:
        return "Binary or packaged reference artifact."
    lines = text.splitlines()
    if path.endswith(".md"):
        for line in lines:
            if line.startswith("#"):
                return line.lstrip("# ").strip()[:240]
    if path.endswith(".py"):
        try:
            module = ast.parse(text)
            doc = ast.get_docstring(module)
            if doc:
                return doc.splitlines()[0][:240]
        except SyntaxError:
            pass
    for line in lines[:30]:
        stripped = line.strip()
        if not stripped or stripped.startswith("#!"):
            continue
        if stripped.startswith(("#", "//", "<!--")):
            return stripped.lstrip("#/<!- ").rstrip("-> ").strip()[:240]
        break
    return purpose_from_path(path)


def purpose_from_path(path: str) -> str:
    if path.startswith(".claude/commands/"):
        return "Claude command adapter for the repository development workflow."
    if path.startswith(".claude/rules/"):
        return "Normative development and validation rule."
    if path.startswith("patches/android-16/patches/"):
        return "Archived AOSP16 customization patch used for replay and promotion review."
    if path.startswith("patches/android-16/a13-authority/"):
        return "Frozen Android 13 authority commit patch used for code-level port coverage review."
    if path.startswith("patches/android-16/a13-completion/"):
        return "Reviewed Android 16 promotion commit patch and root-pointer evidence."
    if path.startswith("patches/android-16/untracked-src/"):
        return "Source or payload snapshot that was not represented by a Git diff."
    if path.startswith("progress/"):
        return "Chronological engineering record and validation evidence."
    if path.startswith("references/"):
        return "External or historical comparison reference."
    if path.startswith("scripts/archive/"):
        return "Historical executable record from an AOSP16 bring-up iteration."
    if path.startswith("scripts/"):
        return "Build, migration, audit, packaging, or diagnostic helper."
    if path.startswith("docs/"):
        return "Project documentation and review output."
    return "Repository configuration or project entry document."


def classify_stage(path: str, text: str | None) -> str:
    lower = path.lower()
    if path in GENERATED_PATHS or lower.startswith((".codex-tmp/", ".triage_tmp/")):
        return "generated"
    if path in SHARED_REPOSITORY_TOOLS:
        return "shared"
    if path in ANDROID16_ACTIVE_SCRIPTS:
        return "android16-promotion"
    if lower.startswith("references/"):
        return "reference"
    if lower.startswith("docs/development-history/aosp16/"):
        return "aosp16-development"
    if lower.startswith("docs/development-history/android16-merge/"):
        return "android16-promotion"
    if lower.startswith("docs/android-16-patch-review/"):
        return "android16-promotion"
    if lower.startswith((
        "patches/android-16/a13-authority/",
        "patches/android-16/a13-completion/",
    )):
        return "android16-promotion"
    if lower.startswith("patches/android-16/"):
        return "aosp16-development"
    if any(
        token in lower
        for token in (
            "merge_aosp16_to_android16",
            "audit_a16_merge",
            "g1_build_android16",
            "android16-promotion",
            "resolve_kernel_conflicts",
            "libhidl_drop_mgr_token",
            "aemu_host_supported",
        )
    ):
        return "android16-promotion"
    if lower.startswith("progress/archive/"):
        return "aosp16-development"
    if lower == "progress/porting-log.md":
        return "shared"
    if lower.startswith("scripts/archive/"):
        return "aosp16-development"
    if text and "~/aosp16" in text:
        return "aosp16-development"
    if text and (
        "~/android-16" in text
        or "aosp16-bst-merge" in text
        or "mark-bst" in text
    ):
        return "android16-promotion"
    if lower.startswith("scripts/"):
        return "aosp16-development"
    return "shared"


def infer_origin_target(stage: str) -> tuple[str | None, str | None]:
    if stage == "aosp16-development":
        return "android-13/AOSP16 bring-up inputs", "aosp16"
    if stage == "android16-promotion":
        return "aosp16 validated development line", "android-16 mainline"
    return None, None


def infer_result(path: str, stage: str, text: str | None) -> str:
    lower = path.lower()
    if stage == "generated":
        return "generated"
    if any(token in lower for token in ("failed", "revert", "broken")):
        return "failed"
    if lower.startswith("scripts/archive/"):
        return "superseded"
    if lower.startswith("progress/archive/"):
        return "recorded"
    if lower.endswith((".status", ".base")):
        return "recorded"
    if text and re.search(r"(?i)(已废弃|reverted|failed|syntax error)", text[:5000]):
        return "recorded"
    if stage in {"android16-promotion", "shared"}:
        return "current"
    return "recorded"


def infer_preservation(path: str, stage: str) -> str:
    if is_secret_artifact(path):
        return "external-secret"
    if stage == "generated":
        return "generated"
    if stage in {"aosp16-development", "reference"}:
        return "historical-first-class"
    return "active"


def infer_replacement(path: str) -> str | None:
    expected = EXPECTED_VALIDATION_FAILURES.get(path)
    if expected:
        return expected[1]
    if is_secret_artifact(path):
        return "approved external signing injection; rotate the recorded credential"
    return None


def infer_availability(
    path: str, git_state: str, exists: bool
) -> tuple[str, str]:
    if path in REMOVED_PATHS and not exists:
        return "removed-tombstone", "security-and-provenance-record"
    if path in GENERATED_PATHS:
        return "generated", "regenerable"
    if git_state == "tracked":
        return "repository", "repository-authoritative"
    if git_state in {"ignored", "untracked", "filesystem-only"}:
        return "local-only", "local-observation"
    return "unknown", "unresolved"


def infer_necessity(path: str, stage: str) -> str:
    if stage == "generated":
        return "Regenerable; do not treat as a source of truth."
    if stage == "aosp16-development":
        return "Required for provenance, replay analysis, or failure-to-fix traceability."
    if stage == "reference":
        return "Retain when its provenance or binary identity supports comparison."
    if path.startswith("scripts/"):
        return "Review as an active entry point, helper, or compatibility surface."
    return "Retain unless a canonical replacement and inbound-reference audit prove redundancy."


def infer_performance(path: str, stage: str, size: int) -> str:
    if path.endswith((".sh", ".py", ".ps1")):
        return "No guest runtime cost by itself; may materially affect build, copy, or packaging time."
    if path.endswith((".patch", ".diff")):
        return "Review changed code for runtime impact; artifact itself only affects storage and review time."
    if stage == "reference" or size > 1024 * 1024:
        return "Storage and checkout cost; no runtime cost unless injected into a build artifact."
    return "No material runtime cost identified from repository role."


def timeline_refs(text: str | None) -> list[str]:
    if not text:
        return []
    refs: set[str] = set()
    for regex in TIMELINE_TOKEN_RES:
        for match in regex.finditer(text):
            value = match.group(1)
            if regex.pattern.startswith(r"\bcont"):
                refs.add(f"cont.{value}")
            elif regex.pattern.startswith(r"\bR") or regex.pattern.startswith(r"\bRound"):
                refs.add(f"R{value}")
            else:
                refs.add(value.upper() if value.lower().startswith("p2-") else value)
            if len(refs) >= 80:
                break
    return sorted(refs, key=lambda value: (natural_key(value), value))


def natural_key(value: str) -> list[Any]:
    return [
        int(part) if part.isdigit() else part.lower()
        for part in re.split(r"(\d+)", value)
    ]


def validate_content(path: str, text: str | None) -> dict[str, Any]:
    if text is None:
        return {"status": "not-applicable", "checks": ["binary-identification"]}
    suffix = Path(path).suffix.lower()
    python_by_shebang = bool(
        text.startswith("#!") and "python" in text.splitlines()[0].lower()
    )
    if suffix == ".py" or python_by_shebang:
        try:
            ast.parse(text, filename=path)
            check = "python-ast" if suffix == ".py" else "python-ast-by-shebang"
            return {"status": "pass", "checks": [check]}
        except SyntaxError as error:
            return {
                "status": "fail",
                "checks": ["python-ast"],
                "detail": f"{error.msg} at line {error.lineno}",
            }
    if suffix == ".json":
        try:
            json.loads(text)
            return {"status": "pass", "checks": ["json-parse"]}
        except json.JSONDecodeError as error:
            return {
                "status": "fail",
                "checks": ["json-parse"],
                "detail": f"{error.msg} at line {error.lineno}",
            }
    if suffix == ".sh":
        return {"status": "pending", "checks": ["bash-n"]}
    if suffix == ".ps1":
        return {"status": "pending", "checks": ["powershell-parser"]}
    return {"status": "pass", "checks": ["text-decode"]}


def security_assessment(
    path: str, text: str | None, exists: bool
) -> dict[str, Any]:
    findings: list[str] = []
    if SECRET_NAME_RE.search(Path(path).name):
        findings.append("sensitive-filename")
    if text and PRIVATE_KEY_RE.search(text):
        findings.append("private-key-material")
    if text and SECRET_ASSIGNMENT_RE.search(text):
        findings.append("secret-like-assignment-review")
    severity = (
        "P0"
        if exists
        and ("private-key-material" in findings or is_secret_artifact(path))
        else None
    )
    return {
        "status": (
            "removed-from-working-tree"
            if not exists and is_secret_artifact(path)
            else "review"
            if findings
            else "clear-by-pattern-scan"
        ),
        "severity": severity,
        "findings": findings,
    }


def is_secret_artifact(path: str) -> bool:
    return Path(path).suffix.lower() in SECRET_ARTIFACT_SUFFIXES


def media_type(path: str, text: str | None) -> str:
    guessed = mimetypes.guess_type(path)[0]
    if guessed:
        return guessed
    if text is not None:
        return "text/plain"
    return "application/octet-stream"


def explicit_dependencies(
    path: str, text: str | None, script_names: dict[str, list[str]]
) -> list[str]:
    if not text:
        return []
    deps: set[str] = set()
    for match in SCRIPT_TOKEN_RE.finditer(text):
        name = match.group(1)
        candidates = script_names.get(name, [])
        if len(candidates) == 1 and candidates[0] != path:
            deps.add(candidates[0])
        elif f"scripts/{name}" in candidates and f"scripts/{name}" != path:
            deps.add(f"scripts/{name}")
    return sorted(deps)


def markdown_missing_links(path: str, text: str | None) -> list[dict[str, Any]]:
    if not text or not path.endswith(".md"):
        return []
    missing: list[dict[str, Any]] = []
    base = (ROOT / path).parent
    for line_number, line in enumerate(text.splitlines(), 1):
        for raw in MARKDOWN_LINK_RE.findall(line):
            target = raw.strip().split()[0].strip("<>")
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            candidate = (base / target).resolve()
            try:
                candidate.relative_to(ROOT)
            except ValueError:
                continue
            if not candidate.exists():
                missing.append({"line": line_number, "target": raw})
    return missing


def collect_inventory() -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    tracked, untracked, ignored, _porcelain = git_state()
    paths = all_paths()
    index_blobs = git_index_blobs(
        sorted(path for path in paths if path in tracked and path not in GENERATED_PATHS)
    )
    script_names: dict[str, list[str]] = defaultdict(list)
    for path in paths:
        if path.startswith("scripts/") and Path(path).suffix.lower() in {
            ".sh",
            ".py",
            ".ps1",
        }:
            script_names[Path(path).name].append(path)

    raw: dict[str, tuple[bytes, str | None, str]] = {}
    for path in paths:
        absolute = ROOT / path
        if path in GENERATED_PATHS:
            # Generated outputs describe themselves without content-derived fields so
            # regeneration reaches a stable fixed point.
            raw[path] = (b"", None, "generated-output")
        elif path in index_blobs:
            data = index_blobs[path]
            text, encoding = decode_text(data, absolute.suffix.lower())
            raw[path] = (data, text, encoding)
        elif absolute.exists():
            data = absolute.read_bytes()
            text, encoding = decode_text(data, absolute.suffix.lower())
            raw[path] = (data, text, encoding)
        else:
            raw[path] = (b"", None, "generated-output")

    inventory: list[dict[str, Any]] = []
    findings: list[dict[str, Any]] = []
    hashes: dict[tuple[int, str], list[str]] = defaultdict(list)

    for path in paths:
        data, text, encoding = raw[path]
        generated_self = path in GENERATED_PATHS
        exists = generated_self or (ROOT / path).exists()
        digest = None if generated_self or not exists else hashlib.sha256(data).hexdigest()
        if digest:
            hashes[(len(data), digest)].append(path)

        if generated_self:
            state = "generated"
        elif path in REMOVED_PATHS and not exists:
            state = "removed"
        elif path in tracked:
            state = "tracked"
        elif path in untracked:
            state = "untracked"
        elif path in ignored:
            state = "ignored"
        else:
            state = "filesystem-only"
        stage = classify_stage(path, text)
        origin_tree, target_tree = infer_origin_target(stage)
        validation = validate_content(path, text)
        security = security_assessment(path, text, exists)
        missing_links = markdown_missing_links(path, text)
        line_count = None if text is None else len(text.splitlines())
        availability, authority = infer_availability(path, state, exists)
        content_source = (
            "generated-contract"
            if generated_self
            else "git-index"
            if path in index_blobs
            else "removed-tombstone"
            if path in REMOVED_PATHS and not (ROOT / path).exists()
            else "working-tree"
        )
        record = {
            "path": path,
            "exists": exists,
            "git_state": state,
            "availability": availability,
            "authority": authority,
            "content_source": content_source,
            "bytes": len(data) if exists else None,
            "sha256": digest,
            "media_type": media_type(path, text),
            "encoding": encoding,
            "line_count": line_count,
            "line_endings": line_endings(data, text),
            "stage": stage,
            "timeline_refs": timeline_refs(text),
            "origin_tree": origin_tree,
            "target_tree": target_tree,
            "source_commit": None,
            "target_commit": None,
            "purpose": first_description(path, text),
            "necessity": infer_necessity(path, stage),
            "performance": infer_performance(path, stage, len(data)),
            "security": security,
            "result": infer_result(path, stage, text),
            "replacement": infer_replacement(path),
            "dependencies": explicit_dependencies(path, text, script_names),
            "validation_evidence": validation,
            "preservation": infer_preservation(path, stage),
            "missing_links": missing_links,
        }
        inventory.append(record)

        if validation["status"] == "fail":
            expected = EXPECTED_VALIDATION_FAILURES.get(path)
            findings.append(
                finding(
                    "P1" if stage != "aosp16-development" else "P2",
                    path,
                    "Syntax or parse failure",
                    validation.get("detail", "Parser rejected the file."),
                    (
                        f"Preserve the failed source; use `{expected[1]}` as the "
                        "successful replacement."
                        if expected
                        else "Fix active content or document the failure as historical evidence."
                    ),
                    status=expected[0] if expected else "open",
                )
            )
        if missing_links:
            findings.append(
                finding(
                    "P2",
                    path,
                    "Broken relative documentation links",
                    f"{len(missing_links)} relative links do not resolve.",
                    "Update links to the canonical project-relative target.",
                )
            )
        if security["severity"] == "P0":
            findings.append(
                finding(
                    "P0",
                    path,
                    "Tracked or present signing/private material",
                    ", ".join(security["findings"]),
                    "Remove secret material from the current tree, retain only identity and retrieval policy, and rotate externally.",
                )
            )
        if (
            path.startswith("scripts/")
            and "/archive/" not in path
            and path.endswith(".sh")
            and stage != "aosp16-development"
            and record["line_endings"] == "crlf"
        ):
            findings.append(
                finding(
                    "P1",
                    path,
                    "Active Bash script uses CRLF",
                    "Raw bash parsing can fail with carriage-return tokens.",
                    "Normalize maintained Bash entry points to LF under .gitattributes.",
                )
            )

    duplicate_groups = [
        {
            "bytes": size,
            "sha256": digest,
            "paths": sorted(group),
            "wasted_bytes": size * (len(group) - 1),
        }
        for (size, digest), group in hashes.items()
        if len(group) > 1
    ]
    duplicate_groups.sort(key=lambda item: (-item["wasted_bytes"], item["paths"]))
    for group in duplicate_groups:
        findings.append(
            finding(
                "P3",
                group["paths"][0],
                "Exact duplicate content",
                f"{len(group['paths'])} paths share SHA-256 {group['sha256']}; "
                f"{group['wasted_bytes']} duplicate bytes.",
                "Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.",
                related_paths=group["paths"][1:],
                status="preserve-pending-semantic-review",
            )
        )

    inventory.sort(key=lambda item: item["path"])
    findings.sort(key=lambda item: (item["severity"], item["path"], item["title"]))
    return inventory, findings, duplicate_groups


def finding(
    severity: str,
    path: str,
    title: str,
    evidence: str,
    action: str,
    related_paths: list[str] | None = None,
    status: str = "open",
) -> dict[str, Any]:
    return {
        "severity": severity,
        "path": path,
        "title": title,
        "evidence": evidence,
        "action": action,
        "related_paths": related_paths or [],
        "status": status,
    }


def parse_headings(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    text = path.read_text(encoding="utf-8-sig")
    for line_number, line in enumerate(text.splitlines(), 1):
        match = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if not match:
            continue
        title = match.group(2)
        cont_match = re.search(r"\bcont\.(\d+)\b", title, re.IGNORECASE)
        rounds: set[str] = set()
        for regex in (
            re.compile(r"\bR(\d+[a-z]?)\b", re.IGNORECASE),
            re.compile(r"\bRound\s+(\d+[a-z]?)\b", re.IGNORECASE),
            re.compile(r"回合\s*(?:R)?(\d+(?:[a-z]|[–-]\d+)?)", re.IGNORECASE),
        ):
            rounds.update(match.group(1) for match in regex.finditer(title))
        date_match = re.search(r"\b(20\d{2}-\d{2}-\d{2})\b", title)
        records.append(
            {
                "source": path.relative_to(ROOT).as_posix(),
                "line": line_number,
                "level": len(match.group(1)),
                "title": title,
                "date": date_match.group(1) if date_match else None,
                "cont": int(cont_match.group(1)) if cont_match else None,
                "rounds": sorted(rounds, key=natural_key),
            }
        )
    return records


def history_records() -> dict[str, list[dict[str, Any]]]:
    porting = parse_headings(ROOT / "progress" / "porting-log.md")
    boot = parse_headings(ROOT / "progress" / "archive" / "android-16-boot-debug.md")
    aosp_porting = [
        record
        for record in porting
        if record["cont"] is None or record["cont"] < 103
    ]
    promotion = [
        record
        for record in porting
        if record["cont"] is not None and record["cont"] >= 103
    ]
    boot_rounds = [
        record
        for record in boot
        if record["level"] == 2 or record["rounds"]
    ]
    return {
        "aosp16-development": aosp_porting + boot_rounds,
        "android16-promotion": promotion,
    }


def history_markdown(
    title: str, description: str, records: list[dict[str, Any]]
) -> str:
    lines = [
        f"# {title}",
        "",
        f"> {description}",
        "",
        f"Indexed records: **{len(records)}**.",
        "",
        "| Source | Line | Date | Cont | Rounds | Record |",
        "|---|---:|---|---:|---|---|",
    ]
    for record in records:
        source = record["source"]
        link = Path(source).as_posix()
        date = record["date"] or ""
        cont = record["cont"] if record["cont"] is not None else ""
        rounds = ", ".join(f"R{item}" for item in record["rounds"])
        title_text = record["title"].replace("|", "\\|")
        lines.append(
            f"| [`{source}`](../../../{link}#L{record['line']}) | "
            f"{record['line']} | {date} | {cont} | {rounds} | {title_text} |"
        )
    lines.append("")
    return "\n".join(lines)


def patch_traceability() -> str:
    inventory_path = (
        ROOT / "docs" / "android-16-patch-review" / "patch-inventory.json"
    )
    if not inventory_path.exists():
        return (
            "# AOSP16 to Android-16 Patch Traceability\n\n"
            "Patch inventory is not present. Run "
            "`scripts/generate_android16_patch_inventory.py` first.\n"
        )
    payload = json.loads(inventory_path.read_text(encoding="utf-8"))
    artifacts = payload.get("artifacts", [])
    evidence_paths = [
        ROOT / "progress" / "porting-log.md",
        ROOT / "progress" / "android-16-boot-guide.md",
        ROOT / "patches" / "android-16" / "RESTORE.md",
        PROMOTION_HISTORY_DIR / "a13-authority-completion.md",
    ]
    evidence = {
        path.relative_to(ROOT).as_posix(): path.read_text(
            encoding="utf-8-sig", errors="replace"
        )
        for path in evidence_paths
        if path.exists()
    }
    lines = [
        "# AOSP16 to Android-16 Patch Traceability",
        "",
        "> Every archived patch is listed even when no progress-log basename mention "
        "exists. Registry and checkpoint fields are the primary semantic evidence.",
        "",
        f"Artifacts: **{len(artifacts)}**.",
        "",
        "| Patch | Category | Registry IDs | Verification/checkpoint | Timeline evidence |",
        "|---|---|---|---|---|",
    ]
    for item in artifacts:
        name = item["name"]
        artifact = item["artifact"]
        registry = item.get("registry", [])
        ids = ", ".join(f"`{record.get('id')}`" for record in registry) or "unmapped"
        proof_parts: list[str] = []
        for record in registry:
            if record.get("verification"):
                proof_parts.append(str(record["verification"]))
            if record.get("checkpoint_ref"):
                proof_parts.append(str(record["checkpoint_ref"]))
        mentions: list[str] = []
        for evidence_path, text in evidence.items():
            for line_number, line in enumerate(text.splitlines(), 1):
                if name in line or artifact in line:
                    mentions.append(f"`{evidence_path}:{line_number}`")
        lines.append(
            f"| [`{name}`](../../../{artifact}) | {item.get('category', '')} | "
            f"{ids} | {'; '.join(proof_parts) or 'inspect registry/review'} | "
            f"{', '.join(mentions[:8]) or 'registry-only'} |"
        )
    lines.append("")
    return "\n".join(lines)


def inventory_schema() -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "BST AOSP project review inventory",
        "type": "object",
        "required": [
            "schema_version",
            "generated_from",
            "summary",
            "files",
            "findings",
            "duplicate_groups",
        ],
        "properties": {
            "schema_version": {"const": 1},
            "generated_from": {"const": "."},
            "summary": {"type": "object"},
            "files": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": [
                        "path",
                        "git_state",
                        "availability",
                        "authority",
                        "content_source",
                        "stage",
                        "purpose",
                        "necessity",
                        "performance",
                        "security",
                        "result",
                        "dependencies",
                        "validation_evidence",
                        "preservation",
                    ],
                },
            },
            "findings": {"type": "array"},
            "duplicate_groups": {"type": "array"},
        },
    }


def summary_for(inventory: list[dict[str, Any]], findings: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "files": len(inventory),
        "existing_files": sum(1 for item in inventory if item["exists"]),
        "bytes": sum(item["bytes"] or 0 for item in inventory),
        "text_lines": sum(item["line_count"] or 0 for item in inventory),
        "by_stage": dict(sorted(Counter(item["stage"] for item in inventory).items())),
        "by_git_state": dict(
            sorted(Counter(item["git_state"].split(":", 1)[0] for item in inventory).items())
        ),
        "by_availability": dict(
            sorted(Counter(item["availability"] for item in inventory).items())
        ),
        "findings_by_severity": dict(
            sorted(Counter(item["severity"] for item in findings).items())
        ),
    }


def inventory_markdown(inventory: list[dict[str, Any]], summary: dict[str, Any]) -> str:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for item in inventory:
        area = item["path"].split("/", 1)[0]
        grouped[area].append(item)
    lines = [
        "# Project File Inventory",
        "",
        "> Generated by `scripts/generate_project_review.py`. "
        "Tracked records are repository-authoritative; ignored and untracked records "
        "are explicitly local observations.",
        "",
        f"- Files: **{summary['files']}**",
        f"- Existing bytes: **{summary['bytes']}**",
        f"- Text lines: **{summary['text_lines']}**",
        "",
    ]
    for area, items in sorted(grouped.items()):
        lines.extend(
            [
                f"## `{area}`",
                "",
                "| Path | Stage | Availability | Git | Result | Preservation | Validation | Purpose |",
                "|---|---|---|---|---|---|---|---|",
            ]
        )
        for item in items:
            path = item["path"]
            purpose = item["purpose"].replace("|", "\\|").replace("\n", " ")
            lines.append(
                f"| [`{path}`](../../{path}) | `{item['stage']}` | "
                f"`{item['availability']}` | "
                f"`{item['git_state']}` | `{item['result']}` | "
                f"`{item['preservation']}` | "
                f"`{item['validation_evidence']['status']}` | {purpose} |"
            )
        lines.append("")
    return "\n".join(lines)


def findings_markdown(findings: list[dict[str, Any]]) -> str:
    lines = [
        "# Project Review Findings",
        "",
        "> Generated findings are evidence-backed candidates. Historical failures remain "
        "first-class records and are not automatically rewritten.",
        "",
    ]
    for severity in ("P0", "P1", "P2", "P3"):
        subset = [item for item in findings if item["severity"] == severity]
        lines.extend([f"## {severity}", "", f"Findings: **{len(subset)}**.", ""])
        for item in subset:
            related = (
                " Related: " + ", ".join(f"`{path}`" for path in item["related_paths"])
                if item["related_paths"]
                else ""
            )
            lines.extend(
                [
                    f"### `{item['path']}`: {item['title']}",
                    "",
                    f"- Status: `{item['status']}`",
                    f"- Evidence: {item['evidence']}{related}",
                    f"- Action: {item['action']}",
                    "",
                ]
            )
    return "\n".join(lines)


BINARY_EXTERNAL_REQUIRED = {
    "references/henry-hd-guest/BootImage/Boot/boot/bzImage": "henry-boot-baseline",
    "references/henry-hd-guest/BootImage/Boot/boot/initrd.img": "henry-boot-baseline",
    "references/henry-hd-guest/BootImage/bstchkdata": "henry-initrd-runtime",
    "references/henry-hd-guest/BootImage/bstconf": "henry-initrd-runtime",
    "references/henry-hd-guest/BootImage/fastboot/bzImage": "henry-fastboot-baseline",
    "references/henry-hd-guest/BootImage/fastboot/fastboot.img": "henry-fastboot-baseline",
    "references/henry-hd-guest/BootImage/initrd.img": "henry-fastboot-baseline",
}
BINARY_EXTERNAL_MODULE_PREFIX = (
    "references/henry-hd-guest/BootImage/initrd/boot/bstmods/"
)
BINARY_GENERATED_INTERMEDIATES = {
    "references/henry-hd-guest/BootImage/fastboot/boot_bzImage.o",
    "references/henry-hd-guest/BootImage/fastboot/fastboot.img.padded",
    "references/henry-hd-guest/BootImage/fastboot/fastboot_asm.o",
    "references/henry-hd-guest/BootImage/fastboot/fastboot_main.o",
    "references/henry-hd-guest/BootImage/fastboot/fastbootblock",
    "references/henry-hd-guest/BootImage/fastboot/fastbootblock.o",
    "references/henry-hd-guest/BootImage/fastboot/zero.file",
}
BINARY_DUPLICATES = {
    ".codex-tmp/videobuf-core.ko": (
        "references/henry-hd-guest/BootImage/initrd/boot/bstmods/"
        "videobuf-core.ko"
    ),
    "references/henry-hd-guest/BootImage/fastboot/initrd.img": (
        "references/henry-hd-guest/BootImage/initrd.img"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/bstchkdata": (
        "references/henry-hd-guest/BootImage/bstchkdata"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/bstconf": (
        "references/henry-hd-guest/BootImage/bstconf"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/bstreport": (
        "references/henry-hd-guest/BootImage/bstreport_64"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/busybox": (
        "references/henry-hd-guest/BootImage/busybox-ndk"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/echo": (
        "references/henry-hd-guest/BootImage/busybox-ndk"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/insmod": (
        "references/henry-hd-guest/BootImage/busybox-ndk"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/recovery": (
        "references/henry-hd-guest/BootImage/recovery"
    ),
    "references/henry-hd-guest/BootImage/initrd/boot/bin/sh": (
        "references/henry-hd-guest/BootImage/busybox-ndk"
    ),
}


def binary_retention_decision(item: dict[str, Any]) -> dict[str, Any]:
    path = item["path"]
    decision = ""
    reason = ""
    canonical = None
    bundle = None
    status = "complete"
    if path in REMOVED_PATHS:
        decision = "security-tombstone"
        reason = "Credential bytes must stay out of Git; retain identity and rotation record."
    elif item["git_state"] == "tracked":
        decision = "keep-in-git"
        reason = (
            "Repository clones can retrieve and verify this canonical historical payload. "
            "Opaque executables still require provenance and license review."
        )
    elif "__pycache__/" in path or path.endswith(".pyc"):
        decision = "drop-cache"
        reason = "Interpreter cache is reproducible, machine-specific, and has no evidence value."
    elif path in BINARY_DUPLICATES:
        decision = "drop-duplicate-layout"
        canonical = BINARY_DUPLICATES[path]
        reason = (
            "Bytes duplicate the canonical input; preserve only the layout/copy relation "
            "in the initrd assembly manifest."
        )
    elif path in BINARY_GENERATED_INTERMEDIATES:
        decision = "drop-generated-intermediate"
        reason = (
            "Object, padding, bootblock, or zero-fill output is derivable from source and "
            "the final image; record the toolchain instead of the bytes."
        )
    elif path in BINARY_EXTERNAL_REQUIRED:
        decision = "external-artifact-required"
        bundle = BINARY_EXTERNAL_REQUIRED[path]
        reason = (
            "Canonical boot input or final image is not available from Git and cannot be "
            "reconstructed from this repository alone."
        )
        status = "blocked-no-artifact-uri"
    elif path.startswith(BINARY_EXTERNAL_MODULE_PREFIX):
        decision = "external-artifact-required"
        bundle = "henry-initrd-runtime"
        reason = (
            "Kernel module bytes are required for exact historical initrd replay; source, "
            "kernel ABI, and toolchain are outside this repository."
        )
        status = "blocked-no-artifact-uri"
    else:
        decision = "manual-review"
        reason = "No retention rule matched this binary-like file."
        status = "open"
    return {
        "path": path,
        "bytes": item["bytes"],
        "sha256": item["sha256"],
        "availability": item["availability"],
        "git_state": item["git_state"],
        "decision": decision,
        "status": status,
        "canonical": canonical,
        "artifact_bundle": bundle,
        "reason": reason,
    }


def binary_retention_payload(inventory: list[dict[str, Any]]) -> dict[str, Any]:
    binary_items = [
        item
        for item in inventory
        if item["encoding"] == "binary" or item["path"] in REMOVED_PATHS
    ]
    local_evidence = json.loads(
        LOCAL_BINARY_EVIDENCE_PATH.read_text(encoding="utf-8")
    )
    known_paths = {item["path"] for item in binary_items}
    for item in local_evidence["files"]:
        if item["path"] in known_paths:
            continue
        binary_items.append(
            {
                **item,
                "availability": "local-only",
                "git_state": "ignored",
                "encoding": "binary",
            }
        )
    decisions = [binary_retention_decision(item) for item in binary_items]
    decisions.sort(key=lambda item: item["path"])
    counts = Counter(item["decision"] for item in decisions)
    bytes_by_decision = {
        decision: sum(
            item["bytes"] or 0
            for item in decisions
            if item["decision"] == decision
        )
        for decision in counts
    }
    bundles = {
        bundle: {
            "files": sum(item["artifact_bundle"] == bundle for item in decisions),
            "bytes": sum(
                item["bytes"] or 0
                for item in decisions
                if item["artifact_bundle"] == bundle
            ),
        }
        for bundle in sorted(
            {
                item["artifact_bundle"]
                for item in decisions
                if item["artifact_bundle"]
            }
        )
    }
    return {
        "schema_version": 1,
        "scope": "binary-like repository and local-evidence files",
        "policy": (
            "A hash verifies bytes after retrieval; it does not make an absent binary "
            "available or reproducible."
        ),
        "local_evidence_source": (
            LOCAL_BINARY_EVIDENCE_PATH.relative_to(ROOT).as_posix()
        ),
        "local_evidence_observed_at": local_evidence["observed_at"],
        "summary": {
            "files": len(decisions),
            "by_decision": dict(sorted(counts.items())),
            "bytes_by_decision": dict(sorted(bytes_by_decision.items())),
            "external_bundles": bundles,
            "external_artifact_blockers": sum(
                item["decision"] == "external-artifact-required"
                for item in decisions
            ),
        },
        "files": decisions,
    }


def binary_retention_markdown(payload: dict[str, Any]) -> str:
    counts = payload["summary"]["by_decision"]
    lines = [
        "# Binary Retention Assessment",
        "",
        "> SHA-256 is an identity check, not storage. Local-only binaries are not",
        "> authoritative project assets until they have a retrieval URI or a complete",
        "> source/toolchain reconstruction recipe.",
        "",
        "Local-only identities come from the committed observation manifest",
        "[`binary-local-evidence.json`](binary-local-evidence.json); they are not",
        "counted as repository files.",
        "",
        "The deterministic pack/verify/restore workflow is defined in",
        "[`binary-artifacts.md`](../development-workflow/binary-artifacts.md) and",
        "implemented by [`manage_binary_artifacts.py`](../../scripts/manage_binary_artifacts.py).",
        "",
        "## Decision Summary",
        "",
    ]
    for decision, count in counts.items():
        size = payload["summary"]["bytes_by_decision"][decision]
        lines.append(
            f"- `{decision}`: **{count}** files, **{size / 1024 / 1024:.2f} MiB**"
        )
    lines.extend(
        [
            "",
            "## Required External Bundles",
            "",
            "| Bundle | Required content | Current status |",
            "|---|---|---|",
            "| `henry-boot-baseline` | Boot kernel and boot initrd | Local bundle supported; artifact URI missing |",
            "| `henry-fastboot-baseline` | Fastboot kernel, canonical initrd, and final fastboot image | Local bundle supported; artifact URI missing |",
            "| `henry-initrd-runtime` | bstconf, bstchkdata, and nine kernel modules | Local bundle supported; artifact URI missing |",
            "",
            "The 16 files in these bundles must be uploaded to an approved artifact",
            "store or made reproducible from pinned source, kernel ABI, and toolchain",
            "identities. Until then they are recovery blockers, not completed evidence.",
            "",
            "## Per-File Decision",
            "",
            "| Decision | Status | Path | Bytes | Canonical/bundle | Reason |",
            "|---|---|---|---:|---|---|",
        ]
    )
    for item in payload["files"]:
        path = item["path"]
        link = f"[`{path}`](../../{path})" if item["availability"] == "repository" else f"`{path}`"
        target = item["canonical"] or item["artifact_bundle"] or "-"
        reason = item["reason"].replace("|", "\\|")
        lines.append(
            f"| `{item['decision']}` | `{item['status']}` | {link} | "
            f"{item['bytes'] or ''} | `{target}` | {reason} |"
        )
    lines.extend(
        [
            "",
            "## Deletion Rule",
            "",
            "Only `drop-cache`, `drop-generated-intermediate`, and",
            "`drop-duplicate-layout` entries are deletion candidates. Delete them only",
            "after canonical paths and initrd layout relations are committed. The",
            "security tombstone remains in metadata, never as credential bytes.",
            "",
        ]
    )
    return "\n".join(lines)


def verify_local_binary_evidence() -> tuple[int, int, list[str]]:
    payload = json.loads(LOCAL_BINARY_EVIDENCE_PATH.read_text(encoding="utf-8"))
    present = 0
    missing = 0
    mismatches: list[str] = []
    for item in payload["files"]:
        path = ROOT / item["path"]
        if not path.is_file():
            missing += 1
            continue
        present += 1
        data = path.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if len(data) != item["bytes"] or digest != item["sha256"]:
            mismatches.append(item["path"])
    return present, missing, mismatches


def review_readme(summary: dict[str, Any]) -> str:
    stages = ", ".join(
        f"`{stage}`={count}" for stage, count in summary["by_stage"].items()
    )
    findings = ", ".join(
        f"{severity}={count}"
        for severity, count in summary["findings_by_severity"].items()
    )
    return f"""# Repository-Wide Project Review

This review treats the validated AOSP16 line as the primary development record and
the AOSP16-to-Android-16 work as a promotion into the mainline integration tree.

## Generated Artifacts

- [`inventory.json`](inventory.json): per-file inventory with explicit authority and availability.
- [`inventory.md`](inventory.md): human-readable file index.
- [`binary-retention.md`](binary-retention.md): byte-retention decision for every binary-like record.
- [`binary-local-evidence.json`](binary-local-evidence.json): observed identities for ignored local binaries.
- [`binary-artifact-staging.json`](binary-artifact-staging.json): deterministic archive identities awaiting publication.
- [Binary artifact workflow](../development-workflow/binary-artifacts.md): deterministic external bundle handling.
- [`findings.md`](findings.md): P0-P3 generated findings and actions.
- [`inventory.schema.json`](inventory.schema.json): inventory contract.
- [`validation.md`](validation.md): full Python, JSON, Bash, and PowerShell static validation.
- [`baseline.md`](baseline.md): immutable worktree identity captured before this review.
- [`security.md`](security.md): secret-material disposition and rotation requirement.
- [`scripts.md`](scripts.md): active and historical script classification.
- [`documents.md`](documents.md): documentation source-of-truth and conflict review.
- [`patches.md`](patches.md): patch, payload, and checkpoint review map.
- [AOSP16 timeline](../development-history/aosp16/timeline.md).
- [Android-16 promotion timeline](../development-history/android16-merge/timeline.md).
- [Patch traceability](../development-history/android16-merge/patch-traceability.md).

## Current Snapshot

- Inventory entries: **{summary['files']}**
- Existing files: **{summary['existing_files']}**
- Text lines: **{summary['text_lines']}**
- Stages: {stages}
- Availability: {", ".join(f"`{key}`={value}" for key, value in summary["by_availability"].items())}
- Findings: {findings or "none"}

Regenerate with:

```bash
python scripts/generate_project_review.py
```
"""


def write_outputs(
    inventory: list[dict[str, Any]],
    findings: list[dict[str, Any]],
    duplicate_groups: list[dict[str, Any]],
) -> None:
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    AOSP16_HISTORY_DIR.mkdir(parents=True, exist_ok=True)
    PROMOTION_HISTORY_DIR.mkdir(parents=True, exist_ok=True)
    summary = summary_for(inventory, findings)
    payload = {
        "schema_version": 1,
        "generated_from": ".",
        "summary": summary,
        "files": inventory,
        "findings": findings,
        "duplicate_groups": duplicate_groups,
    }
    (REVIEW_DIR / "inventory.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    (REVIEW_DIR / "inventory.schema.json").write_text(
        json.dumps(inventory_schema(), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    (REVIEW_DIR / "inventory.md").write_text(
        inventory_markdown(inventory, summary), encoding="utf-8", newline="\n"
    )
    (REVIEW_DIR / "findings.md").write_text(
        findings_markdown(findings), encoding="utf-8", newline="\n"
    )
    (REVIEW_DIR / "README.md").write_text(
        review_readme(summary), encoding="utf-8", newline="\n"
    )
    retention = binary_retention_payload(inventory)
    (REVIEW_DIR / "binary-retention.json").write_text(
        json.dumps(retention, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    (REVIEW_DIR / "binary-retention.md").write_text(
        binary_retention_markdown(retention), encoding="utf-8", newline="\n"
    )

    history = history_records()
    (HISTORY_DIR / "timeline.json").write_text(
        json.dumps(history, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    (AOSP16_HISTORY_DIR / "timeline.md").write_text(
        history_markdown(
            "AOSP16 Development Timeline",
            "Generated index over the original porting and boot-debug records. "
            "Source records remain unchanged.",
            history["aosp16-development"],
        ),
        encoding="utf-8",
        newline="\n",
    )
    (PROMOTION_HISTORY_DIR / "timeline.md").write_text(
        history_markdown(
            "AOSP16 to Android-16 Promotion Timeline",
            "Generated index for cont.103 and later promotion/mainline validation records.",
            history["android16-promotion"],
        ),
        encoding="utf-8",
        newline="\n",
    )
    (PROMOTION_HISTORY_DIR / "patch-traceability.md").write_text(
        patch_traceability(), encoding="utf-8", newline="\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Regenerate in memory and fail if existing generated JSON differs.",
    )
    parser.add_argument(
        "--verify-local-evidence",
        action="store_true",
        help="Verify local files that are present against the observation manifest.",
    )
    args = parser.parse_args()
    inventory, findings, duplicate_groups = collect_inventory()
    if args.verify_local_evidence:
        present, missing, mismatches = verify_local_binary_evidence()
        print(
            f"local binary evidence: present={present} missing={missing} "
            f"mismatches={len(mismatches)}"
        )
        if mismatches:
            raise SystemExit(
                "local binary evidence mismatch: " + ", ".join(mismatches)
            )
    if args.check:
        expected_path = REVIEW_DIR / "inventory.json"
        if not expected_path.exists():
            raise SystemExit("inventory.json is missing; run without --check")
        current = json.loads(expected_path.read_text(encoding="utf-8"))
        expected = {
            "schema_version": 1,
            "generated_from": ".",
            "summary": summary_for(inventory, findings),
            "files": inventory,
            "findings": findings,
            "duplicate_groups": duplicate_groups,
        }
        if current != expected:
            raise SystemExit("project review inventory is stale")
        retention = binary_retention_payload(inventory)
        retention_json = REVIEW_DIR / "binary-retention.json"
        retention_md = REVIEW_DIR / "binary-retention.md"
        if not retention_json.exists() or json.loads(
            retention_json.read_text(encoding="utf-8")
        ) != retention:
            raise SystemExit("binary retention inventory is stale")
        expected_markdown = binary_retention_markdown(retention)
        if not retention_md.exists() or retention_md.read_text(
            encoding="utf-8"
        ) != expected_markdown:
            raise SystemExit("binary retention report is stale")
        print("project review inventory is current")
        return
    write_outputs(inventory, findings, duplicate_groups)
    print(
        f"generated {len(inventory)} file records and {len(findings)} findings "
        f"under {REVIEW_DIR.relative_to(ROOT)}"
    )


if __name__ == "__main__":
    main()

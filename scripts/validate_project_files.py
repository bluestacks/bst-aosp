#!/usr/bin/env python3
"""Run repository-only syntax checks without reading either Android source tree."""

from __future__ import annotations

import argparse
import ast
import json
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "docs" / "project-review"
ALLOWLIST_PATH = REVIEW_DIR / "validation-allowlist.json"
JSON_PATH = REVIEW_DIR / "validation.json"
MARKDOWN_PATH = REVIEW_DIR / "validation.md"
EXCLUDED_PARTS = {".git", ".codex-tmp", ".triage_tmp", "__pycache__"}


def relevant_files(suffix: str) -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob(f"*{suffix}")
        if not EXCLUDED_PARTS.intersection(path.relative_to(ROOT).parts)
        and path not in {JSON_PATH}
    )


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def result(path: Path, check: str, status: str, detail: str = "") -> dict[str, str]:
    return {
        "path": relative(path),
        "check": check,
        "status": status,
        "detail": detail,
    }


def python_check(path: Path, check: str = "python-ast") -> dict[str, str]:
    try:
        ast.parse(path.read_text(encoding="utf-8-sig"), filename=str(path))
        return result(path, check, "pass")
    except (SyntaxError, UnicodeDecodeError) as error:
        line = getattr(error, "lineno", None)
        detail = str(error)
        if line:
            detail = f"{getattr(error, 'msg', detail)} at line {line}"
        return result(path, check, "fail", detail)


def json_check(path: Path) -> dict[str, str]:
    try:
        json.loads(path.read_text(encoding="utf-8-sig"))
        return result(path, "json-parse", "pass")
    except (json.JSONDecodeError, UnicodeDecodeError) as error:
        return result(path, "json-parse", "fail", str(error))


def bash_check(path: Path, bash: str | None) -> dict[str, str]:
    data = path.read_bytes()
    first_line = data.splitlines()[0].decode("ascii", "ignore") if data else ""
    if "python" in first_line.lower():
        return python_check(path, "python-ast-by-shebang")
    if not bash:
        return result(path, "bash-n", "unavailable", "bash executable not found")
    normalized = data.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    completed = subprocess.run(
        [bash, "-n"],
        input=normalized,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
    )
    detail = completed.stderr.decode("utf-8", "replace").strip()
    return result(path, "bash-n", "pass" if completed.returncode == 0 else "fail", detail)


def powershell_check(path: Path, powershell: str | None) -> dict[str, str]:
    if not powershell:
        return result(
            path,
            "powershell-parser",
            "unavailable",
            "PowerShell executable not found",
        )
    quoted_path = str(path).replace("'", "''")
    command = (
        "$tokens=$null;$errors=$null;"
        "[void][System.Management.Automation.Language.Parser]::ParseFile("
        f"'{quoted_path}',[ref]$tokens,[ref]$errors);"
        "if($errors.Count){$errors|%{$_.Message};exit 1}"
    )
    completed = subprocess.run(
        [powershell, "-NoProfile", "-NonInteractive", "-Command", command],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
    )
    detail = (
        completed.stdout.decode("utf-8", "replace")
        + completed.stderr.decode("utf-8", "replace")
    ).strip()
    return result(
        path,
        "powershell-parser",
        "pass" if completed.returncode == 0 else "fail",
        detail,
    )


def apply_allowlist(items: list[dict[str, str]]) -> None:
    payload = json.loads(ALLOWLIST_PATH.read_text(encoding="utf-8"))
    entries = {
        (entry["path"], entry["check"]): entry
        for entry in payload.get("entries", [])
    }
    observed: set[tuple[str, str]] = set()
    for item in items:
        key = (item["path"], item["check"])
        if item["status"] != "fail" or key not in entries:
            continue
        item["status"] = "expected-failure"
        item["allowlist_reason"] = entries[key]["reason"]
        item["replacement"] = entries[key].get("replacement")
        observed.add(key)
    stale = sorted(set(entries) - observed)
    for path, check in stale:
        items.append(
            {
                "path": path,
                "check": check,
                "status": "stale-allowlist",
                "detail": "Allowlisted failure was not observed.",
            }
        )


def collect() -> dict[str, Any]:
    items: list[dict[str, str]] = []
    items.extend(python_check(path) for path in relevant_files(".py"))
    items.extend(json_check(path) for path in relevant_files(".json"))

    bash = shutil.which("bash")
    shell_paths = relevant_files(".sh")
    with ThreadPoolExecutor(max_workers=12) as pool:
        items.extend(pool.map(lambda path: bash_check(path, bash), shell_paths))

    powershell = shutil.which("pwsh") or shutil.which("powershell")
    powershell_paths = relevant_files(".ps1")
    with ThreadPoolExecutor(max_workers=4) as pool:
        items.extend(
            pool.map(lambda path: powershell_check(path, powershell), powershell_paths)
        )

    apply_allowlist(items)
    items.sort(key=lambda item: (item["path"], item["check"]))
    counts: dict[str, int] = {}
    for item in items:
        counts[item["status"]] = counts.get(item["status"], 0) + 1
    return {
        "schema_version": 1,
        "scope": "local repository only; Android source trees are not read",
        "counts": dict(sorted(counts.items())),
        "checks": items,
    }


def markdown(payload: dict[str, Any]) -> str:
    counts = ", ".join(
        f"`{status}`={count}" for status, count in payload["counts"].items()
    )
    exceptions = [
        item
        for item in payload["checks"]
        if item["status"] not in {"pass"}
    ]
    lines = [
        "# Static Validation",
        "",
        "> This validation reads only this repository. Historical Bash is normalized",
        "> in memory for parsing so archived byte identity is not changed.",
        "",
        f"- Results: {counts}",
        f"- Allowlist: [`validation-allowlist.json`](validation-allowlist.json)",
        "",
        "## Exceptions",
        "",
        "| Status | Check | Path | Detail |",
        "|---|---|---|---|",
    ]
    if not exceptions:
        lines.append("| pass | - | - | No exceptions. |")
    for item in exceptions:
        detail = item.get("allowlist_reason") or item.get("detail") or ""
        detail = detail.replace("|", "\\|").replace("\n", " ")
        lines.append(
            f"| {item['status']} | `{item['check']}` | `{item['path']}` | {detail} |"
        )
    lines.extend(
        [
            "",
            "Run:",
            "",
            "```bash",
            "python scripts/validate_project_files.py",
            "python scripts/validate_project_files.py --check",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    payload = collect()
    expected_json = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    expected_markdown = markdown(payload)
    if args.check:
        current_json = JSON_PATH.read_text(encoding="utf-8") if JSON_PATH.exists() else ""
        current_md = (
            MARKDOWN_PATH.read_text(encoding="utf-8") if MARKDOWN_PATH.exists() else ""
        )
        if current_json != expected_json or current_md != expected_markdown:
            print("generated validation outputs are stale")
            return 1
    else:
        REVIEW_DIR.mkdir(parents=True, exist_ok=True)
        JSON_PATH.write_text(expected_json, encoding="utf-8", newline="\n")
        MARKDOWN_PATH.write_text(expected_markdown, encoding="utf-8", newline="\n")
    unexpected = payload["counts"].get("fail", 0)
    stale = payload["counts"].get("stale-allowlist", 0)
    unavailable = payload["counts"].get("unavailable", 0)
    print(
        "validation "
        + " ".join(f"{key}={value}" for key, value in payload["counts"].items())
    )
    return 1 if unexpected or stale or unavailable else 0


if __name__ == "__main__":
    raise SystemExit(main())

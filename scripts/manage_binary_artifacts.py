#!/usr/bin/env python3
"""Pack, verify, and restore the required external binary evidence bundles."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
RETENTION_PATH = ROOT / "docs" / "project-review" / "binary-retention.json"
STAGING_PATH = ROOT / "docs" / "project-review" / "binary-artifact-staging.json"
DEFAULT_ARCHIVE_DIR = ROOT / "artifacts" / "binary-retention"
EMBEDDED_MANIFEST = "_bundle-manifest.json"
FIXED_ZIP_TIME = (1980, 1, 1, 0, 0, 0)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_json_sha256(path: Path) -> str:
    payload = json.loads(path.read_text(encoding="utf-8"))
    canonical = json.dumps(
        payload,
        ensure_ascii=True,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return sha256_bytes(canonical)


def display_path(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return str(path.resolve())


def resolve_cli_path(value: str | None, default: Path) -> Path:
    if value is None:
        return default
    path = Path(value).expanduser()
    return path if path.is_absolute() else ROOT / path


def load_bundles() -> dict[str, list[dict[str, Any]]]:
    payload = json.loads(RETENTION_PATH.read_text(encoding="utf-8"))
    bundles: dict[str, list[dict[str, Any]]] = {}
    for item in payload["files"]:
        if item["decision"] != "external-artifact-required":
            continue
        bundle = item.get("artifact_bundle")
        if not bundle:
            raise SystemExit(f"required artifact has no bundle: {item['path']}")
        if not item.get("sha256") or item.get("bytes") is None:
            raise SystemExit(f"required artifact has incomplete identity: {item['path']}")
        bundles.setdefault(bundle, []).append(
            {
                "path": item["path"],
                "bytes": item["bytes"],
                "sha256": item["sha256"],
            }
        )
    for files in bundles.values():
        files.sort(key=lambda item: item["path"])
    if not bundles:
        raise SystemExit(f"no external artifact bundles found in {RETENTION_PATH}")
    return dict(sorted(bundles.items()))


def selected_bundles(
    bundles: dict[str, list[dict[str, Any]]], names: list[str] | None
) -> dict[str, list[dict[str, Any]]]:
    if not names:
        return bundles
    unknown = sorted(set(names) - set(bundles))
    if unknown:
        raise SystemExit(
            f"unknown bundle(s): {', '.join(unknown)}; "
            f"available: {', '.join(bundles)}"
        )
    return {name: bundles[name] for name in names}


def load_staging(
    bundles: dict[str, list[dict[str, Any]]]
) -> dict[str, dict[str, Any]]:
    payload = json.loads(STAGING_PATH.read_text(encoding="utf-8"))
    expected_source_hash = canonical_json_sha256(RETENTION_PATH)
    if payload.get("source_manifest") != RETENTION_PATH.relative_to(ROOT).as_posix():
        raise SystemExit(f"invalid source manifest in {STAGING_PATH}")
    if payload.get("source_manifest_canonical_sha256") != expected_source_hash:
        raise SystemExit(
            "binary artifact staging record is stale: retention manifest changed"
        )
    records = {item["name"]: item for item in payload.get("bundles", [])}
    if set(records) != set(bundles):
        raise SystemExit("binary artifact staging bundle set is stale")
    for name, files in bundles.items():
        record = records[name]
        member_bytes = sum(item["bytes"] for item in files)
        if (
            record.get("member_count") != len(files)
            or record.get("member_bytes") != member_bytes
        ):
            raise SystemExit(f"binary artifact staging record is stale: {name}")
    return records


def bundle_manifest(name: str, files: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "bundle": name,
        "selection": (
            "binary-retention.json entries with decision=external-artifact-required "
            f"and artifact_bundle={name}"
        ),
        "files": files,
    }


def manifest_bytes(name: str, files: list[dict[str, Any]]) -> bytes:
    return (
        json.dumps(
            bundle_manifest(name, files),
            ensure_ascii=True,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    ).encode("utf-8")


def zip_info(name: str) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, FIXED_ZIP_TIME)
    info.compress_type = zipfile.ZIP_STORED
    info.create_system = 3
    info.external_attr = 0o100644 << 16
    info.flag_bits |= 0x800
    return info


def validate_source(item: dict[str, Any]) -> bytes:
    path = ROOT / item["path"]
    if not path.is_file():
        raise SystemExit(f"required local artifact is missing: {item['path']}")
    data = path.read_bytes()
    digest = sha256_bytes(data)
    if len(data) != item["bytes"] or digest != item["sha256"]:
        raise SystemExit(
            f"local artifact identity mismatch: {item['path']} "
            f"(bytes={len(data)}, sha256={digest})"
        )
    return data


def pack_bundle(
    archive_dir: Path,
    name: str,
    files: list[dict[str, Any]],
    staging: dict[str, Any],
) -> tuple[Path, str]:
    archive_dir.mkdir(parents=True, exist_ok=True)
    archive = archive_dir / f"{name}.zip"
    prepared = [(item, validate_source(item)) for item in files]
    file_descriptor, temp_name = tempfile.mkstemp(
        prefix=f".{name}.", suffix=".tmp", dir=archive_dir
    )
    os.close(file_descriptor)
    temp_path = Path(temp_name)
    try:
        with zipfile.ZipFile(temp_path, "w", allowZip64=True) as output:
            output.writestr(zip_info(EMBEDDED_MANIFEST), manifest_bytes(name, files))
            for item, data in prepared:
                output.writestr(zip_info(item["path"]), data)
        os.replace(temp_path, archive)
    finally:
        temp_path.unlink(missing_ok=True)
    digest = sha256_file(archive)
    if (
        archive.stat().st_size != staging["archive_bytes"]
        or digest != staging["archive_sha256"]
    ):
        raise SystemExit(
            f"packed archive differs from committed staging identity: {name}"
        )
    sidecar = archive.with_suffix(archive.suffix + ".sha256")
    sidecar.write_text(f"{digest}  {archive.name}\n", encoding="ascii", newline="\n")
    return archive, digest


def safe_member_name(name: str) -> bool:
    path = PurePosixPath(name)
    return (
        bool(path.parts)
        and not path.is_absolute()
        and ".." not in path.parts
        and "\\" not in name
    )


def verify_bundle(
    archive_dir: Path,
    name: str,
    files: list[dict[str, Any]],
    staging: dict[str, Any],
) -> tuple[Path, str]:
    archive = archive_dir / f"{name}.zip"
    sidecar = archive.with_suffix(archive.suffix + ".sha256")
    if not archive.is_file():
        raise SystemExit(f"bundle archive is missing: {display_path(archive)}")
    if not sidecar.is_file():
        raise SystemExit(f"bundle checksum is missing: {display_path(sidecar)}")

    digest = sha256_file(archive)
    if (
        archive.stat().st_size != staging["archive_bytes"]
        or digest != staging["archive_sha256"]
    ):
        raise SystemExit(
            f"archive differs from committed staging identity: "
            f"{display_path(archive)}"
        )
    expected_sidecar = f"{digest}  {archive.name}"
    if sidecar.read_text(encoding="ascii").strip() != expected_sidecar:
        raise SystemExit(f"bundle checksum mismatch: {display_path(archive)}")

    expected_names = [EMBEDDED_MANIFEST, *(item["path"] for item in files)]
    with zipfile.ZipFile(archive, "r") as source:
        names = source.namelist()
        if len(names) != len(set(names)):
            raise SystemExit(f"duplicate ZIP member in {display_path(archive)}")
        if any(not safe_member_name(member) for member in names):
            raise SystemExit(f"unsafe ZIP member in {display_path(archive)}")
        if names != expected_names:
            raise SystemExit(f"unexpected member list in {display_path(archive)}")
        embedded = json.loads(source.read(EMBEDDED_MANIFEST))
        if embedded != bundle_manifest(name, files):
            raise SystemExit(f"embedded manifest mismatch in {display_path(archive)}")
        for item in files:
            with source.open(item["path"], "r") as stream:
                digest_stream = hashlib.sha256()
                size = 0
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    size += len(chunk)
                    digest_stream.update(chunk)
            if size != item["bytes"] or digest_stream.hexdigest() != item["sha256"]:
                raise SystemExit(
                    f"member identity mismatch: {name}:{item['path']}"
                )
    return archive, digest


def destination_path(root: Path, relative: str) -> Path:
    root_resolved = root.resolve()
    target = (root_resolved / Path(*PurePosixPath(relative).parts)).resolve()
    if target != root_resolved and root_resolved not in target.parents:
        raise SystemExit(f"restore path escapes destination root: {relative}")
    return target


def restore_bundle(
    archive_dir: Path,
    destination_root: Path,
    name: str,
    files: list[dict[str, Any]],
    staging: dict[str, Any],
) -> tuple[int, int]:
    archive, _ = verify_bundle(archive_dir, name, files, staging)
    restored = 0
    existing = 0
    with zipfile.ZipFile(archive, "r") as source:
        for item in files:
            target = destination_path(destination_root, item["path"])
            if target.exists():
                if (
                    target.is_file()
                    and target.stat().st_size == item["bytes"]
                    and sha256_file(target) == item["sha256"]
                ):
                    existing += 1
                    continue
                raise SystemExit(
                    f"refusing to overwrite non-matching path: {display_path(target)}"
                )
            target.parent.mkdir(parents=True, exist_ok=True)
            file_descriptor, temp_name = tempfile.mkstemp(
                prefix=f".{target.name}.", suffix=".tmp", dir=target.parent
            )
            os.close(file_descriptor)
            temp_path = Path(temp_name)
            try:
                with source.open(item["path"], "r") as input_stream:
                    with temp_path.open("wb") as output_stream:
                        for chunk in iter(
                            lambda: input_stream.read(1024 * 1024), b""
                        ):
                            output_stream.write(chunk)
                if (
                    temp_path.stat().st_size != item["bytes"]
                    or sha256_file(temp_path) != item["sha256"]
                ):
                    raise SystemExit(f"restored artifact mismatch: {item['path']}")
                os.replace(temp_path, target)
            finally:
                temp_path.unlink(missing_ok=True)
            restored += 1
    return restored, existing


def command_plan(bundles: dict[str, list[dict[str, Any]]]) -> None:
    total_files = 0
    total_bytes = 0
    for name, files in bundles.items():
        size = sum(item["bytes"] for item in files)
        total_files += len(files)
        total_bytes += size
        print(f"{name}: files={len(files)} bytes={size} ({size / 1024 / 1024:.2f} MiB)")
    print(
        f"total: files={total_files} bytes={total_bytes} "
        f"({total_bytes / 1024 / 1024:.2f} MiB)"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("plan", help="List the required bundle members and sizes.")

    for command in ("pack", "verify"):
        child = subparsers.add_parser(
            command, help=f"{command.capitalize()} required binary bundles."
        )
        child.add_argument("--bundle", action="append", dest="bundles")
        child.add_argument(
            "--archive-dir",
            help="Archive directory (default: artifacts/binary-retention).",
        )

    restore = subparsers.add_parser(
        "restore", help="Restore missing bundle members without overwriting mismatches."
    )
    restore.add_argument("--bundle", action="append", dest="bundles")
    restore.add_argument(
        "--archive-dir",
        help="Archive directory (default: artifacts/binary-retention).",
    )
    restore.add_argument(
        "--destination-root",
        help="Restore root (default: repository root).",
    )

    args = parser.parse_args()
    all_bundles = load_bundles()
    staging = load_staging(all_bundles)
    bundles = selected_bundles(all_bundles, getattr(args, "bundles", None))
    if args.command == "plan":
        command_plan(bundles)
        return

    archive_dir = resolve_cli_path(args.archive_dir, DEFAULT_ARCHIVE_DIR)
    if args.command == "pack":
        for name, files in bundles.items():
            archive, digest = pack_bundle(
                archive_dir, name, files, staging[name]
            )
            print(
                f"packed {name}: {display_path(archive)} "
                f"bytes={archive.stat().st_size} sha256={digest}"
            )
        return

    if args.command == "verify":
        for name, files in bundles.items():
            archive, digest = verify_bundle(
                archive_dir, name, files, staging[name]
            )
            print(
                f"verified {name}: {display_path(archive)} "
                f"bytes={archive.stat().st_size} sha256={digest}"
            )
        return

    destination_root = resolve_cli_path(args.destination_root, ROOT)
    for name, files in bundles.items():
        restored, existing = restore_bundle(
            archive_dir, destination_root, name, files, staging[name]
        )
        print(f"restored {name}: restored={restored} already-matching={existing}")


if __name__ == "__main__":
    main()

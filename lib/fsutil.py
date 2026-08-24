#!/usr/bin/env python3
"""
fsutil.py — shared filesystem utilities for dc.py, dirdiff.py, and syncdir.py.

Provides directory walking with recursion/exclude/mask support, MD5 hashing
(single-file and thread-pool parallel), and parallel file copying.

Author: Andy Roper <andyroper42@gmail.com>
"""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Iterable, Iterator, Optional

IS_WINDOWS = os.name == "nt"

# Thread pools are the right tool here (not process pools): hashing and
# copying are I/O-bound, and hashlib releases the GIL during the C-level
# digest work on chunks of any real size, so threads capture most of the
# available overlap without process-spawn/IPC overhead.
DEFAULT_WORKERS = min(32, (os.cpu_count() or 4) * 4)
HASH_CHUNK_SIZE = 1024 * 1024  # 1 MiB

def fix_path(path: str) -> str:
    """Return an absolute, forward-slash path with no trailing slash."""
    p = str(Path(path).resolve())
    p = p.replace("\\", "/")
    if len(p) > 1:
        p = p.rstrip("/")
    return p


def dos_to_regex(mask: str) -> re.Pattern:
    """Convert a DOS-style wildcard mask (*, ?) to a compiled case-insensitive regex."""
    m = mask.replace("*.*", "*")
    parts = re.split(r"([*?])", m)
    pattern = "".join(
        ".*" if part == "*" else "." if part == "?" else re.escape(part)
        for part in parts
    )
    return re.compile(f"^{pattern}$", re.IGNORECASE)


def split_path_mask(raw: str) -> tuple[str, Optional[re.Pattern]]:
    """
    Split a user-supplied argument into (directory, mask_regex_or_None).

    If `raw` is an existing directory, that directory is returned with no
    mask. If the final path component contains wildcards, the parent
    directory and a compiled mask regex are returned. Otherwise the path is
    treated as a literal single-file path and returned as-is with no mask.
    """
    p = Path(raw) if raw else Path.cwd()
    if p.is_dir():
        return fix_path(str(p)), None

    parent = p.parent if str(p.parent) not in ("", ".") else Path.cwd()
    name = p.name

    if not name:
        return fix_path(str(parent)), None
    if any(c in name for c in "*?"):
        return fix_path(str(parent)), dos_to_regex(name)
    return fix_path(str(parent)) + "/" + name, None


def get_size(path) -> int:
    return os.stat(path).st_size


def get_mtime(path) -> float:
    return os.stat(path).st_mtime

def walk_files(
    root: str,
    recurse: bool = True,
    exclude_dirs: Optional[set[str]] = None,
    exclude_pattern: Optional[re.Pattern] = None,
    mask: Optional[re.Pattern] = None,
    skip_pattern: Optional[re.Pattern] = None,
) -> Iterator[Path]:
    """
    Yield Path objects for every file under `root`.

    exclude_dirs: set of lowercased, fix_path-normalized directory paths to
        skip entirely (and not recurse into).
    exclude_pattern: regex tested against the full file path; matches skipped.
    mask: regex tested against the filename only; non-matches skipped.
    skip_pattern: regex tested against the filename; matches skipped
        (e.g. syncdir's hardcoded *.db skip).
    """
    try:
        entries = sorted(Path(root).iterdir())
    except OSError as e:
        print(f"Unable to open {root}: {e}", file=sys.stderr)
        return

    for entry in entries:
        if entry.is_dir():
            if not recurse:
                continue
            if exclude_dirs and fix_path(str(entry)).lower() in exclude_dirs:
                continue
            yield from walk_files(
                str(entry), recurse, exclude_dirs, exclude_pattern, mask, skip_pattern
            )
            continue

        name = entry.name
        if mask and not mask.search(name):
            continue
        if skip_pattern and skip_pattern.search(name):
            continue
        full = str(entry)
        if exclude_pattern and exclude_pattern.search(full):
            continue
        yield entry

def md5_file(path, chunk_size: int = HASH_CHUNK_SIZE, on_error: str = "raise") -> Optional[str]:
    """
    Return the hex MD5 digest of a file.

    on_error: "raise" propagates the OSError; "warn" prints to stderr and
    returns None; "silent" returns None without printing.
    """
    h = hashlib.md5()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(chunk_size), b""):
                h.update(chunk)
        return h.hexdigest()
    except OSError as e:
        if on_error == "raise":
            raise
        if on_error == "warn":
            print(f"Error hashing {path}: {e}", file=sys.stderr)
        return None


def hash_files_parallel(
    paths: Iterable,
    workers: int = DEFAULT_WORKERS,
    on_error: str = "warn",
) -> dict:
    """
    Hash many files concurrently with a thread pool.

    Returns {str(path): hexdigest_or_None}. Completion order is not
    preserved; callers needing stable output should sort by key afterward.
    """
    results: dict = {}
    paths = list(paths)
    if not paths:
        return results
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(md5_file, p, on_error=on_error): p for p in paths}
        for future in as_completed(futures):
            p = futures[future]
            results[str(p)] = future.result()
    return results

def copy_file(src: str, dst: str, preserve_mtime: bool = True) -> None:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if preserve_mtime:
        shutil.copy2(src, dst)
    else:
        shutil.copy(src, dst)


def copy_files_parallel(
    pairs: Iterable[tuple[str, str]],
    workers: int = DEFAULT_WORKERS,
    verbose: bool = False,
) -> list[tuple[str, str, Exception]]:
    """
    Copy (src, dst) pairs concurrently. Returns a list of (src, dst, error)
    for any copies that failed; successes print nothing unless verbose.
    """
    errors: list[tuple[str, str, Exception]] = []
    pairs = list(pairs)
    if not pairs:
        return errors
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(copy_file, s, d): (s, d) for s, d in pairs}
        for future in as_completed(futures):
            s, d = futures[future]
            try:
                future.result()
                if verbose:
                    print(f"Copied {s} -> {d}")
            except OSError as e:
                print(f"Error copying {s} to {d}: {e}", file=sys.stderr)
                errors.append((s, d, e))
    return errors

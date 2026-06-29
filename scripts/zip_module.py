#!/usr/bin/env python3
from pathlib import Path
from stat import S_IXGRP, S_IXOTH, S_IXUSR
from sys import argv
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(argv[1])
ITEMS = [
    "module.prop",
    "customize.sh",
    "post-fs-data.sh",
    "service.sh",
    "watchdog.sh",
    "uninstall.sh",
    "config",
    "META-INF",
    "README.md",
    "update.json",
    "bin",
]
EXECUTABLES = {
    "customize.sh",
    "post-fs-data.sh",
    "service.sh",
    "watchdog.sh",
    "uninstall.sh",
    "META-INF/com/google/android/update-binary",
    "bin/cli-proxy-api",
}


def add_file(archive: ZipFile, path: Path) -> None:
    rel = path.relative_to(ROOT).as_posix()
    if path.name == ".gitkeep":
        return
    info = ZipInfo(rel)
    mode = path.stat().st_mode
    if rel in EXECUTABLES:
        mode |= S_IXUSR | S_IXGRP | S_IXOTH
    info.external_attr = (mode & 0xFFFF) << 16
    info.compress_type = ZIP_DEFLATED
    archive.writestr(info, path.read_bytes())


with ZipFile(OUT, "w") as archive:
    for item in ITEMS:
        path = ROOT / item
        if path.is_dir():
            for child in sorted(path.rglob("*")):
                if child.is_file():
                    add_file(archive, child)
        elif path.is_file():
            add_file(archive, path)

#!/usr/bin/env python3
"""Build a deterministic probe ZIP; this does not validate WoW behavior."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "probe" / "MagicMarkerForeverProbe"
TOC = ADDON / "MagicMarkerForeverProbe.toc"


def main():
    if not TOC.is_file():
        raise SystemExit("Probe TOC is missing")
    for line in TOC.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            target = (ADDON / line.replace("\\", "/")).resolve()
            if not target.is_relative_to(ADDON.resolve()) or not target.is_file():
                raise SystemExit(f"Invalid or missing TOC reference: {line}")
    files = sorted(p for p in ADDON.rglob("*") if p.is_file())
    for path in files:
        if path.suffix.lower() not in {".lua", ".toc", ".md", ".txt"}:
            raise SystemExit(f"Unexpected package file: {path.relative_to(ADDON)}")
    destination = ROOT / "dist" / "MagicMarkerForeverProbe-m0.zip"
    destination.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            info = zipfile.ZipInfo(str(path.relative_to(ADDON.parent)), (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
    print(destination)
    print("SHA256", hashlib.sha256(destination.read_bytes()).hexdigest())


if __name__ == "__main__":
    main()

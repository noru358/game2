"""Remove detached alpha debris from each fixed 4x4 reskin cell.

The generated RGB artwork of the main silhouette is not redrawn or recolored.
For every cell this removes near-transparent residue, peels the source sheet's
red/yellow segmentation-key fringe only where it touches transparency, then
keeps the largest connected alpha component. Original generated sheets are
retained under ``raw_generated`` before the active files are replaced.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image

from hero_alpha_components import components


SHEETS = ("walk_contact.png", "walk_pass.png", "run_contact.png", "run_pass.png")
MIN_ALPHA = 16


def cell_bounds(length: int, index: int) -> tuple[int, int]:
    return length * index // 4, length * (index + 1) // 4


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def boundary(mask: np.ndarray) -> np.ndarray:
    padded = np.pad(mask, 1, constant_values=False)
    surrounded = np.ones_like(mask)
    for dy in range(3):
        for dx in range(3):
            surrounded &= padded[dy : dy + mask.shape[0], dx : dx + mask.shape[1]]
    return mask & ~surrounded


def remove_key_fringe(tile: np.ndarray) -> tuple[int, int]:
    low_alpha = (tile[:, :, 3] > 0) & (tile[:, :, 3] < MIN_ALPHA)
    low_alpha_count = int(np.count_nonzero(low_alpha))
    tile[low_alpha] = 0

    red = tile[:, :, 0].astype(np.int16)
    green = tile[:, :, 1].astype(np.int16)
    blue = tile[:, :, 2].astype(np.int16)
    keyed = ((red > 180) & (red > green * 2) & (red > blue * 2)) | (
        (red > 180) & (green > 180) & (blue < 100)
    )
    keyed_removed = 0
    # Key colors can be several pixels deep. Peel only layers exposed to the
    # transparent exterior, never an enclosed costume detail.
    for _iteration in range(24):
        opaque = tile[:, :, 3] > 0
        exposed = keyed & boundary(opaque)
        count = int(np.count_nonzero(exposed))
        if count == 0:
            break
        tile[exposed] = 0
        keyed_removed += count
    return low_alpha_count, keyed_removed


def clean_sheet(source: Path, target: Path) -> dict:
    image = np.array(Image.open(source).convert("RGBA"))
    height, width = image.shape[:2]
    cells = []
    total_removed = 0

    for row in range(4):
        y0, y1 = cell_bounds(height, row)
        for column in range(4):
            x0, x1 = cell_bounds(width, column)
            tile = image[y0:y1, x0:x1]
            low_alpha_removed, keyed_removed = remove_key_fringe(tile)
            labels, groups = components(tile[:, :, 3] > 0)
            if not groups:
                raise RuntimeError(f"{source.name} cell {row * 4 + column} has no alpha silhouette")
            main = max(groups.values(), key=lambda item: item["area"])
            discarded = (labels != 0) & (labels != main["id"])
            removed = int(np.count_nonzero(discarded))
            total_removed += low_alpha_removed + keyed_removed + removed
            tile[discarded] = 0
            cells.append(
                {
                    "index": row * 4 + column,
                    "kept_area": int(main["area"]),
                    "kept_box": [int(value) for value in main["box"]],
                    "low_alpha_removed": low_alpha_removed,
                    "key_fringe_removed": keyed_removed,
                    "detached_removed": removed,
                    "removed_pixels": low_alpha_removed + keyed_removed + removed,
                }
            )

    Image.fromarray(image, mode="RGBA").save(target)
    return {
        "sheet": source.name,
        "source_sha256": digest(source),
        "output_sha256": digest(target),
        "removed_pixels": total_removed,
        "cells": cells,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("asset_dir", type=Path)
    args = parser.parse_args()

    asset_dir = args.asset_dir.resolve()
    raw_dir = asset_dir / "raw_generated"
    raw_dir.mkdir(exist_ok=True)
    report = {
        "operation": "alpha_only_remove_low_alpha_and_exterior_key_fringe_then_keep_largest_component_per_cell",
        "minimum_retained_alpha": MIN_ALPHA,
        "sheets": [],
    }

    for name in SHEETS:
        active = asset_dir / name
        raw = raw_dir / name
        if not raw.exists():
            shutil.copy2(active, raw)
        report["sheets"].append(clean_sheet(raw, active))

    report_path = asset_dir / "alpha_cleanup_report.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

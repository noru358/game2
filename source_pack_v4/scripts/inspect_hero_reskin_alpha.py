"""Report per-cell alpha components for the four hero reskin sprite sheets.

This is deliberately read-only.  It helps distinguish the character silhouette
from detached generation debris before any alpha-only cleanup is applied.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

from hero_alpha_components import components


SHEETS = ("walk_contact.png", "walk_pass.png", "run_contact.png", "run_pass.png")


def cell_bounds(length: int, index: int) -> tuple[int, int]:
    return length * index // 4, length * (index + 1) // 4


def inspect_sheet(path: Path) -> dict:
    image = np.asarray(Image.open(path).convert("RGBA"))
    height, width = image.shape[:2]
    cells = []
    for row in range(4):
        y0, y1 = cell_bounds(height, row)
        for column in range(4):
            x0, x1 = cell_bounds(width, column)
            alpha = image[y0:y1, x0:x1, 3]
            _labels, groups = components(alpha > 0)
            ranked = sorted(groups.values(), key=lambda item: item["area"], reverse=True)
            cells.append(
                {
                    "index": row * 4 + column,
                    "cell": [x0, y0, x1 - x0, y1 - y0],
                    "opaque_pixels": int(np.count_nonzero(alpha)),
                    "components": [
                        {"area": int(item["area"]), "box": [int(v) for v in item["box"]]}
                        for item in ranked
                        if item["area"] >= 4
                    ],
                }
            )
    return {"path": str(path), "size": [width, height], "cells": cells}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("asset_dir", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    report = {name: inspect_sheet(args.asset_dir / name) for name in SHEETS}
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)


if __name__ == "__main__":
    main()

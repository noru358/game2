"""Summarize opaque colors that directly touch transparency in reskin sheets."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image


SHEETS = ("walk_contact.png", "walk_pass.png", "run_contact.png", "run_pass.png")


def adjacent_to_transparency(alpha: np.ndarray) -> np.ndarray:
    opaque = alpha > 0
    padded = np.pad(opaque, 1, constant_values=False)
    surrounded = np.ones_like(opaque)
    for dy in range(3):
        for dx in range(3):
            surrounded &= padded[dy : dy + opaque.shape[0], dx : dx + opaque.shape[1]]
    return opaque & ~surrounded


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("asset_dir", type=Path)
    args = parser.parse_args()
    report = {}
    for name in SHEETS:
        rgba = np.asarray(Image.open(args.asset_dir / name).convert("RGBA"))
        boundary = adjacent_to_transparency(rgba[:, :, 3])
        rgb = rgba[:, :, :3][boundary]
        alpha = rgba[:, :, 3][boundary]
        quantized = (rgb // 16 * 16).astype(np.uint8)
        top = Counter(map(tuple, quantized.tolist())).most_common(30)
        red = (rgb[:, 0] > 180) & (rgb[:, 0] > rgb[:, 1] * 2) & (rgb[:, 0] > rgb[:, 2] * 2)
        yellow = (rgb[:, 0] > 180) & (rgb[:, 1] > 180) & (rgb[:, 2] < 100)
        keyed = red | yellow
        report[name] = {
            "boundary_pixels": int(rgb.shape[0]),
            "keyed_red_yellow": int(np.count_nonzero(keyed)),
            "keyed_by_alpha_threshold": {
                str(level): int(np.count_nonzero(keyed & (alpha >= level)))
                for level in (8, 16, 24, 32, 64, 128)
            },
            "keyed_alpha_percentiles": [
                float(value) for value in np.percentile(alpha[keyed], [0, 25, 50, 75, 90, 100])
            ],
            "top_quantized_rgb": [[list(map(int, color)), int(count)] for color, count in top],
        }
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

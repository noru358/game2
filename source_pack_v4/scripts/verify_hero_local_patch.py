"""Read-only pixel guard for a local sprite repair; never edits either image.

The mask is an explicit, visually reviewed permitted-change area (white=editable).
An exact preservation PASS proves only pixel preservation, never anatomy quality.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('allowed_mask', type=Path)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    original = np.asarray(Image.open(args.original).convert('RGBA'))
    candidate = np.asarray(Image.open(args.candidate).convert('RGBA'))
    mask = np.asarray(Image.open(args.allowed_mask).convert('L'))
    same_dimensions = original.shape == candidate.shape and mask.shape == original.shape[:2]
    report = {
        'original': str(args.original.resolve()),
        'candidate': str(args.candidate.resolve()),
        'allowed_mask': str(args.allowed_mask.resolve()),
        'original_sha256': sha(args.original),
        'candidate_sha256': sha(args.candidate),
        'mask_sha256': sha(args.allowed_mask),
        'same_dimensions': same_dimensions,
        'art_acceptance': False,
        'scope': 'Exact RGBA preservation outside reviewed mask only. Does not prove anatomy, costume continuity, foot contact, or animation quality.',
    }
    passed = False
    if same_dimensions:
        allowed = mask > 0
        changed = np.any(original != candidate, axis=2)
        protected_changes = int(np.count_nonzero(changed & ~allowed))
        allowed_changes = int(np.count_nonzero(changed & allowed))
        meaningful_mask = bool(allowed.any() and (~allowed).any())
        passed = meaningful_mask and protected_changes == 0 and allowed_changes > 0
        report.update(protected_pixel_changes=protected_changes, allowed_pixel_changes=allowed_changes,
                      meaningful_mask=meaningful_mask, allowed_fraction=float(allowed.mean()))
    report['preservation_pass'] = passed
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))
    raise SystemExit(0 if passed else 1)


if __name__ == '__main__':
    main()

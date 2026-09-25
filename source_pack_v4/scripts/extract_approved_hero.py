"""User-authorized deterministic alpha extraction; never redraws source RGB."""
from pathlib import Path
from collections import deque
import hashlib
import json
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/design_refs/hero_turnaround_approved.png'
OUT = ROOT / 'experiments/terrace/art_review/hero_idle_exact_v1'


def largest_component(binary):
    h, w = binary.shape
    seen = np.zeros((h, w), dtype=bool)
    best = []
    for y, x in zip(*np.nonzero(binary)):
        if seen[y, x]:
            continue
        queue = deque([(int(y), int(x))])
        seen[y, x] = True
        component = []
        while queue:
            cy, cx = queue.popleft()
            component.append((cy, cx))
            for ny, nx in ((cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)):
                if 0 <= ny < h and 0 <= nx < w and binary[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx] = True
                    queue.append((ny,nx))
        if len(component) > len(best):
            best = component
    result = np.zeros((h,w),dtype=np.uint8)
    for y,x in best:
        result[y,x] = 255
    return Image.fromarray(result)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert('RGB')
    atlas = Image.new('RGBA', source.size)
    slots = [('FRONT',2),('FRONT-RIGHT',1),('RIGHT',0),('BACK-RIGHT',7),
             ('BACK',6),('BACK-LEFT',5),('LEFT',4),('FRONT-LEFT',3)]
    # Individual source rectangles: equal grid slicing clips the right views' tails.
    regions = [(0,0,362,492),(362,0,340,492),(700,0,328,492),(1038,0,372,492),
               (0,520,362,490),(362,520,370,490),(768,520,310,490),(1084,520,364,490)]
    frames = []
    checks = []
    for cell,(name,index) in enumerate(slots):
        col,row = cell%4,cell//4
        x,y,w,h = regions[cell]
        crop = source.crop((x,y,x+w,y+h))
        rgb = np.asarray(crop).astype(np.int16)
        low = rgb.min(axis=2)
        chroma = rgb.max(axis=2)-low
        # Dark ink and colored material form an enclosing silhouette. White fabric
        # is restored by enclosed-hole fill, not deleted by a global white key.
        seed = (chroma>24) | (low<180)
        # Floor shadow is neutral gray. Use a stricter floor band near the soles.
        floor = 470 if row==0 else 456
        seed[floor:] = (chroma[floor:]>28) | (low[floor:]<115)
        seed[:2] = False
        seed[-2:] = False
        seed[:,:2] = False
        seed[:,-2:] = False
        mask = Image.fromarray(seed.astype(np.uint8)*255)
        mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
        mask = largest_component(np.asarray(mask)>0)
        outside = mask.copy()
        ImageDraw.floodfill(outside,(0,0),128,thresh=0)
        filled = np.where(np.asarray(outside)==128,0,255).astype(np.uint8)
        # Keep unmodified source colors. No inpainting, warping or resynthesis.
        rgba = crop.convert('RGBA')
        rgba.putalpha(Image.fromarray(filled))
        atlas.paste(rgba,(x,y))
        bbox = Image.fromarray(filled).getbbox()
        foot = bbox[3]-1
        sole_x = np.nonzero(filled[max(0,foot-12):foot+1])[1]
        root_x = float((sole_x.min()+sole_x.max())/2)
        rgba.save(OUT/(name.lower().replace('-','_')+'.png'))
        frames.append(dict(direction=name,engine_index=index,region=[x,y,w,h],
                           top=bbox[1],foot=foot,root_x=root_x,
                           source_cell=cell,anchor_status='sole_extent_midpoint_provisional'))
        checks.append(dict(direction=name,foreground_pixels=int((filled>0).sum()),
                           opaque_rgb_identical=bool(np.array_equal(np.asarray(rgba)[:,:,:3],np.asarray(crop))),
                           local_bbox=bbox,edge_touches=bool((filled[0]>0).any() or (filled[-1]>0).any() or (filled[:,0]>0).any() or (filled[:,-1]>0).any())))
    atlas.save(OUT/'candidate.png')
    frames.sort(key=lambda d:d['engine_index'])
    (OUT/'frames.json').write_text(json.dumps(frames,indent=2),encoding='utf-8')
    report=dict(method='source RGB preserved; color/ink component + enclosed hole fill',
                authorized='User explicitly selected Python mask processing on 2026-09-24',
                source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                directions=8,checks=checks,visual_status='PENDING_PIXEL_REVIEW')
    (OUT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__ == '__main__':
    main()

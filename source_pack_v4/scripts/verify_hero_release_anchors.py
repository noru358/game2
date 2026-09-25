"""Guard the GPU-reviewed glove centres against transparent/wrist anchor regressions.

Dark-pixel membership alone is not anatomical proof; pair with hand_alignment GPU sheets.
"""
import json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]/'experiments/terrace/art_review/hero_pose_v2'
manifest=json.loads((ROOT/'frames.json').read_text(encoding='utf-8'))
rows=[]
for frame in manifest['frames']:
    if frame['state']!='attack' or frame['frame']!=1:
        continue
    x,y=frame['hands'][0]
    if frame.get('mirror_h'):
        x=frame['region'][2]-x
    pixel=Image.open(ROOT/frame['sheet']).getpixel((int(frame['region'][0]+x),int(frame['region'][1]+y)))
    ok=pixel[3]==255 and max(pixel[:3])<110
    rows.append(dict(direction=frame['direction'],step=frame['step'],rgba=pixel,opaque_glove_pixel=ok))
report=dict(checks=len(rows),failures=sum(not row['opaque_glove_pixel'] for row in rows),scope='release centre pixels only; pair with GPU anatomical review',rows=rows)
(ROOT/'hand_anchor_pixels.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
raise SystemExit(1 if report['failures'] else 0)

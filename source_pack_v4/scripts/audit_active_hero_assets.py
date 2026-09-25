"""Read-only runtime asset audit. Never rewrites or removes sprite assets."""
import json
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'experiments/terrace/art_review/hero_pose_v2'
OUT = ROOT / 'experiments/terrace/art_review/hero_repair_v3'
frames = json.loads((ART / 'frames.json').read_text(encoding='utf-8'))['frames']
active = Counter(f['sheet'] for f in frames)
records = []
for path in sorted(ART.rglob('*.png')):
    rel = path.relative_to(ART).as_posix()
    category = 'runtime_sheet' if rel in active else 'generation_source' if rel.endswith('_source.png') else 'archive' if rel.startswith('archive/') else 'not_referenced_by_motion_renderer'
    records.append({'path': rel, 'category': category, 'runtime_frame_references': active.get(rel, 0)})
selected = sorted([f for f in frames if f['direction'] in (5,7) and f['state'] in ('walk','run')], key=lambda f:(f['direction'],f['state'],f['frame']))
OUT.mkdir(exist_ok=True)
data = {'scope':'hero_pose_player frames.json only; nonreferenced does not imply deletable', 'png_count':len(records),'runtime_sheets':len(active),'registered_frames':len(frames),'assets':records,'rear_diagonal_frames':selected}
(OUT/'active_asset_audit.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# 실제 모션 참조 자산 감사 — 2026-09-25','','`hero_pose_player.gd`는 `hero_pose_v2/frames.json`만 읽는다. 정지는 별도 승인 atlas를 사용한다. 미참조 파일을 삭제 대상으로 해석하지 않는다.','','| 방향 | 상태 | 컷(0부터) | 실제 시트 | 반전 |','|---|---|---|---|---|']
for f in selected:
    lines.append(f"| {f['direction']} | {f['state']} | {f['frame']} | {f['sheet']} | {f.get('mirror_h',False)} |")
lines += ['',f'총 PNG {len(records)}개, 모션 런타임 시트 {len(active)}개, 프레임 등록 {len(frames)}개.','', '## 픽셀 관찰', '', '- 뒤대각선 run opposite: 상체/머리 우상 방향과 하체 정후면/지지 부츠 측면 방향 불일치.','- 뒤대각선 walk opposite: 상체 아래의 골반/양 코트 패널은 정후면에 가깝고 지지 부츠는 옆을 향함.','- first/opposite 전환에서 체형·꼬리·복장도 바뀜. 발끝만 돌리는 처리는 불충분.','- 좌상(5)은 우상(7) 원본 반전. 서로 다른 자산을 새로 만들 필요 없음.','- 새 left_support 후보02에 대한 사용자 수용은 한 자세의 다리 연결에 한정. 활성 움직임/복장 승인 아님.']
(OUT/'ACTIVE_ASSET_AUDIT.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({'png':len(records),'runtime_sheets':len(active),'rear_unique_sheets':sorted({f['sheet'] for f in selected})}))

raise SystemExit("One-off V5 migration already applied. Do not rerun; read docs/WORK_LOG.md.")
from pathlib import Path
import hashlib,json,re,shutil
W=Path(__file__).resolve().parent; R=W/'source_pack_v4'; D=R/'docs'; refs=D/'design_refs'
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s.rstrip()+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
supplied=Path('C:/Users/User/AppData/Local/Temp/codex-clipboard-0f565a22-f971-43ae-94c2-4bebbc7ad754.png')
mapping={
'file_00000000fe8482119f76e7ebf30f8900.png':'enemy_wanderer_reference.png',
'file_00000000b06c81f88e23d05e568e2620.png':'enemy_charger_reference.png',
'file_000000008fe88211851f3f98b4bd1c9b.png':'enemy_ranged_reference.png',
'file_000000006a148211864c646c7ca8d1ed.png':'surface_dirt_reference.png',
'file_000000005264820ea2400c746aa4926b.png':'surface_path_reference.png',
'file_0000000013c88211a31328d5a01b10ab.png':'surface_water_reference.png',
'file_00000000c25082119a4456203fc02b29.png':'surface_paving_reference.png'}
oldmanifest=json.loads((refs/'ASSET_MANIFEST.json').read_text('utf-8'))
delete=[]
for p in refs.glob('file_*.png'):
 reason='주인공 기준 충돌/중복: 사용자 제공 hero_turnaround_approved.png로 대체'
 if p.name in mapping:
  shutil.copyfile(p,refs/mapping[p.name]);reason='내용 보존, 용도를 알 수 있는 파일명으로 변경: '+mapping[p.name]
 delete.append((p,reason))
shutil.copyfile(supplied,refs/'hero_turnaround_approved.png')
for rel in ['READ_FIRST.txt','docs/START_HERE.md','docs/CURRENT_STATE.md','docs/EXPERIMENT_PLAN.md','docs/NEW_PROJECT_START_PROMPT.md','docs/SOURCE_PACK_GUIDE.md','docs/NEXT_SESSION_HANDOFF.md','docs/CLEANUP_PLAN.md','docs/D118_DISK_CLEANUP.md','docs/D118_DISK_CLEANUP.json']:
 delete.append((R/rel,'중복 진입/과거PC 정리 문서: README와 GAME_PROJECT_SOURCE로 필요한 내용 통합'))
for rel in ['game/path.gdshader','game/water.gdshader','lab/distant_forest.gdshader']:
 for ext in ['', '.uid']:delete.append((R/'experiments/terrace'/(rel+ext),'전체 소스 리터럴 참조0인 미사용 shader/식별자'))
for name in ['latest8.jpg','refs_1.jpg','refs_2.jpg','refs_3.jpg','refs_4.jpg']:
 delete.append((W/'docs/audit_v4'/name,'폐기 주인공을 다시 보여주는 이전 감사 비교이미지'))
for name in ['audit_pack.py','build_review_index.py']:
 delete.append((W/name,'삭제된 V4파일을 전제로 한 일회성 감사 생성도구'))
records=[]
for p,reason in delete:
 assert p.resolve().is_relative_to(W) and p.is_file(),p
 records.append({'path':p.relative_to(W).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size,'reason':reason})
write(W/'docs/CLEANUP_DELETIONS.json',json.dumps({'date':'2026-09-24','authorization':'현재 사용자: 기준과 다르거나 혼동/불필요 자료는 삭제하여 정리','files':records},ensure_ascii=False,indent=2))
assetrecords=[]
for name in ['hero_turnaround_approved.png',*mapping.values()]:
 p=refs/name
 assetrecords.append({'file':name,'sha256':sha(p),'bytes':p.stat().st_size,'status':'USER_SUPPLIED_CANONICAL_VISUAL_REFERENCE' if name.startswith('hero_') else 'APPROVED_DIRECTION_REFERENCE_NOT_RUNTIME_INTEGRATED','runtime_integrated':False})
directions=['FRONT','FRONT-RIGHT','RIGHT','BACK-RIGHT','BACK','BACK-LEFT','LEFT','FRONT-LEFT']
write(refs/'ASSET_MANIFEST.json',json.dumps({'date':'2026-09-24','canonical_hero':'hero_turnaround_approved.png','source':'이번 사용자 첨부. PNG 원본 바이트 그대로 복사','note':'이전 개별8장/주인공보드 폐기. 시트의 시각방향은 기준확정, 실사용alpha/anchor/모션/엔진통합은 미완료.','directions':[{'label':v,'row':i//4,'column':i%4,'engine_index':dict(FRONT=2,RIGHT=0,BACK=6,LEFT=4).get(v,{'FRONT-RIGHT':1,'BACK-RIGHT':7,'BACK-LEFT':5,'FRONT-LEFT':3}.get(v))} for i,v in enumerate(directions)],'files':assetrecords},ensure_ascii=False,indent=2))
write(refs/'README.md','''# 미술 기준

주인공은 **아래 한 장만 기준**으로 사용한다. 이전 개별8장과 옛 주인공 보드는 삭제했다.

![사용자 확정 주인공 8방향](hero_turnaround_approved.png)

2026-09-24 사용자가 “제대로된 이미지”로 제공한 원본이다. 위줄 FRONT / FRONT-RIGHT / RIGHT / BACK-RIGHT, 아래줄 BACK / BACK-LEFT / LEFT / FRONT-LEFT. 지팡이·등 두루마리 없음. 큰 귀·꼬리, 아이보리/남청/금/청색 보석, 검정 폐쇄형 신발과 손 시전.

이 파일은 배경·방향 글자가 있는 참고 시트다. 투명 PNG8개/발 기준점/모션이 완성됐다는 뜻은 아니다. 다음 제작은 이 시트의 디자인을 그대로 보존해 게임용8방향을 준비하는 것. 옛 개별4번 수리 작업은 폐기됐으므로 다시 하지 않는다.

## 적·지면 참고

주인공과 다른 용도다. 모두 방향 참고 보드이며 실사용 sprite/반복 texture로 바로 넣지 않는다.

- [배회 적](enemy_wanderer_reference.png) · [돌진 적](enemy_charger_reference.png) · [원거리 적](enemy_ranged_reference.png)
- [흙](surface_dirt_reference.png) · [길](surface_path_reference.png) · [물](surface_water_reference.png) · [포석](surface_paving_reference.png)

원본해시/상태/시트방향과 엔진슬롯 대응은 ASSET_MANIFEST.json. 최종 가독성은 기존 카메라의 실제 크기로 확인한다.
''')
old=(D/'GAME_PROJECT_SOURCE.md').read_text('utf-8-sig')
promises=old.split('## 게임의 핵심 약속')[1].split('## 전체 흐름')[0]
write(D/'GAME_PROJECT_SOURCE.md','''# 현재 게임 기준

2026-09-24 · V5 정리본. **이 문서가 현재 상태와 다음 작업의 유일한 기준이다.**

## 지금 어디인가

최종 목표는 본편 완성→Steam 출시→초기 안정화. 현재 **P1 핵심 경험 검증 / P2 일부 제작, M1-A**. 약10분 데모는 중간 목표이며 완성/사람수용/실청음은 미완료다.

| 축 | 현재 | 다음 통과 조건 |
|---|---|---|
| 게임성 | terrace0.10 / Packet1A 입력반응 부분 구현 | 사람의 정지·반전·자동사냥·직접연타·밀치기·회피·타격음·반복피로 확인 |
| 주인공 | 이번 사용자 제공8방향 시트로 시각기준 통일 | 동일 디자인의 게임용 투명8방향,방향/크기/발/root등록. G2 엔진준비는 미완료 |
| 미술 | B′ 클린2.5D. 적/지면 방향참고 유지 | 소량모션·작은통합구간. 게임은 아직 옛 임시그림 사용 |
| 지역/분량 | 3지역왕복·강화·발견·저장·작은결말 기능 | 지역별 전투/경로 선택과 사람의 초회8~12분 |

**옛 개별PNG4 수리/개별7·8 재검수는 더 이상 다음 작업이 아니다.** 해당 파일들은 현재 작업본에서 삭제했다. 새 [주인공 기준 및 적·지면 참고](design_refs/README.md)만 읽는다. 이 시트가 게임에 적용되었다고 보고하지 않는다.

## 실제 작업 대상

이 폴더의 `experiments/terrace/project.godot` 하나가 실행 대상이다. 일반 실행은 `game/boot.tscn → lab/journey.tscn`. `lab/world.gd → game/world.gd`는 공통 기반이다. game/의 옛 코드도 상속/회귀 참조가 있어 통째 삭제하지 않는다.

이 작업본은 게임 v2 안의 source_pack_v4 폴더에서 이어가며 폴더명만 최초수입본 이름을 유지한다. 내용은 V5다. 이전 겜1 프로젝트와 Downloads의 원본V4 ZIP은 별도 원본이고 동기화되지 않는다. 이 폴더에는 기존 Windows/Mac 실행본이 없다.

## 핵심 경험
'''+promises+'''
## 다음 실행 순서

1. **새 시트 기반 게임용8방향 준비**: 디자인/방향/캔버스/발/root/alpha를 확인한 개별 원본과 등록표. 실제 개별원본에서 검수시트를 조립한다. 배경글자가 있는 참고시트를 sprite로 바로 사용하지 않는다.
2. **현재0.10 사람 체감 확인**: 이미 구현한 가속0.75초·상쇄입력·회복중탭 예약을 반복 구현하지 않는다. 사람관찰에 따라 필요한 조정만 한다.
3. **소량모션**: 대표4방향×4보행단계16컷→연속재생, 대표방향 시전 소량→손/VFX/판정 검수. 최종 이동/표현은8방향이며 대표4방향은 생산검증 샘플이다.
4. **작은 통합구간**: 새주인공+적1종+최소환경/효과를 실제카메라에 연결. 경사/가림/전투/축소크기와 사람수용 확인 후 필요한8방향·3타 확대.
5. **Packet2 / M1-B**: 세지역 고유경로·전투·발견. 높은길/낮은길 재합류와 전투행동 차이.
6. **Packet3 / M1-C**: 짧은성과·중단복귀, 초행시간/막힘/기억한성장 관찰. 이어 M1-D 대표품질→P3 공개검증→본편범위/생산성확정.

1과2는 독립 작업축이다. 사람검수 전 Packet1완료, 이미지한장 확보로 모션/실게임완료를 선언하지 않는다. 110컷·전체환경을 먼저 양산하지 않는다.

## 필요한 문서만 읽기

- 큰단계와 종료기준: [로드맵](GAME_MASTER_ROADMAP.md)
- 게임성 작업범위: [Packet1~3](NEXT_IMPLEMENTATION_PACKETS.md)
- 채택된 이야기: [STORY_CANON](STORY_CANON.md)
- 그림 등록계약: [ART_PRODUCTION_CONSTRAINTS](ART_PRODUCTION_CONSTRAINTS.md)
- 지형/픽셀 검사: [RENDER_QA](RENDER_QA.md)
- 실행/이관 한계: [MIGRATION_VERIFICATION](MIGRATION_VERIFICATION.md)
- 변경과판단: [작업기록](WORK_LOG.md), [결정기록](DECISION_HISTORY.md), [논의기록](DISCUSSION_LOG.md)

## 이번 정리

사용자가 제공한 새8방향 시트를 유일한 주인공기준으로 저장했다. 충돌하는 주인공자료12개 삭제, 적/지면7개 의미있는 이름으로 변경, 중복안내·PC정리문서·미사용shader 정리. 런타임18PNG는 실제참조가 있어 임시자산으로 남긴다. 전투/저장/이야기내용은 바꾸지 않았다. 패키저는 현재기록을 그대로 보존한다. 최종 삭제·검증 결과는 WORK_LOG의 V5항목을 따른다.
''')
write(R/'README.md','''# 게임 v2

**[현재 상태·다음 작업](docs/GAME_PROJECT_SOURCE.md)**부터 읽는다.

- [유일한 주인공 기준과 적·지면 참고](docs/design_refs/README.md)
- 게임 실행: Godot4.7.2에서 `experiments/terrace/project.godot` 열기.
- 현재 게임은0.10 시제품이며 새주인공은 아직 통합하지 않았다.
- 코드/임시자산은 `experiments/terrace`, 작업기록은 `docs/WORK_LOG.md`.
- 재포장: `python scripts/package_project_source.py --out <출력폴더> --version V5 --date 20260924`.

이 폴더의 현재자료만 기준으로 작업한다. 삭제된 옛개별PNG나 과거인계프롬프트를 원본ZIP에서 되살리지 않는다. 기존V4 ZIP은 과거복구용이며 현행미술기준이 아니다.
''')
write(W/'README.md','''# 게임 v2

**[현재 상태와 다음 작업](source_pack_v4/docs/GAME_PROJECT_SOURCE.md)**

**[확정 주인공 그림](source_pack_v4/docs/design_refs/hero_turnaround_approved.png)** · [적·지면 참고](source_pack_v4/docs/design_refs/README.md)

개발 위치는 `source_pack_v4/experiments/terrace/project.godot`이다. 기존 폴더명만 유지하며 내용은V5 정리본이다. 게임은0.10 시제품, 새미술의 엔진통합은 다음 작업이다.

[현재 작업기록](docs/WORK_LOG.md) · [삭제 내역](docs/CLEANUP_DELETIONS.json)

`docs/audit_v4`와 V4_AUDIT는 **정리 전 감사증거**이며 현재자료목록/주인공기준이 아니다.
''')
# Keep technical contracts, remove obsolete branching style decision process.
p=D/'ART_PRODUCTION_CONSTRAINTS.md';s=p.read_text('utf-8-sig')
s=s[:s.index('## 6. 현재 엔진 구조')]
s=s.replace('2026-09-22 · D109 · 현행 0.9 구조를 기준으로 한 작화 비교용 기술 조건. 이 문서는 2D·2.5D·stylized 3D 중 하나를 선택하지 않는다. 각 방향을 **같은 플레이 조건에서 비교할 수 있게 만드는 최소 계약**만 정리한다.','2026-09-24 현행 등록계약. B′ 클린2.5D는 선택 완료. 주인공의 유일한 시각기준은 [새8방향 시트](design_refs/hero_turnaround_approved.png)다. 아래는 기존0.10 엔진 등록값이며 새미술통합은 미완료다.')
s=s.replace('Godot 4.4, GL Compatibility','실행검증 Godot4.7.2, GL Compatibility (project.features는4.4)')
s=s.replace('큰 전경 뒤 위치 보조용 청록 silhouette와 no-depth familiar가 있다.','no-depth familiar가 있다. 청록 silhouette는 D105 이후 비표시이며 옛가림 설명을 복원하지 않는다.')
s=s[:s.index('### 기술적으로 가능하지만')]
s+='''\n## 다음 자산 등록

시트 방향→현재엔진 슬롯: RIGHT0, FRONT-RIGHT1, FRONT2, FRONT-LEFT3, LEFT4, BACK-LEFT5, BACK6, BACK-RIGHT7. 월드 +X가화면오른쪽, +Z가화면아래인 현행고정카메라 기준이다. 슬롯 등록 후 실제회전 검사로 확인한다.

원본8방향 각각의region/top/foot/root_x를 기록한다. 시전은hand/hands도 필요하다. 시트배경/그림자/글자를 투명원본으로 오인하지 않는다. 승인장식·보석·꼬리의 좌우를 임의mirror로 변경하지 않는다. 동일팔레트/몸비율/발접지와 어두운/밝은배경의alpha경계를 실제74px급 화면에서 확인한다.

대표4방향16컷은 제작검증 샘플이다. 최종8방향·달리기·피격·회피·시전/회수 생산범위는 샘플재생 이후 닫는다. 사용도구/원본참조/후편집/생성일/실제시간·비용을 자산별로 남긴다.
''';write(p,s)
p=D/'NEXT_IMPLEMENTATION_PACKETS.md';s=p.read_text('utf-8-sig');s=s[:s.index('## CURRENT_STATE 반영 초안')];s=s.replace('# 다음 구현 묶음 제안','# 게임성 작업 묶음');s=re.sub(r'2026-09-22 · D108 ·.*?현재 위치는', '2026-09-24. 현재 상태는 [통합 기준](GAME_PROJECT_SOURCE.md)에서만 관리한다. 아래는 각 묶음의 작업범위/통과조건이다.\n\n현재 위치는',s, count=1,flags=re.S);write(p,s)
p=D/'GAME_MASTER_ROADMAP.md';s=p.read_text('utf-8-sig');start=s.index('## 전체 단계와 완성되어야 할 것');end=s.index('## 세션 승계와 매 작업 기록');s='# 본편까지의 단계 정의\n\n현재 단계/다음 작업은 [현재 게임 기준](GAME_PROJECT_SOURCE.md)을 따른다. 여기서는 단계 정의와 통과조건만 유지한다.\n\n'+s[start:end];write(p,s)
p=D/'STORY_CANON.md';s=p.read_text('utf-8-sig');s=s.replace('갱신: 2026-09-21. 현재 채택 범위만 기준으로 삼는다. [논의 이력](DECISION_HISTORY.md)의 S01~S08과 [최신 논의](DISCUSSION_LOG.md)를 함께 참조한다.','채택된 이야기 기준. 외형은 [현재 주인공 시트](design_refs/hero_turnaround_approved.png)를 따른다. 과거S01~S08 원문은 원V4에도 미포함이며 새설정을 추정하지 않는다.');s=s.replace('주인공은 기존에 선택한 숲 생명체다.','주인공은 사막여우형 비인간 문관이다.');s=s[:s.index('2026-09-21 개발 착수:')];write(p,s)
write(D/'DOCUMENTATION_PROTOCOL.md','''# 기록 규칙

시작: 사용가능한 WORK_MEMORY → GAME_PROJECT_SOURCE의 현재/다음 → 관련 WORK_LOG.

종료: WORK_LOG에 날짜/요청/문제/원인 또는가설/실제변경/검증/남은문제. DISCUSSION_LOG는 판단이유, DECISION_HISTORY는 결정변경을 기록한다. 현재 상태는 GAME_PROJECT_SOURCE 하나에서만 갱신한다. 이야기 결정만 STORY_CANON에 반영한다.

사용자수용·이미지규격·엔진통합·자동검사·실제픽셀·사람체감은 별도 상태다. 옛기록은 날짜가붙은 역사이며 현재명령이 아니다. 사용자가 삭제를요청한 폐기자료는 활성폴더에 백업복제하지 않고 삭제목록/이유/해시를 기록한다. 누적기록은 재포장에서도 그대로 유지한다. 다른기기/온라인과 자동동기화된다고 하지 않는다.
''')
write(D/'RENDER_QA.md','''# 현재 렌더 검수

- 지형의흙/길/물은 단일불투명표면. 포석은 공통삼각형높이. 이동/충돌/카메라/저장복원/적경고가 높이계약을 공유한다.
- `ground_surfaces/terrain_probe/grounded_run/exploration`은 기존공통기능 회귀. `render_surface_motion`은 옛맵14지점 진단이며 현재3지역의미술승인이 아니다.
- 현재여정의화면은 `journey_flow`, 경사/예고는 `slope_cues/warning_damage`, 모션/손은 `gait_cycle/hand_origin/diagonal_strike/moving_strike`를 목적에맞게 실행한다. GPU가필요한검사를 headless로기다리지 않는다.
- `--test`와PID별저장을쓴다. GPU캡처는 DEMO_QA_OUTPUT으로지정한다. 사용자게임/실제저장을 건드리지않는다.
- 단색기하검사와실제텍스처픽셀검사를구분한다. 경사·포석접합·가림·발접지·손/VFX·연속보행을실제로본다. PNG저장성공은품질통과가아니다.
- 새미술기준은 [확정시트](design_refs/hero_turnaround_approved.png). 옛캐릭터가보이는테스트캡처는미술기준으로쓰지않는다. 사람조작감/실청음은별도다.
''')
write(D/'MIGRATION_VERIFICATION.md','''# 실행과 재포장

현재 게임: `experiments/terrace/project.godot`,0.10-core-response. Godot4.7.2로import한뒤실행한다. 같은버전의export templates는별도설치한다. 소스팩에는실행본/엔진/실제저장이없다.

주인공기준은 [이번사용자시트](design_refs/hero_turnaround_approved.png). 과거19참고/개별PNG4수리절차는폐기됐다. 현재참고는주인공1+적3+지면4=8장이다. 런타임PNG18은기존임시자산이다.

재포장도구는현재파일바이트와누적로그를그대로보존하고누락자원/문서링크를실패로알린다. 빠진링크를설명문구로숨기지않는다. PACKAGE_MANIFEST와ZIP CRC/각파일SHA를검증한다. 버전/날짜는명시인자다.

V4감사때core_response6/여정GPU28통과. V5정리검증은WORK_LOG에별도기록한다. 기능통과는사람체감/미술통합/Mac실기보증이아니다.

Mac배포스크립트는아직원작업공간.tools배치와 builds/THIRD_PARTY_LICENSES.txt를요구한다. 라이선스생성도구미포함이므로표준엔진설치만으로포장이완결되었다고하지않는다. 다음배포작업에서경로인자화/라이선스생성까지수리해야한다. 현재요청은미술기준과자료정리이며Mac빌드완료를주장하지않는다.
''')
write(R/'AGENTS.md','''# 게임 v2 작업 규칙

- 이폴더 README → docs/GAME_PROJECT_SOURCE → 관련 WORK_LOG를 읽는다. 환경의 WORK_MEMORY가있으면먼저읽는다.
- 주인공은 docs/design_refs/hero_turnaround_approved.png 하나가시각기준이다. 옛개별8장/4번수리프롬프트/과거보드를복원하지않는다. 그림준비와엔진통합/모션/사람수용을구분한다.
- 현재상태는 GAME_PROJECT_SOURCE 한곳,이야기는STORY_CANON,과거구현은날짜붙은기록으로구분한다. 종료기록은DOCUMENTATION_PROTOCOL을따른다.
- 사용자게임과실제저장을시험에쓰지않는다. 독립 --test/PID저장을사용한다.
- 지형/이동/충돌/카메라/저장/리스폰/경고는공유높이계약. 불투명단일지형과Landscape.paving을유지한다. 관련수정은headless회귀+GPU실제픽셀을함께검수한다.
- 키보드메뉴는진입/선택/닫기/복귀까지검사. 모션은방향프레임수보다연속재생/접지/손-VFX가중요하다.
- 전투성능수정은실제AI/물리/경고/공격/저장을켠live_combat_performance와warning_cache_contract를쓴다. physics를끈combat_performance는부분측정이다.
- 임시검수경로/프로세스를기록하고작업종료시생성물만정리한다. docs/.gdignore를유지한다. 삭제실패시사실을기록한다.
- 패키저는누적로그를그대로읽고포장해야한다. 기록을고정문구로초기화하지않는다.
''')
p=R/'experiments/terrace/AGENTS.md';s=p.read_text('utf-8-sig');s=s.replace('상위 겜1/AGENTS.md와 겜1/docs/START_HERE.md, 겜1/docs/EXPERIMENT_PLAN.md, 본 프로젝트 docs/WORK_LOG.md를 읽는다.','상위 AGENTS.md와 docs/GAME_PROJECT_SOURCE.md, 본 프로젝트 docs/WORK_LOG.md를 읽는다.');s=s.replace('lab/world.gd가 실험 진입점이며','일반 진입점은 game/boot → lab/journey.tscn이며, lab/world.gd는 기반 실험장으로');write(p,s)
p=R/'experiments/terrace/README.md';write(p,'''# 현재 실행 시제품0.10

Godot4.7.2에서이폴더의project.godot를연다. 일반진입은boot→lab/journey다. [현재작업기준](../../docs/GAME_PROJECT_SOURCE.md)을따른다.

WASD/방향키 이동, Space/Shift 회피, J 직접마법, 근처적 자동마법, F 발견/지역이동, Esc 메뉴. 물길입구→뿌리단상→얼굴사원3지역. 발견/성장/열린길이저장된다.

런타임그림18개는기존임시미술이다. 새사막여우기준과다르지만현재실행에필요하여유지한다. 승인그림/완성미술로재사용하지말고후속대체후의존검사로제거한다. 현재약10분초회/사람체감/실청음미완료.

소스팩에는builds실행본이없다. 이전검증기록은docs/WORK_LOG와D107/D112/D113문서. 실제저장으로검사하지말고 --test를사용한다.
''')
log='''\n## 2026-09-24 — V5: 사용자 제공 기준시트와 삭제 정리
- 요청: 새이미지로다음작업을이어가고기준과다르거나혼동/불필요자료는삭제.
- 결정: hero_turnaround_approved.png를유일한주인공시각기준으로채택. 옛개별8장/보드4장폐기,적·지면7보드는의미있는이름으로유지. 옛PNG4수리는새작업에서제외.
- 실제변경: 충돌참고/중복시작문서/미사용shader 삭제계획,정본과기술/검수/인계문서정리. 현재로그보존패키저로교체. 게임런타임미술18PNG는실제참조때문에유지하며승인기준과구분.
- 검증/남은것: 삭제완료/의존/해시/ZIP검증은후속결과추가. 새시트의픽셀8방향확인. 투명개별자산/anchor/모션/엔진통합은미실행. P1/P2일부 M1-A,Packet1A사람체감미완료유지.
'''
for name in ['WORK_LOG.md','DISCUSSION_LOG.md','DECISION_HISTORY.md']:
 p=D/name;write(p,p.read_text('utf-8-sig')+log)
write(R/'experiments/terrace/docs/WORK_LOG.md',(R/'experiments/terrace/docs/WORK_LOG.md').read_text('utf-8-sig')+log)
# Rewrite only actual links to retired material; dated plain historical mentions stay history.
deleted={p.resolve() for p,_ in delete}
for p in [*R.rglob('*.md'),W/'docs/V4_AUDIT_20260924.md',W/'docs/audit_v4/FILE_REVIEW.md']:
 if p.resolve() in deleted:continue
 s=p.read_text('utf-8-sig')
 def replace(m):
  target=m.group(3)
  if re.match(r'\w+://',target) or target.startswith('#'):return m.group(0)
  q=(p.parent/target.split('#')[0]).resolve()
  if q not in deleted:return m.group(0)
  return m.group(2)+'（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록）'
 s=re.sub(r'(!?)\[([^\]]*)\]\(([^)]+)\)',replace,s)
 if p in [W/'docs/V4_AUDIT_20260924.md',W/'docs/audit_v4/FILE_REVIEW.md']:
  s='> 역사 기록: 이 문서는 V5 정리 **전** V4 감사다. 현재 주인공/다음작업/파일수는 작업공간 README의 현행기준을 따른다. 폐기 주인공자료의 링크/비교이미지는 제거했다.\n\n'+s
 write(p,s)
print('Prepared',len(records),'exact-file deletions; approved source SHA',sha(refs/'hero_turnaround_approved.png'))

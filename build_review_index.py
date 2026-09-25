from pathlib import Path
import json
R=Path('source_pack_v4');O=Path('docs/audit_v4')
inventory=json.loads((O/'INVENTORY.json').read_text('utf-8'))
notes={
1:'개별8. 오른쪽 앞사선으로 관찰. 시트 FRONT-LEFT와 대응 불일치. 시각적 수용 유지, 방향 QA 필요.',
2:'개별4. 뒤쪽 몸통과 오른쪽 측면 얼굴. 기존 수리 대상.',
3:'초기 B′ 종합 아트보드. 스타일/구성 참고. 최신 주인공·개별 적보다 우선하지 않음. 게임 캡처가 아님.',
4:'S03 물 설명보드. 물색/경계 방향 참고. 바로 반복 텍스처로 쓸 파일 아님.',
5:'개별1 정면. 승인 외형 참고. 다른 장과 실루엣 높이/아래경계 차이, anchor 등록 필요.',
6:'최신8방향 검수 시트. 개별4/7/8과 픽셀/방향 대응 다름. 개별원본의 정확한 조립 검수표로 교체할 후보.',
7:'S02 길 설명보드. 타일링 예시/소품/제목 포함. 실제 타일 원본과 연속성 검사 필요.',
8:'승인 주인공 콘셉트. 얼굴·복장·검정 신발·보석 참고의 핵심. 다면 설명 이미지로 유지.',
9:'개별5 후면. 꼬리/등 의복 참고. 방향·발/root 등록 필요.',
10:'S01 흙 설명보드. 작은 돌/풀과 타일 예시. 실제 지면 샘플 별도 필요.',
11:'승인 대표4방향. 정면/오른앞/오른측면/뒤. 캐릭터 기준으로 유지. 왼쪽/모션 전체를 보증하지 않음.',
12:'E03 원거리 식물형 적. 흰 배경·실루엣·제목 포함. 역할 참고 유지, 투명원본/공격준비·발사·피격 필요.',
13:'E02 멧돼지형 돌진 적. 방향 참고 유지. 현 런타임 멧돼지와 별도 디자인. 반복 방향/동작 미완료.',
14:'S04 포석 설명보드. 문양/균열/이끼·타일 예시. 실제 반복패턴과 지형투영 필요.',
15:'개별6. 몸 뒤사선/얼굴 왼쪽 측면. 사용자 시각적 수용 유지. 방향각과 얼굴·몸 대응 QA.',
16:'개별3. 오른쪽 측면. 개별7과 방향 역할이 겹침. 원본 유지.',
17:'개별7. 오른쪽 측면으로 관찰. 시트 LEFT와 대응 불일치. 좌우등록/반전정책 검토.',
18:'개별2. 오른쪽 앞사선. 개별8과 방향 역할 중첩. 원본 유지.',
19:'E01 작은 잎옷 동물형 근접 적. 주인공과 귀/꼬리 실루엣 유사성은 실제29px에서 확인 필요. 초기보드의 둥근 적과 다름.',
20:'임시 적16프레임: 딱정벌레8+멧돼지8. 새 G1 적 아님. 방향 정지포즈+카드변형이며 관절 모션 완성 아님.',
21:'임시 돌 수호자8방향. 전후 실루엣 존재. B′ 적 세트의 최종 승인으로 취급하지 않음.',
22:'사실적 초가지붕 쉼터. 재료감은 있으나 클린 B′와 밀도 차이. 옛 공간 참조 의존 때문에 즉시삭제 금지.',
23:'어둡고 세밀한 숲바닥 텍스처. B′ 지면 참고와 대비/질감 차이. 임시 유지.',
24:'세밀한 사암 표식, 녹색 발광 문양. 현재 발견물/환경에 연결. 새 스타일로 후속 정리.',
25:'사실적 정글 파노라마. 먼산·안개. B′ 캐릭터와 다른 렌더 밀도, 전체 장면에서 통일 필요.',
26:'나무/수풀/석문/작은 집4개 atlas. 세밀한 재료감. 나무 반복 실루엣이 실게임에서 두드러짐.',
27:'석판 바닥 텍스처. 현 포석 기반, 임시 유지. 신규 G1 포석보드와 동일파일 아님.',
28:'벽돌 석축 텍스처. 사실적 갈색 재질. 옛 코드/지형 계약 확인 없이 삭제하지 않음.',
29:'얼굴 사원 PNG. 지역 랜드마크는 존재. 정면 카드의 사실적 재료감과 주변 게임 미술의 통일 미완료.',
30:'옛 주인공 직접3연타15 canonical 포즈. 손 metadata 있음. 새 사막여우 모션 아님.',
31:'옛 주인공 대기8+기본시전8. 대기8은 idle_v2로 덮이지만 시전8은 여전히 사용. 통째 삭제 금지.',
32:'옛 주인공 내린손 대기8. 초록귀/짙은옷/노출발 모양은 새승인 외형과 다름. 임시런타임 유지.',
33:'옛 주인공 회수15포즈. combo와 비슷해도 역할/실제바이트 다름. 삭제 금지.',
34:'옛 주인공 달리기 접지16. run_pass와 조합. 동작별 다른 포즈라 중복 아님.',
35:'옛 주인공 달리기 통과16. run_eight와 조합. 연속 재생 품질은 이번에 판정하지 않음.',
36:'옛 주인공 낮은팔 걷기 접지16. walk_pass와 조합, 새 캐릭터용 재제작 필요.',
37:'옛 주인공 걷기 통과16. 4단계보행 계약에 필요. 개별 정지장 비교가 자연스러운 모션 보증은 아님.'}
docs={
'READ_FIRST.txt':'짧은 진입안내로 유지/다른 시작안내와 통합 가능.',
'AGENTS.md':'공통 작업계약 유지. 정본 우선순위/기록위치 최신화.',
'SOURCE_PACK_GUIDE.md':'전체 목차 유지. 감사 발견/실제 파일 역할 반영.',
'NEW_PROJECT_START_PROMPT.md':'과거 실행요청 템플릿. 이번 감사의 명령으로 실행하지 않음. 길이는 인계서와 중복.',
'GAME_PROJECT_SOURCE.md':'현행 결정의 중심. 방향4/7/8 검증·인계재현 누락·팩 시점 차이를 반영할 대상.',
'GAME_MASTER_ROADMAP.md':'P0~P8/M1 정의 유지. 현재 상태 반복을 줄이고 정본으로 연결.',
'STORY_CANON.md':'이야기 확정/미정 유지. D95 사건 구현 이력 분리, S01~S08 누락 참조 보완.',
'NEXT_IMPLEMENTATION_PACKETS.md':'Packet1~3 목적/통과기준 유지. D108 옛 상태 초안을 현행에서 분리.',
'ART_PRODUCTION_CONSTRAINTS.md':'화면크기/방향/anchor/높이 계약 유지. 스타일 미선택·3D비교·구버전표기·청록가림 현행화.',
'START_HERE.md':'짧은 정본포인터. CURRENT_STATE와 의미중복이나 기존경로 호환상 유지 가능.',
'CURRENT_STATE.md':'정본포인터 유지. 상태를 여기에도 다시 쓰라는 다른 지침과 충돌 정리.',
'NEXT_SESSION_HANDOFF.md':'작업절차 유지. PNG4만이 아니라8방향 대응검사 필요.4방향샘플/최종8방향 구분.',
'EXPERIMENT_PLAN.md':'초기실험 대신 정본포인터. 독립 기획문서 역할 없음.',
'DOCUMENTATION_PROTOCOL.md':'누적/정정/사실구분 규칙 유지. GAME_PROJECT_SOURCE가 상태쓰기 대상임을 통일.',
'WORK_LOG.md':'루트는 이관1문단이고 나머지로그2개와 동일. 하위는 D99~D118 실제누적기록. 둘을 혼동하지 않음.',
'DISCUSSION_LOG.md':'현재 이관1문단. 루트 WORK_LOG와 바이트중복. 후속 논의가 포장에서도 보존되게 수정 필요.',
'DECISION_HISTORY.md':'현재 이관1문단. 이야기 S01~S08 결정내용 없음. 결정요약 이관 필요.',
'RENDER_QA.md':'공통 표면/픽셀규칙 유지. 옛 맵/없는검사/과거단계 설명은 별도이력.',
'FONT_DISTRIBUTION.md':'폰트해시/출처/OFL 유지. license_report.gd 설명과 팩 실제파일 불일치.',
'CLEANUP_PLAN.md':'제외이유 기록 유지. 인계서/현재문서상태 설명 최신화.',
'MIGRATION_VERIFICATION.md':'검증범위 고지 유지. 실제 새환경 실행과 Mac 포장 누락 증거 추가 필요.',
'D118_DISK_CLEANUP.md':'PC유지보수 이력. 활성 개발문서에서 보관영역 이동 후보.',
'D107_PERFORMANCE_REVIEW.md':'실제AI 성능검증의 교훈/조건. 과거측정 기록으로 유지.',
'D112_CORE_RESPONSE_REVIEW.md':'현 입력수정과 사람검수 항목. 이번6PASS와 과거GPU성능을 분리.',
'D113_MACOS_BUILD.md':'기존 Mac산출물/실기미검증 기록. 팩만의 빌드재현성은 별도.',
'OFL.txt':'폰트라이선스 원문. 삭제/요약대체하지 않음.',
}
out=['# 파일별 검토 목록','', '기준: 원본 ZIP294파일. 자동생성된 Godot캐시/이번 검사 이미지는 포함 수량에서 제외. 상세 핵심판정은 [전체 보고서](../V4_AUDIT_20260924.md).','', '## 문서30개','', '| 파일 | 역할/판정 |','|---|---|']
manifest=json.loads((R/'PACKAGE_MANIFEST.json').read_text('utf-8'))['files']
for rec in sorted(manifest,key=lambda x:x['path']):
 p=Path(rec['path'])
 if p.suffix not in ['.md','.txt']:continue
 note=docs.get(p.name,'')
 if rec['path']=='docs/design_refs/README.md':note='19원본 역할/순서/수용 상태. 방향 대응 검수와 보드/실사용자산 구분 보강.'
 elif rec['path']=='experiments/terrace/README.md':note='시제품 실행/조작과 과거 버전 혼재. 팩 미포함exe 지시를 소스실행 절차로 보완.'
 elif rec['path']=='experiments/terrace/AGENTS.md':note='추가계약 유지. lab/world 진입설명을 lab/journey와 구분.'
 out.append(f'| [{rec["path"]}](../../source_pack_v4/{rec["path"]}) | {note} |')
out+=['','## 그림37개 — 개별 판정','', '아래 ID는 이 감사의 파일번호다. 개별 PNG1~8의 사용자 순서와 다르므로 설명의 개별번호를 확인한다. 전수 비교시트: [참고1](refs_1.jpg) · [참고2](refs_2.jpg) · [참고3](refs_3.jpg) · [참고4](refs_4.jpg) · [런타임1](runtime_1.jpg) · [런타임2](runtime_2.jpg) · [런타임3](runtime_3.jpg).','', '| ID / 파일 | 규격 | 내용과 처리 |','|---|---|---|']
for x in inventory['images']:
 out.append(f'| {x["id"]:02} [{Path(x["path"]).name}](../../source_pack_v4/{x["path"]}) | {x["size"][0]}×{x["size"][1]} {x["mode"]} | {notes[x["id"]]} |')
out+=['','## 코드·검사·씬·shader 전수 구조','', '아래는 전수 구조/의존 색인이다. 모든함수의 모든분기를 실행했다는 뜻은 아니다. 코드 줄 수/파일 수는 완성률이 아니다. 주요 경로 상세 대조 및 두 검사 재실행은 전체 보고서 참조.','', '| 파일 | 줄 수 | 역할/검토상태 |','|---|---:|---|']
for x in json.loads((O/'CODE_INDEX.json').read_text('utf-8')):
 p=x['file']; note='구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지.'
 if p.startswith('tests/'):note='검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름.'
 if p in ['tests/core_response.gd','tests/journey_flow.gd']:note='이번 실행 PASS. 각각6/28항목. 사람체감/실제전투품질 보증 아님.'
 if p in ['game/path.gdshader','game/water.gdshader','lab/distant_forest.gdshader']:note='전체소스 리터럴 inbound0. 미사용/보관 후보; 이번삭제 없음.'
 if p=='lab/world.tscn':note='제품 기본진입 아님.11검사에서 참조하므로 유지.'
 if p=='game/hero_visual.gd':note='상세 대조.8방향/미러/atlas/foot-root-hand 공통계약. 새디자인원본 미연결.'
 if p=='game/boot.gd':note='상세 대조. 일반실행은lab/journey, --test --qa-script만 별도하네스.'
 if p=='game/combat.gd':note='상세 대조. 회복/탭버퍼/회피취소·3타판정·손효과 연결.'
 if p=='lab/journey.gd':note='상세 대조.3지역24일반+1강적/2발견/왕복/저장/완료. 반복배치·사람시간 미검증.'
 if p=='game/save_store.gd':note='상세 대조.임시쓰기/검사/정상본만backup/rename. 전체손상시나리오 재실행은 아님.'
 out.append(f'| [{p}](../../source_pack_v4/experiments/terrace/{p}) | {x["lines"]} | {note} |')
out+=['','## 나머지 파일군','', '| 파일군 | 확인/처리 |','|---|---|',
'| 자산JSON11 | 전부parse. 주인공8/적2/소품1의atlas region·발/root·일부손좌표. 새8장 등록JSON 아님. 유지 |',
'| PACKAGE_MANIFEST.json | 293파일 크기·해시 일치. 스냅샷 무결성 근거. 게임품질 판정 아님 |',
'| design_refs/ASSET_MANIFEST.json | 19원본 크기·해시·일부승인상태·gallery순서. 의미방향/엔진등록/생성프롬프트는 없음 |',
'| D118_DISK_CLEANUP.json | 과거 PC정리 목록. 참조하는 D118_REMOVED 세부JSON은 팩에 없음. 보관영역 후보 |',
'| UID79/import31 | 경로/식별/리소스변환설정. 중복이미지로 오인해 제거하지 않음 |',
'| project.godot/export_presets.cfg | version0.10,boot→journey,GL Compatibility,1280×800/창1152×720. export template은 외부설치 |',
'| scripts/package_project_source.py | 읽기검토. 루트3로그를 고정D119내용으로 대체,버전고정,누락링크 문구화. 재사용전수정 필요 |',
'| scripts/build_macos.ps1 | 읽기검토. 원본 .tools배치/Windows엔진 경로 필요. 독립경로 인자로 바꿀 후보 |',
'| scripts/package_macos.py | 읽기검토. builds/THIRD_PARTY_LICENSES.txt 누락으로 clean pack 포장불완결 |',
'| TTF2/OFL | Regular/Bold는 별도폰트. 출처/고지보존. 무결성확인, 이번GPU 한글표시 확인 |',
'| docs/.gdignore | 게임프로젝트 내부 docs를 자산import에서 제외. 유지 |','', '## 음향11개','', 'WAV디코드/헤더·길이·참조 확인. 귀로 타격감/반복피로를 평가하지 않았다. 모두22,050Hz·16bit PCM.','', '| 파일 | 초 | 채널 |','|---|---:|---:|']
for x in inventory['audio']:out.append(f'| {Path(x["path"]).name} | {x["seconds"]:.2f} | {x["channels"]} |')
(O/'FILE_REVIEW.md').write_text('\n'.join(out)+'\n','utf-8')
print('Wrote FILE_REVIEW.md',len(out),'lines')

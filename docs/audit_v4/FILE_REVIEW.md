> 역사 기록: 이 문서는 V5 정리 **전** V4 감사다. 현재 주인공/다음작업/파일수는 작업공간 README의 현행기준을 따른다. 폐기 주인공자료의 현행 링크는 제거했다. 디스크삭제는 자동심사 차단으로 미완료다.

# 파일별 검토 목록

기준: 원본 ZIP294파일. 자동생성된 Godot캐시/이번 검사 이미지는 포함 수량에서 제외. 상세 핵심판정은 [전체 보고서](../V4_AUDIT_20260924.md).

## 문서30개

| 파일 | 역할/판정 |
|---|---|
| [AGENTS.md](../../source_pack_v4/AGENTS.md) | 공통 작업계약 유지. 정본 우선순위/기록위치 최신화. |
| READ_FIRST.txt（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 짧은 진입안내로 유지/다른 시작안내와 통합 가능. |
| [docs/ART_PRODUCTION_CONSTRAINTS.md](../../source_pack_v4/docs/ART_PRODUCTION_CONSTRAINTS.md) | 화면크기/방향/anchor/높이 계약 유지. 스타일 미선택·3D비교·구버전표기·청록가림 현행화. |
| docs/CLEANUP_PLAN.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 제외이유 기록 유지. 인계서/현재문서상태 설명 최신화. |
| docs/CURRENT_STATE.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 정본포인터 유지. 상태를 여기에도 다시 쓰라는 다른 지침과 충돌 정리. |
| docs/D118_DISK_CLEANUP.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | PC유지보수 이력. 활성 개발문서에서 보관영역 이동 후보. |
| [docs/DECISION_HISTORY.md](../../source_pack_v4/docs/DECISION_HISTORY.md) | 현재 이관1문단. 이야기 S01~S08 결정내용 없음. 결정요약 이관 필요. |
| [docs/DISCUSSION_LOG.md](../../source_pack_v4/docs/DISCUSSION_LOG.md) | 현재 이관1문단. 루트 WORK_LOG와 바이트중복. 후속 논의가 포장에서도 보존되게 수정 필요. |
| [docs/DOCUMENTATION_PROTOCOL.md](../../source_pack_v4/docs/DOCUMENTATION_PROTOCOL.md) | 누적/정정/사실구분 규칙 유지. GAME_PROJECT_SOURCE가 상태쓰기 대상임을 통일. |
| docs/EXPERIMENT_PLAN.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 초기실험 대신 정본포인터. 독립 기획문서 역할 없음. |
| [docs/FONT_DISTRIBUTION.md](../../source_pack_v4/docs/FONT_DISTRIBUTION.md) | 폰트해시/출처/OFL 유지. license_report.gd 설명과 팩 실제파일 불일치. |
| [docs/GAME_MASTER_ROADMAP.md](../../source_pack_v4/docs/GAME_MASTER_ROADMAP.md) | P0~P8/M1 정의 유지. 현재 상태 반복을 줄이고 정본으로 연결. |
| [docs/GAME_PROJECT_SOURCE.md](../../source_pack_v4/docs/GAME_PROJECT_SOURCE.md) | 현행 결정의 중심. 방향4/7/8 검증·인계재현 누락·팩 시점 차이를 반영할 대상. |
| [docs/MIGRATION_VERIFICATION.md](../../source_pack_v4/docs/MIGRATION_VERIFICATION.md) | 검증범위 고지 유지. 실제 새환경 실행과 Mac 포장 누락 증거 추가 필요. |
| docs/NEW_PROJECT_START_PROMPT.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 과거 실행요청 템플릿. 이번 감사의 명령으로 실행하지 않음. 길이는 인계서와 중복. |
| [docs/NEXT_IMPLEMENTATION_PACKETS.md](../../source_pack_v4/docs/NEXT_IMPLEMENTATION_PACKETS.md) | Packet1~3 목적/통과기준 유지. D108 옛 상태 초안을 현행에서 분리. |
| docs/NEXT_SESSION_HANDOFF.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 작업절차 유지. PNG4만이 아니라8방향 대응검사 필요.4방향샘플/최종8방향 구분. |
| [docs/RENDER_QA.md](../../source_pack_v4/docs/RENDER_QA.md) | 공통 표면/픽셀규칙 유지. 옛 맵/없는검사/과거단계 설명은 별도이력. |
| docs/SOURCE_PACK_GUIDE.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 전체 목차 유지. 감사 발견/실제 파일 역할 반영. |
| docs/START_HERE.md（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 짧은 정본포인터. CURRENT_STATE와 의미중복이나 기존경로 호환상 유지 가능. |
| [docs/STORY_CANON.md](../../source_pack_v4/docs/STORY_CANON.md) | 이야기 확정/미정 유지. D95 사건 구현 이력 분리, S01~S08 누락 참조 보완. |
| [docs/WORK_LOG.md](../../source_pack_v4/docs/WORK_LOG.md) | 루트는 이관1문단이고 나머지로그2개와 동일. 하위는 D99~D118 실제누적기록. 둘을 혼동하지 않음. |
| [docs/design_refs/README.md](../../source_pack_v4/docs/design_refs/README.md) | 19원본 역할/순서/수용 상태. 방향 대응 검수와 보드/실사용자산 구분 보강. |
| [experiments/terrace/AGENTS.md](../../source_pack_v4/experiments/terrace/AGENTS.md) | 추가계약 유지. lab/world 진입설명을 lab/journey와 구분. |
| [experiments/terrace/README.md](../../source_pack_v4/experiments/terrace/README.md) | 시제품 실행/조작과 과거 버전 혼재. 팩 미포함exe 지시를 소스실행 절차로 보완. |
| [experiments/terrace/assets/fonts/OFL.txt](../../source_pack_v4/experiments/terrace/assets/fonts/OFL.txt) | 폰트라이선스 원문. 삭제/요약대체하지 않음. |
| [experiments/terrace/docs/D107_PERFORMANCE_REVIEW.md](../../source_pack_v4/experiments/terrace/docs/D107_PERFORMANCE_REVIEW.md) | 실제AI 성능검증의 교훈/조건. 과거측정 기록으로 유지. |
| [experiments/terrace/docs/D112_CORE_RESPONSE_REVIEW.md](../../source_pack_v4/experiments/terrace/docs/D112_CORE_RESPONSE_REVIEW.md) | 현 입력수정과 사람검수 항목. 이번6PASS와 과거GPU성능을 분리. |
| [experiments/terrace/docs/D113_MACOS_BUILD.md](../../source_pack_v4/experiments/terrace/docs/D113_MACOS_BUILD.md) | 기존 Mac산출물/실기미검증 기록. 팩만의 빌드재현성은 별도. |
| [experiments/terrace/docs/WORK_LOG.md](../../source_pack_v4/experiments/terrace/docs/WORK_LOG.md) | 루트는 이관1문단이고 나머지로그2개와 동일. 하위는 D99~D118 실제누적기록. 둘을 혼동하지 않음. |

## 그림37개 — 개별 판정

아래 ID는 이 감사의 파일번호다. 개별 PNG1~8의 사용자 순서와 다르므로 설명의 개별번호를 확인한다. 전수 비교시트: 참고1（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） · 참고2（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） · 참고3（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） · 참고4（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） · [런타임1](runtime_1.jpg) · [런타임2](runtime_2.jpg) · [런타임3](runtime_3.jpg).

| ID / 파일 | 규격 | 내용과 처리 |
|---|---|---|
| 01 file_0000000007d482119782ee8cb193c0e1.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별8. 오른쪽 앞사선으로 관찰. 시트 FRONT-LEFT와 대응 불일치. 시각적 수용 유지, 방향 QA 필요. |
| 02 file_000000000cf88211bec5b54d1b75e86e.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별4. 뒤쪽 몸통과 오른쪽 측면 얼굴. 기존 수리 대상. |
| 03 file_00000000137c8230b75a674685952857.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1536×1024 RGB | 초기 B′ 종합 아트보드. 스타일/구성 참고. 최신 주인공·개별 적보다 우선하지 않음. 게임 캡처가 아님. |
| 04 file_0000000013c88211a31328d5a01b10ab.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGB | S03 물 설명보드. 물색/경계 방향 참고. 바로 반복 텍스처로 쓸 파일 아님. |
| 05 file_0000000017e881f4af688ffa4f4c9338.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별1 정면. 승인 외형 참고. 다른 장과 실루엣 높이/아래경계 차이, anchor 등록 필요. |
| 06 file_000000004bc882118250962bba6930fe.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1448×1086 RGB | 최신8방향 검수 시트. 개별4/7/8과 픽셀/방향 대응 다름. 개별원본의 정확한 조립 검수표로 교체할 후보. |
| 07 file_000000005264820ea2400c746aa4926b.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGB | S02 길 설명보드. 타일링 예시/소품/제목 포함. 실제 타일 원본과 연속성 검사 필요. |
| 08 file_00000000611c82118fe016615ba370c6.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1536×1024 RGB | 승인 주인공 콘셉트. 얼굴·복장·검정 신발·보석 참고의 핵심. 다면 설명 이미지로 유지. |
| 09 file_00000000620881f78f62d84482cf7590.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별5 후면. 꼬리/등 의복 참고. 방향·발/root 등록 필요. |
| 10 file_000000006a148211864c646c7ca8d1ed.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGB | S01 흙 설명보드. 작은 돌/풀과 타일 예시. 실제 지면 샘플 별도 필요. |
| 11 file_0000000070488211bfaf60d556d10dde.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1448×1086 RGB | 승인 대표4방향. 정면/오른앞/오른측면/뒤. 캐릭터 기준으로 유지. 왼쪽/모션 전체를 보증하지 않음. |
| 12 file_000000008fe88211851f3f98b4bd1c9b.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1122×1402 RGB | E03 원거리 식물형 적. 흰 배경·실루엣·제목 포함. 역할 참고 유지, 투명원본/공격준비·발사·피격 필요. |
| 13 file_00000000b06c81f88e23d05e568e2620.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1122×1402 RGB | E02 멧돼지형 돌진 적. 방향 참고 유지. 현 런타임 멧돼지와 별도 디자인. 반복 방향/동작 미완료. |
| 14 file_00000000c25082119a4456203fc02b29.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGB | S04 포석 설명보드. 문양/균열/이끼·타일 예시. 실제 반복패턴과 지형투영 필요. |
| 15 file_00000000e370821197780fa54d4158b0.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별6. 몸 뒤사선/얼굴 왼쪽 측면. 사용자 시각적 수용 유지. 방향각과 얼굴·몸 대응 QA. |
| 16 file_00000000ea5481f48bdcfdab84f9ba3d.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별3. 오른쪽 측면. 개별7과 방향 역할이 겹침. 원본 유지. |
| 17 file_00000000f530820d99318610d85d83e4.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별7. 오른쪽 측면으로 관찰. 시트 LEFT와 대응 불일치. 좌우등록/반전정책 검토. |
| 18 file_00000000f6c48206a7f5472edbe641e1.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1254×1254 RGBA | 개별2. 오른쪽 앞사선. 개별8과 방향 역할 중첩. 원본 유지. |
| 19 file_00000000fe8482119f76e7ebf30f8900.png（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 1122×1402 RGB | E01 작은 잎옷 동물형 근접 적. 주인공과 귀/꼬리 실루엣 유사성은 실제29px에서 확인 필요. 초기보드의 둥근 적과 다름. |
| 20 [forest_creatures_v1.png](../../source_pack_v4/experiments/terrace/assets/enemies/forest_creatures_v1.png) | 1254×1254 RGBA | 임시 적16프레임: 딱정벌레8+멧돼지8. 새 G1 적 아님. 방향 정지포즈+카드변형이며 관절 모션 완성 아님. |
| 21 [ruin_guardian_v1.png](../../source_pack_v4/experiments/terrace/assets/enemies/ruin_guardian_v1.png) | 1774×887 RGBA | 임시 돌 수호자8방향. 전후 실루엣 존재. B′ 적 세트의 최종 승인으로 취급하지 않음. |
| 22 [canal_shelter_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/canal_shelter_v1.png) | 1536×1024 RGBA | 사실적 초가지붕 쉼터. 재료감은 있으나 클린 B′와 밀도 차이. 옛 공간 참조 의존 때문에 즉시삭제 금지. |
| 23 [forest_floor_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/forest_floor_v1.png) | 1254×1254 RGB | 어둡고 세밀한 숲바닥 텍스처. B′ 지면 참고와 대비/질감 차이. 임시 유지. |
| 24 [garden_waystone_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/garden_waystone_v1.png) | 1024×1536 RGBA | 세밀한 사암 표식, 녹색 발광 문양. 현재 발견물/환경에 연결. 새 스타일로 후속 정리. |
| 25 [jungle_distance_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/jungle_distance_v1.png) | 2172×724 RGB | 사실적 정글 파노라마. 먼산·안개. B′ 캐릭터와 다른 렌더 밀도, 전체 장면에서 통일 필요. |
| 26 [monsoon_props_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/monsoon_props_v1.png) | 1254×1254 RGBA | 나무/수풀/석문/작은 집4개 atlas. 세밀한 재료감. 나무 반복 실루엣이 실게임에서 두드러짐. |
| 27 [reservoir_floor_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/reservoir_floor_v1.png) | 1254×1254 RGB | 석판 바닥 텍스처. 현 포석 기반, 임시 유지. 신규 G1 포석보드와 동일파일 아님. |
| 28 [reservoir_masonry_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/reservoir_masonry_v1.png) | 1254×1254 RGB | 벽돌 석축 텍스처. 사실적 갈색 재질. 옛 코드/지형 계약 확인 없이 삭제하지 않음. |
| 29 [temple_face_v1.png](../../source_pack_v4/experiments/terrace/assets/environment/temple_face_v1.png) | 1122×1402 RGBA | 얼굴 사원 PNG. 지역 랜드마크는 존재. 정면 카드의 사실적 재료감과 주변 게임 미술의 통일 미완료. |
| 30 [grove_scholar_combo_v1.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_combo_v1.png) | 1619×971 RGBA | 옛 주인공 직접3연타15 canonical 포즈. 손 metadata 있음. 새 사막여우 모션 아님. |
| 31 [grove_scholar_eight_v1.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_eight_v1.png) | 1254×1254 RGBA | 옛 주인공 대기8+기본시전8. 대기8은 idle_v2로 덮이지만 시전8은 여전히 사용. 통째 삭제 금지. |
| 32 [grove_scholar_idle_v2.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_idle_v2.png) | 1536×1024 RGBA | 옛 주인공 내린손 대기8. 초록귀/짙은옷/노출발 모양은 새승인 외형과 다름. 임시런타임 유지. |
| 33 [grove_scholar_recovery_v1.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_recovery_v1.png) | 1619×971 RGBA | 옛 주인공 회수15포즈. combo와 비슷해도 역할/실제바이트 다름. 삭제 금지. |
| 34 [grove_scholar_run_eight_v1.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_run_eight_v1.png) | 1254×1254 RGBA | 옛 주인공 달리기 접지16. run_pass와 조합. 동작별 다른 포즈라 중복 아님. |
| 35 [grove_scholar_run_pass_v1.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_run_pass_v1.png) | 1254×1254 RGBA | 옛 주인공 달리기 통과16. run_eight와 조합. 연속 재생 품질은 이번에 판정하지 않음. |
| 36 [grove_scholar_walk_eight_v2.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_walk_eight_v2.png) | 1254×1254 RGBA | 옛 주인공 낮은팔 걷기 접지16. walk_pass와 조합, 새 캐릭터용 재제작 필요. |
| 37 [grove_scholar_walk_pass_v2.png](../../source_pack_v4/experiments/terrace/assets/hero/grove_scholar_walk_pass_v2.png) | 1254×1254 RGBA | 옛 주인공 걷기 통과16. 4단계보행 계약에 필요. 개별 정지장 비교가 자연스러운 모션 보증은 아님. |

## 코드·검사·씬·shader 전수 구조

아래는 전수 구조/의존 색인이다. 모든함수의 모든분기를 실행했다는 뜻은 아니다. 코드 줄 수/파일 수는 완성률이 아니다. 주요 경로 상세 대조 및 두 검사 재실행은 전체 보고서 참조.

| 파일 | 줄 수 | 역할/검토상태 |
|---|---:|---|
| [game/ambience.gd](../../source_pack_v4/experiments/terrace/game/ambience.gd) | 41 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/astral_energy.gdshader](../../source_pack_v4/experiments/terrace/game/astral_energy.gdshader) | 43 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/boot.gd](../../source_pack_v4/experiments/terrace/game/boot.gd) | 15 | 상세 대조. 일반실행은lab/journey, --test --qa-script만 별도하네스. |
| [game/boot.tscn](../../source_pack_v4/experiments/terrace/game/boot.tscn) | 4 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/combat.gd](../../source_pack_v4/experiments/terrace/game/combat.gd) | 101 | 상세 대조. 회복/탭버퍼/회피취소·3타판정·손효과 연결. |
| [game/combat_effect.gd](../../source_pack_v4/experiments/terrace/game/combat_effect.gd) | 260 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/contact.gdshader](../../source_pack_v4/experiments/terrace/game/contact.gdshader) | 8 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/demo_menu.gd](../../source_pack_v4/experiments/terrace/game/demo_menu.gd) | 180 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/demo_menu.tscn](../../source_pack_v4/experiments/terrace/game/demo_menu.tscn) | 4 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/effect_surface.gd](../../source_pack_v4/experiments/terrace/game/effect_surface.gd) | 19 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/enemy.gd](../../source_pack_v4/experiments/terrace/game/enemy.gd) | 239 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/enemy_visual.gd](../../source_pack_v4/experiments/terrace/game/enemy_visual.gd) | 55 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/exploration.gd](../../source_pack_v4/experiments/terrace/game/exploration.gd) | 190 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/facility.gd](../../source_pack_v4/experiments/terrace/game/facility.gd) | 172 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/facility_stone.gdshader](../../source_pack_v4/experiments/terrace/game/facility_stone.gdshader) | 22 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/ground.gdshader](../../source_pack_v4/experiments/terrace/game/ground.gdshader) | 96 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/ground_warning.gd](../../source_pack_v4/experiments/terrace/game/ground_warning.gd) | 87 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/grove_gate.gd](../../source_pack_v4/experiments/terrace/game/grove_gate.gd) | 41 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/grove_masonry.gd](../../source_pack_v4/experiments/terrace/game/grove_masonry.gd) | 39 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/hero_visual.gd](../../source_pack_v4/experiments/terrace/game/hero_visual.gd) | 110 | 상세 대조.8방향/미러/atlas/foot-root-hand 공통계약. 새디자인원본 미연결. |
| [game/hud.gd](../../source_pack_v4/experiments/terrace/game/hud.gd) | 440 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/journey.gd](../../source_pack_v4/experiments/terrace/game/journey.gd) | 54 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/landscape.gd](../../source_pack_v4/experiments/terrace/game/landscape.gd) | 248 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| game/path.gdshader（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 12 | 전체소스 리터럴 inbound0. 미사용/보관 후보; 이번삭제 없음. |
| [game/player.gd](../../source_pack_v4/experiments/terrace/game/player.gd) | 270 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/reservoir_keeper.gd](../../source_pack_v4/experiments/terrace/game/reservoir_keeper.gd) | 104 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/ridge_caster.gd](../../source_pack_v4/experiments/terrace/game/ridge_caster.gd) | 56 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/save_queue.gd](../../source_pack_v4/experiments/terrace/game/save_queue.gd) | 40 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/save_store.gd](../../source_pack_v4/experiments/terrace/game/save_store.gd) | 51 | 상세 대조.임시쓰기/검사/정상본만backup/rename. 전체손상시나리오 재실행은 아님. |
| [game/sluice_hoist.gd](../../source_pack_v4/experiments/terrace/game/sluice_hoist.gd) | 61 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/sluice_masonry.gd](../../source_pack_v4/experiments/terrace/game/sluice_masonry.gd) | 24 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/sound_bank.gd](../../source_pack_v4/experiments/terrace/game/sound_bank.gd) | 46 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/story.gd](../../source_pack_v4/experiments/terrace/game/story.gd) | 116 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/visuals.gd](../../source_pack_v4/experiments/terrace/game/visuals.gd) | 113 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| game/water.gdshader（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 12 | 전체소스 리터럴 inbound0. 미사용/보관 후보; 이번삭제 없음. |
| [game/waterworks.gd](../../source_pack_v4/experiments/terrace/game/waterworks.gd) | 305 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/world.gd](../../source_pack_v4/experiments/terrace/game/world.gd) | 514 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [game/world.tscn](../../source_pack_v4/experiments/terrace/game/world.tscn) | 6 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/compact_hud.gd](../../source_pack_v4/experiments/terrace/lab/compact_hud.gd) | 60 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| lab/distant_forest.gdshader（2026-09-24 사용자 요청으로 현행에서 삭제; 당시 기록） | 9 | 전체소스 리터럴 inbound0. 미사용/보관 후보; 이번삭제 없음. |
| [lab/exploration.gd](../../source_pack_v4/experiments/terrace/lab/exploration.gd) | 7 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/ground.gdshader](../../source_pack_v4/experiments/terrace/lab/ground.gdshader) | 39 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/hud.gd](../../source_pack_v4/experiments/terrace/lab/hud.gd) | 5 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/journey.gd](../../source_pack_v4/experiments/terrace/lab/journey.gd) | 276 | 상세 대조.3지역24일반+1강적/2발견/왕복/저장/완료. 반복배치·사람시간 미검증. |
| [lab/journey.tscn](../../source_pack_v4/experiments/terrace/lab/journey.tscn) | 4 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/jungle_shelves.gd](../../source_pack_v4/experiments/terrace/lab/jungle_shelves.gd) | 41 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/routes.gd](../../source_pack_v4/experiments/terrace/lab/routes.gd) | 22 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/spell_growth.gd](../../source_pack_v4/experiments/terrace/lab/spell_growth.gd) | 11 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/surroundings.gd](../../source_pack_v4/experiments/terrace/lab/surroundings.gd) | 25 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/thresholds.gd](../../source_pack_v4/experiments/terrace/lab/thresholds.gd) | 72 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/world.gd](../../source_pack_v4/experiments/terrace/lab/world.gd) | 344 | 구조·리터럴 의존 대조. 기존 공통 기능/회귀가 연결되어 임의삭제 금지. |
| [lab/world.tscn](../../source_pack_v4/experiments/terrace/lab/world.tscn) | 4 | 제품 기본진입 아님.11검사에서 참조하므로 유지. |
| [tests/combat_performance.gd](../../source_pack_v4/experiments/terrace/tests/combat_performance.gd) | 71 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/core_response.gd](../../source_pack_v4/experiments/terrace/tests/core_response.gd) | 88 | 이번 실행 PASS. 각각6/28항목. 사람체감/실제전투품질 보증 아님. |
| [tests/diagonal_strike.gd](../../source_pack_v4/experiments/terrace/tests/diagonal_strike.gd) | 46 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/exploration.gd](../../source_pack_v4/experiments/terrace/tests/exploration.gd) | 82 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/gait_cycle.gd](../../source_pack_v4/experiments/terrace/tests/gait_cycle.gd) | 62 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/ground_surfaces.gd](../../source_pack_v4/experiments/terrace/tests/ground_surfaces.gd) | 59 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/grounded_run.gd](../../source_pack_v4/experiments/terrace/tests/grounded_run.gd) | 56 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/hand_origin.gd](../../source_pack_v4/experiments/terrace/tests/hand_origin.gd) | 37 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/hud_concepts.gd](../../source_pack_v4/experiments/terrace/tests/hud_concepts.gd) | 69 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/journey_flow.gd](../../source_pack_v4/experiments/terrace/tests/journey_flow.gd) | 81 | 이번 실행 PASS. 각각6/28항목. 사람체감/실제전투품질 보증 아님. |
| [tests/journey_playthrough.gd](../../source_pack_v4/experiments/terrace/tests/journey_playthrough.gd) | 67 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/journey_routes.gd](../../source_pack_v4/experiments/terrace/tests/journey_routes.gd) | 82 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/keyboard_choices.gd](../../source_pack_v4/experiments/terrace/tests/keyboard_choices.gd) | 62 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/lab_combat.gd](../../source_pack_v4/experiments/terrace/tests/lab_combat.gd) | 27 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/lab_contract.gd](../../source_pack_v4/experiments/terrace/tests/lab_contract.gd) | 45 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/lab_flow.gd](../../source_pack_v4/experiments/terrace/tests/lab_flow.gd) | 130 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/lab_footing.gd](../../source_pack_v4/experiments/terrace/tests/lab_footing.gd) | 45 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/lab_growth.gd](../../source_pack_v4/experiments/terrace/tests/lab_growth.gd) | 100 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/lab_render.gd](../../source_pack_v4/experiments/terrace/tests/lab_render.gd) | 29 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/live_combat_performance.gd](../../source_pack_v4/experiments/terrace/tests/live_combat_performance.gd) | 98 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/lookout_contract.gd](../../source_pack_v4/experiments/terrace/tests/lookout_contract.gd) | 41 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/moving_strike.gd](../../source_pack_v4/experiments/terrace/tests/moving_strike.gd) | 72 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/presentation_review.gd](../../source_pack_v4/experiments/terrace/tests/presentation_review.gd) | 28 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/render_surface_motion.gd](../../source_pack_v4/experiments/terrace/tests/render_surface_motion.gd) | 69 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/save_queue_contract.gd](../../source_pack_v4/experiments/terrace/tests/save_queue_contract.gd) | 37 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/slope_cues.gd](../../source_pack_v4/experiments/terrace/tests/slope_cues.gd) | 58 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/strike_range.gd](../../source_pack_v4/experiments/terrace/tests/strike_range.gd) | 35 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/terrace_review.gd](../../source_pack_v4/experiments/terrace/tests/terrace_review.gd) | 63 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/terrain_probe.gd](../../source_pack_v4/experiments/terrace/tests/terrain_probe.gd) | 23 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/threshold_contract.gd](../../source_pack_v4/experiments/terrace/tests/threshold_contract.gd) | 37 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/warning_cache_contract.gd](../../source_pack_v4/experiments/terrace/tests/warning_cache_contract.gd) | 98 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |
| [tests/warning_damage.gd](../../source_pack_v4/experiments/terrace/tests/warning_damage.gd) | 40 | 검사하네스. 전수실행 아님; GPU/AI/입력/저장 여부에 따라 증거범위 다름. |

## 나머지 파일군

| 파일군 | 확인/처리 |
|---|---|
| 자산JSON11 | 전부parse. 주인공8/적2/소품1의atlas region·발/root·일부손좌표. 새8장 등록JSON 아님. 유지 |
| PACKAGE_MANIFEST.json | 293파일 크기·해시 일치. 스냅샷 무결성 근거. 게임품질 판정 아님 |
| design_refs/ASSET_MANIFEST.json | 19원본 크기·해시·일부승인상태·gallery순서. 의미방향/엔진등록/생성프롬프트는 없음 |
| D118_DISK_CLEANUP.json | 과거 PC정리 목록. 참조하는 D118_REMOVED 세부JSON은 팩에 없음. 보관영역 후보 |
| UID79/import31 | 경로/식별/리소스변환설정. 중복이미지로 오인해 제거하지 않음 |
| project.godot/export_presets.cfg | version0.10,boot→journey,GL Compatibility,1280×800/창1152×720. export template은 외부설치 |
| scripts/package_project_source.py | 읽기검토. 루트3로그를 고정D119내용으로 대체,버전고정,누락링크 문구화. 재사용전수정 필요 |
| scripts/build_macos.ps1 | 읽기검토. 원본 .tools배치/Windows엔진 경로 필요. 독립경로 인자로 바꿀 후보 |
| scripts/package_macos.py | 읽기검토. builds/THIRD_PARTY_LICENSES.txt 누락으로 clean pack 포장불완결 |
| TTF2/OFL | Regular/Bold는 별도폰트. 출처/고지보존. 무결성확인, 이번GPU 한글표시 확인 |
| docs/.gdignore | 게임프로젝트 내부 docs를 자산import에서 제외. 유지 |

## 음향11개

WAV디코드/헤더·길이·참조 확인. 귀로 타격감/반복피로를 평가하지 않았다. 모두22,050Hz·16bit PCM.

| 파일 | 초 | 채널 |
|---|---:|---:|
| ambience_forest.wav | 20.00 | 2 |
| ambience_reservoir.wav | 20.00 | 2 |
| ambience_water.wav | 20.00 | 2 |
| auto.wav | 0.22 | 1 |
| cast.wav | 0.20 | 1 |
| dash.wav | 0.20 | 1 |
| heavy.wav | 0.28 | 1 |
| hit.wav | 0.16 | 1 |
| hurt.wav | 0.32 | 1 |
| reward.wav | 0.65 | 1 |
| warning.wav | 0.45 | 1 |

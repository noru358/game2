# 소스팩 문서 안내 — D119 / V4

이 파일은 목차다. 게임의 현행 결정은 [GAME_PROJECT_SOURCE.md](GAME_PROJECT_SOURCE.md)에서만 갱신한다. 모든 문서를 처음부터 읽을 필요는 없다.

## 먼저 읽는 순서

1. [GAME_PROJECT_SOURCE.md](GAME_PROJECT_SOURCE.md)의 CURRENT/NEXT: 목표·현재 위치·확정 사항·다음 작업.
2. [NEXT_SESSION_HANDOFF.md](NEXT_SESSION_HANDOFF.md): 새 환경에서의 확인 절차와 첫 작업 범위.
3. 작업축에 따라 디자인 원본 목록 또는 게임성 묶음/검수 기록.

## 포함 문서 전체

경로의 `docs/`는 팩 루트 기준이다. 아래 표의 파일은 V4에 실제 포함한다.

| 경로 | 역할 / 읽는 때 |
|---|---|
| READ_FIRST.txt | 압축을 처음 열었을 때 읽는 짧은 안내 |
| AGENTS.md | 전체 작업·검수·저장·임시파일 정리 규칙. 팩에는 다른 기기용 메모리 경로 예외가 명시됨 |
| docs/SOURCE_PACK_GUIDE.md | 지금 읽는 문서별 역할과 읽는 순서 |
| docs/NEW_PROJECT_START_PROMPT.md | 새 프로젝트의 첫 메시지에 붙여 넣는 인계 요청 |
| docs/GAME_PROJECT_SOURCE.md | **유일한 통합 정본**. 디자인·게임성·이야기·큰 단계·현재/다음/미정 |
| docs/GAME_MASTER_ROADMAP.md | P0~P8 전체 단계와 각 단계의 통과 조건, M1-A~D |
| docs/STORY_CANON.md | 채택된 이야기와 아직 미정인 설정. 과거 사건 구현은 시제품 이력으로 구분 |
| docs/NEXT_IMPLEMENTATION_PACKETS.md | Packet1~3의 목적·후보 파일·자동 검사·사람 검수. Packet1은 일부 구현,2는 대기 |
| docs/ART_PRODUCTION_CONSTRAINTS.md | 기존 엔진의 화면 크기·방향·기준점 등 기술 제약. 기존 미술의 승인 문서가 아님 |
| docs/design_refs/README.md | 19개 이미지의 용도, 최신8개 순서,4번 수정 대기 표시 |
| docs/START_HERE.md | 기존 진입 경로를 유지하는 정본 안내 |
| docs/CURRENT_STATE.md | 별도 정본을 만들지 않고 통합 정본으로 연결 |
| docs/NEXT_SESSION_HANDOFF.md | **실행용 인계서**. 시작 확인, 디자인/게임성 첫 작업, 종료 기록 |
| docs/EXPERIMENT_PLAN.md | 팩 안에서는 현행 정본으로 연결하는 안내. 초기 D99 계획 원문은 제외 |
| docs/DOCUMENTATION_PROTOCOL.md | 논의·작업·결정 기록을 언제 어떻게 갱신할지 |
| docs/WORK_LOG.md | 팩에서 시작하는 새 작업 기록. 원본 작업공간의 전체 이력 사본은 아님 |
| docs/DISCUSSION_LOG.md | 새 프로젝트의 논의·대안·결정 이유 누적용 |
| docs/DECISION_HISTORY.md | 새 프로젝트의 결정/변경 이유 누적용 |
| docs/RENDER_QA.md | 지형 겹침·이동·카메라·모션 관련 검사 계약과 이전 검사 이력 |
| docs/FONT_DISTRIBUTION.md | 폰트 배포/라이선스 설명 |
| docs/CLEANUP_PLAN.md | 무엇을 남기고 제외했는지와 그 이유 |
| docs/MIGRATION_VERIFICATION.md | 팩 구성·검증 범위·설치 의존성·이관 한계 |
| docs/D118_DISK_CLEANUP.md | 용량 정리와 원본 보존 검증. 개발할 때 매번 읽을 필요 없음 |
| experiments/terrace/README.md | 현행 Godot 프로젝트 안내와 과거 빌드 이력 |
| experiments/terrace/AGENTS.md | 이 독립 프로젝트에 적용되는 추가 규칙 |
| experiments/terrace/docs/WORK_LOG.md | 현행 게임의 실제 누적 구현/검증 기록. **날짜별 이력이며 과거 상태가 최신 결정을 덮지 않음** |
| experiments/terrace/docs/D107_PERFORMANCE_REVIEW.md | 실제 적 AI를 켠 전투 성능 병목과 수정 검증 |
| experiments/terrace/docs/D112_CORE_RESPONSE_REVIEW.md | 현재0.10의 이동/직접공격 반응성 변경·검사·사람 검수 미완료 범위 |
| experiments/terrace/docs/D113_MACOS_BUILD.md | Mac 패키징 검사와 Mac 실기 미검증 범위 |
| experiments/terrace/assets/fonts/OFL.txt | 실제 포함 폰트의 라이선스 원문 |

## 문서가 아닌 중요한 파일

- `PACKAGE_MANIFEST.json`: ZIP 항목별 크기/SHA256, 제외 목록. ZIP 옆 `.verification.json`은 압축 전체 해시와 검사 결과이며 압축 외부의 확인서다.
- `docs/design_refs/ASSET_MANIFEST.json`:19원본의 해시/규격/용도/개별 순서. PNG4는 수정 대기.
- `experiments/terrace/project.godot`, `game/`, `lab/`: 실제 현행 코드/씬. game+lab GD39개.
- `experiments/terrace/tests/`: 테스트 GD32개. 숫자는 완성률이 아니다.
- `experiments/terrace/assets/`: 현재 실행에 쓰이는 자산. 상당수는 교체 예정 임시 미술이다.
- `scripts/package_project_source.py`: 현행 소스팩 재생성 도구.

## 없는 것 / 오해하지 않을 것

이전 D95의 루트 게임, 과거 방향 원문 전체, 이전 대화 원문 전체, 실행본, Godot 설치 도구, 대량 검수 캡처, 실제 사용자 저장은 제외했다. 원본 작업공간에는 보존되어 있지만 새 환경에서 자동 접근되는 것은 아니다. 원본 없는 과거 검증은 **기록 인용**이라고 말한다.

팩에는 실제 소스가 있지만 소스 존재와 해당 환경에서 실행 성공은 다르다. 디자인 PNG도 게임에 통합되어 있지 않다. 새 프로젝트가 이 ZIP을 열고 파일을 확인할 수 있는지 먼저 확인하고, 확인하지 못한 파일을 읽었다고 말하지 않는다.

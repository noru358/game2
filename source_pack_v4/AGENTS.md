# 게임 v2 작업 규칙

- 이폴더 README → docs/GAME_PROJECT_SOURCE → 관련 WORK_LOG를 읽는다. 환경의 WORK_MEMORY가있으면먼저읽는다.
- 주인공은 docs/design_refs/hero_turnaround_approved.png 하나가시각기준이다. 옛개별8장/4번수리프롬프트/과거보드를복원하지않는다. 그림준비와엔진통합/모션/사람수용을구분한다.
- 현재상태는 GAME_PROJECT_SOURCE 한곳,이야기는STORY_CANON,과거구현은날짜붙은기록으로구분한다. 종료기록은DOCUMENTATION_PROTOCOL을따른다.
- 사용자게임과실제저장을시험에쓰지않는다. 독립 --test/PID저장을사용한다.
- 지형/이동/충돌/카메라/저장/리스폰/경고는공유높이계약. 불투명단일지형과Landscape.paving을유지한다. 관련수정은headless회귀+GPU실제픽셀을함께검수한다.
- 키보드메뉴는진입/선택/닫기/복귀까지검사. 모션은방향프레임수보다연속재생/접지/손-VFX가중요하다.
- 전투성능수정은실제AI/물리/경고/공격/저장을켠live_combat_performance와warning_cache_contract를쓴다. physics를끈combat_performance는부분측정이다.
- 임시검수경로/프로세스를기록하고작업종료시생성물만정리한다. docs/.gdignore를유지한다. 삭제실패시사실을기록한다.
- 패키저는누적로그를그대로읽고포장해야한다. 기록을고정문구로초기화하지않는다.

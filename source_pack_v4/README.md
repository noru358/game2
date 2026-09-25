# 게임 v2

**2026-09-25 중단 시점 인계: [HANDOFF_START_HERE.md](HANDOFF_START_HERE.md). 좌상·우상 다리와 복장 검수 불합격이며, 최신 소스도 완성본이 아니다.**

**[현재 상태·다음 작업](docs/GAME_PROJECT_SOURCE.md)**부터 읽는다.

V6 종합본의 ChatGPT/Work 병행 작업: **[시작 안내와 복사용 지시문](START_PARALLEL_WORK.md)**.

- [유일한 주인공 기준과 적·지면 참고](docs/design_refs/README.md)
- 게임 실행: Godot4.7.2에서 `experiments/terrace/project.godot` 열기.
- 기본 게임은0.10 시제품이다. 새 주인공은 PLAY_HERO_PREVIEW의 실제 전투 검수 장면에 통합했으며, 기본 진입점 전환과 최종 모션 품질 검수는 진행 중이다.
- 코드/임시자산은 `experiments/terrace`, 작업기록은 `docs/WORK_LOG.md`.
- 재포장: `python scripts/package_project_source.py --out <출력폴더> --version V6 --date 20260924`. 이미 같은 버전 ZIP이 있으면 새 버전을 사용한다.

이 폴더의 현재자료만 기준으로 작업한다. 현행에서 제외된 옛개별PNG나 과거인계프롬프트를 원본ZIP에서 되살리지 않는다. 기존V4 ZIP은 과거복구용이며 현행미술기준이 아니다.


물리 삭제 상태: 자동 승인 검토가 지정42파일 삭제를 차단하여 디스크에는 남아 있다. `PACKAGE_EXCLUSIONS.json`의 파일은 현행기준/새V5팩에서 제외한다. 새로운 삭제방식으로 우회하지 않았다.

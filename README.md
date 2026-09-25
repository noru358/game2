# 게임 v2

**다음 세션은 [인계 문서](source_pack_v4/HANDOFF_START_HERE.md)의 최상단 최신 정정부터 읽는다. 캐릭터 미술은 아직 사용자 최종 승인 전이며 완성본이 아니다.**

**[현재 상태와 다음 작업](source_pack_v4/docs/GAME_PROJECT_SOURCE.md)**

**[확정 주인공 그림](source_pack_v4/docs/design_refs/hero_turnaround_approved.png)** · [적·지면 참고](source_pack_v4/docs/design_refs/README.md)

개발 위치는 `source_pack_v4/experiments/terrace/project.godot`이다. 기존 폴더명만 유지하며 내용은 V7 이후 로컬 후속작업을 포함한다. 기본 게임은0.10 시제품이고, 맵·캐릭터 검토 장면은 별도다.

[최신 작업기록](source_pack_v4/docs/WORK_LOG.md) · [초기 외부 작업기록](docs/WORK_LOG.md) · [삭제 내역](docs/CLEANUP_DELETIONS.json)

`docs/audit_v4`와 V4_AUDIT는 **정리 전 감사증거**이며 현재자료목록/주인공기준이 아니다.


물리 삭제 상태: 자동 승인 검토가 지정42파일 삭제를 차단하여 디스크에는 남아 있다. `PACKAGE_EXCLUSIONS.json`의 파일은 현행기준/새V5팩에서 제외한다. 새로운 삭제방식으로 우회하지 않았다.


## 맵 제작본
[맵 미리보기 실행](PLAY_MAP_PREVIEW.cmd) · [실행/검증/한계](source_pack_v4/experiments/terrace/maps/README.md) · [맵 제작 기준](source_pack_v4/docs/MAP_DESIGN_AND_PRODUCTION.md)

이전 PLAY_ROOTS_BLOCKOUT.cmd는 과거 Downloads 단일장면 확인용이며 현행 맵 제작본에서 제외한다.

## 다른 기기에서 이어가기

```powershell
git clone https://github.com/noru358/game2.git
cd game2
```

1. Godot 4.7.2를 설치한다. 엔진 실행 파일은 저장소에 포함하지 않는다.
2. `source_pack_v4/experiments/terrace/project.godot`을 Godot에서 연다.
3. 현재 상태는 `source_pack_v4/docs/GAME_PROJECT_SOURCE.md`, 누적 변경은 `source_pack_v4/docs/WORK_LOG.md`를 먼저 읽는다.
4. Windows 검수 런처는 Godot 실행 파일을 `.cmd` 위로 드래그해 실행할 수 있다. 이 PC와 같은 형제 폴더 구조에 엔진이 있으면 기본 경로도 동작한다.

### macOS 검수 장면 실행

Godot 4.7.2 앱을 `/Applications`, `~/Applications`, `~/Downloads` 중 한 곳에 두거나 `godot`/`godot4`를 PATH에 추가한다. 저장소 루트의 `PLAY_HERO_DIRECTIONS.command`, `PLAY_HERO_PREVIEW.command`, `PLAY_FOREST_PILGRIMAGE_ART_SLICE.command`, `PLAY_FOREST_PILGRIMAGE_GRAYBOX.command`, `PLAY_WATER_ENTRY_DIRECTION.command`를 Finder에서 더블클릭하면 해당 검수 장면이 열린다. 처음 실행 시 macOS가 확인을 요구하면 파일을 오른쪽 클릭해 **열기**를 선택한다.

터미널에서도 실행할 수 있다. 자동 탐지되지 않으면 첫 인자로 Godot 실행 파일이나 `.app` 경로를 준다.

```sh
./PLAY_HERO_DIRECTIONS.command
./PLAY_HERO_DIRECTIONS.command "/Applications/Godot.app"
```

`deliveries/*.zip`은 추적된 소스의 중복 스냅샷이고 GitHub 단일 파일 제한을 넘을 수 있어 Git에서는 제외한다. 각 ZIP의 검증 JSON은 기록으로 남긴다. Godot의 `.godot/` 폴더와 Python 캐시는 다른 기기에서 자동 재생성된다.

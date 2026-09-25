# 현재 자료 정리 결과 — D118

기준은 [통합 정본](GAME_PROJECT_SOURCE.md) 하나다. 현재 코드는 terrace0.10이며 이전 D95는 원래 작업공간에 보존한다.

| 자료 | 처리/이유 |
|---|---|
| START_HERE / CURRENT_STATE / NEXT_SESSION_HANDOFF | 정본을 가리키는 짧은 진입점으로 정리; 누적된 이전 내용은 archive 보존 |
| 현재 게임이 쓰는 옛 미술 | 임시 런타임 자산으로 유지; 승인된 새 미술과 구분 |
| 미사용 옛 시안/모션8파일 | 새 팩 제외; 원본은 보존. 코드의 리터럴 참조 누락 없음 확인 |
| D95와 동일한45자산 | 독립 프로젝트 유지에 필요하므로 원본 두 프로젝트는 보존; 현행팩에는 terrace만 포함 |
| 과거 방향/초기 로드맵/검토 시안 문서 | 현행팩 제외, 원본 이력 유지. 확정 설정으로 되살리지 않음 |
| 현행 정본/이야기/총괄 로드맵/Packet/기술 검수 계약 | 현행팩 포함. 증거/과거 산출물 중 제외된 링크는 별도 보관이라고 표시 |
| 디자인 이미지19개 | 원본/해시/용도 보존. 최신 개별4번째만 수정 대기, 최신 시트는 검수용 |
| 빌드/대량 QA 캡처/엔진/캐시/실제 저장 | 현행 소스팩 제외. 검수 이미지 원본과 보관 배포본은 로컬 유지 |
| 종료된 QA 임시 복사본/문서 변환 캐시/설치 압축 | D118 C: 정리에서 실제 삭제. [내역](D118_DISK_CLEANUP.md) |

미사용8파일: tropical_props_v1.png, grove_scholar_atlas.png, grove_scholar_motion_v1/v2.png, grove_scholar_walk_eight_v1.png/.json, grove_scholar_walk_pass_v1.png/.json. 정확한 경로/포함 목록은 패키저와 ZIP 내부 PACKAGE_MANIFEST.json에 있다.

[이관 검수](MIGRATION_VERIFICATION.md)와 생성된 ZIP 옆 verification.json으로 최종 결과를 확인한다. 게임 기능/이야기/승인 상태를 바꾼 정리가 아니다.

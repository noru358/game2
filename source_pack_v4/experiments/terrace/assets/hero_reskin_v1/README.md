# 현재 주인공 디자인 × grove_scholar 이동 리스킨

사용자 지시로 기존 `hero_pose_v2` 걷기·달리기 그림은 전부 폐기 대상으로 배제했다. 이 폴더의 네 시트는 새 자세를 생성한 것이 아니라, 기존 `assets/hero/grove_scholar_*`의 검증된 8방향 걷기·달리기 포즈와 16슬롯 배열을 편집 대상으로 고정하고 `docs/design_refs/hero_turnaround_approved.png`의 외형만 입힌 리스킨 후보다.

- `walk_contact.png`: `grove_scholar_walk_eight_v2.png` 리스킨.
- `walk_pass.png`: `grove_scholar_walk_pass_v2.png` 리스킨.
- `run_contact.png`: `grove_scholar_run_eight_v1.png` 리스킨.
- `run_pass.png`: `grove_scholar_run_pass_v1.png` 리스킨.
- JSON 네 개: 원본 1254×1254 시트의 16슬롯 순서와 절대 발/root 기준점을 유지한다. 실제 클린업된 실루엣 경계+2px로 region을 조여 셀 경계 샘플링·파편을 막았다.

`raw_generated/`는 ImageGen 직출력 보관본이다. 현행 PNG는 그 RGB 원화를 다시 그리지 않고, 투명 배경에 붙은 저알파 잔여·적/황색 키 테두리·셀 밖 분리 파편만 `scripts/clean_hero_reskin_alpha.py`로 제거한 본이다. `alpha_cleanup_report.json`에 원본/결과 해시와 셀별 제거량이 있다.

외형 입력은 승인 원화 한 장뿐이다. 중단된 `hero_locomotion_rebuild_v1`, `hero_pose_v2` 이동 프레임, `hero_repair_v3`, 과거 보행 참고 이미지는 리스킨 입력으로 사용하지 않았다. 현재 `approved_hero_visual.gd`의 걷기·달리기는 이 네 시트만 사용하며, `hero_pose_v2`는 공격72프레임만 로드한다.

2026-09-25 GPU 8방향 걷기4상·달리기4상 픽셀 검수에서 셀 파편/세로선이 사라진 것을 확인했고, 실제 이동·공격·회피 통합은 96/0 FAIL이다. 기능 통과와 사용자 미술 승인은 구분하며 현재 상태는 `RESKIN_CANDIDATE_NOT_USER_ACCEPTED`다.

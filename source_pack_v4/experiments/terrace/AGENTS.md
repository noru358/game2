# 경험 실험 지침

상위 AGENTS.md와 docs/GAME_PROJECT_SOURCE.md, 본 프로젝트 docs/WORK_LOG.md를 읽는다. 전역 WORK_MEMORY와 상위 DOCUMENTATION_PROTOCOL을 따른다.

- 기존 겜1 게임 런타임과 배포본을 수정하지 않는다. 이 폴더는 독립 Godot 프로젝트다.
- 실제 사용자 저장·게임으로 시험하지 않는다. --test와 PID별 저장을 사용한다.
- 일반 진입점은 game/boot → lab/journey.tscn이며, lab/world.gd는 기반 실험장으로 game/world.gd의 공통 전투/효과를 상속한다. game/의 옛 맵 코드는 회귀 비교용으로 보존되어 있으나 새 맵 생성에 사용하지 않는다.
- Landscape x>=90 구간의 높이와 lab_flat은 새 맵 전용이다. 옛 좌표의 회귀검사와 lab_contract/lab_flow/lab_combat, 새 공간 GPU lab_render를 함께 검증한다.
- 높이·시야·충돌·발견·저장·리스폰 계약을 따로 수정하지 않는다. 단일 불투명 바닥과 Landscape.paving 사용.
- 실험 전체 기획/논의 결정은 상위 문서에도 반영한다. 기능 통과를 재미·최종 미술 승인으로 기록하지 않는다.

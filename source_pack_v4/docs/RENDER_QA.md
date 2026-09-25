# 현재 렌더 검수

- 지형의흙/길/물은 단일불투명표면. 포석은 공통삼각형높이. 이동/충돌/카메라/저장복원/적경고가 높이계약을 공유한다.
- `ground_surfaces/terrain_probe/grounded_run/exploration`은 기존공통기능 회귀. `render_surface_motion`은 옛맵14지점 진단이며 현재3지역의미술승인이 아니다.
- 현재여정의화면은 `journey_flow`, 경사/예고는 `slope_cues/warning_damage`, 모션/손은 `gait_cycle/hand_origin/diagonal_strike/moving_strike`를 목적에맞게 실행한다. GPU가필요한검사를 headless로기다리지 않는다.
- `--test`와PID별저장을쓴다. GPU캡처는 DEMO_QA_OUTPUT으로지정한다. 사용자게임/실제저장을 건드리지않는다.
- 단색기하검사와실제텍스처픽셀검사를구분한다. 경사·포석접합·가림·발접지·손/VFX·연속보행을실제로본다. PNG저장성공은품질통과가아니다.
- 새미술기준은 [확정시트](design_refs/hero_turnaround_approved.png). 옛캐릭터가보이는테스트캡처는미술기준으로쓰지않는다. 사람조작감/실청음은별도다.

# 실제 모션 참조 자산 감사 — 2026-09-25

`hero_pose_player.gd`는 `hero_pose_v2/frames.json`만 읽는다. 정지는 별도 승인 atlas를 사용한다. 미참조 파일을 삭제 대상으로 해석하지 않는다.

| 방향 | 상태 | 컷(0부터) | 실제 시트 | 반전 |
|---|---|---|---|---|
| 5 | run | 0 | back_right_run_first.png | True |
| 5 | run | 1 | back_right_run_first.png | True |
| 5 | run | 2 | back_right_run_opposite.png | True |
| 5 | run | 3 | back_right_run_opposite.png | True |
| 5 | walk | 0 | back_right_walk_center_first.png | True |
| 5 | walk | 1 | back_right_walk_center_first.png | True |
| 5 | walk | 2 | back_right_walk_opposite.png | True |
| 5 | walk | 3 | back_right_walk_opposite.png | True |
| 7 | run | 0 | back_right_run_first.png | False |
| 7 | run | 1 | back_right_run_first.png | False |
| 7 | run | 2 | back_right_run_opposite.png | False |
| 7 | run | 3 | back_right_run_opposite.png | False |
| 7 | walk | 0 | back_right_walk_center_first.png | False |
| 7 | walk | 1 | back_right_walk_center_first.png | False |
| 7 | walk | 2 | back_right_walk_opposite.png | False |
| 7 | walk | 3 | back_right_walk_opposite.png | False |

총 PNG 117개, 모션 런타임 시트 23개, 프레임 등록 136개.

## 픽셀 관찰

- 뒤대각선 run opposite: 상체/머리 우상 방향과 하체 정후면/지지 부츠 측면 방향 불일치.
- 뒤대각선 walk opposite: 상체 아래의 골반/양 코트 패널은 정후면에 가깝고 지지 부츠는 옆을 향함.
- first/opposite 전환에서 체형·꼬리·복장도 바뀜. 발끝만 돌리는 처리는 불충분.
- 좌상(5)은 우상(7) 원본 반전. 서로 다른 자산을 새로 만들 필요 없음.
- 새 left_support 후보02에 대한 사용자 수용은 한 자세의 다리 연결에 한정. 활성 움직임/복장 승인 아님.

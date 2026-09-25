# 승인 원화에서 직접 분리한 8방향

2026-09-24. 사용자가 Python 마스크 처리를 명시적으로 선택했다. 새로 그린 이미지가 아니라 **승인 시트의 원래 RGB 픽셀에 투명 마스크를 붙인 결과**다. 최종 목표는 정지·이동 모두 8방향이며, 보행4방향은 제작시험일 뿐이다.

## 결과

- candidate.png: 원본 위치를 유지한 8방향 투명 아틀라스.
- front/front_right/right/back_right/back/back_left/left/front_left.png: 각 방향 개별 원본 픽셀 추출물.
- frames.json: 실제 엔진 순서0~7, region/top/foot/root_x. 방향별 반전 없음. 발의 최하단13px 범위에서 부츠 외곽 중간값으로 root를 잠정 등록했다.
- review.png: 실제 Godot GPU의 222px/74px·밝은/어두운/녹색 배경 검사.
- validation.json: 픽셀동일성·alpha·영역·GPU검사와 한계.

## 원본 보존 및 검증

원본 SHA256 `0a01d4f99412b2a1eb3d51112e0d921033ef70f8a461dfc451752e03e57ffcf5` 그대로다. 불투명 출력 픽셀의 RGB는 승인 시트의 같은 위치와 전부 일치한다. alpha는0/255로, 기존 생성후보의 내부반투명 문제는 없다. 배경/글자/바닥그림자를 제거했고 원화의8방향·귀·꼬리·의상 형태를 GPU 화면에서 대조했다. 등록8방향/영역경계/발좌표 검사 통과, Godot4.7.2 GPU 캡처 성공/stderr없음.

균등4×2 칸 분리는 오른쪽/뒤오른쪽 꼬리를 자르므로 개별영역으로 수정했다. 미리보기는 `Image.fix_alpha_edges()` 후 mipmap을 만들어 투명부의 흰 RGB가 축소 테두리에 섞이는 문제를 줄인다. 이 처리는 메모리에서만 수행하며 저장된 원본 색을 바꾸지 않는다.

## 재현과 한계

`scripts/extract_approved_hero.py`를 Pillow와 NumPy가 있는 Python으로 실행한다. 임계색/외곽선의 가장 큰 연결영역과 내부 채우기로 마스크를 재현한다. 자동 분리가 완벽한 수작업 매트라는 뜻은 아니다. 이진 경계여서 원래 배경과 섞인 가장자리의 정확한 subpixel alpha를 복원하지는 않는다. 현재74px 검수에서는 큰 흰 테두리/배경 잔여/방향누락이 관찰되지 않았다. 작은 장신구 가독성, 실제 경사접지/회전/모션 연결은 별도 검증이다.

GPU 재검사: Godot 프로젝트 experiments/terrace에서 `--script res://tests/hero_asset_review.gd -- --test --asset-dir=res://art_review/hero_idle_exact_v1`.

## 적용 상태

후속 독립3D검사: `tests/hero_static_3d_review.gd`에서 실제 카메라 pitch52/size22, 1152×720, 평지/앞뒤±20%경사에 각각8방향(총24개)을 배치했다. Sprite3D의 게임과 같은 발-offset/세로보정 공식으로 발높이오차0건, GPU캡처성공/stderr없음. review_3d.png에서 바닥접점과 머리/꼬리의 표시를 확인했다. 이것은 단순경사 독립장면이며 실제 Landscape의복잡한경사/전경가림/이동검사를 대체하지 않는다.

**8방향 정지 자산의 분리·등록과 2D GPU검수까지 완료. 본 게임 미적용.** 현행 정지 제작물은 이 폴더이며, 이전 hero_idle_v1의 생성형 후보는 실패 이력이다. 보행 후보는 별도이며 부정확한 발교대/꼬리전환을 먼저 고쳐야 한다. 정지만 교체해서 이동할 때 옛 캐릭터로 바뀌는 상태를 만들지 않는다.

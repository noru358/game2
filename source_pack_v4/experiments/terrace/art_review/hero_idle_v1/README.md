# 주인공 정지 자산 검수 — 2026-09-24

**과거 생성형 실패 후보. 현행 정지 제작물은 [원화 직접 분리8방향](../hero_idle_exact_v1/README.md)이다.** 아래는 실패 원인 기록이며 새 작업 기준으로 사용하지 않는다.

상태: **제작 후보, 미승인, 본 게임 미적용**. 유일한 시각기준은 상위 docs/design_refs/hero_turnaround_approved.png다. 이 폴더는 대체 디자인 모음이 아니라 다음 제작을 위한 격리 검수물이다.

## 이번 작업

- 내장 imagegen으로 승인 시트의 배경·글자·바닥 그림자 제거를 2회 시도했다. 현재 candidate.png는 두 번째 결과다. 첫 결과는 생성 도구의 원래 저장소에만 남는다.
- 1448×1086 RGBA, 8개 영역을 AtlasTexture와 호환되는 region/top/foot/root_x로 잠정 등록했다. 엔진 순서는 RIGHT, FRONT-RIGHT, FRONT, FRONT-LEFT, LEFT, BACK-LEFT, BACK, BACK-RIGHT. 좌우 반전으로 대체하지 않았다.
- tests/hero_asset_review.gd는 게임이나 저장을 생성하지 않는 독립 검수기다. 222px 확대와 74px 실제 목표 크기를 밝은/어두운/녹색 면에서 비교한다. 청록 십자는 발/root이며 후보 원화 일부가 아니다.
- Godot 4.7.2 / RTX 4060 Ti GPU 실행: 8영역 기본계약 통과, PNG 저장 성공, stderr 비어 있음. review.png의 실제 픽셀도 확인했다. 최종 미리보기는 메모리에서 mipmap을 생성한다. 런타임 원본 PNG와 게임의 샘플링 설정은 변경하지 않았다.

## 미통과와 다음 작업

투명 픽셀 865,387개, 완전 불투명 1,932개, 부분 alpha 705,209개. 대다수 캐릭터 내부도 약한 반투명이고 귀/꼬리 외곽에 작은 잔여 픽셀이 있다. alpha 존재만으로 제작 완료가 아니다. 원화의 세부 묘사도 생성 중 달라져 승인본과 완전히 동일하다고 할 수 없다. 74px에서 방향/큰 귀/옷 색은 구분되지만 작은 금장·손·장신구는 뭉친다.

다음은 승인 원형을 유지한 정밀 마스크/가장자리 정리와 내부 불투명화가 가능한 제작 방식으로 마무리하고, 이 검수기를 다시 실행해 기준 이미지와 비교하는 것이다. 단순 배경제거 생성 반복으로 해결됐다고 처리하지 않는다. 현 foot/root는 정지 후보 기준이며 걷기 접지나 경사 검증을 대체하지 않는다.

이후 대표 4방향×4보행단계 16컷 → 연속재생/접지 → 시전 손/VFX → 작은 통합구간 순서. 사람의 조작 체감/실청음은 독립 미완료 항목이다.

## 재현

프로젝트 경로를 experiments/terrace로 지정하고 Godot 실행 인자 `--script res://tests/hero_asset_review.gd -- --test`를 사용한다. GPU 창이 필요한 검사다. `--test`를 빼면 검수창 유지, Esc 종료. 실제 사용자 저장을 읽거나 쓰지 않는다.

## 사용한 최종 프롬프트

내장 imagegen 편집, referenced_image_paths는 승인 시트 하나. CLI/API는 사용하지 않았다.

> Produce a clean professional game sprite sheet by extracting exactly the eight existing figures from this reference. Keep their original artwork and directions faithfully, with no character redesign. Replace the background with true transparent alpha. Remove every label and floor shadow. CRITICAL: completely clear empty space between figures, no red/yellow edge noise, no stray pixels, no residual background haze. Figure interiors including white robes and pale fur must be fully opaque, only a narrow smooth antialiased contour may be partly transparent. Place eight full-body figures in a regular 4 columns by 2 rows grid, each fully inside its own equal-sized cell with 24px minimum clear margin. Align their boot soles to a consistent baseline in each row. Top row front, front-right, right, back-right; bottom row back, back-left, left, front-left. Preserve jewelry, costume silhouette and colors, huge ears and fluffy tails. No text or ground shadows. Output RGBA PNG.

프롬프트 요구사항 전체가 충족된 것은 아니다. 동일 크기 셀/최소여백도 불충족하여 frames.json은 개별 region으로 등록했다.

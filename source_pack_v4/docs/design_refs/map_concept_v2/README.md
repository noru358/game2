# 맵 컨셉 시안 v2 — 높은 시점·저밀도 숲 수로 성소

2026-09-25 정정: 아래 당시 평가 중 직사각 포석/격자/비대칭 부족 자체를 위험으로 본 판단은 철회했다. 시안의 석조 구조를 현행 기준으로 보존한다. 생성 프롬프트는 과거 기록이지 새 의무 목록이 아니다. [통합 규칙](../../MAP_RULES_INDEX.md) 참고.

상태: **방향성 잠정 채택 / 정확한 배치 미채택 / 런타임 미구현**  
날짜: 2026-09-25

## 목적

v1 후속 의견인 `더 높은 시점`, `한 맵 전체와 실제 플레이 화면의 분리`, `덜 빽빽한 밀도`, `주인공의 깨끗한 그림체와 호환`, `Sol 중심으로 구현 가능한 자산 경제성`을 한 장에서 검토한다. 캐릭터·적·UI는 포함하지 않았다.

## 결과 파일

- `forest_waterway_north_star_v2.png`
- 1672×941 RGB
- SHA256 `D8C662B846F61424E417969A0383FE81FA8DF651EFCBBC0B70045FF0F708DBA9`
- Codex 내장 ImageGen 사용

입력 역할:

- v1 컨셉: 지역 정체성과 수정 대상.
- 승인 주인공 turnaround: 큰 형태·명암·색·깨끗한 스타일의 보정 기준. 결과에는 주인공을 그리지 않음.

## 실제 화면 판단

### v1보다 개선된 점

- 시점이 높아져 바닥 윗면, 계단, 수로 연결과 상하층이 빠르게 읽힌다.
- 전경 구조물 가림이 줄고 장거리 시야가 열린다.
- 개별 꽃·균열·점광이 줄고 큰 색면과 덩어리 식생 중심이라 주인공의 깨끗한 실루엣과 결합하기 쉽다.
- 같은 기둥·난간·벽·계단 가족을 반복해 만드는 구조가 보여 v1보다 솔로 개발에 현실적이다.
- 전체 이미지를 한 맵 조감으로 보고 실제 카메라는 일부를 확대 추적한다는 전제가 성립한다.

### 새로 생긴 위험

- 중앙이 넓은 직사각 포석 마당으로 읽혀 장소 행동보다 `전투장`이 먼저 보일 수 있다.
- 수로와 벽·난간이 정규 격자에 가깝고 기둥·계단 반복이 강해 `예쁜 모듈형 타일맵` 인상을 만들 수 있다.
- 재사용 가능성을 강조한 결과 자연 지형의 비대칭 원인과 짧은 방향 전환이 약해졌다.
- 실제 74px 주인공과 전투 효과를 얹은 엔진 화면은 아직 아니므로 최종 호환성 증거가 아니다.

따라서 v2는 v1보다 카메라·밀도·그림체·생산비 기준에 가깝지만, 이 정확한 평면 배치를 맵 문법으로 승인하거나 구현에 들어갈 단계는 아니다.

## 2026-09-25 사용자 판단과 시안 종료선

사용자는 v2가 이전보다 나은 느낌이라고 판단했으며, 이 이미지를 맵 전체의 고정 화면이 아니라 **맵 안의 대표적인 큰 구간**으로 보는 방향에 동의했다. 실제 플레이 화면은 이보다 가까운 이동식 크롭이며 캐릭터가 구간 안을 탐험한다.

이 판단은 v2의 정확한 중앙 마당·수로·기둥·계단 배치를 승인했다는 뜻이 아니다. 높은 시점, 넓은 바닥 가시성, 낮춘 미세 밀도, 큰 형태 언어, 반복 가능한 자산 가족만 다음 단계의 방향성으로 잠정 채택한다. 전체 장면을 더 예쁘게 고치는 컨셉 반복은 여기서 멈추고, 다음 산출물은 `MAP_SPEC → 실제 크기 그레이박스 → 대표 플레이 화면 아트 슬라이스`다. 후속 이미지 생성은 엔진에서 해결되지 않은 특정 질문이 생긴 경우에만 사용한다.

## 최종 프롬프트

```text
Use case: stylized-concept
Asset type: revised game environment North Star concept, environment and map only

Input images:
- Image 1: edit target and regional identity reference. Preserve the tropical waterway, connected ruin terraces, and root-bound sanctuary concept, but substantially revise camera, density, and rendering language.
- Image 2: style calibration reference only. Use its clean large shape language, controlled outlines, smooth value grouping, ivory/gold/teal harmony, and charming stylization to guide the environment. Do not draw the character or any character-like figure.

Primary revision:
Create v2 of the forest waterway sanctuary as a conceptual whole-map overview that still uses the actual game's fixed orthographic oblique projection. It should feel suitable for later gameplay where the camera shows a closer subset and follows the player through the map.

Camera and readability:
- Clearly higher and more top-down than Image 1, visually around 60–62 degrees down from the horizon, with mild diagonal yaw.
- Show substantially more ground top surfaces and longer connected sightlines.
- Reduce foreground and wall occlusion; stairs, routes, and height changes must read immediately.
- Keep visible wall and canal side faces so the world remains dimensional, not flat top-down.
- The terrain continues naturally beyond the frame; no floating islands or diorama edges.

Spatial composition:
- Preserve an old diagonal canal as the organizing spine.
- Preserve a root-bound stone sanctuary as the primary distant landmark, but keep it offset and partially framed rather than centered like a stage.
- Make the traversable land one continuous map with a clear sequence of canal edge, crossing/turn, broad irregular playable court, and higher sanctuary approach.
- The open playable floor should be generous, calm, and irregular rather than a circular arena.
- Use fewer tall obstacles around the main route so exploration sightlines extend farther.
- Suggest that this entire image is one explorable map, while any real gameplay screen would show only a closer moving portion.

Density and production economy:
- Reduce micro-detail and prop density significantly compared with Image 1.
- Concentrate detail at the sanctuary, canal edges, major stairs, and selected foreground framing.
- Keep the main traversal/combat ground quiet: broad value shapes, sparse cracks, minimal flowers, minimal dappled light, no tiny clutter.
- Use a believable reusable visual vocabulary: consistent wall-cap stones, stair family, railing-post family, paving transitions, and a few large foliage-cluster families. It should look authored but feasible for a solo developer using modular assets.
- Avoid a unique carved ornament, plant species, or masonry pattern at every meter.
- Create variation through grouping, scale, overlap, tint, and terrain relationships rather than endless unique props.

Art direction:
Clean stylized 2.5D fantasy environment matching the visual family of Image 2: crisp silhouettes, smooth controlled shading, larger readable shapes, restrained painterly texture, clear material separation. Do not imitate the character's black outline literally on every environmental object. Warm ivory sandstone, mossy green, muted turquoise water, dark cool vegetation. Keep background cyan and highlights less saturated than the character's jewel and future spell effects.
Lighting should use broad warm light and clear soft shadows, not dense speckled sunlight. Top surfaces are calmer and lighter; wall and canal side faces carry more texture and depth.

Composition:
16:9 landscape, map/environment only, polished game concept. This is not a map diagram, not a cinematic horizon shot, and not a single static battle arena.

Constraints:
Absolutely no player character, NPC, monster, animal, statue shaped like a cute character, health bar, damage number, quest panel, minimap, ability icon, inventory, caption, signage text, logo, or watermark.
No excessive foliage walls, no dense flower carpet, no noisy stone cracks across the whole floor, no symmetrical plaza, no giant empty circle, no narrow maze, no isolated terrain islands, no ocean surrounding the map, no sci-fi elements.
Preserve the region identity from Image 1 while making it more readable, more open, more compatible with the clean hero art, and materially cheaper to build.
```

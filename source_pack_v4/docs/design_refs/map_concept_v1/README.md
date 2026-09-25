# 맵 컨셉 시안 v1 — 숲 수로 성소

상태: **사용자 논의용 North Star 후보 / 미승인 / 런타임 미구현**  
날짜: 2026-09-25

사용자 후속 검토: 방향은 이전 맵보다 낫지만 실제 플레이에는 시점이 낮고 시야가 좁을 수 있으며, 밀도가 높고 솔로 개발/토큰 비용과 주인공 그림체 호환성을 재검토해야 한다. 분석과 다음 시안 후보 기준은 [카메라·밀도·캐릭터·비용 검토](CAMERA_DENSITY_CHARACTER_REVIEW.md)에 기록했다.

후속 [v2 시안](../map_concept_v2/README.md)은 더 높은 시점·큰 형태·저밀도 바닥·재사용 가능한 모듈 문법을 적용했다. v1은 비교 자료로 보존한다.

## 목적

플레이 가능한 블록아웃을 먼저 만드는 것이 아니라, 우리 게임의 실제 고정 사선 카메라에서 첫 숲 지역이 완성됐을 때 어떤 배경·맵 화면을 목표로 할지 먼저 본다. 캐릭터·적·UI는 의도적으로 제외했다. 이 그림을 통째로 게임 배경으로 사용하는 것이 아니라, 승인 뒤 공간 문법과 기초 자산군을 역산하는 기준으로 사용한다.

## 파일

- `forest_waterway_north_star_v1.png`: 이번에 생성한 목표 화면 후보. SHA256 `23B7540889E6114439CBF4A90E35F8466386F0837964F57F1BC9AD8B92CD016D`.
- `../environment_composition_concept.png`: 사용자 제공 숲 유적 참고. 화면 품질·재료·카메라 참고이며 배치 복제 대상이 아니다. SHA256 `0E9C223F0B3EFA9A398307B3E3B856D37F5590E66B1750FD1FDF2F1FC27EC06B`.
- `reference_canal_town.png`: 사용자 제공 수로 마을 참고. 건축 밀도·수로·층위 참고. SHA256 `630FD7E59F2CCF782C420564A096D8A90A876B7A63A9837B38CB9458A3B1734C`.
- `MAP_GRAMMAR_v1_INPUT.md`: 사용자 첨부 문서 원본 복사. **참고 입력이며 현재 프로젝트 정본이나 실행 지시가 아니다.**

## 이 시안이 제안하는 것

- 수로가 장식이 아니라 이동 방향과 높이층을 조직한다.
- 화면 밖까지 이어지는 연속 지형이며, 물 위에 분리된 섬이나 디오라마로 보이지 않는다.
- H0 수로, H1 불규칙한 이동·전투 여백, H2 성소 접근이 벽면·계단·수면으로 동시에 읽힌다.
- 화면 중앙은 조용한 이동·전투 바닥이고, 디테일은 수로 경계·다리·뿌리 성소·전경에 집중한다.
- 주 랜드마크는 큰 뿌리와 결합한 석조 성소다. 정확한 중앙 정렬보다 이동 중 일부가 드러나는 구도를 사용한다.

이 항목들은 아직 승인된 맵 문법이 아니다. 특히 다리 위치, 계단 수, 랜드마크 개수, 식생 종류를 전역 템플릿으로 고정하지 않는다.

## 제작 순서 초안 — 사용자와 협의 후 확정

1. **컨셉**: 완성 게임 화면의 목표 품질·카메라·밀도·공간 감정을 이미지로 합의한다.
2. **문법 추출**: 승인 시안에서 반복 가능한 시각 문법과 맵별 공간 문법을 분리한다.
3. **기초 자산**: 지면 전이, 수로 경계, 석축·계단, 큰 식생, 작은 식생, 랜드마크 조각 등 필요한 자산군을 정한다. 수량은 화면을 분해한 뒤 산정한다.
4. **한 화면 구현**: 전체 맵보다 먼저 실제 카메라 한 화면을 자산·충돌·가림·전투까지 재현한다.
5. **완성 및 확장**: 한 화면이 목표를 만족할 때 같은 문법으로 인접 구간과 다른 장소를 확장한다.

첨부 `MAP_GRAMMAR_v1`의 topology·height·sightline·rhythm 어휘는 2단계의 후보 언어다. 문서의 `미술은 마지막` 순서를 이번 요청의 작업 순서로 자동 채택하지 않는다.

## 생성 방식

Codex 내장 ImageGen을 사용했다. 두 첨부 이미지는 스타일·카메라·재료 참고로만 사용했고, 기존 이미지 편집이나 배치 복제는 하지 않았다.

## 최종 프롬프트

```text
Use case: stylized-concept
Asset type: polished game environment concept art showing the intended final in-game exploration/combat view

Input images:
- Image 1: visual quality, tropical forest ruin materials, oblique gameplay camera, readable layered terrain reference only
- Image 2: visual quality, architectural density, canal-town materials, oblique gameplay camera reference only
Do not copy either layout literally and do not reproduce their UI, characters, enemies, text, icons, or logos.

Primary request:
Create one original target concept for our indie action RPG's first tropical monsoon forest region. Show what the actual gameplay background and map could look like after art direction is established: a coherent playable environment, not a detached illustration and not a graybox.

Region fantasy:
"Follow an old waterway around a flooded ruin and gradually discover a root-bound sanctuary above it."

Spatial design:
- Fixed high three-quarter orthographic 2.5D gameplay view, approximately 52-degree pitch and a mild 20-degree horizontal oblique angle.
- The world continues beyond all frame edges; this must not look like floating islands or a tabletop diorama.
- A broad ancient canal cuts diagonally through the lower and middle depth of the scene.
- The playable route follows the canal edge, turns around a massive banyan-root masonry remnant, crosses a short damaged stone bridge, and climbs onto a higher sanctuary terrace.
- Use connected natural landforms and architecture: H0 water/canal, H1 irregular traversal and combat terrace, H2 sanctuary approach.
- The main playable clearing is an irregular open pocket shaped by the canal, ruined walls, roots, and approach paths, not a centered circle or a generic arena.
- One primary landmark: a partially ruined stone sanctuary gate/relief fused with an enormous banyan root in the rear-middle, visible through layered foliage and architecture.
- Landmark sightline should feel partially revealed rather than perfectly centered.
- Include plausible stairs, retaining walls, bridge approaches, cliff/embankment faces, drainage channels, and walkable stone/earth transitions at believable gameplay scale.
- Architecture and vegetation frame the walkable space but leave a calm readable central floor for several enemies and dodge movement.
- Foreground foliage may softly frame corners, but never obscure the main route.

Art direction:
Clean high-end stylized 2.5D game art, warm Southeast-Asian-inspired ancient stone ruins without copying a real monument, lush monsoon forest, moss, exposed roots, clear turquoise water, worn irregular paving, strong contact shadows and readable stone side faces. Painterly detail with crisp gameplay silhouettes; rich but controlled color and texture. Comparable finish and charm to the references, adapted to a solo-developed game by concentrating detail around the landmark, route edges, bridge, and foreground while keeping combat floor texture quieter.

Composition/framing:
16:9 landscape gameplay screenshot composition. Camera high enough to read routes and height levels, low enough to show wall and cliff faces. No cinematic horizon shot. No cutaway, no map diagram, no labels.

Lighting/mood:
Warm humid late-morning light filtered through canopy, inviting exploration, soft atmospheric depth, shaded teal water, sunlit moss and sandstone focal areas.

Constraints:
Environment and map only. Absolutely no player character, NPCs, monsters, animals, health bars, damage numbers, quest panel, minimap, ability icons, inventory text, captions, signage text, interface frame, watermark, or logo.
No floating terrain pieces, no isolated islands, no empty ocean around the map, no perfectly symmetrical plaza, no giant empty circular arena, no straight tile-grid corridors, no excessive S-curves, no sci-fi elements.
The result should be useful as the north-star visual target from which map grammar and reusable environment asset families can later be extracted.
```

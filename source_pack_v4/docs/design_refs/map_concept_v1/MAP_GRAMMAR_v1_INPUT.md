# MAP GRAMMAR v1 — 맵 설계 표준

> 프로젝트 주석: 이 파일은 사용자가 첨부한 참고 원문이다. 아래 '채택' 표기는 원문 내용이며 이 프로젝트의 승인 상태가 아니다. 강제 선택길/제작 순서/형상 제한을 자동 적용하지 않는다. 현행은 [통합 규칙](../../MAP_RULES_INDEX.md)을 따른다.

상태: **D120 채택된 설계 표준 / 런타임 미구현**  
적용 대상: `experiments/terrace` 이후의 지역·필드·던전 blockout  
현재 구현 게이트: Packet 2는 여전히 HOLD. Packet 1A 사람 체감 승인 전에는 이 문법을 런타임 구현 완료로 간주하지 않는다.

## 0. 목적

맵을 `배경 에셋 배치`가 아니라 **플레이 가능한 공간 구조**로 먼저 설계한다. 같은 카메라·캐릭터·전투 시스템을 써도 지역마다 이동, 시야, 고저, 전투 접근, 랜드마크 회상이 달라져야 한다.

핵심 원칙은 다음과 같다.

> **지역 = 공간 DNA + 토폴로지 + 이동 동사 + 고저 + 시야 + 공간 박자 + 전투 공간 + 랜드마크 + 미술 패스**

미술은 마지막 단계다. 지역성이 건물 스킨에만 의존하면 실패다.

## 1. NO-SKIN-SWAP GATE

모든 맵은 Art Pass 전에 회색 blockout 상태로 다음을 통과해야 한다.

- 에셋·재질·식생을 제거해도 지역의 공간 성격을 설명할 수 있다.
- 다른 지역의 에셋을 임시로 씌워도 원래 맵의 이동 문법이 남는다.
- `중앙 원형 전투장 + 좌측 다리 + 우상단 계단/랜드마크` 같은 동일 레이아웃 반복을 지역 차이로 인정하지 않는다.
- 장소를 `나무 많은 곳`, `사원 있는 곳`이 아니라 `물가를 돌아 올라가는 길`, `넓은 축에서 골목으로 압축되는 곳`, `상하층이 겹쳐 보이는 곳`처럼 지형과 행동으로 설명할 수 있어야 한다.

## 2. 설계 순서

맵 하나는 항상 아래 순서로 만든다.

1. `REGION_FANTASY` — 플레이어가 이 장소에서 어떤 공간 감정을 느껴야 하는가.
2. `MAP_DNA` — 지역의 7개 핵심 공간 값.
3. `TOPOLOGY` — 노드와 연결만 작성. 좌표·에셋 금지.
4. `SPATIAL_GRAMMAR` — 이동 동사, 높이, 시야, 공간 박자, 전투 유형을 부여.
5. `GRAYBOX` — Godot blockout. 재질/장식 최소.
6. `PLAYTEST` — 미니맵/문구 없이 길 읽기, 선택, 전투 차이를 확인.
7. `ART_PASS` — 문화권 건축, 재질, 식생, 소품을 적용.
8. `REGRESSION_QA` — 높이/충돌/카메라/적/미니맵/저장 계약 검사.

Art Pass가 Graybox Gate보다 먼저 오면 실패로 처리한다.

## 3. MAP DNA

지역마다 먼저 아래 7개를 잠근다.

| 필드 | 의미 | 대표 값 |
|---|---|---|
| `primary_shape` | 전체를 지배하는 큰 구조 | `AXIS`, `WATER_SPLIT`, `TERRACE`, `BASIN`, `RIDGE`, `WEB`, `RING`, `VALLEY` |
| `path_character` | 길의 성질 | `BROAD_STRAIGHT`, `NARROW_CURVED`, `BROKEN_DIAGONAL`, `SWITCHBACK`, `BRAIDED`, `RADIAL` |
| `height_character` | 높낮이가 공간을 만드는 방식 | `FLAT_MONUMENTAL`, `WALL_TERRACE`, `STACKED`, `RIDGE_VALLEY`, `STEPWISE`, `CLIFF_LEDGE` |
| `visibility` | 기본 시야 성격 | `LONG`, `SHORT`, `ALTERNATING`, `LAYERED`, `OCCLUDED` |
| `density` | 공간 압축도 | `LOW`, `MEDIUM`, `HIGH` |
| `navigation_driver` | 길 찾기를 주도하는 정보 | `DISTANT_LANDMARK`, `LOCAL_REVEAL`, `WATER_EDGE`, `HEIGHT`, `SOUND`, `LIGHT`, `STRUCTURAL_AXIS` |
| `region_signature` | 다른 지역과 바꿀 수 없는 공간 특징 | 자유 문자열 1~2개. 예: `WARD_AND_GATE`, `CANAL_AND_ALLEY`, `ROOT_SHELVES` |

### 예시

```yaml
map_dna:
  primary_shape: AXIS
  path_character: BROAD_STRAIGHT
  height_character: WALL_TERRACE
  visibility: LONG
  density: LOW
  navigation_driver: DISTANT_LANDMARK
  region_signature: WARD_AND_GATE
```

## 4. TOPOLOGY — 공간 노드

좌표보다 먼저 노드와 연결로 맵을 표현한다.

### 4.1 표준 노드 타입

- `ENTRY` — 진입점
- `PATH` — 일반 이동 구간
- `FORK` — 의미 있는 선택 갈림
- `CHOKE` — 폭이 줄어드는 통과부
- `ARENA` — 전투의 위치 잡기가 중요한 공간
- `POCKET` — 작은 발견/휴식/보상 공간
- `LANDMARK` — 길 찾기 기준이 되는 구조/지형
- `OVERLOOK` — 이전/다음 공간을 읽게 하는 전망
- `ASCENT` — 상승 전환
- `DESCENT` — 하강 전환
- `BRIDGE` — 물리적으로 나뉜 공간의 연결
- `LOOP` — 우회 뒤 기존 공간으로 복귀
- `SHORTCUT` — 상태 변화 후 열리는 단축 연결
- `SECRET` — 필수 경로 밖 선택 발견
- `GATE` — 조건/전투/상호작용이 걸린 진행 경계
- `EXIT` — 다음 공간으로 이동

`ARENA`는 반드시 원형 공터일 필요가 없다. 전투가 일어난다는 이유만으로 모든 넓은 공간을 ARENA로 만들지 않는다.

### 4.2 노드 최소 데이터

```yaml
N05:
  type: OVERLOOK
  height: H2
  landmark_relation: REVEAL
  encounter: NONE
  purpose:
    - preview_destination
    - reorient_player
```

## 5. EDGE — 이동 동사

노드 연결은 단순 선이 아니라 플레이어 행동을 가진다.

표준 동사:

- `ADVANCE` — 직진/진행
- `ENTER` — 외부에서 내부/측면 공간으로 진입
- `CROSS` — 다리·수로·틈을 횡단
- `CLIMB` — 상승
- `DESCEND` — 하강
- `DROP` — 되돌리기 어려운 하강
- `TURN` — 시야가 크게 바뀌는 코너
- `SQUEEZE` — 좁은 통로 통과
- `CIRCLE` — 구조물을 감싸며 이동
- `DETOUR` — 목적지와 반대 방향으로 잠시 우회
- `PASS_UNDER` — 상층 아래 통과
- `PASS_OVER` — 다른 경로 위를 횡단
- `RETURN` — 이전 공간으로 재합류
- `UNLOCK` — 상태 변화로 새 연결을 연다

같은 지역에서 같은 동사를 반복해도 되지만, 연속 3회 이상 동일 리듬이 이어지면 의도 여부를 검토한다.

## 6. HEIGHT GRAMMAR

높이는 장식이 아니라 행동을 바꿔야 한다.

기본 층:

- `H0` — 저지대 / 물가 / 하층
- `H1` — 기본 플레이면
- `H2` — 상층 / 능선 / 회랑
- `H3` — 전망·특수 접근층

높이 전환에는 최소 1개의 기능을 붙인다.

- `change_sightline`
- `ranged_advantage`
- `safer_but_longer`
- `riskier_but_faster`
- `discover_optional_object`
- `create_rejoin`
- `open_shortcut`
- `show_previous_area`
- `show_future_area`

`예뻐서 계단을 넣음`은 기능으로 인정하지 않는다.

## 7. SIGHTLINE GRAMMAR

주요 랜드마크는 플레이 동안 다음 상태로 관리한다.

- `VISIBLE` — 명확히 보임
- `PARTIAL` — 일부만 보임
- `HIDDEN` — 구조물/지형에 가림
- `REVEAL` — 코너/고저 변화 뒤 처음 강하게 드러남
- `LOST` — 한 번 보였던 목적지가 사라짐
- `REACQUIRED` — 사라졌던 목적지가 다시 보임

좋은 탐험 구간은 랜드마크를 계속 화면에 고정하지 않고, `보임 → 가림 → 재노출 → 가까워짐` 같은 변화를 만든다.

## 8. SCREEN RHYTHM — 공간 박자

각 노드는 화면에서 느끼는 공간 상태를 가진다.

표준 값:

- `COMPRESSED` — 좁고 시야가 막힘
- `OPEN` — 넓고 전투/이동 여유가 있음
- `MONUMENTAL` — 규모와 축선이 강조됨
- `VERTICAL` — 상하층을 동시에 읽음
- `BEND_REVEAL` — 코너 뒤 새로운 공간이 열림
- `VISTA` — 먼 목적지/이전 장소를 봄
- `COMBAT_PRESSURE` — 전투가 공간 인식을 지배
- `QUIET` — 전투 뒤 탐색/호흡
- `CHOICE` — 두 경로의 차이가 읽힘

맵마다 리듬 시퀀스를 적는다.

```yaml
screen_rhythm:
  - COMPRESSED
  - BEND_REVEAL
  - CHOICE
  - VERTICAL
  - COMBAT_PRESSURE
  - VISTA
  - QUIET
```

`MEDIUM → MEDIUM → MEDIUM`처럼 화면 상태가 계속 같은 맵은 재설계 후보다.

## 9. COMBAT SPACE GRAMMAR

전투 공간은 아래 타입을 우선 사용한다.

- `OPEN_FIELD`
- `CROSSROAD`
- `CORRIDOR`
- `BRIDGE`
- `STAIR`
- `TWO_LEVEL`
- `RING`
- `OBSTACLE_FIELD`
- `EDGE`
- `AMBUSH`
- `GATE_FRONT`
- `WALL_TOP`

각 지역은 `preferred`와 `forbidden`을 가진다. `GENERIC_CIRCULAR_ARENA`는 특별한 이유 없이는 금지한다.

전투 배치는 자동 마법/3연타/밀치기/회피의 역할을 공간으로 바꾸어야 한다. 예를 들어 상층 caster, 좁은 길 charger, 넓은 저지대 wanderer처럼 접근선이 달라져야 한다.

## 10. LANDMARK GRAMMAR

랜드마크는 3단계로 구분한다.

- `PRIMARY` — 지역 전체 방향 기준. 한 구간에 보통 1개.
- `SECONDARY` — 갈림/구역 기억 기준.
- `MICRO` — 상호작용·발견의 근거리 표식.

PRIMARY는 소품 크기만 키운 것이 아니라 이동 경로·시야·고저와 연결되어야 한다.

## 11. MAP_SPEC 표준 양식

```yaml
map:
  id: REGION_01
  name: Display Name
  status: DRAFT

region_fantasy:
  sentence: "..."
  player_memory: "플레이 후 지형으로 어떻게 기억해야 하는가"

camera:
  mode: FIXED_OBLIQUE
  screen_axis_rule: WORLD_NOT_LOCKED_TO_SCREEN
  exact_yaw: TBD_BY_BLOCKOUT

map_dna:
  primary_shape: ...
  path_character: ...
  height_character: ...
  visibility: ...
  density: ...
  navigation_driver: ...
  region_signature: ...

nodes:
  N01:
    type: ENTRY
    height: H1
    rhythm: COMPRESSED

edges:
  - from: N01
    to: N02
    verb: TURN

sightlines:
  - at: N01
    landmark: PRIMARY_A
    state: PARTIAL

combat:
  preferred: []
  forbidden: [GENERIC_CIRCULAR_ARENA]

validation:
  no_skin_swap_gate: REQUIRED
  route_choice: REQUIRED
  human_recall: REQUIRED
```

## 12. Godot 구현 매핑

문법은 엔진 구현과 1:1로 강제 결합하지 않는다. 다만 blockout 자동화 시 아래 최소 데이터로 내린다.

### MapNode

```text
id
node_type
position
height_band
radius_or_bounds
rhythm
landmark_id
encounter_id
```

### MapEdge

```text
from
to
verb
width
height_delta
slope_class
visibility_class
one_way
unlock_condition
```

현재 `experiments/terrace`에서는 지형을 별도 얇은 면으로 포개지 않고 `Landscape`의 단일 불투명 표면/높이 계약을 유지한다. Map Grammar가 이 엔진 계약을 우회하지 않는다.

## 13. Blockout 검증 체크

Art Pass 전 사람 플레이에서 최소 다음을 확인한다.

1. 미니맵/안내문 없이 주경로와 최소 1개 선택 경로가 읽히는가.
2. 높은/낮은 길이 실제 위치 잡기·몰이·직접 공격 사용을 바꾸는가.
3. 갈림이 다시 재합류하며 어느 길을 택했는지 플레이어가 말할 수 있는가.
4. 전투 뒤 `QUIET` 또는 `VISTA`가 있어 호흡이 생기는가.
5. 랜드마크가 시야 상태 변화를 가지는가.
6. 회색 blockout만 보고도 다른 지역 MAP_SPEC와 구별되는가.
7. 지형으로 기억할 문장이 실제 플레이 후 성립하는가.

## 14. 지역별 문법은 별도 MAP_SPEC에서 정의

이 문서는 공통 언어만 정의한다. 장안형, 강남형, 복건 산지형, 첫 숲형 같은 실제 지역 차이는 각 MAP_SPEC에서 `MAP_DNA / topology / rhythm / combat / sightline`을 별도로 잠근다. 문화권 미술은 이 차이를 강화해야지 대신해서는 안 된다.

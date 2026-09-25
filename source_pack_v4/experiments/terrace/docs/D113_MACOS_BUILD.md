# D113 — 0.10 macOS universal 체감 확인본

2026-09-24. Windows `.exe`를 열 수 없는 Mac에서 D112의 동일한 Packet 1 후보를 확인할 수 있도록 **macOS `.app`을 담은 ZIP**을 추가했다. 게임 코드·미술·환경·콘텐츠·저장 schema는 변경하지 않았다. Packet 1은 여전히 사람 체감 확인 전 PARTIAL이고 Packet 2는 HOLD다.

## 받기와 실행

ExperienceLab-0.10-macos-universal.zip (원본 작업공간의 별도 이력/산출물: `../builds/ExperienceLab-0.10-macos-universal.zip`; 이 팩 제외)을 Mac으로 옮긴 뒤:

1. ZIP 전체를 압축 해제한다.
2. `ExperienceLab.app`을 더블클릭한다. Godot 설치는 필요 없다.
3. 처음 실행이 차단되면 **시스템 설정 → 개인정보 보호 및 보안 → 확인 없이 열기/Open Anyway**를 선택하고 다시 연다.

Intel은 macOS 11 이상, Apple Silicon은 macOS 13 이상을 최소값으로 내보냈다. 두 아키텍처가 한 앱에 든 universal build다. 개발용 ad-hoc 서명은 포함했지만 Apple 공증은 하지 않았다. 따라서 처음부터 아무 경고도 없는 정식 배포 패키지는 아니다.

저장은 `~/Library/Application Support/FirstTrailExperienceLab/journey_v2.json`에 생성된다. Windows 저장과 자동 공유하지 않는다.

## 패키지 검증

- 파일: `ExperienceLab-0.10-macos-universal.zip`
- 크기: 98,142,039 bytes
- SHA256: `313249EA4FA8D7CBE2E25A99D878E8C3AD46B759FF0C95DDED953F1DD1FD7775`
- 번들: `ExperienceLab.app`
- bundle id: `org.firsttrail.experiencelab`
- 버전: `0.10.0`
- Mach-O: `x86_64` + `arm64`
- 양쪽 slice의 내장 서명 명령, `_CodeSignature/CodeResources`, PCK, Unix 실행 권한, ZIP CRC 확인
- README와 Godot/포함 구성요소 라이선스 동봉
- `tests/`, `docs/`, 기존 빌드는 게임 패키지에서 제외

ZIP의 PCK를 별도 임시 폴더로 추출해 같은 Godot 4.7.2 Windows release runtime에 연결했다. D112 `core_response` 6항목과 `journey_flow` 28항목이 실패 0이었고 14개 GPU 캡처를 생성했다. 이는 **Mac 패키지에 올바른 공통 게임 데이터가 들어 있다는 검사**이며 Mac 실행 파일, Metal/OpenGL 드라이버, Gatekeeper, 키보드, 소리를 실제 Mac에서 검증한 것은 아니다.

manifest: manifest-0.10-macos.json (원본 작업공간의 별도 이력/산출물: `../builds/manifest-0.10-macos.json`; 이 팩 제외). 증거: `docs/validation/d113`.

## Mac에서 확인할 것

1. 앱이 열리고 한글 UI가 잘리는 곳이 없는가.
2. WASD/방향키, Space/Shift, J, F, Esc가 정상 입력되는가.
3. 정지·반전·탭 3연타·공격 중 회피가 D112 의도대로 느껴지는가.
4. 자동 마법/직접 공격/밀치기와 소리가 정상인가.
5. 종료 후 다시 열었을 때 `journey_v2` 진행이 복원되는가.
6. Intel 또는 Apple Silicon 모델, macOS 버전, 실행 차단 문구와 체감 문제를 함께 기록한다.

Mac 실기 결과 전에는 이 ZIP을 macOS 정식 지원, 공증 완료, 다른 Mac 전체 호환 또는 Packet 1 승인 근거로 쓰지 않는다.

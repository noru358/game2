# 배포 폰트 — 2026-09-21

나눔고딕 Regular/Bold 원본 TTF를 assets/fonts에 포함했다. 메뉴/HUD/장소 이름/수호자 경고 및 기본 GUI 폰트에 적용. 두 폰트의 Godot import 설정에서 allow_system_fallback=false. 폰트 자체는 수정하지 않았다. 이미지 생성 자산과 다른 외부 폰트 자산이다.

출처: [Google Fonts Nanum Gothic](https://github.com/google/fonts/tree/133ccbee9a8b408eb71f31a36ccb9116f5c695ad/ofl/nanumgothic). 고정 커밋 133ccbee9a8b408eb71f31a36ccb9116f5c695ad. [원문 라이선스](https://raw.githubusercontent.com/google/fonts/133ccbee9a8b408eb71f31a36ccb9116f5c695ad/ofl/nanumgothic/OFL.txt)는 SIL OFL 1.1이며 저작권 고지와 전문을 함께 배포한다. scripts/license_report.gd가 ZIP의 THIRD_PARTY_LICENSES.txt에 두 폰트 표기와 전문을 추가한다. 폰트 단독 판매 없음.

SHA256:

| 파일 | SHA256 |
| --- | --- |
| NanumGothic-Regular.ttf | 76F45EF4A6BCFF344C837C95A7DCC26E017E38B5846D5AE0CDCB5B86BE2E2D31 |
| NanumGothic-Bold.ttf | F96298F9FB18E364D2370F4C3CE948AC67A2B61AF992D7234BC15C42B033C674 |
| OFL.txt | EEACF16032901D0ED0456876EC77B8F0FDA6B3FECEC7D972F8543EB602E6C30F |

검증: 소스 환경 font_coverage는 game/*.gd에 있는 한글 음절과 주요 UI 기호/영문/숫자의 지원을 양쪽 폰트에서 확인한다. 배포본에는 소스가 없으므로 고정 한글/기호 샘플과 OS 대체 비활성화만 확인한다. 모든 유니코드·다국어 지원을 주장하지 않는다.

GPU 960×600 demo_flow21, 1600×900 waterworks_note13 통과. 작은 도입 화면과 큰 기록 마지막 문단 실PNG 확인. 기존 canvas_items 확대로 레이아웃을 유지했으며 창 크기/카메라 설정 코드를 바꾸지 않았다. 다른 PC/DPI/전체화면 실전환은 별도 검증 대상이다.

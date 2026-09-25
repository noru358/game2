# 실행과 재포장

현재 게임: `experiments/terrace/project.godot`,0.10-core-response. Godot4.7.2로import한뒤실행한다. 같은버전의export templates는별도설치한다. 소스팩에는실행본/엔진/실제저장이없다.

주인공기준은 [이번사용자시트](design_refs/hero_turnaround_approved.png). 과거19참고/개별PNG4수리절차는폐기됐다. 현재참고는주인공1+적3+지면4=8장이다. 런타임PNG18은기존임시자산이다.

재포장도구는현재파일바이트와누적로그를그대로보존하고누락자원/문서링크를실패로알린다. 빠진링크를설명문구로숨기지않는다. PACKAGE_MANIFEST와ZIP CRC/각파일SHA를검증한다. 버전/날짜는명시인자다.

V4감사때core_response6/여정GPU28통과. V5정리검증은WORK_LOG에별도기록한다. 기능통과는사람체감/미술통합/Mac실기보증이아니다.

Mac배포스크립트는아직원작업공간.tools배치와 builds/THIRD_PARTY_LICENSES.txt를요구한다. 라이선스생성도구미포함이므로표준엔진설치만으로포장이완결되었다고하지않는다. 다음배포작업에서경로인자화/라이선스생성까지수리해야한다. 현재요청은미술기준과자료정리이며Mac빌드완료를주장하지않는다.

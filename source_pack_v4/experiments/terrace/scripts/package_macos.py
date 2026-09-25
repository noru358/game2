"""Package the current universal macOS app without changing signed bundle bytes."""

from pathlib import Path
import hashlib
import json
import plistlib
import struct
import zipfile


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "builds/ExperienceLab-0.10-macos-app.zip"
OUTPUT = ROOT / "builds/ExperienceLab-0.10-macos-universal.zip"
REPORT = ROOT / "builds/manifest-0.10-macos.json"
FINAL_BUNDLE = "ExperienceLab.app"

README = """물길의 단상 · Experience Lab — macOS 0.10 체감 확인본

1. ZIP 전체를 압축 해제합니다.
2. ExperienceLab.app을 더블클릭합니다. Godot 설치는 필요 없습니다.
3. 처음 실행이 차단되면 시스템 설정 > 개인정보 보호 및 보안에서
   해당 앱의 '확인 없이 열기 / Open Anyway'를 선택하고 다시 엽니다.

Intel: macOS 11 이상 / Apple Silicon: macOS 13 이상.
두 CPU용 실행 파일이 함께 든 universal 앱입니다.
개발용 ad-hoc 서명이며 Apple 공증은 하지 않았습니다.
Windows에서 패키지 구조와 공통 게임 데이터를 검사했으며 Mac 실기 실행은 별도 확인이 필요합니다.

WASD/방향키 이동, Space/Shift 회피, J 직접 마법, F 상호작용, Esc 메뉴.
가까운 적은 자동 마법이 공격합니다.

0.10 확인 항목:
- 짧게 이동한 뒤 정지와 방향 반전
- J를 눌렀다 떼며 회복 초반에 다음 J를 눌러 2·3타 연결
- 공격 중 회피로 연타 예약 취소
- 자동 마법과 직접 공격, 밀치기, 실제 소리

저장: ~/Library/Application Support/FirstTrailExperienceLab/journey_v2.json
이 빌드는 Packet 1 체감 후보이며 완성 데모나 macOS 정식 지원 약속이 아닙니다.
"""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def verify_universal_macho(binary: bytes) -> list[str]:
    assert struct.unpack_from(">I", binary)[0] == 0xCAFEBABE, "Not a universal Mach-O"
    count = struct.unpack_from(">I", binary, 4)[0]
    arches = [struct.unpack_from(">IIIII", binary, 8 + i * 20) for i in range(count)]
    names = {0x01000007: "x86_64", 0x0100000C: "arm64"}
    assert {arch[0] for arch in arches} == set(names), "Expected x86_64 and arm64"
    for cpu, _subtype, offset, size, _align in arches:
        assert struct.unpack_from("<I", binary, offset)[0] == 0xFEEDFACF
        commands = struct.unpack_from("<I", binary, offset + 16)[0]
        position = offset + 32
        signed = False
        for _ in range(commands):
            command, command_size = struct.unpack_from("<II", binary, position)
            assert command_size >= 8
            if command == 0x1D:
                data_offset, data_size = struct.unpack_from("<II", binary, position + 8)
                assert data_size > 0 and data_offset + data_size <= size
                signed = True
            position += command_size
        assert signed, f"Missing embedded signature for {names[cpu]}"
    return [names[arch[0]] for arch in arches]


with zipfile.ZipFile(SOURCE) as source, zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as target:
    assert source.testzip() is None, "Raw export ZIP CRC failed"
    plist_names = [name for name in source.namelist() if name.endswith("/Contents/Info.plist")]
    assert len(plist_names) == 1
    plist_name = plist_names[0]
    source_bundle = plist_name.split("/")[0]
    plist = plistlib.loads(source.read(plist_name))
    assert plist["CFBundleIdentifier"] == "org.firsttrail.experiencelab"
    assert plist["CFBundleShortVersionString"] == "0.10.0"
    executable = source_bundle + "/Contents/MacOS/" + plist["CFBundleExecutable"]
    architectures = verify_universal_macho(source.read(executable))
    assert source.getinfo(executable).external_attr >> 16 & 0o111
    assert any(name.endswith("/_CodeSignature/CodeResources") for name in source.namelist())
    assert any(name.endswith(".pck") for name in source.namelist())

    for info in source.infolist():
        data = source.read(info.filename)
        info.filename = FINAL_BUNDLE + info.filename[len(source_bundle):]
        target.writestr(info, data)

    extras = {
        "README.txt": README.encode("utf-8"),
        "THIRD_PARTY_LICENSES.txt": (ROOT / "builds/THIRD_PARTY_LICENSES.txt").read_bytes(),
    }
    for name, data in extras.items():
        info = zipfile.ZipInfo(name)
        info.create_system = 3
        info.external_attr = 0o100644 << 16
        target.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)

with zipfile.ZipFile(OUTPUT) as package:
    assert package.testzip() is None, "Final ZIP CRC failed"
    final_executable = executable.replace(source_bundle, FINAL_BUNDLE, 1)
    assert package.getinfo(final_executable).external_attr >> 16 & 0o111
    members = package.namelist()
    assert "README.txt" in members and "THIRD_PARTY_LICENSES.txt" in members

report = {
    "version": "0.10-core-response",
    "file": OUTPUT.name,
    "sha256": sha256(OUTPUT),
    "zip_bytes": OUTPUT.stat().st_size,
    "bundle": FINAL_BUNDLE,
    "bundle_identifier": "org.firsttrail.experiencelab",
    "architectures": architectures,
    "minimum_macos": {"x86_64": "11.0", "arm64": "13.0"},
    "embedded_signature_present": True,
    "notarized": False,
    "mac_runtime_tested": False,
    "common_game_data_tested_on_windows": False,
}
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, ensure_ascii=False, indent=2))

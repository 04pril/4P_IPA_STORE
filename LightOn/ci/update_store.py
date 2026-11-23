#!/usr/bin/env python3
"""Publish LightOn only after its unsigned IPA has actually been uploaded."""
import datetime
import json
import os
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
source_path = repo_root / 'source.json'
source = json.loads(source_path.read_text(encoding='utf-8'))
release = 'https://github.com/04pril/4P_IPA_STORE/releases/download/lighton-v0.1.0/LightOn-v0.1.0-unsigned.ipa'
ipa_path = Path(os.environ['LIGHTON_IPA_PATH'])
size = ipa_path.stat().st_size
now = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z')
app = {
    'name': 'LightOn',
    'bundleIdentifier': '04prillighton',
    'developerName': '04pril',
    'subtitle': 'HFKJ 조명 제어 · 위젯 · 단축어',
    'localizedDescription': 'HFKJ BLE 패킷으로 조명을 켜거나 끕니다. 통합 전원 버튼, 홈 화면 위젯, 단축어 켜기/끄기/전환을 지원합니다. Bluetooth 권한이 필요합니다.',
    'iconURL': 'https://raw.githubusercontent.com/04pril/4P_IPA_STORE/main/LightOn/LightOn/Assets.xcassets/AppIcon.appiconset/Icon-1024.png',
    'version': '0.1.0',
    'versionDate': now,
    'downloadURL': release,
    'size': size,
    'versions': [{
        'version': '0.1.0', 'date': now,
        'localizedDescription': 'LightOn 첫 공개 빌드: 통합 전원 버튼, 위젯, 단축어 지원.',
        'downloadURL': release, 'size': size
    }]
}
apps = source['apps']
for i, old in enumerate(apps):
    if old.get('bundleIdentifier') == app['bundleIdentifier']:
        if old.get('downloadURL') == release and old.get('size') == size:
            print('Store entry already current')
            raise SystemExit(0)
        apps[i] = app
        break
else:
    apps.append(app)
source_path.write_text(json.dumps(source, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Updated Feather/AltStore source.json LightOn entry')

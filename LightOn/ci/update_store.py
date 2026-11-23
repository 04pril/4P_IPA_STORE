#!/usr/bin/env python3
"""Publish LightOn only after its unsigned IPA has actually been uploaded."""
import datetime
import json
import os
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
source_path = repo_root / 'source.json'
source = json.loads(source_path.read_text(encoding='utf-8'))
release = 'https://github.com/04pril/4P_IPA_STORE/releases/download/lighton-v0.2.0/LightOn-v0.2.0-unsigned.ipa'
ipa_path = Path(os.environ['LIGHTON_IPA_PATH'])
size = ipa_path.stat().st_size
now = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z')
app = {
    'name': 'LightOn',
    'bundleIdentifier': '04prillighton',
    'developerName': '04pril',
    'subtitle': 'HFKJ 조명 제어 · 위젯 · 단축어',
    'localizedDescription': 'HFKJ BLE ON/OFF 패킷, 한 버튼 전환, 개별 ON/OFF, 앱 화면 열지 않는 인터랙티브 위젯과 단축어 실험 지원. iOS 백그라운드 BLE 광고 제한으로 실제 조명 동작은 보장되지 않습니다.',
    'iconURL': 'https://raw.githubusercontent.com/04pril/4P_IPA_STORE/main/LightOn/LightOn/Assets.xcassets/AppIcon.appiconset/Icon-1024.png',
    'version': '0.2.0',
    'versionDate': now,
    'downloadURL': release,
    'size': size,
    'versions': [{
        'version': '0.2.0', 'date': now,
        'localizedDescription': 'LightOn 0.2 실험 빌드: 작은 화면 UI 개선, 개별 ON/OFF, 무오픈 위젯과 단축어 시도.',
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

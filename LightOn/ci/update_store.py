#!/usr/bin/env python3
"""Publish LightOn only after its unsigned IPA has actually been uploaded."""
import datetime
import json
import os
from pathlib import Path

repo_root = Path(__file__).resolve().parents[2]
source_path = repo_root / 'source.json'
source = json.loads(source_path.read_text(encoding='utf-8'))
release = 'https://github.com/04pril/4P_IPA_STORE/releases/download/lighton-v0.3.0/LightOn-v0.3.0-unsigned.ipa'
ipa_path = Path(os.environ['LIGHTON_IPA_PATH'])
size = ipa_path.stat().st_size
now = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z')
app = {
    'name': 'LightOn',
    'bundleIdentifier': '04prillighton',
    'developerName': '04pril',
    'subtitle': 'HFKJ 조명 제어 · 위젯 · 단축어',
    'localizedDescription': 'HFKJ BLE 제어: 통합 전환 및 개별 ON/OFF, 단축어/위젯 무오픈 실험, iOS 26+ Live Activity 백그라운드 광고 실험. 실제 기기 검증 필요.',
    'iconURL': 'https://raw.githubusercontent.com/04pril/4P_IPA_STORE/main/LightOn/LightOn/Assets.xcassets/AppIcon.appiconset/Icon-1024.png',
    'version': '0.3.0',
    'versionDate': now,
    'downloadURL': release,
    'size': size,
    'versions': [{
        'version': '0.3.0', 'date': now,
        'localizedDescription': 'LightOn v0.3 실험: Live Activity를 켜고 무오픈 위젯과 단축어 BLE 제어 테스트.',
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

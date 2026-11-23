# LightOn v0.3.0 — Live Activity background BLE experiment

Apple documents that since iOS 26 an app with an instantiated `CBManager` and a Live Activity started **before going to background** can continue certain Bluetooth tasks with the same privileges as in foreground. See: https://developer.apple.com/documentation/corebluetooth

**Important:** Apple explicitly mentions scanning; whether this also preserves the 13 HFKJ advertisement UUIDs sent by `CBPeripheralManager.startAdvertising` is **not verified**. If iOS sends them in overflow format the lamp will not respond. This release is a real-device experiment, not a guaranteed fix.

## Test on iOS 26/27

1. Sign and install `LightOn-v0.3.0-unsigned.ipa` in Feather (widgets and Live Activities require correct extension signing).
2. Open LightOn, allow Bluetooth permissions, make sure it says Bluetooth is ready.
3. Tap **무오픈 BLE 실험 → 준비**; allow Live Activities in iOS settings if asked. A status will appear in the Dynamic Island / Lock Screen.
4. Press **켜기 / 끄기** in the app to confirm the previously-working HFKJ packets remain functional.
5. Leave the app open in background. From Home Screen use the one-button LightOn widget, or from Shortcuts run LightOn 전환 / 켜기 / 끄기, without reopening the app UI.
6. Verify **the physical lamp**. Advertising callback success alone is not proof of command reception. Also test when screen is locked/turned off, which may be more restricted.
7. Press **종료** to end the Live Activity. The normal foreground button and opening-app deep links continue to work regardless.

No server, jailbreak, or extra hardware is used. App bundle ID is `04prillighton`, widget bundle ID `04prillighton.widget`.

If background mode still fails, the reliable fallback is `lighton://toggle` opening LightOn or using an external BLE relay (such as ESP32) that broadcasts the original HFKJ bytes. There is no supported generic iOS API to broadcast arbitrary HFKJ data from a widget with guaranteed foreground advertising semantics.

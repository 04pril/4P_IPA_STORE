# LightOn v0.2.0 — headless experiment

- Bundle ID: `04prillighton`
- iOS 17+ / HFKJ BLE service UUID advertising (ON 0xB3, OFF 0xB2).
- Main screen: large toggle, dedicated ON/OFF controls, scrolling on smaller displays.
- Interactive Home Screen small widget and Lock Screen circular widget: a single `Button(intent: LightToggleIntent())`.
- Shortcuts: LightOn 전환, LightOn 켜기, LightOn 끄기. Intents have `openAppWhenRun = false` and use `ForegroundContinuableIntent` in the app target, attempting execution in the app's background process.
- These actions wait for CoreBluetooth advertising completion or an error/timeout rather than returning immediately.
- Legacy deep links `lighton://toggle`, `lighton://on`, `lighton://off` remain for fallback, but open the app.

## Important limitation (read before testing)

This is an **experiment**, not a guarantee of no-open switching.
iOS changes BLE advertising behavior when an app is not in the foreground. Service UUIDs may move to the overflow area, which a lamp relying on standard foreground advertising may not recognize. CoreBluetooth accepting an advertising request is NOT an acknowledgement that the lamp received it.

On first installation open LightOn once and grant Bluetooth permission. To test, keep LightOn in the background, toggle from Shortcuts, then from the Home Screen widget. Check that the **physical light** changed. If it fails but foreground works, iOS background BLE restrictions are the likely cause.

Widget and Shortcuts intents share the containing app process on supported OS configurations via `ForegroundContinuableIntent`; the same intent source, controller and protocol are included in the widget for type visibility and extension-side compilation. Intent execution is limited by OS policy.

The actual lamp power is not queried. Toggle uses the last accepted advertising command. An external remote can desync it; use the menu in LightOn to correct assumed state.

## Build

Use GitHub Actions → **Build LightOn unsigned IPA**, or:

```sh
cd LightOn
swiftc LightOn/HFKJProtocol.swift Tests/PacketTest.swift -o /tmp/hfkj-test && /tmp/hfkj-test
xcodegen generate --spec project.yml
xcodebuild -project LightOn.xcodeproj -scheme LightOn -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

A successful main branch build publishes `LightOn-v0.2.0-unsigned.ipa` as a GitHub Release and updates the Feather source. Sign in Feather; extension signing support is required for widgets.

# LightOn

Minimal iOS 17+ HFKJ BLE advertising controller, based on the tested ZhimeiLightSwitch v0.6.

- **App name:** `LightOn`
- **Main bundle identifier:** `04prillighton` (requested verbatim)
- **Widget identifier:** `04prillighton.widget`
- **Main app:** one large ON/OFF toggle. Optional `…` menu corrects last-command state if another controller was used.
- **Home Screen widget:** one button; tapping launches `lighton://toggle` in the containing app and sends the appropriate command. The widget does not directly use Bluetooth.
- **Lock Screen circular widget:** also toggles through the containing app.
- **Shortcuts:** `LightOn 전환`, `LightOn 켜기`, `LightOn 끄기` (App Intents). These activate the app so its BLE advertising sender can operate.
- **Deep links:** `lighton://toggle`, `lighton://on`, `lighton://off`.

## Protocol

HFKJ commands ON=`0xB3`, OFF=`0xB2`. For each command a changing 8-bit counter is used with the verified HFKJ 16-byte encoder and CRC16-CCITT 0x1021, padded to 26 bytes, and advertised as 13 16-bit service UUIDs five times (roughly 0.35 seconds apart).

The first dynamic `0xB3` packet at counter `0x2E` is **identical** to Sample A, confirmed working in real-world tests. The `0xB2` generation is reconstructed from the successful v0.6 binary.

Run packet regression tests on Linux/macOS (no Xcode needed):

```sh
swiftc LightOn/HFKJProtocol.swift Tests/PacketTest.swift -o /tmp/lighton-packet-test
/tmp/lighton-packet-test
```

## Build IPA via GitHub Actions

Run the **Build LightOn unsigned IPA** workflow. It builds on a macOS GitHub runner, packages the containing app **and its WidgetKit extension**, then uploads the unsigned IPA as an Actions artifact. A push to `main` also publishes it as a GitHub release and adds/updates the entry in the Feather/AltStore `source.json`.

Unsigned IPA requires signing on-device using Feather or another supported signing method. The installed signing profile must support app extensions; some sideloading providers do not support widgets. Launch the app once and grant Bluetooth permission before using the widget or Shortcuts.

## Important limitation

This lighting protocol advertises commands but does **not** provide reliable physical ON/OFF feedback. Toggle refers to the **last advertising command accepted by iOS**, not a confirmed physical lamp status. An external remote, another phone, or unsuccessful RF reception can desynchronize it. Use the app's `…` menu to correct the assumed state. Direct background BLE from a widget is not implemented because iOS does not guarantee a widget extension enough Bluetooth advertising execution time. The widget opens the app to perform the operation.

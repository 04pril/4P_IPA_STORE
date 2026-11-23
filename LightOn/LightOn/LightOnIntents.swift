import AppIntents

/// ForegroundContinuableIntent executes the widget action in the containing
/// app's process without forcing its user interface to appear on iOS 17+.
/// Deprecated on newer SDKs, but intentionally retained for iOS 17 support.
/// The system can still refuse background Bluetooth advertising.
struct LightOnIntent: AppIntent, ForegroundContinuableIntent {
    static var title: LocalizedStringResource = "LightOn 켜기"
    static var description = IntentDescription("앱 화면을 열지 않고 HFKJ BLE 켜기 신호를 시도합니다.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = try await LampController.shared.sendAndWait(.on)
        return .result()
    }
}

struct LightOffIntent: AppIntent, ForegroundContinuableIntent {
    static var title: LocalizedStringResource = "LightOn 끄기"
    static var description = IntentDescription("앱 화면을 열지 않고 HFKJ BLE 끄기 신호를 시도합니다.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = try await LampController.shared.sendAndWait(.off)
        return .result()
    }
}

struct LightToggleIntent: AppIntent, ForegroundContinuableIntent {
    static var title: LocalizedStringResource = "LightOn 전환"
    static var description = IntentDescription("마지막 명령 기준으로 앱 화면을 열지 않고 전원 전환을 시도합니다.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = try await LampController.shared.sendAndWait(.toggle)
        return .result()
    }
}

import AppIntents

/// ForegroundContinuableIntent executes the widget action in the containing
/// app's process without forcing its user interface to appear on iOS 17+.
/// Deprecated on newer SDKs, but intentionally retained for iOS 17 support.
/// The system can still refuse background Bluetooth advertising.
struct LightOnIntent: AppIntent {
    static var title: LocalizedStringResource = "LightOn 켜기"
    static var description = IntentDescription("앱 화면을 열지 않고 HFKJ BLE 켜기 신호를 시도합니다.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = try await LampController.shared.sendAndWait(.on)
        return .result()
    }
}

struct LightOffIntent: AppIntent {
    static var title: LocalizedStringResource = "LightOn 끄기"
    static var description = IntentDescription("앱 화면을 열지 않고 HFKJ BLE 끄기 신호를 시도합니다.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = try await LampController.shared.sendAndWait(.off)
        return .result()
    }
}

struct LightToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "LightOn 전환"
    static var description = IntentDescription("마지막 명령 기준으로 앱 화면을 열지 않고 전원 전환을 시도합니다.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = try await LampController.shared.sendAndWait(.toggle)
        return .result()
    }
}

 // ForegroundContinuableIntent is available to the containing app, but marked
 // unavailable to iOS application extensions. The app's conformance asks the
 // system to execute widget actions inside the app process without UI.
 @available(iOSApplicationExtension, unavailable)
 extension LightOnIntent: ForegroundContinuableIntent {}
 @available(iOSApplicationExtension, unavailable)
 extension LightOffIntent: ForegroundContinuableIntent {}
 @available(iOSApplicationExtension, unavailable)
 extension LightToggleIntent: ForegroundContinuableIntent {}

import AppIntents

struct LightOnIntent: AppIntent {
    static var title: LocalizedStringResource = "LightOn 켜기"
    static var description = IntentDescription("HFKJ BLE 신호로 조명을 켭니다.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        try LampController.shared.send(.on)
        return .result()
    }
}

struct LightOffIntent: AppIntent {
    static var title: LocalizedStringResource = "LightOn 끄기"
    static var description = IntentDescription("HFKJ BLE 신호로 조명을 끕니다.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        try LampController.shared.send(.off)
        return .result()
    }
}

struct LightToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "LightOn 전환"
    static var description = IntentDescription("마지막 조명 명령을 기준으로 켜기 또는 끄기를 실행합니다.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        try LampController.shared.send(.toggle)
        return .result()
    }
}

struct LightOnShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LightToggleIntent(),
            phrases: ["Toggle the light with \(.applicationName)"],
            shortTitle: "전원 전환",
            systemImageName: "power"
        )
        AppShortcut(
            intent: LightOnIntent(),
            phrases: ["Turn on the light with \(.applicationName)"],
            shortTitle: "조명 켜기",
            systemImageName: "lightbulb.fill"
        )
        AppShortcut(
            intent: LightOffIntent(),
            phrases: ["Turn off the light with \(.applicationName)"],
            shortTitle: "조명 끄기",
            systemImageName: "lightbulb.slash.fill"
        )
    }
}

import AppIntents

/// Keep AppShortcutsProvider in the containing app only, while making the
/// intent types available to both the app and the interactive widget target.
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

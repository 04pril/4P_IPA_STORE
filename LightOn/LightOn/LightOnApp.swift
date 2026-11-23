import SwiftUI

@main
struct LightOnApp: App {
    var body: some Scene {
        WindowGroup {
            LightOnView()
                .onOpenURL { url in
                    guard url.scheme?.lowercased() == "lighton" else { return }
                    let action: LightAction
                    switch url.host?.lowercased() {
                    case "on": action = .on
                    case "off": action = .off
                    case "toggle": action = .toggle
                    default: return
                    }
                    do {
                        try LampController.shared.send(action)
                    } catch {
                        LampController.shared.showError(error)
                    }
                }
        }
    }
}

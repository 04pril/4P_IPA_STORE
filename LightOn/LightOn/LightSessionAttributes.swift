import ActivityKit
import Foundation

/// Shared between the app and WidgetKit extension.
struct LightSessionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
    }

    var title: String
}

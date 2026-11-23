import SwiftUI
import WidgetKit

private struct PowerEntry: TimelineEntry {
    let date: Date
}

private struct PowerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PowerEntry { PowerEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (PowerEntry) -> Void) {
        completion(PowerEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PowerEntry>) -> Void) {
        completion(Timeline(entries: [PowerEntry(date: .now)], policy: .never))
    }
}

private struct PowerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    private let accent = Color(red: 1.0, green: 0.77, blue: 0.30)

    var body: some View {
        Group {
            if family == .accessoryCircular {
                Image(systemName: "power")
                    .font(.system(size: 30, weight: .medium))
                    .widgetAccentable()
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("LightOn")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Spacer()
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(accent)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "power")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(accent)
                    Spacer(minLength: 0)
                    Text("전원 전환")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { Color(uiColor: .secondarySystemGroupedBackground) }
        .widgetURL(URL(string: "lighton://toggle"))
        .accessibilityLabel("LightOn 전원 전환. 누르면 앱을 열고 조명 신호를 보냅니다.")
    }
}

@main
struct LightOnWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LightOnPowerWidget", provider: PowerProvider()) { _ in
            PowerWidgetView()
        }
        .configurationDisplayName("LightOn 전원")
        .description("하나의 버튼으로 조명 전원을 켜고 끕니다. 조명 제어를 위해 LightOn을 엽니다.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

import SwiftUI
import WidgetKit
import AppIntents
import ActivityKit

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
        Button(intent: LightToggleIntent()) {
            Group {
                if family == .accessoryCircular {
                    Image(systemName: "power")
                        .font(.system(size: 30, weight: .medium))
                        .widgetAccentable()
                } else {
                    VStack(spacing: 10) {
                        HStack {
                            Text("LightOn")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Spacer()
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(accent)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "power")
                            .font(.system(size: 49, weight: .medium))
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemGroupedBackground)
        }
        .accessibilityLabel("LightOn 전원 전환. 앱 화면을 열지 않고 신호 전송을 시도합니다.")
    }
}

struct LightOnWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LightOnPowerWidget", provider: PowerProvider()) { _ in
            PowerWidgetView()
        }
        .configurationDisplayName("LightOn 전원")
        .description("통합 전원 버튼입니다. 앱을 열지 않는 BLE 광고는 iOS 환경에 따라 실패할 수 있습니다.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}


/// A visible ongoing activity is required for the iOS 26+ CoreBluetooth test.
/// This is separate from the one-button Home Screen widget.
struct LightOnLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LightSessionAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("LightOn · BLE 실험")
                        .font(.headline)
                    Text(context.state.status)
                        .font(.caption)
                }
                Spacer()
                Image(systemName: "antenna.radiowaves.left.and.right")
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.84))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(context.state.status)
                            .font(.subheadline)
                    }
                }
            } compactLeading: {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
            } compactTrailing: {
                Text("BLE")
            } minimal: {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

@main
struct LightOnWidgets: WidgetBundle {
    var body: some Widget {
        LightOnWidget()
        LightOnLiveActivityWidget()
    }
}

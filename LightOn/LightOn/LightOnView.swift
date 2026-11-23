import SwiftUI

struct LightOnView: View {
    @StateObject private var lamp = LampController.shared
    @StateObject private var session = LightSessionController.shared
    @Environment(\.scenePhase) private var scenePhase
    private let accent = Color(red: 1.0, green: 0.77, blue: 0.30)

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 650
            ScrollView {
                VStack(spacing: compact ? 13 : 20) {
                    header
                    Spacer(minLength: compact ? 8 : 18)
                    primaryButton(diameter: compact ? 170 : 214)
                    HStack(spacing: 12) {
                        Button(action: { send(.on) }) {
                            Label("켜기", systemImage: "lightbulb.fill")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accent)

                        Button(action: { send(.off) }) {
                            Label("끄기", systemImage: "lightbulb.slash")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                    .disabled(lamp.isSending)
                    if #available(iOS 26.0, *) { liveSessionControl }
                    Spacer(minLength: compact ? 8 : 20)
                    statusFooter
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: max(0, geometry.size.height - 28))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { session.refresh() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { session.refresh() }
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("LightOn")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                Text("한 번 누르면 전원 전환")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("실제 조명 켜짐으로 맞추기", systemImage: "lightbulb.fill") {
                    lamp.setAssumedState(true)
                }
                Button("실제 조명 꺼짐으로 맞추기", systemImage: "lightbulb.slash") {
                    lamp.setAssumedState(false)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("상태 보정")
        }
    }

    private func primaryButton(diameter: CGFloat) -> some View {
        Button(action: { send(.toggle) }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(lamp.lastStateOn == true ? accent.opacity(0.12) : Color.secondary.opacity(0.08))
                        .frame(width: diameter, height: diameter)
                    Circle()
                        .strokeBorder(lamp.lastStateOn == true ? accent.opacity(0.6) : Color.secondary.opacity(0.18), lineWidth: 2)
                        .frame(width: diameter - 22, height: diameter - 22)
                    Image(systemName: "power")
                        .font(.system(size: diameter * 0.36, weight: .medium))
                        .foregroundStyle(lamp.lastStateOn == true ? accent : .primary)
                        .shadow(color: lamp.lastStateOn == true ? accent.opacity(0.35) : .clear, radius: 16)
                }
                .scaleEffect(lamp.isSending ? 0.96 : 1)
                .animation(.easeInOut(duration: 0.2), value: lamp.isSending)

                VStack(spacing: 6) {
                    Text(lamp.lastStateOn == nil ? "상태 미확인" : (lamp.lastStateOn == true ? "켜짐" : "꺼짐"))
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                    Text(lamp.isSending ? "신호 전송 중" : "터치해서 \(lamp.lastStateOn == true ? "끄기" : "켜기")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(lamp.isSending)
        .accessibilityLabel("조명 전원 전환")
        .accessibilityHint("마지막 전송 상태를 기준으로 켜거나 끕니다")
    }

    private var liveSessionControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("무오픈 BLE 실험")
                        .font(.subheadline.weight(.semibold))
                    Text("Live Activity로 백그라운드 송신 시도")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button(session.isActive ? "종료" : "준비") {
                    if session.isActive { session.stop() }
                    else { session.start() }
                }
                .buttonStyle(.bordered)
            }
            Text(session.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("iOS 26+ 실험 기능. 조명 반응을 보장하지 않습니다.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var statusFooter: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                Circle()
                    .fill(lamp.isReady ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(lamp.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Text("실제 조명 응답은 읽지 못합니다. 마지막으로 전송 요청한 상태입니다.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Text("최근 BLE 진단: \(lamp.lastDiagnostic)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("위젯 · 단축어 무오픈 실행은 실험 기능입니다.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func send(_ action: LightAction) {
        do { try lamp.send(action) }
        catch { lamp.showError(error) }
    }
}

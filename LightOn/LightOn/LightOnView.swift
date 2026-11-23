import SwiftUI

struct LightOnView: View {
    @StateObject private var lamp = LampController.shared
    private let accent = Color(red: 1.0, green: 0.77, blue: 0.30)

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LightOn")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
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
                .padding(.top, 30)

                Spacer()

                Button(action: toggle) {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(lamp.lastStateOn == true ? accent.opacity(0.12) : Color.secondary.opacity(0.08))
                                .frame(width: 242, height: 242)
                            Circle()
                                .strokeBorder(lamp.lastStateOn == true ? accent.opacity(0.6) : Color.secondary.opacity(0.18), lineWidth: 2)
                                .frame(width: 216, height: 216)
                            Image(systemName: "power")
                                .font(.system(size: 88, weight: .medium))
                                .foregroundStyle(lamp.lastStateOn == true ? accent : .primary)
                                .shadow(color: lamp.lastStateOn == true ? accent.opacity(0.35) : .clear, radius: 20)
                        }
                        .scaleEffect(lamp.isSending ? 0.96 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: lamp.isSending)

                        VStack(spacing: 7) {
                            Text(lamp.lastStateOn == nil ? "상태 미확인" : (lamp.lastStateOn == true ? "켜짐" : "꺼짐"))
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
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

                Spacer()

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(lamp.isReady ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(lamp.statusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Text("실제 전등 상태는 읽지 못합니다. 마지막으로 보낸 명령을 표시합니다.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 25)
            }
            .padding(.horizontal, 26)
        }
    }

    private func toggle() {
        do { try lamp.send(.toggle) }
        catch { lamp.showError(error) }
    }
}

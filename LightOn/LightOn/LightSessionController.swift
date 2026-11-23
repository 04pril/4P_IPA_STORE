import ActivityKit
import Combine
import Foundation

/// iOS 26+ experiment: Apple documents foreground-equivalent CoreBluetooth
/// privileges for an app with an instantiated CBManager and active Live Activity.
/// Whether this also preserves HFKJ service-UUID advertising must be confirmed
/// with the physical light; ActivityKit alone is NOT a protocol workaround.
@MainActor
final class LightSessionController: ObservableObject {
    static let shared = LightSessionController()

    @Published private(set) var isActive = false
    @Published private(set) var statusText = "활성화하면 Live Activity가 잠금 화면에 표시됩니다."
    private init() {
        refresh()
    }

    func refresh() {
        isActive = !Activity<LightSessionAttributes>.activities.isEmpty
        if isActive {
            statusText = "Live Activity 활성화됨 · 위젯/단축어 무오픈 테스트 가능"
        }
    }

    func start() {
        guard #available(iOS 26.0, *) else {
            statusText = "이 실험은 iOS 26 이상에서만 지원합니다."
            return
        }
        // Apple's iOS 26 CoreBluetooth guidance requires CBManager to be
        // instantiated BEFORE the Live Activity is started in foreground.
        let lamp = LampController.shared
        guard lamp.isReady else {
            statusText = "먼저 Bluetooth 권한을 허용하고 연결 준비가 끝났는지 확인하세요."
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusText = "설정에서 LightOn의 실시간 현황(Live Activities)을 켜주세요."
            return
        }
        if !Activity<LightSessionAttributes>.activities.isEmpty {
            refresh()
            return
        }
        do {
            _ = try Activity<LightSessionAttributes>.request(
                attributes: LightSessionAttributes(title: "LightOn BLE"),
                content: .init(
                    state: LightSessionAttributes.ContentState(status: "조명 제어 준비"),
                    staleDate: nil
                ),
                pushType: nil
            )
            refresh()
        } catch {
            statusText = "Live Activity 시작 실패: \(error.localizedDescription)"
        }
    }

    func stop() {
        Task { @MainActor in
            for activity in Activity<LightSessionAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            isActive = false
            statusText = "Live Activity 종료됨."
        }
    }
}

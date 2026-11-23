import Foundation
import CoreBluetooth
import Combine

enum LightAction: String {
    case on, off, toggle

    var label: String {
        switch self {
        case .on: return "켜기"
        case .off: return "끄기"
        case .toggle: return "전환"
        }
    }
}

enum LightError: LocalizedError {
    case bluetoothUnavailable
    case alreadySending
    case timedOut
    case advertisingFailed(String)

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth가 꺼져 있거나 사용 권한이 없습니다."
        case .alreadySending:
            return "전송 중입니다. 잠시 후 다시 눌러주세요."
        case .timedOut:
            return "BLE 광고 시작을 기다리다가 시간 초과되었습니다."
        case .advertisingFailed(let message):
            return message
        }
    }
}

/// The physical lamp never sends a power acknowledgement. This model only tracks
/// commands whose first CoreBluetooth advertising request was accepted by iOS.
/// Intents run in the containing app process (ForegroundContinuableIntent).
@MainActor
final class LampController: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    static let shared = LampController()

    @Published private(set) var statusText = "Bluetooth 준비 중…"
    @Published private(set) var isReady = false
    @Published private(set) var isSending = false
    @Published private(set) var lastStateOn: Bool?
    @Published private(set) var lastDiagnostic = UserDefaults.standard.string(forKey: "lighton.lastDiagnostic") ?? "기록 없음"

    private let stateKey = "lighton.lastRequestedPower"
    private let counterKey = "lighton.nextHFKJCounter"
    private var manager: CBPeripheralManager!
    private var frames: [[CBUUID]] = []
    private var timer: Timer?
    private var pendingAction: LightAction?
    private var firstAdvertisementAccepted = false

    // Keep the App Intent alive until all repeats finish (or an explicit error).
    private var completion: CheckedContinuation<LightAction, Error>?
    private var timeoutTask: Task<Void, Never>?

    private override init() {
        lastStateOn = UserDefaults.standard.object(forKey: stateKey) as? Bool
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }

    private func recordDiagnostic(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let log = "\(timestamp) · \(message)"
        lastDiagnostic = log
        UserDefaults.standard.set(log, forKey: "lighton.lastDiagnostic")
    }

    func showError(_ error: Error) {
        statusText = error.localizedDescription
        recordDiagnostic("오류: \(error.localizedDescription)")
    }

    func setAssumedState(_ on: Bool) {
        guard !isSending else { return }
        lastStateOn = on
        UserDefaults.standard.set(on, forKey: stateKey)
        statusText = "상태 기준을 \(on ? "켜짐" : "꺼짐")으로 맞췄습니다."
    }

    /// Use from the app's foreground controls.
    @discardableResult
    func send(_ requestedAction: LightAction) throws -> LightAction {
        guard !isSending else { throw LightError.alreadySending }
        guard manager.state != .unsupported &&
              manager.state != .unauthorized &&
              manager.state != .poweredOff else {
            throw LightError.bluetoothUnavailable
        }

        let action: LightAction = requestedAction == .toggle
            ? (lastStateOn == true ? .off : .on)
            : requestedAction
        let defaults = UserDefaults.standard
        let counter = UInt8(truncatingIfNeeded: defaults.object(forKey: counterKey) as? Int ?? 0x2E)
        let command = action == .on ? HFKJProtocol.onCommand : HFKJProtocol.offCommand
        let frame = HFKJProtocol.serviceUUIDStrings(counter: counter, command: command)
            .map(CBUUID.init(string:))

        timer?.invalidate()
        timer = nil
        manager.stopAdvertising()
        frames = Array(repeating: frame, count: 5)
        pendingAction = action
        firstAdvertisementAccepted = false
        isSending = true
        statusText = "\(action.label) 신호 준비 중…"
        recordDiagnostic("\(action.label) 요청 · BLE 상태 \(manager.state.rawValue)")
        defaults.set(Int(counter &+ 1), forKey: counterKey)

        if manager.state == .poweredOn { sendNext() }
        return action
    }

    /// Used by Shortcuts and WidgetKit. Returning immediately after startAdvertising
    /// would allow iOS to suspend the intent before the five advertising attempts.
    /// A successful result means CoreBluetooth accepted advertising, NOT that the
    /// physical light received the HFKJ packet.
    func sendAndWait(_ action: LightAction) async throws -> LightAction {
        try await withCheckedThrowingContinuation { continuation in
            do {
                _ = try send(action)
                completion = continuation
                timeoutTask?.cancel()
                timeoutTask = Task { @MainActor [weak self] in
                    do { try await Task.sleep(nanoseconds: 8_000_000_000) }
                    catch { return }
                    self?.stopWithError(
                        "BLE 광고 전송 시간 초과 (앱 없이 실행할 수 없는 상태일 수 있습니다).",
                        error: .timedOut
                    )
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func sendNext() {
        guard manager.state == .poweredOn, isSending else { return }
        guard !frames.isEmpty else {
            let action = pendingAction
            let wasAccepted = firstAdvertisementAccepted
            finishAdvertising()
            if wasAccepted, let action {
                statusText = "BLE 광고 요청 완료 · 실제 조명 응답은 확인할 수 없습니다."
                recordDiagnostic("광고 5회 완료 (기기 수신 확인 아님)")
                finishIntent(.success(action))
            } else {
                let error = LightError.advertisingFailed("BLE 광고가 시작되지 않았습니다.")
                statusText = error.localizedDescription
                finishIntent(.failure(error))
            }
            return
        }

        manager.stopAdvertising()
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: frames.removeFirst()])
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.sendNext() }
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        isReady = (peripheral.state == .poweredOn)
        switch peripheral.state {
        case .poweredOn:
            if isSending { sendNext() }
            else { statusText = "Bluetooth 사용 가능" }
        case .poweredOff:
            stopWithError("Bluetooth가 꺼져 있습니다.", error: .bluetoothUnavailable)
        case .unauthorized:
            stopWithError("Bluetooth 접근 권한이 없습니다.", error: .bluetoothUnavailable)
        case .unsupported:
            stopWithError("BLE 광고를 지원하지 않는 기기입니다.", error: .bluetoothUnavailable)
        case .unknown, .resetting:
            statusText = "Bluetooth 준비 중…"
        @unknown default:
            statusText = "Bluetooth 상태를 알 수 없습니다."
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard isSending else { return }
        if let error {
            stopWithError(
                "광고 시작 실패: \(error.localizedDescription)",
                error: .advertisingFailed(error.localizedDescription)
            )
            return
        }
        if !firstAdvertisementAccepted, let action = pendingAction {
            firstAdvertisementAccepted = true
            let on = action == .on
            lastStateOn = on
            UserDefaults.standard.set(on, forKey: stateKey)
            statusText = "\(action.label) 신호 보내는 중…"
            recordDiagnostic("\(action.label) 광고 시작 콜백 성공")
        }
    }

    private func finishAdvertising() {
        timer?.invalidate()
        timer = nil
        frames.removeAll()
        manager?.stopAdvertising()
        isSending = false
        pendingAction = nil
    }

    private func stopWithError(_ message: String, error: LightError) {
        finishAdvertising()
        statusText = message
        recordDiagnostic("광고 오류: \(message)")
        finishIntent(.failure(error))
    }

    private func finishIntent(_ result: Result<LightAction, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        let continuation = completion
        completion = nil
        guard let continuation else { return }
        switch result {
        case .success(let action): continuation.resume(returning: action)
        case .failure(let error): continuation.resume(throwing: error)
        }
    }
}

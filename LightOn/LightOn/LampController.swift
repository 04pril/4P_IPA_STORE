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

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable: return "Bluetooth가 꺼져 있거나 사용 권한이 없습니다."
        case .alreadySending: return "전송 중입니다. 잠시 후 다시 눌러주세요."
        }
    }
}

/// Uses advertising rather than connecting to a BLE peripheral, as the verified app does.
/// The lamp does not report its actual power state; lastStateOn is the last accepted send request.
@MainActor
final class LampController: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    static let shared = LampController()

    @Published private(set) var statusText = "Bluetooth 준비 중…"
    @Published private(set) var isReady = false
    @Published private(set) var isSending = false
    @Published private(set) var lastStateOn: Bool?

    private let stateKey = "lighton.lastRequestedPower"
    private let counterKey = "lighton.nextHFKJCounter"
    private var manager: CBPeripheralManager!
    private var frames: [[CBUUID]] = []
    private var timer: Timer?
    private var pendingAction: LightAction?
    private var firstAdvertisementAccepted = false

    private override init() {
        lastStateOn = UserDefaults.standard.object(forKey: stateKey) as? Bool
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func showError(_ error: Error) {
        statusText = error.localizedDescription
    }

    func setAssumedState(_ on: Bool) {
        guard !isSending else { return }
        lastStateOn = on
        UserDefaults.standard.set(on, forKey: stateKey)
        statusText = "상태 기준을 \(on ? "켜짐" : "꺼짐")으로 맞췄습니다."
    }

    @discardableResult
    func send(_ requestedAction: LightAction) throws -> LightAction {
        guard !isSending else { throw LightError.alreadySending }
        guard manager.state != .unsupported && manager.state != .unauthorized &&
              manager.state != .poweredOff else { throw LightError.bluetoothUnavailable }

        let action: LightAction = requestedAction == .toggle
            ? (lastStateOn == true ? .off : .on)
            : requestedAction

        let defaults = UserDefaults.standard
        let counter = UInt8(truncatingIfNeeded: defaults.object(forKey: counterKey) as? Int ?? 0x2E)
        let command = action == .on ? HFKJProtocol.onCommand : HFKJProtocol.offCommand
        let uuidStrings = HFKJProtocol.serviceUUIDStrings(counter: counter, command: command)
        let frame = uuidStrings.map(CBUUID.init(string:))

        // Follow v0.6: 5 advertisements, spaced ~0.35 seconds apart.
        timer?.invalidate()
        manager.stopAdvertising()
        frames = Array(repeating: frame, count: 5)
        pendingAction = action
        firstAdvertisementAccepted = false
        isSending = true
        statusText = "\(action.label) 신호 준비 중…"
        defaults.set(Int(counter &+ 1), forKey: counterKey)

        if manager.state == .poweredOn { sendNext() }
        return action
    }

    private func sendNext() {
        guard manager.state == .poweredOn, isSending else { return }
        guard !frames.isEmpty else {
            timer?.invalidate()
            manager.stopAdvertising()
            isSending = false
            pendingAction = nil
            statusText = firstAdvertisementAccepted
                ? "BLE 광고 전송 요청 완료 · 기기 응답은 확인할 수 없습니다."
                : "광고 신호가 시작되지 않았습니다."
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
            if isSending { sendNext() } else { statusText = "Bluetooth 사용 가능" }
        case .poweredOff:
            stopWithError("Bluetooth가 꺼져 있습니다.")
        case .unauthorized:
            stopWithError("Bluetooth 접근 권한이 없습니다.")
        case .unsupported:
            stopWithError("BLE 광고를 지원하지 않는 기기입니다.")
        case .unknown, .resetting:
            statusText = "Bluetooth 준비 중…"
        @unknown default:
            statusText = "Bluetooth 상태를 알 수 없습니다."
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard isSending else { return }
        if let error {
            stopWithError("광고 시작 실패: \(error.localizedDescription)")
            return
        }
        if !firstAdvertisementAccepted, let action = pendingAction {
            firstAdvertisementAccepted = true
            let on = (action == .on)
            lastStateOn = on
            UserDefaults.standard.set(on, forKey: stateKey)
            statusText = "\(action.label) 신호 보내는 중…"
        }
    }

    private func stopWithError(_ message: String) {
        timer?.invalidate()
        timer = nil
        frames.removeAll()
        manager?.stopAdvertising()
        isSending = false
        pendingAction = nil
        statusText = message
    }
}

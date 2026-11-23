import Foundation

@main
struct PacketTest {
    static func main() {
        // Sample A from original BLE captures: user confirmed it turns the light on.
        let originalSampleA = [
            "4648", "4A4B", "D769", "0E9B", "6AE1", "CB94", "6048",
            "1637", "013B", "B0AE", "1110", "1312", "1514"
        ]
        let generated = HFKJProtocol.serviceUUIDStrings(counter: 0x2E, command: 0xB3)
        precondition(generated == originalSampleA, "HFKJ ON must reproduce working sample A: \(generated)")
        let off = HFKJProtocol.serviceUUIDStrings(counter: 0x2F, command: 0xB2)
        let expectedOff = [
            "4648", "4A4B", "5607", "701A", "CC43", "50F6", "32AA",
            "B83A", "876D", "80E1", "1110", "1312", "1514"
        ]
        precondition(off == expectedOff, "HFKJ OFF reference vector mismatch")
        precondition(HFKJProtocol.packet(counter: 0x2E, command: 0xB3).count == 26)
        print("PASS: HFKJ dynamic ON matches captured working packet; OFF CRC, encoding and UUID order validated")
    }
}

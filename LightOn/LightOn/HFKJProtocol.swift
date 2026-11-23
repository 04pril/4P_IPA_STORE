import Foundation

/// Reconstructed from the verified v0.6 advertising protocol.
/// counter 0x2E + command 0xB3 reproduces the confirmed working ON Sample A, byte for byte.
enum HFKJProtocol {
    static let onCommand: UInt8 = 0xB3
    static let offCommand: UInt8 = 0xB2
    private static let table: [UInt8] = [
        0x1D, 0x04, 0x11, 0x20, 0x98, 0x75, 0x28, 0x46,
        0x0B, 0xAF, 0x43, 0xAC, 0xD6, 0xBE, 0x89, 0x8E
    ]

    static func packet(counter: UInt8, command: UInt8) -> [UInt8] {
        var payload: [UInt8] = [
            0xFF, counter &+ 1, counter, 0xE1, 0x20, 0x00, 0x00,
            command, 0x01, 0xFF, counter, 0x00, 0x00, 0x00, 0x00, 0x00
        ]
        encode(&payload, start: 9, length: 5, keyOffset: 10)
        let checksum = crc16(Array(payload.prefix(13)))
        payload[14] = UInt8(truncatingIfNeeded: checksum)
        payload[15] = UInt8(truncatingIfNeeded: checksum >> 8)
        encode(&payload, start: 0, length: 16, keyOffset: 0x56)
        return [0x48, 0x46, 0x4B, 0x4A] + payload + [0x10, 0x11, 0x12, 0x13, 0x14, 0x15]
    }

    /// iOS advertises each little-endian pair as a 16-bit service UUID.
    static func serviceUUIDStrings(counter: UInt8, command: UInt8) -> [String] {
        let data = packet(counter: counter, command: command)
        return stride(from: 0, to: data.count, by: 2).map { index in
            String(format: "%02X%02X", Int(data[index + 1]), Int(data[index]))
        }
    }

    private static func encode(_ bytes: inout [UInt8], start: Int, length: Int, keyOffset: Int) {
        let keyByte = bytes[start + 1]
        let keyIndex = Int((keyByte & 0x0F) ^ (keyByte >> 4))
        let key = table[keyIndex]
        for index in 0..<length {
            let offset = table[(index + keyOffset) & 0x0F]
            bytes[start + index] = (bytes[start + index] ^ key) &+ offset
        }
    }

    private static func crc16(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                crc = (crc & 0x8000 != 0) ? (crc &<< 1) ^ 0x1021 : (crc &<< 1)
            }
        }
        return crc
    }
}

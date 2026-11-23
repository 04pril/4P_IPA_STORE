from pathlib import Path

root = Path("ZhimeiLightSwitch_Test")
ctrl = root / "LampSwitch/LampController.swift"
view = root / "LampSwitch/LampView.swift"
proj = root / "LampSwitch.xcodeproj/project.pbxproj"

def replace_once(file, old, new):
    s = file.read_text()
    count = s.count(old)
    if count != 1:
        raise RuntimeError(f"{file}: expected exactly one anchor ({count} found): {old[:100]!r}")
    file.write_text(s.replace(old,new,1))

# These were recorded as 26-byte HFKJ advertising packets in the user's nRF screenshots.
# Reverse the UUID 2-byte endianness and undo the original ARM64 16-byte outer
# hfMsgEncodeWithBuf transform to classify the control codes. All three HFKJ
# frames decode to ctrlCode=0xB2; the reported working ON frame decodes to 0xB3.
hf = {
    1: '4648 4A4B C799 1E8B 3AF1 FA64 C518 D5DA BCDA 53D7 1110 1312 1514',
    2: '4648 4A4B 520A AB18 C980 6DF3 B1A5 CBFA B0F0 F412 1110 1312 1514',
    3: '4648 4A4B 4816 9F0E BD74 61E7 C199 EBEC D8E0 BE86 1110 1312 1514'
}
working_on = '4648 4A4B D769 0E9B 6AE1 CB94 6048 1637 013B B0AE 1110 1312 1514'
lookup = bytes.fromhex('1d 04 11 20 98 75 28 46 0b af 43 ac d6 be 89 8e')
def decode_code(text):
    data = b''.join(bytes.fromhex(u)[::-1] for u in text.split())
    assert len(data)==26 and data[0:4]==b'HFKJ' and data[20:26]==bytes(range(0x10,0x16))
    enc=data[4:20]
    matches=[]
    for key in lookup:
        plain=bytes(((((enc[i]-lookup[(i+0x56)&15]) & 255)^key)) for i in range(16))
        if (plain[0]==255 and (plain[1]-plain[2])%256==1
            and plain[3:7]==bytes.fromhex('e1 20 00 00') and plain[8]==1):
            matches.append(plain)
    assert len(matches)==1
    return matches[0][7]
assert decode_code(working_on)==0xB3
assert all(decode_code(value)==0xB2 for value in hf.values())

new_cases=''.join(f'    case hfOff{i} = "HF_OFF{i}"\n' for i in hf)
replace_once(ctrl,
    '    case off7 = "OFF7"\n',
    '    case off7 = "OFF7"\n'+new_cases)

replace_once(ctrl,
    'static let offCandidates: [CapturedSample] = [.sampleB, .off2, .off3, .off4, .off5, .off6, .off7]',
    'static let offCandidates: [CapturedSample] = [.hfOff1, .hfOff2, .hfOff3]')

new_names=''.join(f'        case .hfOff{i}: return "HFKJ 0xB2 OFF 후보 {i}"\n' for i in hf)
replace_once(ctrl,
    '        case .off7: return "OFF 후보 7 (20:32)"\n',
    '        case .off7: return "과거 08F9 후보 7 (미작동)"\n'+new_names)

new_data=''.join('        case .hfOff'+str(i)+':\n            return ['+ ', '.join(f'"{u}"' for u in seq.split())+']\n' for i,seq in hf.items())
replace_once(ctrl, '        case .off7:\n', new_data + '        case .off7:\n')

new_source_cases=''.join(
    f'''        case "hfOff{i}":
            frames = [CapturedSample.hfOff{i}.uuids.map {{ CBUUID(string: $0) }}]
''' for i in hf
)
replace_once(ctrl,
    '        case "offCycle" where action == .off:\n',
    new_source_cases + '        case "offCycle" where action == .off:\n')

replace_once(ctrl,
    'OFF 후보 7종 순차 시험 (총 35회)',
    'HFKJ 0xB2 후보 3종 (총 15회)')

new_options=''.join(f'        SourceOption(title: "HFKJ OFF 후보 {i} (0xB2)", value: "hfOff{i}"),\n' for i in hf)
replace_once(view,
    '        SourceOption(title: "OFF 7종 순차 시험", value: "offCycle"),\n',
    new_options + '        SourceOption(title: "HFKJ 0xB2 3종 순차", value: "offCycle"),\n')

replace_once(view,
    'Text("기존 ON 송신은 유지했습니다. OFF 후보 7종을 각각 또는 연속 시험할 수 있습니다.")',
    'Text("동작 확인된 ON 샘플 A는 유지했습니다. 새 OFF 후보들은 같은 HFKJ 형식이며 내부 제어 코드 0xB2로 디코딩됩니다.")')

replace_once(view,
    'Text("OFF 송신 테스트 (7종)").font(.headline)',
    'Text("HFKJ 제어 코드 0xB2 시험 (ON 유지)")')
replace_once(view,
    'Text("OFF는 매번 데이터가 바뀌므로 고정 패킷 재전송은 미검증입니다.")',
    'Text("기존 08F9 테스트는 실패했습니다. 여기서는 작동한 ON과 같은 HFKJ 형식의 0xB2 패킷 3종만 시험합니다. 실제 OFF 동작은 미검증입니다.")')
replace_once(view,
    'Button("OFF 후보 7종 순차 송신 (35회 요청)")',
    'Button("HFKJ OFF 3종 순차 시험 (15회 요청)")')

replace_once(view,
    'Text("기존 ON 송신 유지", systemImage: "antenna.radiowaves.left.and.right")',
    'Text("기존 ON 송신 유지", systemImage: "antenna.radiowaves.left.and.right")'
) if False else None

s=proj.read_text()
assert "MARKETING_VERSION = 0.4.0;" in s
s=s.replace("MARKETING_VERSION = 0.4.0;", "MARKETING_VERSION = 0.5.0;")
s=s.replace("CURRENT_PROJECT_VERSION = 5;", "CURRENT_PROJECT_VERSION = 6;")
proj.write_text(s)
print("Validated ctrl 0xB3 ON and 0xB2 HFKJ candidates; v0.5 source patched, ON data/sender preserved")


# v0.6: generate live HFKJ OFF frames using the reverse engineered encoder.
# Confirmed byte-for-byte against two ON + three 0xB2 captured HFKJ packets.
hf_swift = '''
// Generate a 26-byte HFKJ BLE advertisement for the previously paired light.
private enum HFKJProtocol {
    private static let table: [UInt8] = [
        0x1D, 0x04, 0x11, 0x20, 0x98, 0x75, 0x28, 0x46,
        0x0B, 0xAF, 0x43, 0xAC, 0xD6, 0xBE, 0x89, 0x8E
    ]
    private static func encode(_ bytes: inout [UInt8], start: Int, length: Int, keyOffset: Int) {
        let source = bytes[start + 1]
        let keyIndex = Int(((source & 0x0F) ^ (source >> 4)) & 0x0F)
        let key = table[keyIndex]
        for i in 0..<length {
            bytes[start + i] = (bytes[start + i] ^ key) &+ table[(i + keyOffset) & 0x0F]
        }
    }
    private static func crc16(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0
        for byte in bytes.prefix(13) {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                if crc & 0x8000 != 0 {
                    crc = (crc << 1) ^ 0x1021
                } else {
                    crc <<= 1
                }
            }
        }
        return crc
    }
    static func makeUUIDs(counter: UInt8, command: UInt8) -> [CBUUID] {
        // Address E1 20 00 00 0A and PID 01 are extracted from observed frames.
        var bytes: [UInt8] = [0xFF, counter &+ 1, counter,
                              0xE1, 0x20, 0, 0, command, 0x01,
                              0xFF, counter, 0, 0, 0, 0, 0]
        encode(&bytes, start: 9, length: 5, keyOffset: 0x0A)
        let crc = crc16(bytes)
        bytes[14] = UInt8(truncatingIfNeeded: crc)
        bytes[15] = UInt8(truncatingIfNeeded: crc >> 8)
        encode(&bytes, start: 0, length: 16, keyOffset: 0x56)
        var packet: [UInt8] = [0x48, 0x46, 0x4B, 0x4A]
        packet.append(contentsOf: bytes)
        packet.append(contentsOf: [0x10, 0x11, 0x12, 0x13, 0x14, 0x15])
        return stride(from: 0, to: packet.count, by: 2).map { i in
            CBUUID(string: String(format: "%02X%02X", Int(packet[i + 1]), Int(packet[i])))
        }
    }
}
'''
replace_once(ctrl, 'enum LampAction: String {', hf_swift + '\nenum LampAction: String {')

send_hf_off = '''    // Preserve the working ON sample; only OFF is generated anew.
    func sendHFOff() throws {
        let defaults = UserDefaults.standard
        let next = defaults.object(forKey: "zhimeiHFNextCounter") as? Int ?? 47
        let counter = UInt8(truncatingIfNeeded: next)
        let frame = HFKJProtocol.makeUUIDs(counter: counter, command: 0xB2)
        try enqueue([frame], label: "HFKJ OFF 동적 생성 (카운터 \\(counter), UUID 13)")
        defaults.set(Int(counter &+ 1), forKey: "zhimeiHFNextCounter")
    }

'''
replace_once(ctrl,'    func send(_ action: LampAction) throws {',
    send_hf_off+'    func send(_ action: LampAction) throws {')

replace_once(ctrl,'        case "offCycle" where action == .off:\n',
'''        case "hfDynamicOff" where action == .off:
            try sendHFOff()
            return
        case "offCycle" where action == .off:
''')

option_anchor='        SourceOption(title: "HFKJ 0xB2 3종 순차", value: "offCycle"),'
replace_once(view, option_anchor, option_anchor + '\n' +
    '        SourceOption(title: "HFKJ OFF 동적 생성 (추천)", value: "hfDynamicOff"),')

heading='Text("HFKJ 제어 코드 0xB2 시험 (ON 유지)")'
replace_once(view, heading,
'''Button("OFF - 새 HFKJ 패킷 생성") {
                            do { try lamp.sendHFOff() } catch { lamp.showError(error) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        Text("HFKJ 제어 코드 0xB2 시험 (ON 유지)")''')
replace_once(view,
    'Text("기존 08F9 테스트는 실패했습니다. 여기서는 작동한 ON과 같은 HFKJ 형식의 0xB2 패킷 3종만 시험합니다. 실제 OFF 동작은 미검증입니다.")',
    'Text("새 OFF 버튼은 HFKJ 0xB2를 현재 카운터로 생성하고 CRC를 다시 계산합니다. 원본 패킷과 바이트 일치 검증됨. 실제 소등은 아직 미검증입니다.")')

project_text=proj.read_text()
assert 'MARKETING_VERSION = 0.5.0;' in project_text
project_text=project_text.replace('MARKETING_VERSION = 0.5.0;', 'MARKETING_VERSION = 0.6.0;')
project_text=project_text.replace('CURRENT_PROJECT_VERSION = 6;', 'CURRENT_PROJECT_VERSION = 7;')
proj.write_text(project_text)
print('v0.6: validated dynamic HFKJ OFF encoder added; original ON is unchanged')

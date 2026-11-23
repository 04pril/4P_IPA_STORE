from pathlib import Path
root = Path("ZhimeiLightSwitch_Test")

def replace(path, old, new):
    file = root / path
    value = file.read_text()
    matches = value.count(old)
    if matches != 1:
        raise RuntimeError(f"{file}: expected one match; got {matches}: {old[:80]!r}")
    file.write_text(value.replace(old, new, 1))

c = "LampSwitch/LampController.swift"
v = "LampSwitch/LampView.swift"

replace(c, '    case sampleB = "B"\n',
'''    case sampleB = "B"
    case off2 = "OFF2"
    case off3 = "OFF3"
''')
replace(c, '        case .sampleB: return "샘플 B (14:57)"\n',
'''        case .sampleB: return "샘플 B (14:57, OFF 후보 1)"
        case .off2: return "OFF 후보 2 (19:28)"
        case .off3: return "OFF 후보 3 (19:28)"
''')
replace(c, '''        case .sampleB:
            return ["08F9", "B249", "2CCE", "663F", "CD36", "7355", "600C",
                    "9F15", "1110", "1312", "1514", "1716", "1918"]
''',
'''        case .sampleB:
            return ["08F9", "B249", "2CCE", "663F", "CD36", "7355", "600C",
                    "9F15", "1110", "1312", "1514", "1716", "1918"]
        case .off2:
            return ["08F9", "B249", "2CCE", "2F76", "847F", "3A1C", "290C",
                    "CD45", "1110", "1312", "1514", "1716", "1918"]
        case .off3:
            return ["08F9", "B249", "2CCE", "3168", "9A61", "2402", "370C",
                    "3AA0", "1110", "1312", "1514", "1716", "1918"]
''')
replace(c, '    func send(_ action: LampAction) throws {\n',
'''    // OFF candidate tests: preserve original sample A / ON transmission.
    func testOffCandidates() throws {
        let samples: [CapturedSample] = [.sampleB, .off2, .off3]
        let frames = samples.map { $0.uuids.map { CBUUID(string: $0) } }
        try enqueue(frames, label: "OFF 후보 3종 순차 시험 (각 5회)")
    }

    func send(_ action: LampAction) throws {
''')
replace(c, '''        case "sampleB":
            frames = [CapturedSample.sampleB.uuids.map { CBUUID(string: $0) }]
''',
'''        case "sampleB":
            frames = [CapturedSample.sampleB.uuids.map { CBUUID(string: $0) }]
        case "off2":
            frames = [CapturedSample.off2.uuids.map { CBUUID(string: $0) }]
        case "off3":
            frames = [CapturedSample.off3.uuids.map { CBUUID(string: $0) }]
        case "offCycle" where action == .off:
            frames = [CapturedSample.sampleB, .off2, .off3].map { $0.uuids.map { CBUUID(string: $0) } }
''')
replace(c, '        try enqueue(frames, label: "전등 \\(action.title)")\n',
'''        let counts = frames.map { String($0.count) }.joined(separator: "+")
        try enqueue(frames, label: "전등 \\(action.title) (UUID \\(counts))")
'''.replace('\\\\(','\\('))
replace(c, '''        for line in input.components(separatedBy: .newlines) {
            let noComment = String(line.split(separator: "#", maxSplits: 1,
                                             omittingEmptySubsequences: false).first ?? "")
''',
'''        // Accept a visually wrapped capture as a single frame.
        // A blank line is the separator for multiple frames.
        let normalized = input.replacingOccurrences(of: "\\r\\n", with: "\\n")
        for paragraph in normalized.components(separatedBy: "\\n\\n") {
            let noComment = paragraph.components(separatedBy: .newlines)
                .map { String($0.split(separator: "#", maxSplits: 1,
                                       omittingEmptySubsequences: false).first ?? "") }
                .joined(separator: " ")
''')

replace(v, '''        SourceOption(title: "샘플 B (14:57)", value: "sampleB"),
''',
'''        SourceOption(title: "샘플 B (14:57)", value: "sampleB"),
        SourceOption(title: "OFF 후보 2 (19:28)", value: "off2"),
        SourceOption(title: "OFF 후보 3 (19:28)", value: "off3"),
        SourceOption(title: "OFF 후보 3개 순차", value: "offCycle"),
''')
replace(v,
'Text("아직 어느 샘플이 ON인지 OFF인지 확인되지 않았습니다. 전등 없이 송신 테스트만 가능합니다.")',
'Text("기존 ON 송신은 유지했습니다. OFF는 서로 다른 캡처 후보 3개를 별도로 테스트할 수 있습니다.")')
replace(v, '''                    Text(lamp.statusText)
''',
'''                    VStack(alignment: .leading, spacing: 9) {
                        Text("OFF 송신 테스트").font(.headline)
                        Text("캡처된 OFF 후보 3개입니다. 각 후보는 검증되지 않았습니다.")
                            .font(.footnote).foregroundStyle(.secondary)
                        HStack {
                            Button("OFF 1") { triggerSample(.sampleB) }
                            Button("OFF 2") { triggerSample(.off2) }
                            Button("OFF 3") { triggerSample(.off3) }
                        }.buttonStyle(.bordered)
                        Button("OFF 후보 3개 순차 송신") {
                            do { try lamp.testOffCandidates() }
                            catch { lamp.showError(error) }
                        }.buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

                    Text(lamp.statusText)
''')
replace(v, 'Text("광고 한 건당 한 줄씩 16비트 UUID를 공백으로 구분해 입력하세요.")',
'Text("16비트 UUID는 공백/줄바꿈으로 구분합니다. 패킷 여러 개는 빈 줄로 구분하세요.")')
project = root / "LampSwitch.xcodeproj/project.pbxproj"
p = project.read_text().replace("MARKETING_VERSION = 0.2.0;", "MARKETING_VERSION = 0.3.1;").replace("CURRENT_PROJECT_VERSION = 1;", "CURRENT_PROJECT_VERSION = 4;")
project.write_text(p)
print("Prepared OFF test v0.3.1; original ON packet and advertising scheduler unchanged")

# v0.4: Four more captured OFF frames. Keep ON & sending logic from v0.2.
extra = {
    4: '336A 9863 2600 350C B776',
    5: '2E77 857E 3B1C 280C 9715',
    6: '91C8 39C1 84A5 2DB6 57E8',
    7: '8BD2 21DB 9EBD 2EAF 5387',
}
off_suffix = '1110 1312 1514 1716 1918'
new_cases = ''.join(f'    case off{n} = "OFF{n}"\n' for n in extra)
new_names = ''.join(f'        case .off{n}: return "OFF 후보 {n} (20:3{1 if n<6 else 2})"\n' for n in extra)
new_uuids = ''.join('        case .off'+str(n)+':\n            return ['+ ', '.join('"'+s+'"' for s in ('08F9 B249 2CCE '+middle+' '+off_suffix).split())+']\n' for n,middle in extra.items())
replace(c, '    case off3 = "OFF3"\n', '    case off3 = "OFF3"\n'+new_cases+'\n    static let offCandidates: [CapturedSample] = [.sampleB, .off2, .off3, .off4, .off5, .off6, .off7]\n')
replace(c, '        case .off3: return "OFF 후보 3 (19:28)"\n', '        case .off3: return "OFF 후보 3 (19:28)"\n'+new_names)
old3 = '''        case .off3:
            return ["08F9", "B249", "2CCE", "3168", "9A61", "2402", "370C",
                    "3AA0", "1110", "1312", "1514", "1716", "1918"]
'''
replace(c,old3,old3+new_uuids)
replace(c,'        let samples: [CapturedSample] = [.sampleB, .off2, .off3]\n','        let samples: [CapturedSample] = CapturedSample.offCandidates\n')
replace(c,'OFF 후보 3종 순차 시험 (각 5회)','OFF 후보 7종 순차 시험 (총 35회)')
old_src='''        case "offCycle" where action == .off:
            frames = [CapturedSample.sampleB, .off2, .off3].map { $0.uuids.map { CBUUID(string: $0) } }
'''
new_src=''.join('        case "off'+str(n)+'":\n            frames = [CapturedSample.off'+str(n)+'.uuids.map { CBUUID(string: $0) }]\n' for n in extra)
new_src+='''        case "offCycle" where action == .off:
            frames = CapturedSample.offCandidates.map { $0.uuids.map { CBUUID(string: $0) } }
'''
replace(c,old_src,new_src)
old_opt='''        SourceOption(title: "OFF 후보 3개 순차", value: "offCycle"),
'''
new_opt=''.join('        SourceOption(title: "OFF 후보 '+str(n)+' (20:3'+('1' if n<6 else '2')+')", value: "off'+str(n)+'"),\n' for n in extra)
new_opt+='''        SourceOption(title: "OFF 7종 순차 시험", value: "offCycle"),
'''
replace(v,old_opt,new_opt)
replace(v,'Text("기존 ON 송신은 유지했습니다. OFF는 서로 다른 캡처 후보 3개를 별도로 테스트할 수 있습니다.")','Text("기존 ON 송신은 유지했습니다. OFF 후보 7종을 각각 또는 연속 시험할 수 있습니다.")')
replace(v,'Text("OFF 송신 테스트").font(.headline)','Text("OFF 송신 테스트 (7종)").font(.headline)')
replace(v,'Text("캡처된 OFF 후보 3개입니다. 각 후보는 검증되지 않았습니다.")','Text("OFF는 매번 데이터가 바뀌므로 고정 패킷 재전송은 미검증입니다.")')
old_buttons='''                        HStack {
                            Button("OFF 1") { triggerSample(.sampleB) }
                            Button("OFF 2") { triggerSample(.off2) }
                            Button("OFF 3") { triggerSample(.off3) }
                        }.buttonStyle(.bordered)
                        Button("OFF 후보 3개 순차 송신") {
'''
new_buttons=r'''                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 10) {
                            ForEach(CapturedSample.offCandidates.indices, id: \.self) { index in
                                Button("OFF \(index + 1)") { triggerSample(CapturedSample.offCandidates[index]) }
                                    .buttonStyle(.bordered)
                            }
                        }
                        Button("OFF 후보 7종 순차 송신 (35회 요청)") {
'''
replace(v,old_buttons,new_buttons)
project = root / 'LampSwitch.xcodeproj/project.pbxproj'
p = project.read_text().replace('MARKETING_VERSION = 0.3.1;','MARKETING_VERSION = 0.4.0;').replace('CURRENT_PROJECT_VERSION = 4;','CURRENT_PROJECT_VERSION = 5;')
project.write_text(p)
print('v0.4: preserved ON path, added 4 OFF frames')

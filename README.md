# 4P IPA Store

Feather와 AltStore가 읽는 소스입니다. IPA 파일은 이 저장소에 두지 않고, 각 릴리스의 공개 주소를 `source.json`에 적습니다. 그래서 이 계정의 다른 저장소와 다른 사람의 공개 저장소를 한 목록에 넣을 수 있습니다.

Feather에는 이 주소를 넣습니다.

```
https://raw.githubusercontent.com/04pril/4P_IPA_STORE/refs/heads/main/source.json
```

입력칸 아래의 “AltStore 저장소 형식만 지원됩니다”는 안내 문구입니다. 저장한 뒤 목록에 앱이 보이면 추가된 것입니다.

## 앱을 하나 더 넣을 때

`source.json`의 `apps`에 항목을 추가하고, `downloadURL`만 그 릴리스의 IPA 주소로 바꿉니다. 주소는 로그인 없이 열려야 합니다.

- `bundleIdentifier`는 IPA 안의 값과 같게 적습니다.
- `downloadURL`이 특정 파일을 가리키면, version을 비워도 그 파일만 받아집니다. Feather 업데이트 알림은 `version`이 더 큰 값으로 바뀔 때만 나옵니다.
- `size`는 파일 크기(바이트)입니다.
- `date`는 `2026-11-16T07:55:00Z`처럼 초까지 있는 UTC입니다.

## BitChord 릴리스 수동 동기화

`.github/workflows/sync-bitchord.yml`은 예약 실행하지 않습니다. GitHub Actions에서 **Actions → Sync BitChord releases → Run workflow**를 누를 때만 동기화됩니다.

- `04pril/BitChord-iOS`의 **최신 공개 릴리스**와 원본 `source.json`을 함께 확인합니다.
- 양쪽 IPA 다운로드 주소 및 파일 크기가 일치할 때만 이 저장소의 BitChord 다운로드 URL, 날짜, 버전, 설명, 크기를 갱신하고 자동 커밋합니다.
- 나머지 앱 목록은 변경하지 않습니다. 원본 릴리스와 메타데이터가 일시적으로 어긋나면 변경하지 않으므로, 원본 갱신 후 수동으로 다시 실행하세요.
- **주의:** 앱 내부 버전이 계속 `1.0.2`이면 새로운 IPA로 주소가 바뀌어도 Feather의 업데이트 알림은 뜨지 않을 수 있습니다. 알림이 필요하면 앱 내부 버전을 올려 새 IPA를 빌드하고, 소스의 `version`도 동일하게 맞추세요.

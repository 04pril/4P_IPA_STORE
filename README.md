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

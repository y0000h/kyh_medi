# 앱 런처 아이콘 (Phase 13.1)

여기 `icon.png` 파일을 두면 `flutter_launcher_icons`가 Android `mipmap-*` 폴더로 자동 변환한다.

## 요구사항

- 파일명: `icon.png`
- 크기: **1024×1024** (정사각, PNG)
- 디자인 톤: 베이지(#ECE8E1) + 주황(#B86F40), 약봉투 미감
- 무료 도구: <https://favicon.io/favicon-generator/> 또는 Figma

## 생성 절차 (PNG 준비 후)

```bash
flutter pub get
dart run flutter_launcher_icons
```

→ `android/app/src/main/res/mipmap-*` 안에 자동 생성.

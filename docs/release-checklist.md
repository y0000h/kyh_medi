# 출시 전 체크리스트 (스토어 제출)

> 작성 2026-06-25. UI 라이트 리디자인 일단락 후 배포 준비 점검 결과.
> ✅ = 완료 / ⬜ = 사용자 작업 필요(계정·실 ID 등 코드만으론 못 채움) / 🔶 = 검토 권장

## 1. AdMob (실 ID 교체 — **출시 차단 항목**)

현재 전부 **Google 테스트 ID**. 출시 전 본인 AdMob 계정의 실 ID로 교체. 3곳:

- ⬜ **배너 단위 ID** — [ad_banner.dart](../lib/features/parent/monetization/ad_banner.dart) 상단 `_prodUnitIdIOS` / `_prodUnitIdAndroid` 상수에 입력.
  - 비워두면 **릴리스 빌드에서 배너 미표시**(테스트 광고 실수 출시 = 정책 위반·계정 정지 방지용 안전장치). 디버그/프로파일은 기존 테스트 ID 자동 사용.
- ⬜ **iOS 앱 ID** — [ios/Runner/Info.plist](../ios/Runner/Info.plist) `GADApplicationIdentifier` (현재 `ca-app-pub-3940256099942544~1458002511` = 테스트).
- ⬜ **Android 앱 ID** — [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) `com.google.android.gms.ads.APPLICATION_ID` (현재 테스트).

## 2. 앱 이름 / 식별자

- ✅ 앱 표시 이름 **"KYH 약 알림"** 으로 iOS·Android 통일(이전 iOS만 "Kyh Medi" 영문이었음 → 수정).
- 🔶 번들 ID 플랫폼 간 표기 차이: iOS `com.kyh.medi.kyhMedi` / Android `com.kyh.medi.kyh_medi`. 동작엔 무방하나 인지해 둘 것.
- ✅ 버전 `1.0.0+4` (pubspec).

## 3. 권한 (양호)

- ✅ iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` 한글 설명 있음.
- ✅ Android: INTERNET, POST_NOTIFICATIONS, SCHEDULE/USE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, WAKE_LOCK, VIBRATE, READ_MEDIA_IMAGES, CAMERA, AD_ID 선언됨.

## 4. 푸시 알림 (iOS)

- 발송 파이프라인(Edge Function `on_dose_event_insert`, FCM v1)·토큰 등록·핸들러 **구현 완료**. Android 동작.
- ✅ `Info.plist`에 `UIBackgroundModes: remote-notification` 추가(코드).
- ⬜ **iOS 푸시 활성화** — 코드로 안 되는 계정/Xcode 작업 남음: Apple App ID Push 권한, APNs .p8 키 → Firebase 업로드, Xcode Push Notifications + Background Modes capability. 실기기 검증. → 상세 [docs/setup/ios-push-setup.md](setup/ios-push-setup.md).
  - 인앱 폴링/로컬 알림만 쓸 거면 iOS 푸시 셋업은 생략 가능.
- 🔶 (백엔드) `FCM_SERVICE_ACCOUNT_JSON` 시크릿 + 함수 배포 + `dose_events` Insert Webhook 등록 상태 재확인.

## 5. 백엔드 / 개인정보

- ✅ Supabase keep-alive cron 적용(무료 플랜 일시정지 예방, `4714cf9`).
- 🔶 Supabase **프로덕션 점검**: RLS 정책, 페어링/redeem RPC 권한, 이메일 OTP 발신자(Brevo SMTP) 도메인.
- ✅ **개인정보처리방침 URL 라이브** — https://y0000h.github.io/kyh_medi/ (HTTP 200 확인). Pages를 GitHub Actions 소스로 활성화 + 배포 완료. 남은 건 이 URL을 Play Console / App Store Connect "개인정보처리방침" 칸에 **붙여넣기**만.

## 6. 스토어 자산

- ✅ 앱 아이콘 모던화(`64dbd87`) + **스토어 그래픽 라이트+블루 교체**(`de794ff`): `icon_512.png`, `feature_graphic_1024x500.jpg`(옛 갈색 버전 대체). [docs/store-assets/](store-assets/).
- ✅ **스크린샷** — 라이트 UI 4종(홈·일정·마법사·자녀로그인). Play용 1206×2622 + **App Store 6.9" 1290×2796**(`appstore-6.9/`) 둘 다 준비([docs/screenshots/store-1.0.0+4/](screenshots/store-1.0.0+4/)). (선택) 광고 끈 릴리스 빌드로 이력 추가, 마케팅 프레임. 기존 `screenshots/01~05`는 옛 UI라 사용 금지.
- 🔶 앱 설명·짧은 설명·키워드 — 초안 [docs/setup/play-console-upload.md](setup/play-console-upload.md)에 있음(검토·갱신).
- ⬜ 카테고리, 연령등급 설문(콘솔에서 직접).
- ⬜ iOS: App Store Connect 앱 생성 + 서명(배포 인증서/프로비저닝). Android: 키스토어 서명 + Play Console 등록.

### ✅ Android 업로드 키스토어 (해결 2026-06-25)

- (이전) `key.properties`의 `storeFile`이 윈도우 경로 `C:\Users\y00h\upload-keystore.jks`를
  가리켜 릴리스 서명 실패. 미출시 확인 후 **새 업로드 키 생성**으로 해결.
- 조치: `/Users/y00h/upload-keystore.jks` 생성(별칭 `upload`, RSA 2048, 유효 10000일,
  CN=KYH Medi). `key.properties`의 `storeFile`을 맥 절대경로로 수정(둘 다 gitignore, 레포 밖).
- 검증: `flutter build appbundle --release` → 서명된 `app-release.aab` 64.5MB,
  업로드 키(CN=KYH Medi)로 서명 확인.
- ⚠️ **백업 필수**: `/Users/y00h/upload-keystore.jks` 파일 + `key.properties`의 비밀번호를
  안전한 곳(비밀번호 관리자/암호화 백업)에 보관. **Play에 첫 업로드 후엔 이 키가 영구 업로드 키**가
  되어 분실 시 재설정 절차가 번거롭다. (Play App Signing 사용 시 앱 서명 키는 구글이 보관하지만,
  업로드 키는 본인이 보관.)

## 7. 빌드 검증

- ✅ `flutter analyze` 에러 0, 테스트 16개 통과(2026-06-25 기준).
- ✅ **릴리스 컴파일 스모크 통과(2026-06-25)**: `flutter build appbundle --release`(R8/proguard, debug 서명 폴백으로) → `app-release.aab` 64.5MB, `flutter build ios --release --no-codesign` → `Runner.app` 38.6MB. 둘 다 성공.
- 🔶 Gradle 경고: Kotlin Gradle Plugin → Built-in Kotlin 마이그레이션 권고. **현재는 보류 권장** — 경고는 향후 Flutter 버전 한정이고 지금 빌드는 정상(서명 AAB 검증됨). 빌드 설정 변경은 작동 중인 파이프라인을 깰 위험이 있으니, **Flutter 업그레이드 시점에** [공식 가이드](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) 보며 진행. `settings.gradle.kts`의 `id("org.jetbrains.kotlin.android") version "2.2.20"` 명시 선언이 원인.
- ⬜ 서명된 실기기 릴리스 스모크 — 위 키스토어 경로 수정 + 광고 실 ID 넣은 뒤.

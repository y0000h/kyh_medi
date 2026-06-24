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

- 🔶 로컬 알림(flutter_local_notifications)은 정상. **FCM 원격 푸시**를 실제 쓸 거라면 iOS는 APNS 키 등록 + `UIBackgroundModes: remote-notification` 필요(현재 plist에 없음). 시뮬레이터 APNS 미지원 경고는 정상.
  - 자녀 모니터링 알림을 푸시로 보낼 계획이면 설정 필요. 인앱 폴링/로컬만 쓸 거면 불필요.

## 5. 백엔드 / 개인정보

- ✅ Supabase keep-alive cron 적용(무료 플랜 일시정지 예방, `4714cf9`).
- 🔶 Supabase **프로덕션 점검**: RLS 정책, 페어링/redeem RPC 권한, 이메일 OTP 발신자(Brevo SMTP) 도메인.
- 🔶 **개인정보처리방침 호스팅 URL** — 공개 페이지화 완료([site/index.html](../site/index.html) + Pages 워크플로). 남은 사용자 작업: ① Settings → Pages → Source "GitHub Actions" 활성화 ② `〔운영자/사업자명〕`·`〔성명/직책〕` placeholder 채우기 ③ 배포 URL(`https://y0000h.github.io/kyh_medi/`)을 스토어에 등록.

## 6. 스토어 자산

- ✅ 앱 아이콘 모던화(`64dbd87`).
- ⬜ 스크린샷(기기별), 앱 설명, 키워드, 카테고리, 연령등급 설문.
- ⬜ iOS: App Store Connect 앱 생성 + 서명(배포 인증서/프로비저닝). Android: 키스토어 서명 + Play Console 등록.

## 7. 빌드 검증

- ✅ `flutter analyze` 에러 0, 테스트 16개 통과(2026-06-25 기준).
- ⬜ 릴리스 빌드 실기기 스모크(`flutter build ios --release` / `flutter build appbundle`) — 광고 실 ID 넣은 뒤.

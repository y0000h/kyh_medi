# iOS 푸시(FCM) 설정 가이드

> 자녀 모니터링 알림(부모 미복용 → 자녀 푸시)을 **iOS 자녀 기기**에서 받으려면 필요.
> Android는 추가 설정 없이 동작한다(이미 구현 완료). iOS만 아래 셋업이 필요하다.
>
> 작성 2026-06-25. 코드 측 파이프라인은 완성돼 있음:
> - 토큰 등록 [fcm_service.dart](../../lib/core/firebase/fcm_service.dart) → `child_users.fcm_token`
> - 포그라운드/백그라운드 핸들러 [fcm_message_handler.dart](../../lib/core/firebase/fcm_message_handler.dart)
> - 발송 Edge Function [on_dose_event_insert](../../supabase/functions/on_dose_event_insert/index.ts) (FCM v1 API)
> - `Info.plist`에 `UIBackgroundModes: remote-notification` 추가 완료(코드).

## ⚠️ 시뮬레이터에선 원격 푸시 안 됨

iOS 시뮬레이터는 APNs를 지원하지 않는다(`APNSTokenCheck`/`apns-token-not-set` 경고는 정상).
**실기기로만** 검증 가능.

## 1. Apple Developer — App ID에 Push 권한

1. [developer.apple.com](https://developer.apple.com) → Certificates, IDs & Profiles → Identifiers.
2. App ID `com.kyh.medi.kyhMedi` 선택 → **Push Notifications** 체크 → Save.
3. 프로비저닝 프로파일 재발급(Xcode 자동 서명이면 자동 갱신됨).

## 2. APNs 인증 키(.p8) → Firebase 업로드

1. Apple Developer → Keys → **+** → "Apple Push Notifications service (APNs)" 체크 → 생성 → **.p8 파일 다운로드**(딱 1번만 받을 수 있음, 분실 주의). Key ID, Team ID 메모.
2. [Firebase Console](https://console.firebase.google.com) → 프로젝트 → ⚙️ → Cloud Messaging → Apple 앱 구성 → **APNs Authentication Key** 에 .p8 + Key ID + Team ID 업로드.

> 이 단계가 빠지면 iOS 토큰은 받아도 **푸시가 조용히 실패**한다.

## 3. Xcode — Capability 추가 (entitlements 자동 생성)

`ios/Runner.xcworkspace` 열고 Runner 타겟 → **Signing & Capabilities**:

1. **+ Capability → Push Notifications** 추가. → `Runner.entitlements`(aps-environment)가 자동 생성되고 `CODE_SIGN_ENTITLEMENTS` 빌드 설정이 자동 연결됨.
2. **+ Capability → Background Modes** 추가 → **Remote notifications** 체크.
   (Info.plist의 `UIBackgroundModes`는 이미 코드로 넣었지만, Xcode capability도 함께 켜두면 명확.)

> ⚠️ entitlements 파일은 **Xcode로 추가**하는 게 안전하다(pbxproj의 `CODE_SIGN_ENTITLEMENTS`까지 자동 연결). 손으로 파일만 만들면 빌드에 반영되지 않는다.

## 4. 실기기 검증

1. 자녀 모드로 iOS 실기기 로그인 → 알림 권한 허용 → `child_users.fcm_token` 채워지는지 확인(Supabase Table Editor).
2. 부모 기기에서 복용 시간을 놓쳐 **missed 이벤트** 발생시키거나, `dose_events`에 missed row를 수동 insert.
3. Supabase Webhook(아래) 발화 → 자녀 기기에 "○○이 △△을 못 드셨어요" 푸시 도착 확인.

## 5. (재확인) 백엔드 시크릿 & Webhook

Edge Function이 동작하려면:
- 시크릿: `supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{...}'` (Firebase 서비스 계정 JSON).
- 배포: `supabase functions deploy on_dose_event_insert --no-verify-jwt`.
- Webhook(Supabase 콘솔 → Database → Webhooks): Table `public.dose_events`, Event `Insert` → Edge Function `on_dose_event_insert`.

## 체크리스트

- [ ] Apple Developer App ID에 Push Notifications 활성화
- [ ] APNs .p8 키 생성 → Firebase Cloud Messaging에 업로드
- [ ] Xcode: Push Notifications + Background Modes(Remote notifications) capability
- [x] Info.plist `UIBackgroundModes: remote-notification` (코드 완료)
- [ ] 실기기에서 토큰 등록 + missed 푸시 수신 검증
- [ ] (백엔드) FCM_SERVICE_ACCOUNT_JSON 시크릿 + 함수 배포 + dose_events Insert Webhook

# FCM + Edge Function 셋업 가이드 (Phase 11 사용자 manual)

> Phase 11.1~11.3 코드는 이미 작성됨 (`lib/core/firebase/fcm_*.dart`, `supabase/functions/on_dose_event_insert/`).
> 이 문서는 부모 `dose_events.missed` Insert → 자녀 폰에 푸시가 실제로 도착하도록 만드는 콘솔/CLI 작업.
> 시간: **약 15~20분**.

> ⚠️ 2024-06-20에 Google이 **FCM Legacy API(`fcm.googleapis.com/fcm/send` + Server Key)를 영구 폐기**했음. 본 가이드는 **FCM v1 API + Service Account JSON** 방식 — 모든 신규 프로젝트가 사용해야 하는 표준.

---

## 1단계 — Firebase Service Account JSON 다운로드 (3분)

1. <https://console.firebase.google.com> → 프로젝트 `kyh-medi` 선택
2. 좌측 톱니바퀴(⚙️) → **프로젝트 설정**
3. 상단 탭에서 **서비스 계정** 클릭
4. 화면에 "Firebase Admin SDK" 섹션이 보임. 언어 선택은 **Node.js** 또는 그대로 두면 됨 (어차피 JSON만 받음)
5. 하단 **새 비공개 키 생성** 버튼 클릭
6. 경고 모달 — "이 키를 절대 외부에 공유하지 마세요" → **키 생성**
7. JSON 파일 자동 다운로드 (예: `kyh-medi-firebase-adminsdk-xxxxx-xxxxxxxxxx.json`)

> ⚠️ 이 JSON은 **Firebase 전체 권한**을 가진 키입니다. Git에 올리지 마세요. Supabase secret으로만 사용.

JSON 파일 내용 메모장에서 열기 — 다음 단계에서 필요. 형태 예시:

```json
{
  "type": "service_account",
  "project_id": "kyh-medi",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-xxxxx@kyh-medi.iam.gserviceaccount.com",
  ...
}
```

---

## 2단계 — Supabase Secret 등록 (3분)

JSON 파일 통째로 환경변수 `FCM_SERVICE_ACCOUNT_JSON`에 등록.

### 옵션 A: CLI (Personal Access Token이 정상 발급된 경우)

```bash
cd C:/Users/y00h/IdeaProjects/kyh_medi
supabase login                                      # 토큰 paste
supabase link --project-ref evkuwuyxqyjmaargifnx
# JSON 파일 경로를 정확히 지정 (Windows 경로 quote 주의)
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat /c/Users/y00h/Downloads/kyh-medi-firebase-adminsdk-*.json)"
```

PowerShell이면:

```powershell
$json = Get-Content "C:\Users\y00h\Downloads\kyh-medi-firebase-adminsdk-xxxxx.json" -Raw
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$json"
```

### 옵션 B: Supabase 콘솔 UI (CLI 토큰 마스킹 이슈 시 우회)

1. <https://supabase.com/dashboard> → 프로젝트 `kyh-medi`
2. 좌측 사이드바 **Edge Functions** → 화면 우측 상단 **Manage secrets** 또는 **Secrets** 버튼
3. **Add new secret**:
   - Name: `FCM_SERVICE_ACCOUNT_JSON`
   - Value: JSON 파일 내용 통째로 복사 → 붙여넣기 (`{` 부터 `}`까지 모두)
4. **Save**

> ⚠️ JSON 안의 `\n` 줄바꿈이 여러 개 있는데 그대로 붙여넣으면 됩니다 (Edge Function이 `JSON.parse`로 처리).

---

## 3단계 — Edge Function 배포 (5분)

### 옵션 A: CLI

```bash
cd C:/Users/y00h/IdeaProjects/kyh_medi
supabase functions deploy on_dose_event_insert --no-verify-jwt
```

### 옵션 B: Supabase 콘솔 UI

1. 좌측 **Edge Functions** → **Create new function** (또는 함수가 이미 있으면 클릭 후 **Edit**)
2. 이름: `on_dose_event_insert`
3. 코드 입력 — `supabase/functions/on_dose_event_insert/index.ts` 파일 내용 통째로 복사 → paste
4. 우측 상단 **Verify JWT** 토글 → **OFF** (Webhook이 SERVICE_ROLE로 호출하므로)
5. **Deploy** 클릭

---

## 4단계 — Database Webhook 등록 (3분)

자녀에게 푸시 보낼 트리거: `dose_events` 테이블에 `status='missed'` row가 들어올 때.

1. Supabase 콘솔 → 좌측 **Database** → **Webhooks** (Beta 표시 있을 수 있음)
2. **Create a new hook** 클릭
3. 입력:
   - **Name**: `on_dose_event_insert`
   - **Table**: `public.dose_events`
   - **Events**: ✅ **Insert** (Update/Delete는 체크 안 함)
   - **Type**: **Supabase Edge Functions**
   - **Edge Function**: `on_dose_event_insert` (드롭다운에서 선택)
   - **HTTP Headers**: 자동 주입 (수정 불필요)
   - **HTTP Params**: 비워둠
4. **Create webhook** 클릭

---

## 5단계 — E2E 시연 (선택, Phase 13 release 검증 시)

**준비물**: 부모 폰(또는 emulator A) + 자녀 폰(또는 emulator B). 자녀가 부모와 페어링된 상태.

1. 부모 폰: 약 1개 등록 + 슬롯(현재 시각 +1분) 추가 → 알림 1분 후 발사
2. 부모: 알림 무시 (탭 안 함) → **30분 대기 또는 폰 시간 +30분 조작**
3. 부모 앱 메인 화면 새로고침 → `IntakeProvider.markStaleAsMissed()` 트리거 → `dose_events` insert (status=missed)
4. Supabase Webhook fire → Edge Function 호출 → FCM v1 API로 푸시 전송
5. **자녀 폰 알림 도착** ("○○님이 약을 못 드셨어요") — 백그라운드는 시스템 알림, 포그라운드는 `FcmMessageHandler._onForeground`가 헤드업 표시

### 디버깅

| 증상 | 확인 |
|---|---|
| Webhook이 Edge Function 안 부름 | Supabase 콘솔 → Webhooks → 해당 hook → **Logs** 탭에서 호출 기록 확인 |
| Edge Function 호출은 됐는데 FCM 안 감 | Edge Function → **Logs** 탭에서 `console.error` 확인. `FCM_SERVICE_ACCOUNT_JSON` secret 미등록 가능성 |
| `oauth token error: invalid_grant` | Service Account JSON이 손상되거나 시각이 안 맞음. 다시 다운로드 후 secret 갱신 |
| `403 The caller does not have permission` | Service Account에 Cloud Messaging 권한 없음. Firebase 콘솔에서 새 키 생성 (Firebase Admin SDK는 자동으로 권한 보유) |
| FCM 응답 200인데 폰 안 옴 | `child_users.fcm_token`이 비어 있거나 만료. 자녀 앱 재실행으로 `FcmService.registerForCurrentUser` 재호출 |

---

## 결과 체크리스트

- [ ] Firebase 서비스 계정 JSON 다운로드 + 안전 보관 (Git X)
- [ ] Supabase `FCM_SERVICE_ACCOUNT_JSON` secret 등록
- [ ] Edge Function `on_dose_event_insert` 배포 (Verify JWT OFF)
- [ ] Database Webhook 등록 (`dose_events` Insert → 함수)
- [ ] (Phase 13) E2E 푸시 도착 확인

이 4개 다 ✅면 Phase 11이 진짜로 끝납니다.

---

## 부록 — Edge Function 내부 동작 요약 (참고용)

`on_dose_event_insert/index.ts`가 푸시 1번 보내는 흐름:

1. Webhook payload에서 `record.status === 'missed'` 확인 (아니면 200으로 무시)
2. `medications` 테이블에서 약 이름 조회
3. `pairings` join으로 페어링된 자녀들의 `fcm_token` 조회
4. **OAuth 2.0 access token 발급** (캐시 1시간):
   - Service Account의 RSA private_key로 JWT 서명 (RS256, scope `firebase.messaging`)
   - `oauth2.googleapis.com/token`에 JWT 교환 → access token
5. 각 자녀 토큰마다 `fcm.googleapis.com/v1/projects/<project_id>/messages:send`에 POST
6. `notification.title/body` + `data.type=dose_missed`(부모/슬롯/약 ID) 페이로드

자녀 폰에서:
- 백그라운드: 시스템이 자동으로 알림 표시
- 포그라운드: `lib/core/firebase/fcm_message_handler.dart`의 `_onForeground`가 `flutter_local_notifications`로 헤드업 표시

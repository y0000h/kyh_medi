# FCM + Edge Function 셋업 가이드 (Phase 11 사용자 manual)

> Phase 11.1~11.3 코드는 이미 작성됨 (`lib/core/firebase/fcm_*.dart`, `supabase/functions/on_dose_event_insert/`).
> 이 문서는 부모 `dose_events.missed` Insert → 자녀 폰에 푸시가 실제로 도착하도록 만드는 콘솔/CLI 작업.
> 시간: **약 15~20분**.

---

## 1단계 — Firebase Cloud Messaging Server Key 발급 (5분)

> ⚠️ FCM v1(HTTP v1) API가 표준이 됐지만 우리 Edge Function은 Legacy API(`fcm.googleapis.com/fcm/send` + Server Key) 사용. 신규 Firebase 프로젝트는 Legacy가 비활성화 상태이므로 Google Cloud Console에서 따로 켜야 함.

### 1-1. Google Cloud Console에서 Cloud Messaging API 활성화

1. <https://console.cloud.google.com> → 프로젝트 `kyh-medi` 선택
2. 햄버거(≡) → **API 및 서비스** → **라이브러리**
3. 검색창에 **`Cloud Messaging`** → 결과에서 **Cloud Messaging API**(파란 아이콘) 클릭
4. **사용 설정** 버튼 클릭 (이미 활성이면 "관리"로 표시됨 — OK)

### 1-2. Firebase 콘솔에서 Server Key 복사

1. <https://console.firebase.google.com> → 프로젝트 `kyh-medi` 선택
2. 좌측 톱니바퀴(⚙️) → **프로젝트 설정** → **Cloud Messaging** 탭
3. **Cloud Messaging API (Legacy)** 섹션 → **서버 키** 복사
   - 형태: `AAAA...` 로 시작하는 긴 문자열
   - 안 보이면 우측 ⋮ 메뉴 → **사용 설정** 클릭 (1-1 후에는 자동 노출)

→ 복사한 Server Key는 메모장에 잠시 보관. 다음 단계에서 Supabase secret으로 등록.

---

## 2단계 — Supabase Secret 등록 (3분)

### 옵션 A: CLI (Personal Access Token이 정상 발급된 경우)

```bash
cd C:/Users/y00h/IdeaProjects/kyh_medi
supabase login                                      # 토큰 paste
supabase link --project-ref evkuwuyxqyjmaargifnx
supabase secrets set FCM_SERVER_KEY="AAAA-방금-복사한-Server-Key"
```

### 옵션 B: Supabase 콘솔 UI (CLI 토큰 마스킹 이슈 시 — 우리 케이스는 어제 이미 실패함)

1. <https://supabase.com/dashboard> → 프로젝트 `kyh-medi`
2. 좌측 사이드바 **Edge Functions** → **Manage Secrets** 또는 **Secrets** 버튼
3. **Add new secret**:
   - Name: `FCM_SERVER_KEY`
   - Value: 1단계에서 복사한 Server Key
4. **Save**

---

## 3단계 — Edge Function 배포 (5분)

### 옵션 A: CLI

```bash
cd C:/Users/y00h/IdeaProjects/kyh_medi
supabase functions deploy on_dose_event_insert --no-verify-jwt
```

### 옵션 B: Supabase 콘솔 UI

1. 좌측 **Edge Functions** → **Create new function**
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
4. Supabase Webhook fire → Edge Function 호출 → FCM legacy API로 푸시 전송
5. **자녀 폰 알림 도착** ("○○님이 약을 못 드셨어요") — 백그라운드는 시스템 알림, 포그라운드는 `FcmMessageHandler._onForeground`가 헤드업 표시

### 디버깅

| 증상 | 확인 |
|---|---|
| Webhook이 Edge Function 안 부름 | Supabase 콘솔 → Webhooks → 해당 hook → **Logs** 탭에서 호출 기록 확인 |
| Edge Function 호출은 됐는데 FCM 안 감 | Edge Function → **Logs** 탭에서 `console.error` 확인. `FCM_SERVER_KEY` secret 미등록 가능성 |
| FCM 응답 200인데 폰 안 옴 | `child_users.fcm_token`이 비어 있거나 만료. 자녀 앱 재실행으로 `FcmService.registerForCurrentUser` 재호출 |

---

## 결과 체크리스트

- [ ] Cloud Messaging API 활성화 (Google Cloud Console)
- [ ] Firebase Server Key 복사
- [ ] Supabase `FCM_SERVER_KEY` secret 등록
- [ ] Edge Function `on_dose_event_insert` 배포 (Verify JWT OFF)
- [ ] Database Webhook 등록 (`dose_events` Insert → 함수)
- [ ] (Phase 13) E2E 푸시 도착 확인

이 5개 다 ✅면 Phase 11이 진짜로 끝납니다.

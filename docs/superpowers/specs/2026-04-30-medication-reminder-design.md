# 약 알림 앱 (KYH) — 디자인 스펙

| | |
|---|---|
| **문서 버전** | **v2.0 (2026-05-01 개정 — Supabase + 자녀 모니터링 도입)** |
| **작성일** | 2026-04-30 (v1.0), 2026-05-01 (v2.0) |
| **목표 출시** | Google Play 내부 테스트 트랙. **데드라인 소프트** (부트캠프 5/3 이후 계속 작업) |
| **프로젝트 코드명** | `kyh_medi` (정식 앱명 TBD) |
| **브랜드** | KYH (Korean Young Health) |
| **타깃 플랫폼** | Android (v1.0). iOS는 v2 |
| **타깃 사용자** | (1) 65세 이상 어르신 — **부모 모드** / (2) 부모님께 설치해드린 자녀 — **자녀 모드** (선택) |

---

## 변경 이력 (v1.0 → v2.0)

소모임 협의로 다음을 변경:

- **저장소 모델**: SQLite 단독 → **Hive(부모 로컬, 진실의 원천) + Supabase(원격, 자녀 모니터링용 옵셔널)**
- **신규 사용자 모드**: **자녀 모드** (Google / 이메일 가입, 부모 복약 read-only 모니터링)
- **신규 푸시**: 부모 폰의 `missed` 이벤트 → Supabase Edge Function → **FCM 푸시 → 자녀 폰** (페어링된 경우만)
- **N:M 가족 관계**: 한 자녀가 여러 부모 / 한 부모에 여러 자녀 모니터링 가능
- **데드라인 정책**: 부트캠프 5/3은 소프트 데드라인. 풀 기능 v1.0 우선

설계 원칙: **자녀 없는 부모 = Supabase 코드 자체가 실행되지 않음.** 부모 모드는 100% 오프라인 동작 보장.

---

## 0. 컨텍스트

100세 시대, 한국 어르신 다수가 만성질환 2개 이상 + 복합 처방. 약 한 번 깜빡함 = 응급실 방문으로 연결될 수 있는 진짜 문제. 시중 약 알림 앱은 어르신 친화적이지 않고 영어가 섞이거나 인터페이스가 복잡함.

v2.0 추가 컨텍스트: 부모님께 약 알림 앱을 설치해드린 자녀가 부모님 복약 상태를 멀리서 안심하고 확인하고 싶다는 요구. 자녀 모드로 충족.

**제품의 한 줄**: 한 알도, 잊지 않게 — 어르신을 위한 가장 단순한 약 알림 + 자녀가 안심하는 모니터링.

---

## 1. 핵심 결정 사항

| # | 결정 | 선택 |
|---|---|---|
| 1 | 출시 범위 | A — Play Console 내부 테스트 트랙 + AdMob/IAP 풀 패키지. **데드라인 소프트 (5/3 이후 계속)** |
| 2 | 데이터 모델 | C — 시간 슬롯 + 약별 체크박스 (하이브리드) |
| 3 | **저장소 (★ v2.0)** | **Hive (부모 로컬, 진실의 원천) + Supabase (자녀 모니터링용 옵셔널 원격)** |
| 4 | 알림 동작 | B — 정시 + 10분 후 + 20분 후 (총 3번), 미응답 시 자동 `missed` |
| 5 | 상태관리 | A — Provider |
| 6 | 약 등록 폼 | B — 텍스트 + 사진(선택, **부모 로컬만**) |
| 7 | 광고 | A — 배너만 (부모 모드만) + IAP 영구 광고 제거 ₩2,900 |
| 8 | **사용자 모드 (★ v2.0)** | **부모 모드 (기본, 로그인 없음) + 자녀 모드 (Google / 이메일 가입)** |
| 9 | **자녀 모니터링 (★ v2.0)** | **N부모 ↔ M자녀 페어링, missed 이벤트 푸시 + 오늘 현황 read-only** |

각 결정의 배경/대안은 본 스펙 작성 전 브레인스토밍 세션(v1.0: 2026-04-30, v2.0 개정: 2026-05-01)에서 검토함.

---

## 2. 시스템 아키텍처

### 2.1 전체 구조

```
┌──────────────────────────────────┐         ┌──────────────────────────────────┐
│  부모 폰 (Senior Mode)           │         │  자녀 폰 (Caregiver Mode)        │
│  - 로그인 화면 없음              │         │  - Google / Email 가입           │
│  - 시니어 UI (18pt+, 56dp+)      │         │  - 일반 UI                       │
│  - 100% Offline-First            │         │  - Online-Only (Realtime + 푸시) │
│  ─────────────────────────────   │         │  ─────────────────────────────   │
│  Presentation (Widget+Provider)  │         │  Presentation (Widget+Provider)  │
│  Domain (Service+Repository)     │         │  Domain (Service+Repository)     │
│  Data: Hive (진실의 원천)        │         │  Data: SupabaseClient + Realtime │
│         + 로컬 파일 (사진)       │         │                                  │
│  + (옵션) Supabase Sync (단방향) │  ─────► │                                  │
└──────────────────────────────────┘         └──────────────────────────────────┘
                  │                                              ▲
                  │ INSERT dose_events / medications             │ FCM 푸시
                  ▼                                              │
         ┌────────────────────────────────────────────────────────┐
         │  Supabase (백엔드)                                     │
         │  ─────────────────────────────────────────────         │
         │  Auth: anonymous(부모) / Google · Email(자녀)          │
         │  Database (PostgreSQL):                                │
         │     parent_devices, child_users, pairings,             │
         │     pairing_codes, medications, dose_events            │
         │  RLS (Row Level Security): 페어링된 자녀만 read        │
         │  Realtime: dose_events / medications (자녀 구독)       │
         │  Edge Function: on_dose_event_insert → FCM             │
         └────────────────────────────────────────────────────────┘
```

### 2.2 핵심 원칙

- **부모 폰 = Offline-First**: 인터넷 없어도 약 등록/체크/알림 모두 정상 작동. **자녀 연결 안 한 부모는 Supabase Client가 init만 되고 호출 안 됨**
- **단방향 흐름**: 부모 → Supabase → 자녀. 자녀는 read-only (자녀가 부모 약 정보 수정 불가)
- **의료정보 분리**: 약 데이터는 AdMob에 절대 전달 X. 광고 컨텍스트와 완전 격리
- **사진/메모는 부모 로컬만**: 의료정보 노출 최소화. Supabase에 안 감

### 2.3 Spring 멘탈 모델 매핑 (자바 개발자용)

| Flutter / Backend | Spring 비유 |
|---|---|
| Provider (`ChangeNotifier`) | `@Component` + `ApplicationEventPublisher` |
| Repository (Hive 기반) | `@Repository` (Spring Data JPA) |
| Service | `@Service` |
| Widget | Controller + View 합친 것 |
| `main.dart` | `@SpringBootApplication` 진입점 |
| `pubspec.yaml` | `pom.xml` |
| **Hive Box** | **JPA EntityManager + 테이블** (NoSQL, SQL 없음) |
| **Hive TypeAdapter** | **JPA `@Entity`** (`build_runner`로 자동 생성) |
| **Supabase Client** | **Spring Data JPA over REST + Spring Security RLS** |
| **Supabase Realtime** | **Spring `@MessageMapping` (WebSocket 구독)** |
| **Supabase Edge Function** | **Spring `@RestController` (서버리스, Deno/TypeScript)** |
| **FCM (`firebase_messaging`)** | **Spring `@Async` 푸시 게이트웨이** |

### 2.4 핵심 외부 라이브러리 (v2.0)

| 패키지 | 용도 | 버전 (^) | v1.0 → v2.0 |
|---|---|---|---|
| `flutter_local_notifications` | 부모 본인 알림 | 17.x | 그대로 |
| ~~`sqflite`~~ | ~~SQLite~~ | — | ❌ **제거** |
| **`hive` + `hive_flutter`** | NoSQL 로컬 DB | 2.x / 1.x | ✅ **신규** |
| **`hive_generator` + `build_runner`** | TypeAdapter 자동 생성 | dev | ✅ **신규** |
| **`supabase_flutter`** | Supabase Client + Auth + Realtime | 2.x | ✅ **신규** |
| **`firebase_core` + `firebase_messaging`** | FCM 푸시 (자녀 측) | 3.x / 15.x | ✅ **신규** |
| **`google_sign_in`** | 자녀 Google 로그인 | 6.x | ✅ **신규** (또는 supabase OAuth로 대체) |
| `provider` | 상태관리 | 6.x | 그대로 |
| `image_picker` | 약 사진 (부모) | 1.x | 그대로 |
| `path_provider` | 사진 저장 경로 | 2.x | 그대로 |
| `google_mobile_ads` | AdMob 배너 (부모만) | 5.x | 그대로 |
| `in_app_purchase` | IAP (부모만) | 3.x | 그대로 |
| `table_calendar` | 이력 캘린더 | 3.x | 그대로 |
| `timezone` | Asia/Seoul | 0.9.x | 그대로 |
| `permission_handler` | 권한 요청 | 11.x | 그대로 |

**라이브러리 추가는 검증된 것만**. 신규 패키지 추가 시 사용자 검토 후 결정.

---

## 3. 데이터 모델 (v2.0 — Hive + Supabase)

### 3.1 부모 폰: Hive 박스 5개 (진실의 원천)

자녀 페어링 여부와 무관하게 항상 사용. 모든 부모 측 변경은 여기 먼저 저장.

```dart
// 약 정의
@HiveType(typeId: 0)
class Medication {
  @HiveField(0) String id;          // UUID
  @HiveField(1) String name;
  @HiveField(2) String? photoPath;  // 로컬 파일 절대경로 (Supabase 동기화 X)
  @HiveField(3) String? memo;       // (Supabase 동기화 X)
  @HiveField(4) String colorHex;
  @HiveField(5) DateTime createdAt;
  @HiveField(6) DateTime? deletedAt;
}

// 시간 슬롯
@HiveType(typeId: 1)
class TimeSlot {
  @HiveField(0) String id;
  @HiveField(1) String label;       // "아침", "점심", "저녁"
  @HiveField(2) int hour;           // 0-23
  @HiveField(3) int minute;         // 0-59
  @HiveField(4) int daysOfWeek;     // 비트마스크: 월=1, 화=2, ..., 일=64
  @HiveField(5) bool enabled;
  @HiveField(6) DateTime? deletedAt;
}

// 슬롯 ↔ 약 매핑
@HiveType(typeId: 2)
class SlotMedication {
  @HiveField(0) String slotId;
  @HiveField(1) String medicationId;
  @HiveField(2) int doseCount;
}

// 복용 이력
@HiveType(typeId: 3)
class DoseEvent {
  @HiveField(0) String id;          // "YYYY-MM-DD|slotId|medId"
  @HiveField(1) DateTime date;
  @HiveField(2) String slotId;
  @HiveField(3) String medicationId;
  @HiveField(4) DateTime scheduledAt;
  @HiveField(5) DateTime? takenAt;  // null = 미복용
  @HiveField(6) String status;      // 'pending' | 'taken' | 'missed' | 'skipped'
  @HiveField(7) DateTime createdAt;
}

// 키-값 설정
@HiveType(typeId: 4)
class AppSettings {
  @HiveField(0) String userMode;          // 'parent' | 'child' (모드 선택 후 저장)
  @HiveField(1) bool adsRemoved;
  @HiveField(2) double seniorFontScale;
  @HiveField(3) String? pairedSupabaseUserId;  // 페어링 시 저장 (부모 anonymous user_id)
  @HiveField(4) String? fcmToken;              // 자녀 측 FCM 토큰
  @HiveField(5) int dbVersion;
}
```

**박스 5개**:

| 박스 | 타입 | 키 |
|------|------|-----|
| `medicationsBox` | `Box<Medication>` | `medication.id` |
| `slotsBox` | `Box<TimeSlot>` | `slot.id` |
| `slotMedicationsBox` | `Box<SlotMedication>` | `"{slotId}|{medId}"` |
| `doseEventsBox` | `Box<DoseEvent>` | `"{YYYY-MM-DD}|{slotId}|{medId}"` |
| `settingsBox` | `Box<AppSettings>` | 고정 키 `'app'` |

**쿼리 패턴 (SQL 없음, 람다 + Stream)**:

```dart
// 오늘 미복용 이벤트
final today = DateTime.now().toIso8601String().substring(0, 10);
final missed = doseEventsBox.values.where(
  (e) => e.id.startsWith(today) && e.status == 'missed',
).toList();

// 살아있는 약 목록
final alive = medicationsBox.values.where((m) => m.deletedAt == null).toList();
```

### 3.2 Supabase: 테이블 6개 (원격 미러)

자녀 페어링한 부모 + 자녀가 사용. 페어링 안 한 부모에겐 호출되지 않음.

```sql
-- 부모 디바이스 (anonymous auth user_id)
CREATE TABLE parent_devices (
  id UUID PRIMARY KEY,                  -- = auth.uid() (anonymous)
  device_label TEXT,                    -- 부모 본인이 입력한 라벨 (선택, 예: "내 폰")
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 자녀 사용자 (Google/Email auth user_id)
CREATE TABLE child_users (
  id UUID PRIMARY KEY,                  -- = auth.uid()
  email TEXT,
  display_name TEXT,
  fcm_token TEXT,                       -- FCM 푸시 발송용 (자녀 폰에서 갱신)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- N:M 페어링 조인
CREATE TABLE pairings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  child_user_id UUID NOT NULL REFERENCES child_users(id) ON DELETE CASCADE,
  parent_label TEXT,                    -- 자녀가 부모를 부르는 별칭 ("엄마", "아빠")
  paired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(parent_device_id, child_user_id)
);

-- 페어링 코드 (10분 TTL, 단일 사용)
CREATE TABLE pairing_codes (
  code TEXT PRIMARY KEY,                -- 6자리 숫자 문자열
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  redeemed_at TIMESTAMPTZ,
  redeemed_by UUID REFERENCES child_users(id)
);

-- 약 정의 미러 (부모 → Supabase 단방향 upsert)
CREATE TABLE medications (
  id UUID PRIMARY KEY,                  -- 부모 Hive Medication.id 와 동일 (UUID)
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  -- photo_path, memo, color_hex 는 미러하지 않음 (Q7 결정: 부모 로컬만)
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 복용 이벤트 미러 (부모 → Supabase 단방향 insert)
CREATE TABLE dose_events (
  id UUID PRIMARY KEY,
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  slot_id TEXT NOT NULL,                -- 부모 측 Hive slotId (자유 문자열)
  date DATE NOT NULL,
  status TEXT NOT NULL,                 -- 'taken' | 'missed'
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_dose_events_parent_date ON dose_events(parent_device_id, date);
CREATE INDEX idx_pairings_child ON pairings(child_user_id);
CREATE INDEX idx_pairings_parent ON pairings(parent_device_id);
```

### 3.3 RLS (Row Level Security)

```sql
ALTER TABLE parent_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE child_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairings ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE dose_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairing_codes ENABLE ROW LEVEL SECURITY;

-- parent_devices / child_users: 본인만
CREATE POLICY p_parent_self ON parent_devices FOR ALL USING (id = auth.uid());
CREATE POLICY p_child_self  ON child_users    FOR ALL USING (id = auth.uid());

-- pairings: 본인이 한쪽인 페어링만
CREATE POLICY p_pairings_owned ON pairings FOR ALL
  USING (parent_device_id = auth.uid() OR child_user_id = auth.uid());

-- medications / dose_events: 부모 본인 + 페어링된 자녀(read만)
CREATE POLICY p_meds_read ON medications FOR SELECT
  USING (
    parent_device_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pairings
      WHERE pairings.parent_device_id = medications.parent_device_id
        AND pairings.child_user_id = auth.uid()
    )
  );
CREATE POLICY p_meds_write ON medications FOR INSERT, UPDATE, DELETE
  USING (parent_device_id = auth.uid());

CREATE POLICY p_doses_read ON dose_events FOR SELECT
  USING (
    parent_device_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pairings
      WHERE pairings.parent_device_id = dose_events.parent_device_id
        AND pairings.child_user_id = auth.uid()
    )
  );
CREATE POLICY p_doses_write ON dose_events FOR INSERT, UPDATE, DELETE
  USING (parent_device_id = auth.uid());

-- pairing_codes: 부모는 자기 코드만, 자녀는 RPC를 통해서만 redeem
CREATE POLICY p_codes_parent_own ON pairing_codes FOR ALL
  USING (parent_device_id = auth.uid());
```

### 3.4 RPC (Stored Functions)

```sql
-- 부모: 6자리 코드 발급
CREATE FUNCTION create_pairing_code()
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_code TEXT;
BEGIN
  v_code := lpad(floor(random() * 1000000)::text, 6, '0');
  INSERT INTO pairing_codes(code, parent_device_id, expires_at)
    VALUES (v_code, auth.uid(), now() + interval '10 minutes');
  RETURN v_code;
END $$;

-- 자녀: 코드 입력으로 페어링 성립
CREATE FUNCTION redeem_pairing_code(p_code TEXT, p_label TEXT)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_parent UUID; v_pairing UUID;
BEGIN
  SELECT parent_device_id INTO v_parent
    FROM pairing_codes
    WHERE code = p_code AND expires_at > now() AND redeemed_at IS NULL;
  IF v_parent IS NULL THEN
    RAISE EXCEPTION 'invalid or expired code';
  END IF;
  INSERT INTO pairings(parent_device_id, child_user_id, parent_label)
    VALUES (v_parent, auth.uid(), p_label)
    ON CONFLICT (parent_device_id, child_user_id) DO NOTHING
    RETURNING id INTO v_pairing;
  UPDATE pairing_codes
    SET redeemed_at = now(), redeemed_by = auth.uid()
    WHERE code = p_code;
  RETURN v_pairing;
END $$;
```

### 3.5 동기화 규칙 (단방향)

| 부모 측 변경 | Supabase 동작 | 자녀 알림 |
|---|---|---|
| 약 추가 / 수정 | `medications` upsert | Realtime → 자녀 화면 자동 갱신 |
| 약 삭제 | `medications.deleted_at` set + 관련 `dose_events` 무효화 (옵션) | Realtime → 카드에서 사라짐 |
| 복용 (taken) | `dose_events` insert (status='taken') | Realtime → 자녀 화면 갱신 (조용히, 푸시 X) |
| 미응답 (missed) | `dose_events` insert (status='missed') | **Edge Function → FCM 푸시** |
| 사진 변경 | **동기화 X** (부모 로컬만) | — |
| 메모 변경 | **동기화 X** (부모 로컬만) | — |

### 3.6 실패 모드 (v1.0 단순화)

- Supabase 호출 실패 → 부모 앱은 **그냥 무시** (Hive에는 이미 저장됨)
- 재시도 큐 / 백그라운드 재동기화 → **v1.1+** (YAGNI)
- 자녀 측 오프라인 → 다음 접속 시 Realtime 자동 재구독

---

## 4. 알림 엔진

### 4.1 부모 본인 알림 — 예약 흐름

- 슬롯 등록/수정 시 → **다음 7일치 알림 미리 예약**
- 슬롯 1개 × 7일 × 3 retry = 최대 **21개 알림 예약**
- **앱 시작 시 보충 로직** (단순): 앱 실행될 때마다 "예약된 알림 중 가장 먼 시각"을 확인하고, 7일 미만이면 추가 예약. Workmanager는 v1.1+에서 도입
- 어르신은 보통 매일 1회 이상 앱을 여시므로 이 단순 방식으로 충분

### 4.2 알림 ID 컨벤션

```
notification_id = slot_id_hash × 1000 + day_offset × 10 + retry_index

예시: slot 5(해시), 내일(+1), +10분 retry(retry=1)
  → 5 × 1000 + 1 × 10 + 1 = 5011
```

→ 같은 슬롯의 retry 알림을 ID 패턴으로 일괄 cancel.

### 4.3 복용 체크 흐름

1. 어르신 알림 탭 → 앱 열림 → 그 슬롯 화면으로 자동 라우팅 (payload에 slot_id)
2. 슬롯의 약별 체크박스 표시 (큰 체크박스, 약 사진 함께)
3. **"복용 완료"** 큰 버튼 탭
4. 그 슬롯의 `+10분` / `+20분` retry 알림 cancel
5. `DoseEvent` 업데이트 (`status='taken'`, `takenAt=now()`)
6. (페어링 있으면) Supabase `dose_events` insert — **fire-and-forget**

### 4.4 미복용 처리

- 알림은 **총 3번만 발사** (정시, +10분, +20분). 4번째 알림은 없음
- 예정 시각 기준 +30분 이후에도 `takenAt`이 NULL이면 → 클라이언트 사이드 워커(앱 진입 시 + 화면 진입 시 trigger)가 `status='missed'`로 업데이트
- 이력 캘린더에 빨간 점 표시
- (페어링 있으면) Supabase `dose_events` insert (status='missed') → 자녀 푸시 트리거
- 별도 백그라운드 데몬은 안 씀 (배터리 부담 ↓, 구현 단순화)

### 4.5 시간대 (R2 대응)

- 앱 시작 시 `tz.initializeTimeZones()` + `tz.setLocalLocation(tz.getLocation('Asia/Seoul'))` 호출
- 누락 시 UTC로 예약돼 9시간 어긋남

### 4.6 사운드/진동

- v1.0: 시스템 기본 알림음 + 진동
- v1.1+: 커스텀 음성 알림 ("어머님, 약 드실 시간이에요")

### 4.7 자녀 푸시 (v2.0 신규)

**Supabase Edge Function** (`on_dose_event_insert`, Database Webhook으로 트리거):

```typescript
// AFTER INSERT ON dose_events
import { serve } from 'std/http/server.ts'

serve(async (req) => {
  const { record } = await req.json()
  if (record.status !== 'missed') {
    return new Response('skip', { status: 200 })
  }

  // 1. 약 이름
  const { data: med } = await supabase
    .from('medications')
    .select('name')
    .eq('id', record.medication_id)
    .single()

  // 2. 페어링된 자녀들의 FCM 토큰 + 별칭
  const { data: children } = await supabase
    .from('pairings')
    .select('parent_label, child_users(fcm_token, display_name)')
    .eq('parent_device_id', record.parent_device_id)

  // 3. FCM 발송
  for (const c of children ?? []) {
    const token = c.child_users?.fcm_token
    if (!token) continue
    await fcmSend({
      token,
      notification: {
        title: '복약 알림',
        body: `${c.parent_label ?? '부모님'}이 ${med?.name ?? '약'}을(를) 못 드셨어요`,
      },
      data: {
        type: 'dose_missed',
        parent_device_id: record.parent_device_id,
        slot_id: record.slot_id,
        medication_id: record.medication_id,
      },
    })
  }
  return new Response('ok', { status: 200 })
})
```

**자녀 폰 측**:

- `firebase_messaging` background handler → Android 시스템 알림 표시
- 알림 탭 → 자녀 모드 홈 → 해당 부모 카드 → 오늘 현황 화면

### 4.8 v1.0에서 안 만드는 것 (YAGNI)

- 푸시 묶기 (같은 슬롯의 여러 약 → 1개 푸시) → v1.1+
- 푸시 재시도 / Supabase 동기화 큐 → v1.1+
- 부모가 묶음 처리 시 발사된 푸시 자동 취소 → v1.1+

---

## 5. 화면 구성 (v2.0 — 14개: 분기 1 + 부모 9 + 자녀 4)

### 5.1 첫 실행 분기 (1개, 신규)

| # | 화면 | 진입 | 핵심 |
|---|---|---|---|
| 0 | **모드 선택** | 앱 첫 실행 1회 | "부모님이세요?" / "자녀세요?" 큰 버튼 2개. 선택 후 `settings.userMode`에 저장, 다음 실행부터 자동 진입 |

### 5.2 부모 모드 (8 + 1개)

| # | 화면 | 진입 경로 | 핵심 액션 |
|---|---|---|---|
| 1 | **온보딩** | 부모 모드 첫 실행 1회 | 권한 안내 + 요청 |
| 2 | **메인 — 오늘의 약** | 부모 모드 기본 화면 | 시간 슬롯 카드 보기 |
| 3 | **복용 체크** | 알림 탭 또는 메인에서 슬롯 카드 탭 | "복용 완료" |
| 4 | **약 목록** | 메인 → 메뉴 → 약 관리 | 약 추가/편집 |
| 5 | **약 등록 폼** | 약 목록 → "+ 새 약" | 약 정보 입력 |
| 6 | **시간 슬롯 관리** | 메인 → 메뉴 → 시간 관리 | 슬롯 + 약 묶기 |
| 7 | **이력 캘린더** | 메인 → 메뉴 → 이력 | 복용 패턴 보기 |
| 8 | **설정** | 메인 → 메뉴 → 설정 | 광고 제거 결제, 시니어 모드, **자녀와 연결** 진입 |
| **8b** | **자녀와 연결 (v2.0 신규)** | 설정 → "자녀와 연결" | 6자리 코드 표시 + 연결된 자녀 목록 + 연결 해제 버튼 |

### 5.3 자녀 모드 (4개, 신규)

| # | 화면 | 진입 | 핵심 |
|---|---|---|---|
| 9 | **자녀 가입 / 로그인** | 자녀 모드 첫 진입 | Google 로그인 / 이메일 가입 탭 |
| 10 | **자녀 홈 — 부모 목록** | 가입 후 / 매 진입 | 페어링된 부모 카드들 + "+ 부모님 추가" + 각 카드의 오늘 현황 요약 (3/4 완료) |
| 11 | **부모 추가 — 코드 입력** | 자녀 홈 → "+ 부모님 추가" | 6자리 코드 입력 + 별칭 입력 |
| 12 | **부모 상세 — 오늘 현황** | 자녀 홈 → 부모 카드 탭 | 슬롯별 ✅/❌/⏳ + 약 이름 (read-only) + 푸시 ON/OFF |

### 5.4 화면별 핵심 위젯

- **메인(#2)**: `ListView` of `SlotCard` — 슬롯 시각 + 약 사진들 + 상태 뱃지(pending/taken/missed)
- **복용 체크(#3)**: 큰 약 사진 + 약 이름 (24pt+) + 약 메모 + **"복용 완료"** 버튼 (높이 80dp+)
- **약 등록 폼(#5)**: 약 이름 input + 사진 picker(카메라/갤러리/없음) + 메모 input + 색상 picker
- **이력 캘린더(#7)**: `table_calendar` + 일별 점 표시(초록/빨강/회색) + 날짜 탭 시 그날 슬롯 상세
- **자녀와 연결(#8b)**: 큰 6자리 코드(JetBrains Mono 60pt) + 카운트다운 (10:00) + 연결된 자녀 리스트
- **자녀 홈(#10)**: 부모 카드 (별칭 큰 글씨 + 오늘 진행률 게이지) + FAB "+ 부모님 추가"
- **부모 상세(#12)**: 부모 별칭 + 시간 슬롯 리스트 (각 슬롯에 약 이름 + 상태 아이콘)

### 5.5 라우팅

- `Navigator 1.0` (Flutter 기본). `go_router` 도입은 v1.1+로 미룸 — 14개 화면 규모도 기본 라우팅으로 충분
- `main.dart`에서 `settings.userMode` 확인 후 conditional initial route (parent / child / mode_select)

---

## 6. 디자인 시스템

### 6.1 부모 모드 — 시니어 디자인 (v1.0과 동일)

| 항목 | 값 | 비고 |
|---|---|---|
| 본문 폰트 크기 | 18pt 이상 | Material 기본 14pt 대비 1.3× |
| 버튼 텍스트 크기 | 22pt 이상 | |
| 버튼 최소 높이 | 56dp | Material 기본 48dp 대비 ↑ |
| 색 대비 | WCAG AAA | 배경 #FBFAF6 / 텍스트 #1A1A1A → 16.1:1 |
| 컬러 팔레트 | 베이지 + 다크잉크 + 주황 약봉투 | |
| 폰트 (한글) | Pretendard Variable | 무료 상업이용 OK |
| 폰트 (영문 디스플레이) | Bricolage Grotesque | Google Fonts |
| 폰트 (메타/숫자) | JetBrains Mono | 무료 |
| 애니메이션 | 페이드만 | 슬라이드/확대축소 X (어지러움) |
| 한 화면 한 동작 | 강제 | 메인은 "복용 완료" 버튼 1개 |

### 6.2 자녀 모드 — 일반 디자인 (v2.0 신규)

- 본문 14pt, 버튼 16pt — Material 기본
- 버튼 최소 높이 48dp — Material 기본
- 부모 카드 위 정보(별칭 / 진행률)는 시니어 스타일 차용 (큰 글씨, 명확한 상태) — 부모를 빠르게 식별
- 색 대비 WCAG AA 이상
- 폰트는 Pretendard로 통일

### 6.3 디자인 자산 출처

- 아이콘: Lucide / Phosphor Icons / Material Symbols (모두 MIT/Apache, 상업 이용 OK)
- 일러스트: unDraw / Storyset
- 폰트: 위 표 폰트 모두 무료
- 컬러/스타일: index.html 기반 자체 작업물
- **금지**: 외부 상용 앱(예: TodoMedison)의 이미지/아이콘 직접 사용

---

## 7. 수익화

### 7.1 AdMob 배너 (부모 모드만)

| 화면 | 배너 노출 |
|---|---|
| 0. 모드 선택 | ❌ |
| 1. 온보딩 | ❌ |
| 2. 메인 | ❌ |
| 3. 복용 체크 | ❌ (R3 의료광고 정책 회피) |
| 4. 약 목록 | ✅ 하단 |
| 5. 약 등록 폼 | ❌ |
| 6. 시간 슬롯 관리 | ❌ |
| 7. 이력 캘린더 | ✅ 하단 |
| 8. 설정 | ✅ 하단 |
| 8b. 자녀와 연결 | ❌ |
| **9~12 (자녀 모드 전부)** | **❌** |

자녀 모드는 사용자 수가 적고 의료 컨텍스트 위험이 있어 광고 정책 적용 X.

- 사이즈: BANNER (50dp)
- 카테고리: 일반 (의료/약 카테고리 회피)
- **사용자 입력 약 이름은 절대 광고 컨텍스트로 전달 X**

### 7.2 IAP (광고 제거, 부모 모드만)

- 상품 ID: `kyh_remove_ads_lifetime`
- 가격: ₩2,900 영구 (`PRODUCT_TYPE_NON_CONSUMABLE`)
- 결제 완료 → `settings.adsRemoved = true` → 모든 배너 즉시 숨김
- **구매 복원 버튼 필수** (Play 정책) — 설정 화면에 노출
- 자녀 모드는 IAP 없음 (처음부터 광고 없음)

---

## 8. 프로젝트 구조 (v2.0 Feature-first)

```
lib/
├── main.dart                               # settings.userMode 분기
├── app.dart                                # MaterialApp + ThemeData
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── senior_theme.dart               # 부모 모드용
│   │   ├── caregiver_theme.dart            # 자녀 모드용
│   │   └── tokens.dart
│   ├── hive/
│   │   ├── hive_init.dart                  # 박스 open + adapter 등록
│   │   └── adapters/                       # *.g.dart (build_runner 생성)
│   ├── supabase/
│   │   ├── supabase_init.dart              # SupabaseClient 셋업
│   │   ├── parent_sync_service.dart        # 부모 → Supabase 단방향 push
│   │   └── child_realtime_service.dart     # 자녀 Realtime 구독
│   ├── firebase/
│   │   ├── firebase_init.dart
│   │   ├── fcm_service.dart                # 자녀 토큰 등록 + handler
│   │   └── fcm_message_handler.dart
│   ├── notification/                       # 부모 본인 로컬 알림 (기존)
│   │   ├── notification_service.dart
│   │   └── notification_scheduler.dart
│   ├── time/
│   │   └── timezone_init.dart
│   └── auth/
│       ├── parent_anonymous_auth.dart      # 부모 anonymous (페어링 시점에 trigger)
│       └── child_auth.dart                 # 자녀 Google/Email
├── features/
│   ├── mode_select/                        # 화면 0
│   │   └── mode_select_screen.dart
│   ├── parent/                             # 부모 모드
│   │   ├── medication/
│   │   │   ├── data/                       # MedicationRepository (Hive)
│   │   │   ├── domain/
│   │   │   └── ui/
│   │   ├── slot/
│   │   ├── intake/
│   │   │   └── ui/
│   │   │       ├── home_screen.dart        # 화면 2
│   │   │       ├── intake_check_screen.dart # 화면 3
│   │   │       └── history_calendar_screen.dart # 화면 7
│   │   ├── onboarding/                     # 화면 1
│   │   ├── monetization/                   # AdMob + IAP
│   │   ├── settings/                       # 화면 8
│   │   └── pairing/                        # 화면 8b — 자녀와 연결
│   └── child/                              # 자녀 모드
│       ├── auth/                           # 화면 9
│       ├── home/                           # 화면 10
│       ├── add_parent/                     # 화면 11
│       └── parent_detail/                  # 화면 12
└── shared/
    ├── widgets/
    │   ├── senior_button.dart
    │   ├── senior_input.dart
    │   └── caregiver_card.dart
    └── utils/
        └── date_utils.dart
```

**원칙**: 한 화면 작업할 때 폴더 1개만 열면 됨. 부모 모드와 자녀 모드는 `features/` 아래 명확히 분리.

---

## 9. 테스트 전략 (v2.0)

| 종류 | 우선순위 | 대상 |
|---|---|---|
| 단위 테스트 | ✅ 필수 | NotificationScheduler 시간 계산, 모든 Hive Repository CRUD, ParentSyncService 페이로드 직렬화 |
| 통합 테스트 | ✅ 우선순위 | (1) 알림 예약 → 발사 → cancel, (2) 부모 missed → Supabase insert → Edge Function fire → FCM 모킹, (3) 페어링 코드 발급 → redeem |
| 수동 E2E 체크리스트 | ✅ 필수 | 아래 |
| 위젯 테스트 | ❌ Skip | 잉여시간에만 |

### E2E 체크리스트 (부모 모드, v1.0과 동일)

- [ ] 첫 실행 모드 선택 → "부모님이세요?" 선택 → 부모 온보딩 진입
- [ ] 권한 거부 시 graceful 처리 (앱 죽지 않음)
- [ ] 약 등록: 텍스트만 / 텍스트+사진 / 사진 권한 거부 케이스
- [ ] 시간 슬롯 생성 + 약 묶기
- [ ] 알림 트리거 (실시간 또는 시간 조작)
- [ ] 알림 탭 → 복용 체크 화면 진입
- [ ] "복용 완료" 탭 → retry 알림 cancel 확인
- [ ] +10분/+20분 retry 알림 정상 발사
- [ ] 미복용 처리 → 캘린더 빨간 점
- [ ] 광고 표시되는 화면/안 되는 화면 확인
- [ ] IAP 구매 → 광고 즉시 사라짐
- [ ] IAP 복원 버튼 동작
- [ ] 폰 재부팅 후 알림 살아있는지 (BOOT_COMPLETED 권한)

### E2E 체크리스트 (자녀 모니터링, v2.0 신규)

- [ ] 자녀 모드 첫 실행 → 가입 → 홈 (빈 상태 화면)
- [ ] 부모: 설정 → "자녀와 연결" → 6자리 코드 표시
- [ ] 자녀: 코드 입력 → "엄마" 별칭 → 홈에 부모 카드 표시
- [ ] 부모: 약 미응답 → 자녀 폰에 푸시 도착 ("어머님이 ○○약 못 드셨어요")
- [ ] 자녀: 부모 카드 탭 → 오늘 현황 화면 → 약 이름 + ✅/❌/⏳ 표시
- [ ] 자녀 read-only 검증 (약 정보 수정 UI 자체 없음)
- [ ] 부모: 약 추가/수정/삭제 → 자녀 화면 자동 갱신 (Realtime)
- [ ] 부모/자녀: 연결 해제 → 양쪽 화면에서 사라짐
- [ ] **자녀 없는 부모: 네트워크 끊고 모든 부모 모드 동작 정상 (Supabase 호출 0회)**
- [ ] N:M 검증: 자녀 1명이 부모 2명 추가, 부모 1명이 자녀 2명 추가

---

## 10. 리스크 & 대응

| # | 리스크 | 대응 |
|---|---|---|
| R1 | Android 13+ 알림 권한 미요청 → 알림 무동작 | D2 첫 45분에 권한 요청 플로우 우선 구현 |
| R2 | Timezone 미초기화 → 9시간 어긋남 | 부팅 시 `tz.initializeTimeZones()` + 단위 테스트 |
| R3 | AdMob 의료/약 정보 광고 정책 위반 | 약 이름 등 입력값을 광고 SDK에 절대 전달 X. 일반 카테고리. 광고 노출 화면도 핵심 사용 동선 외로 한정 |
| R4 | IAP 디버그 빌드에서 테스트 불가 | 내부 테스트 트랙 업로드 후 실기기 검증 |
| R5 | Play 신규 개발자 정책 (정식 출시까지 14일 + 12명 테스터) | 1차 목표는 내부 테스트 트랙 |
| R6 | 사진 권한 (Android 13+ `READ_MEDIA_IMAGES`) | 거부 시 graceful 폴백 (텍스트만 등록 가능) |
| R7 | Google Play 개발자 계정 신원확인 1~2일 지연 | 2026-04-30에 신청 완료 (대기 중) |
| R8 | AdMob 첫 결제 24~48시간 지연 가능 | 시연은 테스트 광고 ID로 |
| **R9** | **Supabase 무료 티어 한도** (월 50K MAU, 500MB DB, 2GB 대역폭) | v1.0 사용량은 매우 적음 (이벤트 텍스트만, 사진 X). 한도 모니터링 셋업 |
| **R10** | **FCM 첫 셋업 복잡도** (Firebase 콘솔 + `google-services.json` + SHA-1 키 등록) | 별도 작업 (1~2시간 예상). 자녀 푸시는 페어링이 있어야 작동하므로, 셋업 못 끝내면 v1.0.1 패치로 미룰 수 있음 |
| **R11** | **개인정보**: 약 이름이 Supabase에 평문 저장 | RLS로 페어링된 자녀만 read 가능. 사진/메모는 부모 로컬에만. 개인정보 처리방침에 명시 |
| **R12** | **자녀 가입 마찰** (Google OAuth SHA-1 셋업 누락 등) | OAuth 셋업 우선. 안 되면 이메일/비번 옵션을 폴백 |
| **R13** | **Edge Function 콜드 스타트** (1~3초 지연) | missed 푸시는 즉시성보다 도달성이 중요 → 콜드 스타트 허용 |
| **R14** | **Supabase RLS 정책 실수로 데이터 누출** | RLS 정책 단위 테스트 필수 (다른 사용자 토큰으로 접근 차단 검증) |

---

## 11. 일정 / 출시 단계 (v2.0 — 소프트 데드라인)

### 데드라인 정책

- 부트캠프 5/1~5/3은 **소프트 데드라인**. 5/3 이후에도 계속 작업 (사용자 명시 2026-05-01)
- 풀 기능 v1.0 (자녀 모드 포함) 우선
- 5/3 안에 못 끝내도 부담 없이 출시 일정 조정

### 출시 단계

1. **v1.0**: 부모 모드 + 자녀 페어링 + 푸시 + AdMob + IAP. 출시일 유연
2. **v1.0.x 패치**: 버그 수정, 자녀 푸시 묶기, 동기화 큐
3. **v1.1+**: 자녀 통계/그래프, 카카오 알림톡, iOS 등

### v1.1+ 백로그 (출시 후)

- ~~가족 공유 알림~~ → **v1.0에 포함됨**
- 자녀 측 통계/그래프 (주간/월간 복약률)
- Hive ↔ Supabase 양방향 sync (자녀 권한 확장)
- 카카오 알림톡 채널
- SMS 백업
- iOS 확장
- 위젯 (홈 화면)
- 커스텀 음성 알림
- 약 사진 OCR 자동 인식
- 푸시 묶기 (같은 슬롯 여러 약)
- 동기화 재시도 큐

---

## 12. 다음 단계

이 v2.0 디자인 스펙 승인 후:

1. 사용자 최종 검토
2. **구현 계획서** v2.0으로 재작성 — 기존 `2026-04-30-medication-reminder-plan.md` 를 변경 사항(Hive 도입, Supabase 셋업, FCM, 자녀 모드 화면 4개)을 반영하여 통째로 갱신
3. 실행: 환경(완료) → Supabase / Firebase 프로젝트 셋업 → `flutter create` → Phase 별 구현

---

## 13. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|---|---|---|
| v1.0 | 2026-04-30 | 초기 스펙 (SQLite 단독, 자녀 기능 없음, 3일 데드라인) |
| v2.0 | 2026-05-01 | 저장소 Hive + Supabase 도입, 자녀 모드 신설(가입·페어링·홈·상세), FCM 푸시(Edge Function), N:M 가족 관계, 데드라인 소프트화 |

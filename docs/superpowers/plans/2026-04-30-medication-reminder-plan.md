# 약 알림 앱 (KYH) v2.0 구현 계획서

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter로 어르신용 약 알림 앱 + 자녀 모니터링을 개발해 Google Play 내부 테스트 트랙에 업로드한다 (소프트 데드라인, 풀 기능 v1.0 우선).

**Architecture:** 부모 폰은 Hive 기반 100% 오프라인 우선. 페어링한 부모만 Supabase에 단방향 push. 자녀 폰은 Supabase Realtime으로 read-only 모니터링 + Edge Function이 missed → FCM 푸시. 한 코드베이스에 부모/자녀 모드 분기 (`features/parent`, `features/child`).

**Tech Stack:** Flutter 3.41.9 + Dart 3.5+, hive + hive_flutter (로컬), supabase_flutter (원격), firebase_core + firebase_messaging (푸시), provider (상태), flutter_local_notifications, image_picker, google_mobile_ads, in_app_purchase, table_calendar, timezone, permission_handler.

---

## 0. 가이드 & 사전 준비

### 0.1 본 계획서 사용법

- **Phase 단위로 검토 → 실행 → 다음 Phase**. 14개 Phase × 평균 3~7개 Task.
- 각 Task의 step은 2~5분 단위. 막히면 그 Task를 격리해서 디버깅.
- TDD 적용 Task: 데이터 레이어 (Repository 5개), 시간 계산 (NotificationScheduler), 페어링 코드 발급. UI는 수동 검증.
- v1.0 → v2.0 변경 핵심: SQLite → Hive, 자녀 모드 4개 화면 + 모드 선택 1개 추가, Supabase + FCM 도입.

### 0.2 자바 개발자 빠른 매핑

| Java / Spring | Flutter / 백엔드 |
|---|---|
| `String s = "x";` | `String s = "x";` (동일) |
| `final` | `final` (동일) |
| `List<String>` | `List<String>` (동일) |
| `Map<String, Object>` | `Map<String, dynamic>` |
| `null` 안전 | `String?` (`?` 붙이면 nullable) |
| `Optional<X>` | `X?` + `?.` / `??` 연산자 |
| `CompletableFuture<X>` | `Future<X>` + `async / await` |
| `Stream<X>` (RxJava) | `Stream<X>` |
| `pom.xml` | `pubspec.yaml` |
| Maven `mvn` | `flutter pub` / `dart` |
| `@Component` + 이벤트 발행 | `ChangeNotifier` + Provider 주입 |
| `@Repository` (Spring Data JPA) | `*Repository` 클래스 (Hive Box 래핑) |
| `@Service` | `*Service` 클래스 |
| `@RestController` | Supabase Edge Function (Deno + TS) |
| `@MessageMapping` (WebSocket) | Supabase Realtime 구독 |
| `@Async` 푸시 게이트웨이 | FCM (`firebase_messaging`) |
| JPA `@Entity` | Hive `@HiveType` 클래스 (`build_runner` 자동 생성) |
| EntityManager | `Box<T>` (Hive 박스) |
| Spring Security | Supabase RLS (Postgres Row Level Security) |

### 0.3 환경 셋업 완료 상태 (2026-05-01)

이미 끝난 항목:

- ✅ Flutter SDK 3.41.9 stable, `C:\Users\y00h\flutter\` (수동 ZIP 설치, PATH 등록)
- ✅ Android Studio + SDK Manager (cmdline-tools + system image)
- ✅ Android SDK 36.1.0 (Android 16) + 라이선스 동의
- ✅ AVD: Pixel 7 API 36 (Android 16) 부팅 확인됨
- ✅ `flutter doctor`: "No issues found!"
- ⏳ Play Console 신원확인 대기 (4/30 신청)
- ❌ Supabase 프로젝트 (Phase 0에서 생성)
- ❌ Firebase 프로젝트 / FCM (Phase 0에서 생성)
- ❌ Flutter 프로젝트 스캐폴드 (Phase 0에서 생성)

---

## 파일 구조 (전체 맵, v2.0)

```
kyh_medi/
├── android/
│   └── app/
│       ├── build.gradle                             # AdMob app ID, signing config
│       ├── google-services.json                     # FCM (Phase 0)
│       └── src/main/AndroidManifest.xml             # 권한 + AdMob 메타
├── supabase/                                         # Supabase CLI 작업물 (Phase 0)
│   ├── migrations/                                   # 스키마 SQL
│   ├── functions/
│   │   └── on_dose_event_insert/                    # Edge Function (Phase 11)
│   │       └── index.ts
│   └── config.toml
├── lib/
│   ├── main.dart                                    # 진입점 + 모드 분기
│   ├── app.dart                                     # MaterialApp 셸
│   ├── core/
│   │   ├── theme/
│   │   │   ├── tokens.dart
│   │   │   ├── senior_theme.dart                    # 부모용
│   │   │   └── caregiver_theme.dart                 # 자녀용
│   │   ├── hive/
│   │   │   ├── hive_init.dart                       # 박스 open + adapter 등록
│   │   │   └── (자동 생성).g.dart 파일들
│   │   ├── supabase/
│   │   │   ├── supabase_init.dart
│   │   │   ├── supabase_config.dart                 # URL + anon key 상수
│   │   │   ├── parent_anonymous_auth.dart           # 부모 anonymous 가입
│   │   │   ├── parent_sync_service.dart             # 부모 → Supabase 단방향 push
│   │   │   └── child_realtime_service.dart          # 자녀 Realtime 구독
│   │   ├── firebase/
│   │   │   ├── firebase_init.dart
│   │   │   ├── fcm_service.dart                     # 자녀 토큰 등록 + handler
│   │   │   └── fcm_message_handler.dart
│   │   ├── notification/
│   │   │   ├── notification_service.dart            # 부모 본인 로컬 알림
│   │   │   └── notification_scheduler.dart          # 시간 계산 + ID 인코더
│   │   └── time/
│   │       └── timezone_init.dart                   # Asia/Seoul
│   ├── features/
│   │   ├── mode_select/
│   │   │   └── mode_select_screen.dart              # 화면 0
│   │   ├── parent/                                  # 부모 모드
│   │   │   ├── medication/
│   │   │   │   ├── domain/medication.dart           # Hive @HiveType
│   │   │   │   ├── data/medication_repository.dart
│   │   │   │   └── ui/{medication_list_screen.dart, medication_form_screen.dart, medications_provider.dart}
│   │   │   ├── slot/
│   │   │   │   ├── domain/{time_slot.dart, slot_medication.dart}
│   │   │   │   ├── data/slot_repository.dart
│   │   │   │   └── ui/{slot_list_screen.dart, slot_form_screen.dart, slots_provider.dart}
│   │   │   ├── intake/
│   │   │   │   ├── domain/dose_event.dart           # Hive
│   │   │   │   ├── data/dose_event_repository.dart
│   │   │   │   └── ui/{home_screen.dart, intake_check_screen.dart, history_calendar_screen.dart, intake_provider.dart}
│   │   │   ├── onboarding/onboarding_screen.dart    # 화면 1
│   │   │   ├── settings/
│   │   │   │   ├── domain/app_settings.dart         # Hive
│   │   │   │   ├── data/settings_repository.dart
│   │   │   │   └── ui/settings_screen.dart          # 화면 8
│   │   │   ├── monetization/
│   │   │   │   ├── ads_provider.dart
│   │   │   │   ├── ad_banner.dart
│   │   │   │   └── iap_service.dart
│   │   │   └── pairing/                             # 화면 8b
│   │   │       ├── data/pairing_repository.dart
│   │   │       └── ui/{connect_child_screen.dart, pairing_provider.dart}
│   │   └── child/                                   # 자녀 모드
│   │       ├── auth/                                # 화면 9
│   │       │   ├── child_auth_service.dart
│   │       │   └── ui/child_login_screen.dart
│   │       ├── home/                                # 화면 10
│   │       │   ├── data/child_home_repository.dart
│   │       │   └── ui/{child_home_screen.dart, child_home_provider.dart}
│   │       ├── add_parent/                          # 화면 11
│   │       │   └── ui/add_parent_screen.dart
│   │       └── parent_detail/                       # 화면 12
│   │           ├── data/parent_detail_repository.dart
│   │           └── ui/{parent_detail_screen.dart, parent_detail_provider.dart}
│   └── shared/
│       ├── widgets/
│       │   ├── senior_button.dart
│       │   ├── senior_input.dart
│       │   └── caregiver_card.dart
│       └── utils/
│           └── date_utils.dart
├── test/
│   ├── core/
│   │   ├── notification_scheduler_test.dart
│   │   └── timezone_init_test.dart
│   └── features/parent/
│       ├── medication/medication_repository_test.dart
│       ├── slot/slot_repository_test.dart
│       └── intake/dose_event_repository_test.dart
├── assets/
│   ├── fonts/PretendardVariable.ttf
│   └── icon/icon.png
└── pubspec.yaml
```

---

## Phase 0: 프로젝트 골조 + Hive/Supabase/Firebase 셋업

### Task 0.5: Flutter 프로젝트 스캐폴드

**Files:**
- Create: `C:\Users\y00h\IdeaProjects\kyh_medi\` (이미 존재, `docs/`만 있음)

- [ ] **Step 1: 스캐폴드 (이미 있는 docs/ 보호)**

```bash
cd /c/Users/y00h/IdeaProjects/kyh_medi
flutter create --project-name kyh_medi --org com.kyh.medi --platforms android .
```

기존 `docs/`, `.git/`이 있으므로 Flutter가 충돌 경고할 수 있음. 충돌 시:

```bash
flutter create --project-name kyh_medi --org com.kyh.medi --platforms android --overwrite .
```

(`--overwrite`는 위험 — `git status`로 docs/는 안 건드려졌는지 확인 필수)

- [ ] **Step 2: 첫 실행 — 기본 카운터 앱**

```bash
flutter run
```

Expected: 에뮬레이터(Pixel 7 API 36)에 카운터 앱 표시.

- [ ] **Step 3: 종료 후 커밋**

```bash
git add -A
git commit -m "chore: Flutter 프로젝트 스캐폴드 (v2.0)"
```

### Task 0.6: pubspec.yaml 의존성 (Hive + Supabase + Firebase)

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml 통째 교체**

```yaml
name: kyh_medi
description: "한 알도, 잊지 않게. 어르신용 약 알림 + 자녀 모니터링."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # 로컬 저장 (부모 진실의 원천)
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.4
  path: ^1.9.0

  # 원격 저장 + 자녀 인증
  supabase_flutter: ^2.5.0

  # FCM 푸시 (자녀)
  firebase_core: ^3.3.0
  firebase_messaging: ^15.0.4

  # 상태관리 + 로컬 알림 + 시간
  provider: ^6.1.2
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  permission_handler: ^11.3.1

  # UI
  image_picker: ^1.1.2
  table_calendar: ^3.1.2
  intl: ^0.19.0

  # 수익화 (부모만)
  google_mobile_ads: ^5.1.0
  in_app_purchase: ^3.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true
  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/PretendardVariable.ttf
```

- [ ] **Step 2: Pretendard 폰트 다운로드 + 배치**

```bash
mkdir -p assets/fonts
```

브라우저에서 https://github.com/orioncactus/pretendard/releases → 최신 zip → `PretendardVariable.ttf` 추출 → `assets/fonts/PretendardVariable.ttf` 저장.

- [ ] **Step 3: pub get**

```bash
flutter pub get
```

Expected: `Got dependencies!`. 충돌 시 메시지 따라 패치 버전 조정.

- [ ] **Step 4: 커밋**

```bash
git add pubspec.yaml pubspec.lock assets/fonts/
git commit -m "chore: Hive + Supabase + Firebase 의존성 + Pretendard 폰트"
```

### Task 0.7: Supabase 프로젝트 생성 + CLI 셋업

**Files:**
- Create: `supabase/` (CLI가 생성)
- Create: `supabase/migrations/0001_init.sql`

- [ ] **Step 1: Supabase 콘솔에서 프로젝트 생성**

브라우저: https://supabase.com → "Start your project" → 깃허브/이메일 가입 → "New Project":

- Organization: 본인 (없으면 생성)
- Project name: `kyh-medi`
- Database password: 강한 비밀번호 (메모)
- Region: `Northeast Asia (Seoul)` (ap-northeast-2)
- Pricing plan: Free

→ 생성까지 ~2분. 완료 후 **Project URL** + **anon public key** 메모 (Settings → API).

- [ ] **Step 2: Supabase CLI 설치**

```bash
npm install -g supabase
supabase --version
```

Expected: `1.x.x` 출력. (Node 18+ 필요. 없으면 https://nodejs.org에서 LTS 설치.)

- [ ] **Step 3: 프로젝트 디렉토리 init**

```bash
supabase init
```

→ `supabase/config.toml`, `supabase/seed.sql` 등 생성됨.

- [ ] **Step 4: 마이그레이션 파일 작성**

```bash
supabase migration new init
```

→ `supabase/migrations/<timestamp>_init.sql` 생성. 파일 내용:

```sql
-- 부모 디바이스 (anonymous auth user_id)
CREATE TABLE parent_devices (
  id UUID PRIMARY KEY,                  -- = auth.uid()
  device_label TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 자녀 사용자 (Google/Email auth user_id)
CREATE TABLE child_users (
  id UUID PRIMARY KEY,                  -- = auth.uid()
  email TEXT,
  display_name TEXT,
  fcm_token TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- N:M 페어링
CREATE TABLE pairings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  child_user_id UUID NOT NULL REFERENCES child_users(id) ON DELETE CASCADE,
  parent_label TEXT,
  paired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(parent_device_id, child_user_id)
);

-- 페어링 코드 (10분 TTL)
CREATE TABLE pairing_codes (
  code TEXT PRIMARY KEY,
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  redeemed_at TIMESTAMPTZ,
  redeemed_by UUID REFERENCES child_users(id)
);

-- 약 미러
CREATE TABLE medications (
  id UUID PRIMARY KEY,
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 복용 이벤트 미러
CREATE TABLE dose_events (
  id UUID PRIMARY KEY,
  parent_device_id UUID NOT NULL REFERENCES parent_devices(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  slot_id TEXT NOT NULL,
  date DATE NOT NULL,
  status TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_dose_events_parent_date ON dose_events(parent_device_id, date);
CREATE INDEX idx_pairings_child ON pairings(child_user_id);
CREATE INDEX idx_pairings_parent ON pairings(parent_device_id);

-- RLS
ALTER TABLE parent_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE child_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairings ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE dose_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairing_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY p_parent_self ON parent_devices FOR ALL USING (id = auth.uid());
CREATE POLICY p_child_self  ON child_users    FOR ALL USING (id = auth.uid());

CREATE POLICY p_pairings_owned ON pairings FOR ALL
  USING (parent_device_id = auth.uid() OR child_user_id = auth.uid());

CREATE POLICY p_meds_read ON medications FOR SELECT
  USING (
    parent_device_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pairings
      WHERE pairings.parent_device_id = medications.parent_device_id
        AND pairings.child_user_id = auth.uid()
    )
  );
CREATE POLICY p_meds_insert ON medications FOR INSERT
  WITH CHECK (parent_device_id = auth.uid());
CREATE POLICY p_meds_update ON medications FOR UPDATE
  USING (parent_device_id = auth.uid());
CREATE POLICY p_meds_delete ON medications FOR DELETE
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
CREATE POLICY p_doses_insert ON dose_events FOR INSERT
  WITH CHECK (parent_device_id = auth.uid());

CREATE POLICY p_codes_parent_own ON pairing_codes FOR ALL
  USING (parent_device_id = auth.uid());

-- RPC: 부모 6자리 코드 발급
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

-- RPC: 자녀 코드 redeem
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

- [ ] **Step 5: 프로젝트 연결 + 마이그레이션 push**

```bash
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>   # Project URL의 abc123 부분
supabase db push
```

Expected: 마이그레이션이 원격 DB에 적용됨. Supabase 콘솔 → Table Editor에서 6개 테이블 확인.

- [ ] **Step 6: 익명 인증 활성화 (Supabase 콘솔)**

콘솔 → Authentication → Providers → "Anonymous Sign-Ins" **활성화**. (부모 페어링용)

- [ ] **Step 7: Google OAuth 설정 (자녀용)**

콘솔 → Authentication → Providers → "Google" **활성화**. (Google Cloud Console에서 OAuth Client ID + Secret 발급해야 함 — Phase 9에서 마저 셋업; 지금은 켜두기만.)

- [ ] **Step 8: 커밋**

```bash
git add supabase/
git commit -m "feat(supabase): 프로젝트 init + 6개 테이블 + RLS + RPC 마이그레이션"
```

### Task 0.8: Firebase 프로젝트 + FlutterFire CLI

**Files:**
- Create: `android/app/google-services.json` (CLI가 생성)
- Create: `lib/firebase_options.dart` (CLI가 생성)
- Modify: `android/build.gradle`, `android/app/build.gradle`

- [ ] **Step 1: Firebase 콘솔에서 프로젝트 생성**

https://console.firebase.google.com → "프로젝트 추가":

- 프로젝트 이름: `kyh-medi`
- Google Analytics: 사용 안 함 (단순화)

→ 생성 후 "Android 앱 추가" → 패키지 이름 `com.kyh.medi` → 앱 닉네임 `KYH 약 알림` → 등록.

> SHA-1 인증서 지문은 Phase 13에서 키스토어 만든 후 추가 (지금은 빈칸).

- [ ] **Step 2: FlutterFire CLI 설치**

```bash
dart pub global activate flutterfire_cli
```

PATH에 `$HOME/.pub-cache/bin` 등록 안 됐으면 추가. Windows: `%LOCALAPPDATA%\Pub\Cache\bin`.

- [ ] **Step 3: Firebase CLI 설치 + 로그인**

```bash
npm install -g firebase-tools
firebase login
```

Expected: 브라우저 열림 → Google 로그인 → "Success!" 메시지.

- [ ] **Step 4: flutterfire configure**

```bash
flutterfire configure --project=kyh-medi --platforms=android
```

→ `lib/firebase_options.dart` + `android/app/google-services.json` 생성됨.

- [ ] **Step 5: Android Gradle 설정**

`android/build.gradle` (프로젝트 레벨)의 `plugins` 또는 `buildscript.dependencies`에 추가:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

`android/app/build.gradle` 맨 아래에 추가:

```gradle
apply plugin: 'com.google.gms.google-services'
```

- [ ] **Step 6: 빌드 검증**

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

Expected: `BUILD SUCCESSFUL`. 실패 시 메시지 따라 Gradle 버전/플러그인 정합성 확인.

- [ ] **Step 7: 커밋**

```bash
git add android/build.gradle android/app/build.gradle android/app/google-services.json lib/firebase_options.dart
git commit -m "feat(firebase): FlutterFire 셋업 + google-services.json"
```

### Task 0.9: Hive 초기화 헬퍼 (박스 등록 자리)

**Files:**
- Create: `lib/core/hive/hive_init.dart`

- [ ] **Step 1: 작성 (어댑터는 Phase 1에서 추가)**

```dart
// lib/core/hive/hive_init.dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveInit {
  static const medicationsBox = 'medicationsBox';
  static const slotsBox = 'slotsBox';
  static const slotMedicationsBox = 'slotMedicationsBox';
  static const doseEventsBox = 'doseEventsBox';
  static const settingsBox = 'settingsBox';

  /// main()에서 호출. 어댑터 등록 + 박스 open.
  /// 어댑터는 Phase 1 Task 1.4에서 등록 코드 추가.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    // ▼▼ Phase 1에서 다음 줄들이 추가된다 ▼▼
    // Hive.registerAdapter(MedicationAdapter());
    // Hive.registerAdapter(TimeSlotAdapter());
    // Hive.registerAdapter(SlotMedicationAdapter());
    // Hive.registerAdapter(DoseEventAdapter());
    // Hive.registerAdapter(AppSettingsAdapter());
    // ▲▲

    // 박스 open도 Phase 1에서 추가:
    // await Hive.openBox<Medication>(medicationsBox);
    // await Hive.openBox<TimeSlot>(slotsBox);
    // await Hive.openBox<SlotMedication>(slotMedicationsBox);
    // await Hive.openBox<DoseEvent>(doseEventsBox);
    // await Hive.openBox<AppSettings>(settingsBox);
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/core/hive/hive_init.dart
git commit -m "feat(hive): 초기화 헬퍼 (어댑터 자리는 Phase 1에서 채움)"
```

### Task 0.10: Supabase 초기화 + Config 상수

**Files:**
- Create: `lib/core/supabase/supabase_config.dart`
- Create: `lib/core/supabase/supabase_init.dart`

- [ ] **Step 1: 설정 상수**

```dart
// lib/core/supabase/supabase_config.dart
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );
}
```

`defaultValue`에 실제 값을 넣어두거나, 빌드 시 `--dart-define`으로 주입:

```bash
flutter run --dart-define=SUPABASE_URL=https://abc.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> v1.0에선 단순화를 위해 `defaultValue`에 직접 박아두고 git에 커밋. anon key는 RLS로 안전. Service role key는 절대 클라이언트 넣지 X.

- [ ] **Step 2: Supabase init 헬퍼**

```dart
// lib/core/supabase/supabase_init.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseInit {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: false,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
```

- [ ] **Step 3: 커밋**

```bash
git add lib/core/supabase/
git commit -m "feat(supabase): config + init 헬퍼"
```

### Task 0.11: Firebase / FCM 초기화 자리

**Files:**
- Create: `lib/core/firebase/firebase_init.dart`

- [ ] **Step 1: 작성**

```dart
// lib/core/firebase/firebase_init.dart
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseInit {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
```

> FCM 토큰/메시지 핸들러는 Phase 11에서 추가. 여기선 init만.

- [ ] **Step 2: 커밋**

```bash
git add lib/core/firebase/firebase_init.dart
git commit -m "feat(firebase): init 헬퍼"
```

---

## Phase 1: 데이터 레이어 (Hive 모델 + Repository, TDD)

### Task 1.1: 디자인 토큰 + 자녀 토큰

**Files:**
- Create: `lib/core/theme/tokens.dart`

- [ ] **Step 1: 작성**

```dart
// lib/core/theme/tokens.dart
import 'package:flutter/material.dart';

class AppColors {
  // 부모 모드 (시니어)
  static const bg = Color(0xFFECE8E1);
  static const bg2 = Color(0xFFDDD8CD);
  static const paper = Color(0xFFFBFAF6);
  static const paper2 = Color(0xFFF4F1EA);
  static const ink = Color(0xFF1A1A1A);
  static const ink2 = Color(0xFF3D3D3D);
  static const inkMute = Color(0xFF8A8578);
  static const line = Color(0xFFC9C3B5);
  static const pill = Color(0xFFD88E5E);
  static const pillDeep = Color(0xFFB86F40);
  static const care = Color(0xFFC8554D);
  static const capsule = Color(0xFFC99A4A);
  static const jade = Color(0xFF6B8E7F);

  // 자녀 모드 (Material 일반)
  static const caregiverPrimary = Color(0xFF2563EB);
  static const caregiverBg = Color(0xFFFAFAFA);
  static const caregiverCard = Colors.white;
}

class AppSizes {
  // 부모 (시니어)
  static const double bodyFontSize = 18.0;
  static const double buttonFontSize = 22.0;
  static const double titleFontSize = 28.0;
  static const double minButtonHeight = 56.0;
  static const double largeButtonHeight = 80.0;
  static const double padding = 20.0;

  // 자녀 (Material 기본)
  static const double caregiverBodyFontSize = 14.0;
  static const double caregiverButtonFontSize = 16.0;
  static const double caregiverMinButtonHeight = 48.0;
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/core/theme/tokens.dart
git commit -m "feat(theme): 디자인 토큰 (부모 + 자녀)"
```

### Task 1.2: 시니어 + 자녀 테마 분리

**Files:**
- Create: `lib/core/theme/senior_theme.dart`
- Create: `lib/core/theme/caregiver_theme.dart`

- [ ] **Step 1: 시니어 테마**

```dart
// lib/core/theme/senior_theme.dart
import 'package:flutter/material.dart';
import 'tokens.dart';

class SeniorTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pillDeep,
        brightness: Brightness.light,
        background: AppColors.bg,
      ),
      fontFamily: 'Pretendard',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: AppSizes.bodyFontSize, color: AppColors.ink),
        bodyMedium: TextStyle(fontSize: AppSizes.bodyFontSize, color: AppColors.ink),
        titleLarge: TextStyle(fontSize: AppSizes.titleFontSize, fontWeight: FontWeight.w800, color: AppColors.ink),
        labelLarge: TextStyle(fontSize: AppSizes.buttonFontSize, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minButtonHeight),
          backgroundColor: AppColors.pillDeep,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: AppSizes.buttonFontSize, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 자녀 테마**

```dart
// lib/core/theme/caregiver_theme.dart
import 'package:flutter/material.dart';
import 'tokens.dart';

class CaregiverTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.caregiverBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.caregiverPrimary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Pretendard',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: AppSizes.caregiverBodyFontSize),
        bodyMedium: TextStyle(fontSize: AppSizes.caregiverBodyFontSize),
        labelLarge: TextStyle(fontSize: AppSizes.caregiverButtonFontSize, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.caregiverMinButtonHeight),
          backgroundColor: AppColors.caregiverPrimary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 커밋**

```bash
git add lib/core/theme/senior_theme.dart lib/core/theme/caregiver_theme.dart
git commit -m "feat(theme): 시니어 + 자녀 테마 분리"
```

### Task 1.3: 타임존 초기화 + 단위 테스트

**Files:**
- Create: `lib/core/time/timezone_init.dart`
- Test: `test/core/timezone_init_test.dart`

- [ ] **Step 1: 실패 테스트**

```dart
// test/core/timezone_init_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kyh_medi/core/time/timezone_init.dart';

void main() {
  test('initializeTimezone sets local to Asia/Seoul', () {
    initializeTimezone();
    expect(tz.local.name, equals('Asia/Seoul'));
  });
}
```

- [ ] **Step 2: 실패 확인**

```bash
flutter test test/core/timezone_init_test.dart
```

Expected: FAIL — `initializeTimezone` undefined.

- [ ] **Step 3: 구현**

```dart
// lib/core/time/timezone_init.dart
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzl;

void initializeTimezone() {
  tz.initializeTimeZones();
  tzl.setLocalLocation(tzl.getLocation('Asia/Seoul'));
}
```

- [ ] **Step 4: 통과 + 커밋**

```bash
flutter test test/core/timezone_init_test.dart
git add lib/core/time/ test/core/timezone_init_test.dart
git commit -m "feat(core): timezone Asia/Seoul 강제 초기화"
```

### Task 1.4: Hive 모델 5개 + 어댑터 자동 생성

**Files:**
- Create: `lib/features/parent/medication/domain/medication.dart`
- Create: `lib/features/parent/slot/domain/time_slot.dart`
- Create: `lib/features/parent/slot/domain/slot_medication.dart`
- Create: `lib/features/parent/intake/domain/dose_event.dart`
- Create: `lib/features/parent/settings/domain/app_settings.dart`
- Generated: `lib/.../*.g.dart` (build_runner가 생성)

- [ ] **Step 1: Medication**

```dart
// lib/features/parent/medication/domain/medication.dart
import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 0)
class Medication extends HiveObject {
  @HiveField(0) String id;            // UUID
  @HiveField(1) String name;
  @HiveField(2) String? photoPath;    // 부모 로컬만 (Supabase 동기화 X)
  @HiveField(3) String? memo;         // 부모 로컬만
  @HiveField(4) String? colorHex;
  @HiveField(5) DateTime createdAt;
  @HiveField(6) DateTime? deletedAt;

  Medication({
    required this.id,
    required this.name,
    this.photoPath,
    this.memo,
    this.colorHex,
    required this.createdAt,
    this.deletedAt,
  });
}
```

- [ ] **Step 2: TimeSlot**

```dart
// lib/features/parent/slot/domain/time_slot.dart
import 'package:hive/hive.dart';

part 'time_slot.g.dart';

@HiveType(typeId: 1)
class TimeSlot extends HiveObject {
  @HiveField(0) String id;            // UUID
  @HiveField(1) String label;         // "아침"
  @HiveField(2) int hour;             // 0-23
  @HiveField(3) int minute;           // 0-59
  @HiveField(4) int daysOfWeek;       // 비트마스크: 월=1, 화=2, ..., 일=64
  @HiveField(5) bool enabled;
  @HiveField(6) DateTime? deletedAt;

  TimeSlot({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.enabled = true,
    this.deletedAt,
  });

  static const int everyday = 127; // 월~일 모두
}
```

- [ ] **Step 3: SlotMedication**

```dart
// lib/features/parent/slot/domain/slot_medication.dart
import 'package:hive/hive.dart';

part 'slot_medication.g.dart';

@HiveType(typeId: 2)
class SlotMedication extends HiveObject {
  @HiveField(0) String slotId;
  @HiveField(1) String medicationId;
  @HiveField(2) int doseCount;

  SlotMedication({
    required this.slotId,
    required this.medicationId,
    this.doseCount = 1,
  });

  /// Hive 키: "{slotId}|{medicationId}"
  String get compoundKey => '$slotId|$medicationId';
}
```

- [ ] **Step 4: DoseEvent**

```dart
// lib/features/parent/intake/domain/dose_event.dart
import 'package:hive/hive.dart';

part 'dose_event.g.dart';

@HiveType(typeId: 3)
class DoseEvent extends HiveObject {
  @HiveField(0) String id;            // "YYYY-MM-DD|slotId|medicationId"
  @HiveField(1) DateTime date;
  @HiveField(2) String slotId;
  @HiveField(3) String medicationId;
  @HiveField(4) DateTime scheduledAt;
  @HiveField(5) DateTime? takenAt;
  @HiveField(6) String status;        // 'pending' | 'taken' | 'missed' | 'skipped'
  @HiveField(7) DateTime createdAt;

  DoseEvent({
    required this.id,
    required this.date,
    required this.slotId,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    required this.createdAt,
  });

  static const statusPending = 'pending';
  static const statusTaken = 'taken';
  static const statusMissed = 'missed';
  static const statusSkipped = 'skipped';

  static String makeId(DateTime date, String slotId, String medicationId) {
    final ymd = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '$ymd|$slotId|$medicationId';
  }
}
```

- [ ] **Step 5: AppSettings**

```dart
// lib/features/parent/settings/domain/app_settings.dart
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
class AppSettings extends HiveObject {
  @HiveField(0) String userMode;              // 'parent' | 'child' | '' (미선택)
  @HiveField(1) bool adsRemoved;
  @HiveField(2) double seniorFontScale;
  @HiveField(3) String? pairedSupabaseUserId; // 부모 anonymous user_id (페어링 시 저장)
  @HiveField(4) String? fcmToken;             // 자녀 FCM 토큰
  @HiveField(5) bool onboardingDone;

  AppSettings({
    this.userMode = '',
    this.adsRemoved = false,
    this.seniorFontScale = 1.0,
    this.pairedSupabaseUserId,
    this.fcmToken,
    this.onboardingDone = false,
  });

  static const modeParent = 'parent';
  static const modeChild = 'child';
}
```

- [ ] **Step 6: build_runner로 어댑터 자동 생성**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: 5개 모델 폴더에 `*.g.dart` 파일 생성됨 (`medication.g.dart`, `time_slot.g.dart`, `slot_medication.g.dart`, `dose_event.g.dart`, `app_settings.g.dart`).

- [ ] **Step 7: HiveInit에 어댑터 등록 + 박스 open**

`lib/core/hive/hive_init.dart` 교체:

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/parent/medication/domain/medication.dart';
import '../../features/parent/slot/domain/time_slot.dart';
import '../../features/parent/slot/domain/slot_medication.dart';
import '../../features/parent/intake/domain/dose_event.dart';
import '../../features/parent/settings/domain/app_settings.dart';

class HiveInit {
  static const medicationsBox = 'medicationsBox';
  static const slotsBox = 'slotsBox';
  static const slotMedicationsBox = 'slotMedicationsBox';
  static const doseEventsBox = 'doseEventsBox';
  static const settingsBox = 'settingsBox';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicationAdapter());
    Hive.registerAdapter(TimeSlotAdapter());
    Hive.registerAdapter(SlotMedicationAdapter());
    Hive.registerAdapter(DoseEventAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    await Hive.openBox<Medication>(medicationsBox);
    await Hive.openBox<TimeSlot>(slotsBox);
    await Hive.openBox<SlotMedication>(slotMedicationsBox);
    await Hive.openBox<DoseEvent>(doseEventsBox);
    await Hive.openBox<AppSettings>(settingsBox);
  }
}
```

- [ ] **Step 8: 커밋**

```bash
git add lib/features/parent/*/domain/*.dart lib/features/parent/*/domain/*.g.dart lib/core/hive/hive_init.dart
git commit -m "feat(hive): 5개 모델 + 어댑터 자동 생성 + 박스 open"
```

### Task 1.5: MedicationRepository (TDD)

**Files:**
- Create: `lib/features/parent/medication/data/medication_repository.dart`
- Test: `test/features/parent/medication/medication_repository_test.dart`

- [ ] **Step 1: 실패 테스트**

```dart
// test/features/parent/medication/medication_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kyh_medi/features/parent/medication/data/medication_repository.dart';
import 'package:kyh_medi/features/parent/medication/domain/medication.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late Box<Medication> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MedicationAdapter());
    box = await Hive.openBox<Medication>(p.join('med_${DateTime.now().microsecondsSinceEpoch}'));
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('insert and findActive returns inserted medication', () async {
    final repo = MedicationRepository(box);
    await repo.insert(Medication(
      id: 'med-1', name: '혈압약', createdAt: DateTime(2026, 5, 1),
    ));
    final all = repo.findActive();
    expect(all, hasLength(1));
    expect(all.first.name, '혈압약');
  });

  test('softDelete excludes from findActive', () async {
    final repo = MedicationRepository(box);
    await repo.insert(Medication(
      id: 'med-2', name: '비타민', createdAt: DateTime(2026, 5, 1),
    ));
    await repo.softDelete('med-2');
    expect(repo.findActive(), isEmpty);
    expect(repo.findById('med-2')?.deletedAt, isNotNull);
  });
}
```

- [ ] **Step 2: 실패 확인**

```bash
flutter test test/features/parent/medication/medication_repository_test.dart
```

Expected: FAIL.

- [ ] **Step 3: 구현**

```dart
// lib/features/parent/medication/data/medication_repository.dart
import 'package:hive/hive.dart';
import '../domain/medication.dart';

class MedicationRepository {
  final Box<Medication> _box;
  MedicationRepository(this._box);

  Future<void> insert(Medication m) async => _box.put(m.id, m);

  Future<void> update(Medication m) async => _box.put(m.id, m);

  List<Medication> findActive() => _box.values
      .where((m) => m.deletedAt == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Medication? findById(String id) => _box.get(id);

  Future<void> softDelete(String id) async {
    final m = _box.get(id);
    if (m == null) return;
    m.deletedAt = DateTime.now();
    await m.save();
  }

  Stream<BoxEvent> watch() => _box.watch();
}
```

- [ ] **Step 4: 통과 + 커밋**

```bash
flutter test test/features/parent/medication/medication_repository_test.dart
git add lib/features/parent/medication/data/ test/features/parent/medication/
git commit -m "feat(medication): Hive Repository + TDD 통과"
```

### Task 1.6: SlotRepository (TDD, TimeSlot + SlotMedication)

**Files:**
- Create: `lib/features/parent/slot/data/slot_repository.dart`
- Test: `test/features/parent/slot/slot_repository_test.dart`

- [ ] **Step 1: 실패 테스트**

```dart
// test/features/parent/slot/slot_repository_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kyh_medi/features/parent/slot/data/slot_repository.dart';
import 'package:kyh_medi/features/parent/slot/domain/time_slot.dart';
import 'package:kyh_medi/features/parent/slot/domain/slot_medication.dart';

void main() {
  late Directory tempDir;
  late Box<TimeSlot> slots;
  late Box<SlotMedication> slotMeds;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TimeSlotAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SlotMedicationAdapter());
    final ts = DateTime.now().microsecondsSinceEpoch;
    slots = await Hive.openBox<TimeSlot>('slots_$ts');
    slotMeds = await Hive.openBox<SlotMedication>('slotmeds_$ts');
  });

  tearDown(() async {
    await slots.close();
    await slotMeds.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('insertSlot + findActiveSlots', () async {
    final repo = SlotRepository(slots, slotMeds);
    await repo.insertSlot(TimeSlot(
      id: 'slot-1', label: '아침', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday,
    ));
    final all = repo.findActiveSlots();
    expect(all, hasLength(1));
    expect(all.first.label, '아침');
  });

  test('attachMedication + findMedicationsForSlot', () async {
    final repo = SlotRepository(slots, slotMeds);
    await repo.insertSlot(TimeSlot(
      id: 'slot-1', label: '아침', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday,
    ));
    await repo.attachMedication(SlotMedication(slotId: 'slot-1', medicationId: 'med-1'));
    final meds = repo.findMedicationsForSlot('slot-1');
    expect(meds, hasLength(1));
    expect(meds.first.medicationId, 'med-1');
  });

  test('softDeleteSlot also detaches all medications', () async {
    final repo = SlotRepository(slots, slotMeds);
    await repo.insertSlot(TimeSlot(
      id: 'slot-1', label: '아침', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday,
    ));
    await repo.attachMedication(SlotMedication(slotId: 'slot-1', medicationId: 'med-1'));
    await repo.softDeleteSlot('slot-1');
    expect(repo.findActiveSlots(), isEmpty);
    expect(repo.findMedicationsForSlot('slot-1'), isEmpty);
  });
}
```

- [ ] **Step 2: 실패 확인**

```bash
flutter test test/features/parent/slot/slot_repository_test.dart
```

Expected: FAIL.

- [ ] **Step 3: 구현**

```dart
// lib/features/parent/slot/data/slot_repository.dart
import 'package:hive/hive.dart';
import '../domain/time_slot.dart';
import '../domain/slot_medication.dart';

class SlotRepository {
  final Box<TimeSlot> _slots;
  final Box<SlotMedication> _slotMeds;
  SlotRepository(this._slots, this._slotMeds);

  Future<void> insertSlot(TimeSlot s) async => _slots.put(s.id, s);

  Future<void> updateSlot(TimeSlot s) async => _slots.put(s.id, s);

  List<TimeSlot> findActiveSlots() => _slots.values
      .where((s) => s.deletedAt == null && s.enabled)
      .toList()
    ..sort((a, b) {
      final cmp = a.hour.compareTo(b.hour);
      return cmp != 0 ? cmp : a.minute.compareTo(b.minute);
    });

  TimeSlot? findSlotById(String id) => _slots.get(id);

  Future<void> softDeleteSlot(String id) async {
    final s = _slots.get(id);
    if (s == null) return;
    s.deletedAt = DateTime.now();
    await s.save();
    // 연결된 SlotMedication도 모두 detach
    final keysToDelete = _slotMeds.values
        .where((sm) => sm.slotId == id)
        .map((sm) => sm.compoundKey)
        .toList();
    for (final k in keysToDelete) {
      await _slotMeds.delete(k);
    }
  }

  Future<void> attachMedication(SlotMedication sm) async =>
      _slotMeds.put(sm.compoundKey, sm);

  Future<void> detachMedication(String slotId, String medicationId) async =>
      _slotMeds.delete('$slotId|$medicationId');

  List<SlotMedication> findMedicationsForSlot(String slotId) =>
      _slotMeds.values.where((sm) => sm.slotId == slotId).toList();
}
```

- [ ] **Step 4: 통과 + 커밋**

```bash
flutter test test/features/parent/slot/slot_repository_test.dart
git add lib/features/parent/slot/data/ test/features/parent/slot/
git commit -m "feat(slot): SlotRepository + TimeSlot/SlotMedication TDD 통과"
```

### Task 1.7: DoseEventRepository (TDD)

**Files:**
- Create: `lib/features/parent/intake/data/dose_event_repository.dart`
- Test: `test/features/parent/intake/dose_event_repository_test.dart`

- [ ] **Step 1: 실패 테스트**

```dart
// test/features/parent/intake/dose_event_repository_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kyh_medi/features/parent/intake/data/dose_event_repository.dart';
import 'package:kyh_medi/features/parent/intake/domain/dose_event.dart';

void main() {
  late Directory tempDir;
  late Box<DoseEvent> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DoseEventAdapter());
    box = await Hive.openBox<DoseEvent>('doses_${DateTime.now().microsecondsSinceEpoch}');
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('upsertPending creates new event if missing', () async {
    final repo = DoseEventRepository(box);
    final scheduled = DateTime(2026, 5, 1, 8, 0);
    await repo.upsertPending(
      slotId: 'slot-1', medicationId: 'med-1', scheduledAt: scheduled,
    );
    final logs = repo.findByDate(DateTime(2026, 5, 1));
    expect(logs, hasLength(1));
    expect(logs.first.status, DoseEvent.statusPending);
  });

  test('markSlotTaken flips status to taken', () async {
    final repo = DoseEventRepository(box);
    final scheduled = DateTime(2026, 5, 1, 8, 0);
    await repo.upsertPending(
      slotId: 'slot-1', medicationId: 'med-1', scheduledAt: scheduled,
    );
    await repo.markSlotTaken(
      slotId: 'slot-1', date: DateTime(2026, 5, 1), now: DateTime(2026, 5, 1, 8, 2),
    );
    final logs = repo.findByDate(DateTime(2026, 5, 1));
    expect(logs.first.status, DoseEvent.statusTaken);
    expect(logs.first.takenAt, isNotNull);
  });

  test('markStaleAsMissed flips pending older than 30min to missed', () async {
    final repo = DoseEventRepository(box);
    final scheduled = DateTime(2026, 5, 1, 8, 0);
    await repo.upsertPending(
      slotId: 'slot-1', medicationId: 'med-1', scheduledAt: scheduled,
    );
    await repo.markStaleAsMissed(now: DateTime(2026, 5, 1, 8, 31));
    final logs = repo.findByDate(DateTime(2026, 5, 1));
    expect(logs.first.status, DoseEvent.statusMissed);
  });
}
```

- [ ] **Step 2: 실패 확인**

```bash
flutter test test/features/parent/intake/dose_event_repository_test.dart
```

Expected: FAIL.

- [ ] **Step 3: 구현**

```dart
// lib/features/parent/intake/data/dose_event_repository.dart
import 'package:hive/hive.dart';
import '../domain/dose_event.dart';

class DoseEventRepository {
  final Box<DoseEvent> _box;
  DoseEventRepository(this._box);

  /// 같은 키 (date|slotId|medicationId)가 있으면 그대로, 없으면 pending으로 생성
  Future<void> upsertPending({
    required String slotId,
    required String medicationId,
    required DateTime scheduledAt,
  }) async {
    final date = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final id = DoseEvent.makeId(date, slotId, medicationId);
    if (_box.containsKey(id)) return;
    await _box.put(id, DoseEvent(
      id: id,
      date: date,
      slotId: slotId,
      medicationId: medicationId,
      scheduledAt: scheduledAt,
      status: DoseEvent.statusPending,
      createdAt: DateTime.now(),
    ));
  }

  /// 슬롯 내 모든 약을 taken으로 마킹 (해당 날짜)
  Future<List<DoseEvent>> markSlotTaken({
    required String slotId,
    required DateTime date,
    required DateTime now,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final updated = <DoseEvent>[];
    for (final e in _box.values) {
      if (e.slotId == slotId && _sameDay(e.date, dateOnly)
          && e.status == DoseEvent.statusPending) {
        e.status = DoseEvent.statusTaken;
        e.takenAt = now;
        await e.save();
        updated.add(e);
      }
    }
    return updated;
  }

  /// 30분 지나도 pending인 이벤트를 missed로 마킹. 변경된 이벤트 리스트 반환.
  Future<List<DoseEvent>> markStaleAsMissed({required DateTime now}) async {
    final cutoff = now.subtract(const Duration(minutes: 30));
    final updated = <DoseEvent>[];
    for (final e in _box.values) {
      if (e.status == DoseEvent.statusPending && e.scheduledAt.isBefore(cutoff)) {
        e.status = DoseEvent.statusMissed;
        await e.save();
        updated.add(e);
      }
    }
    return updated;
  }

  List<DoseEvent> findByDate(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _box.values.where((e) => _sameDay(e.date, d)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<DoseEvent> findByMonth(DateTime monthAnchor) {
    final start = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final end = DateTime(monthAnchor.year, monthAnchor.month + 1, 1);
    return _box.values
        .where((e) => e.date.isAtSameMomentAs(start) ||
            (e.date.isAfter(start) && e.date.isBefore(end)))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Stream<BoxEvent> watch() => _box.watch();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
```

- [ ] **Step 4: 통과 + 커밋**

```bash
flutter test test/features/parent/intake/dose_event_repository_test.dart
git add lib/features/parent/intake/data/ test/features/parent/intake/
git commit -m "feat(intake): DoseEventRepository (Hive) + TDD 통과"
```

### Task 1.8: SettingsRepository (Hive)

**Files:**
- Create: `lib/features/parent/settings/data/settings_repository.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/settings/data/settings_repository.dart
import 'package:hive/hive.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  static const _key = 'app';
  final Box<AppSettings> _box;
  SettingsRepository(this._box);

  AppSettings get current {
    var s = _box.get(_key);
    if (s == null) {
      s = AppSettings();
      _box.put(_key, s);
    }
    return s;
  }

  Future<void> setUserMode(String mode) async {
    final s = current;
    s.userMode = mode;
    await s.save();
  }

  Future<void> setOnboardingDone(bool v) async {
    final s = current;
    s.onboardingDone = v;
    await s.save();
  }

  Future<void> setAdsRemoved(bool v) async {
    final s = current;
    s.adsRemoved = v;
    await s.save();
  }

  Future<void> setPairedSupabaseUserId(String? id) async {
    final s = current;
    s.pairedSupabaseUserId = id;
    await s.save();
  }

  Future<void> setFcmToken(String? token) async {
    final s = current;
    s.fcmToken = token;
    await s.save();
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/settings/data/
git commit -m "feat(settings): SettingsRepository (Hive 단일 키-객체)"
```

---

## Phase 2: 알림 엔진 (TDD)

### Task 2.1: 알림 ID 인코더 + 시간 계산 (TDD)

**Files:**
- Create: `lib/core/notification/notification_scheduler.dart`
- Test: `test/core/notification_scheduler_test.dart`

- [ ] **Step 1: 실패 테스트**

```dart
// test/core/notification_scheduler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kyh_medi/core/notification/notification_scheduler.dart';
import 'package:kyh_medi/features/parent/slot/domain/time_slot.dart';

void main() {
  group('NotificationIdEncoder', () {
    test('encodes slotIdHash × 1000 + day_offset × 10 + retry_index', () {
      expect(NotificationIdEncoder.encode(slotHash: 5, dayOffset: 1, retryIndex: 1), 5011);
      expect(NotificationIdEncoder.encode(slotHash: 1, dayOffset: 0, retryIndex: 0), 1000);
      expect(NotificationIdEncoder.encode(slotHash: 9, dayOffset: 6, retryIndex: 2), 9062);
    });

    test('idsForSlotInstance returns 3 IDs (retry 0/1/2)', () {
      final ids = NotificationIdEncoder.idsForSlotInstance(slotHash: 5, dayOffset: 1);
      expect(ids, [5010, 5011, 5012]);
    });

    test('hashSlotId is stable and bounded', () {
      final h1 = NotificationIdEncoder.hashSlotId('slot-uuid-1');
      final h2 = NotificationIdEncoder.hashSlotId('slot-uuid-1');
      expect(h1, h2);                       // 같은 입력 → 같은 출력
      expect(h1, lessThan(1000000));        // < 1M
      expect(h1, greaterThanOrEqualTo(0));
    });
  });

  group('NotificationScheduler.computeFireTimes', () {
    test('returns 3 fire times: scheduled, +10min, +20min', () {
      final base = DateTime(2026, 5, 1, 8, 0);
      final times = NotificationScheduler.computeFireTimes(base);
      expect(times, [
        DateTime(2026, 5, 1, 8, 0),
        DateTime(2026, 5, 1, 8, 10),
        DateTime(2026, 5, 1, 8, 20),
      ]);
    });

    test('next7DaysFor everyday returns 7 dates', () {
      final from = DateTime(2026, 5, 1);
      final all = NotificationScheduler.next7DaysFor(
        slot: TimeSlot(id: 'x', label: 'x', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday),
        from: from,
      );
      expect(all, hasLength(7));
    });

    test('next7DaysFor skips days not in bitmask', () {
      // 월(1) + 수(4) + 금(16) = 21
      final from = DateTime(2026, 5, 1); // 5/1은 금요일 (weekday=5)
      final result = NotificationScheduler.next7DaysFor(
        slot: TimeSlot(id: 'x', label: 'x', hour: 8, minute: 0, daysOfWeek: 21),
        from: from,
      );
      // 5/1 금, 5/4 월, 5/6 수 → 3개
      expect(result, hasLength(3));
    });
  });
}
```

- [ ] **Step 2: 실패 확인**

```bash
flutter test test/core/notification_scheduler_test.dart
```

Expected: FAIL.

- [ ] **Step 3: 구현**

```dart
// lib/core/notification/notification_scheduler.dart
import '../../features/parent/slot/domain/time_slot.dart';

class NotificationIdEncoder {
  /// slotId(UUID 문자열) → 0~999_999 범위의 안정적 정수 해시
  static int hashSlotId(String slotId) {
    int h = 0;
    for (final c in slotId.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h % 1000000;
  }

  static int encode({
    required int slotHash,
    required int dayOffset,
    required int retryIndex,
  }) {
    assert(slotHash >= 0 && slotHash < 1000000);
    assert(dayOffset >= 0 && dayOffset < 100);
    assert(retryIndex >= 0 && retryIndex < 10);
    return slotHash * 1000 + dayOffset * 10 + retryIndex;
  }

  static List<int> idsForSlotInstance({
    required int slotHash,
    required int dayOffset,
  }) {
    final base = encode(slotHash: slotHash, dayOffset: dayOffset, retryIndex: 0);
    return [base, base + 1, base + 2];
  }
}

class NotificationScheduler {
  static const retryOffsetsMinutes = [0, 10, 20];

  static List<DateTime> computeFireTimes(DateTime base) {
    return retryOffsetsMinutes.map((m) => base.add(Duration(minutes: m))).toList();
  }

  static List<DateTime> next7DaysFor({
    required TimeSlot slot,
    required DateTime from,
  }) {
    final result = <DateTime>[];
    for (int offset = 0; offset < 7; offset++) {
      final d = from.add(Duration(days: offset));
      // weekday: 월=1 ~ 일=7. 비트마스크: 월=1, 화=2, 수=4, 목=8, 금=16, 토=32, 일=64
      final bit = 1 << (d.weekday - 1);
      if ((slot.daysOfWeek & bit) != 0) {
        result.add(DateTime(d.year, d.month, d.day, slot.hour, slot.minute));
      }
    }
    return result;
  }
}
```

- [ ] **Step 4: 통과 + 커밋**

```bash
flutter test test/core/notification_scheduler_test.dart
git add lib/core/notification/notification_scheduler.dart test/core/notification_scheduler_test.dart
git commit -m "feat(notification): ID 인코더(UUID 해시) + 시간 계산 + TDD 통과"
```

### Task 2.2: AndroidManifest 권한 + 리시버

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: 권한 추가**

`<manifest>` 태그 안 (`<application>` 위)에 추가:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
```

- [ ] **Step 2: 리시버 등록**

`<application>` 안에 추가:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

- [ ] **Step 3: 커밋**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore(android): 알림/사진/광고 권한 + 리시버 등록"
```

### Task 2.3: NotificationService

**Files:**
- Create: `lib/core/notification/notification_service.dart`

- [ ] **Step 1: 작성**

```dart
// lib/core/notification/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'kyh_medi_alerts';
  static const _channelName = '약 알림';
  static const _channelDesc = '복약 시간 알림';

  static void Function(String payload)? onTap;

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && onTap != null) onTap!(payload);
      },
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId, _channelName,
        description: _channelDesc,
        importance: Importance.max,
      ),
    );
  }

  static Future<bool> requestPermissions() async {
    final notif = await Permission.notification.request();
    return notif.isGranted;
  }

  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> cancel(int id) async => _plugin.cancel(id);

  static Future<void> cancelMany(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/core/notification/notification_service.dart
git commit -m "feat(notification): NotificationService — 초기화 + 권한 + 스케줄"
```

---

## Phase 3: 부모 모드 UI — 약 + 슬롯

### Task 3.1: 공유 위젯 (SeniorButton, SeniorInput, CaregiverCard)

**Files:**
- Create: `lib/shared/widgets/senior_button.dart`
- Create: `lib/shared/widgets/senior_input.dart`
- Create: `lib/shared/widgets/caregiver_card.dart`

- [ ] **Step 1: SeniorButton**

```dart
// lib/shared/widgets/senior_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SeniorButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool large;

  const SeniorButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: large ? AppSizes.largeButtonHeight : AppSizes.minButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.pillDeep,
          foregroundColor: Colors.white,
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: large ? 26 : AppSizes.buttonFontSize,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}
```

- [ ] **Step 2: SeniorInput**

```dart
// lib/shared/widgets/senior_input.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SeniorInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;

  const SeniorInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.paper,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: CaregiverCard**

```dart
// lib/shared/widgets/caregiver_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class CaregiverCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const CaregiverCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.caregiverCard,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/shared/widgets/
git commit -m "feat(shared): SeniorButton + SeniorInput + CaregiverCard"
```

### Task 3.2: 약 등록 폼 (Hive)

**Files:**
- Create: `lib/features/parent/medication/ui/medication_form_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/medication/ui/medication_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import '../../../../shared/widgets/senior_input.dart';
import '../domain/medication.dart';
import 'medications_provider.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key});
  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _name = TextEditingController();
  final _memo = TextEditingController();
  String? _photoPath;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(dir.path, 'photos'));
    if (!photoDir.existsSync()) photoDir.createSync(recursive: true);
    final dest = p.join(photoDir.path, 'med_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(picked.path).copy(dest);
    setState(() => _photoPath = dest);
  }

  String _newId() {
    // 단순 UUID 대체: timestamp + random
    return 'med-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약 이름을 입력해주세요'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final m = Medication(
      id: _newId(),
      name: _name.text.trim(),
      photoPath: _photoPath,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      createdAt: DateTime.now(),
    );
    await context.read<MedicationsProvider>().add(m);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 약 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SeniorInput(controller: _name, label: '약 이름', hint: '예: 혈압약'),
          const SizedBox(height: 24),
          const Text('약 사진 (선택)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_photoPath != null)
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.file(File(_photoPath!), height: 200, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: SeniorButton(
              label: '카메라', onPressed: () => _pickPhoto(ImageSource.camera))),
            const SizedBox(width: 8),
            Expanded(child: SeniorButton(
              label: '갤러리', onPressed: () => _pickPhoto(ImageSource.gallery))),
          ]),
          const SizedBox(height: 24),
          SeniorInput(controller: _memo, label: '메모 (선택)', hint: '예: 식후 30분'),
          const SizedBox(height: 32),
          SeniorButton(label: '저장', onPressed: _save, large: true),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/medication/ui/medication_form_screen.dart
git commit -m "feat(parent/medication): 약 등록 폼 (Hive)"
```

### Task 3.3: 약 목록 + Provider (Hive)

**Files:**
- Create: `lib/features/parent/medication/ui/medications_provider.dart`
- Create: `lib/features/parent/medication/ui/medication_list_screen.dart`

- [ ] **Step 1: Provider**

```dart
// lib/features/parent/medication/ui/medications_provider.dart
import 'package:flutter/foundation.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';

class MedicationsProvider extends ChangeNotifier {
  final MedicationRepository _repo;
  MedicationsProvider(this._repo) {
    _repo.watch().listen((_) {
      _items = _repo.findActive();
      notifyListeners();
    });
    _items = _repo.findActive();
  }

  List<Medication> _items = const [];
  List<Medication> get items => _items;

  Future<void> add(Medication m) async {
    await _repo.insert(m);
    _items = _repo.findActive();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _repo.softDelete(id);
    _items = _repo.findActive();
    notifyListeners();
  }
}
```

- [ ] **Step 2: 목록 화면**

```dart
// lib/features/parent/medication/ui/medication_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../monetization/ad_banner.dart';
import 'medications_provider.dart';
import 'medication_form_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('약 관리')),
      body: Column(children: [
        Expanded(child: meds.isEmpty
            ? const Center(child: Text('아직 등록된 약이 없어요',
                style: TextStyle(fontSize: 20)))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.padding),
                itemCount: meds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final m = meds[i];
                  return Card(child: ListTile(
                    leading: m.photoPath != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(4),
                            child: Image.file(File(m.photoPath!),
                                width: 48, height: 48, fit: BoxFit.cover))
                        : const Icon(Icons.medication, size: 36, color: AppColors.pillDeep),
                    title: Text(m.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    subtitle: m.memo != null ? Text(m.memo!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 28),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('약을 삭제할까요?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context.read<MedicationsProvider>().remove(m.id);
                        }
                      },
                    ),
                  ));
                },
              )),
        const AdBanner(),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MedicationFormScreen())),
        label: const Text('새 약 추가', style: TextStyle(fontSize: 18)),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 3: 커밋**

```bash
git add lib/features/parent/medication/ui/
git commit -m "feat(parent/medication): 약 목록 + Provider (Hive watch)"
```

### Task 3.4: 시간 슬롯 폼 + 목록 + Provider

**Files:**
- Create: `lib/features/parent/slot/ui/slots_provider.dart`
- Create: `lib/features/parent/slot/ui/slot_form_screen.dart`
- Create: `lib/features/parent/slot/ui/slot_list_screen.dart`

- [ ] **Step 1: Provider (알림 예약 통합 포함)**

```dart
// lib/features/parent/slot/ui/slots_provider.dart
import 'package:flutter/foundation.dart';
import '../../../../core/notification/notification_scheduler.dart';
import '../../../../core/notification/notification_service.dart';
import '../data/slot_repository.dart';
import '../domain/time_slot.dart';
import '../domain/slot_medication.dart';

class SlotsProvider extends ChangeNotifier {
  final SlotRepository _repo;
  SlotsProvider(this._repo) {
    _items = _repo.findActiveSlots();
  }

  List<TimeSlot> _items = const [];
  List<TimeSlot> get items => _items;

  String _newId() => 'slot-${DateTime.now().millisecondsSinceEpoch}';

  Future<TimeSlot> create({
    required String label,
    required int hour,
    required int minute,
    required int daysOfWeek,
    required List<String> medicationIds,
  }) async {
    final s = TimeSlot(
      id: _newId(), label: label, hour: hour, minute: minute, daysOfWeek: daysOfWeek,
    );
    await _repo.insertSlot(s);
    for (final mid in medicationIds) {
      await _repo.attachMedication(SlotMedication(slotId: s.id, medicationId: mid));
    }
    await _scheduleNotifications(s);
    _items = _repo.findActiveSlots();
    notifyListeners();
    return s;
  }

  Future<void> remove(String slotId) async {
    final hash = NotificationIdEncoder.hashSlotId(slotId);
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      await NotificationService.cancelMany(
        NotificationIdEncoder.idsForSlotInstance(slotHash: hash, dayOffset: dayOffset),
      );
    }
    await _repo.softDeleteSlot(slotId);
    _items = _repo.findActiveSlots();
    notifyListeners();
  }

  Future<void> _scheduleNotifications(TimeSlot slot) async {
    final hash = NotificationIdEncoder.hashSlotId(slot.id);
    final from = DateTime.now();
    final today0 = DateTime(from.year, from.month, from.day);
    final fireDays = NotificationScheduler.next7DaysFor(slot: slot, from: from);
    for (final day in fireDays) {
      final dayOffset = day.difference(today0).inDays;
      final fires = NotificationScheduler.computeFireTimes(day);
      for (int i = 0; i < fires.length; i++) {
        if (fires[i].isBefore(from)) continue;
        final notifId = NotificationIdEncoder.encode(
          slotHash: hash, dayOffset: dayOffset, retryIndex: i,
        );
        await NotificationService.scheduleAt(
          id: notifId,
          title: '${slot.label} 약 드실 시간이에요',
          body: '${slot.hour.toString().padLeft(2, '0')}:'
                '${slot.minute.toString().padLeft(2, '0')}',
          fireAt: fires[i],
          payload: 'slot:${slot.id}',
        );
      }
    }
  }

  List<SlotMedication> medicationsFor(String slotId) =>
      _repo.findMedicationsForSlot(slotId);
}
```

- [ ] **Step 2: 슬롯 폼**

```dart
// lib/features/parent/slot/ui/slot_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import '../../../../shared/widgets/senior_input.dart';
import '../../medication/domain/medication.dart';
import '../../medication/ui/medications_provider.dart';
import '../domain/time_slot.dart';
import 'slots_provider.dart';

class SlotFormScreen extends StatefulWidget {
  const SlotFormScreen({super.key});
  @override
  State<SlotFormScreen> createState() => _SlotFormScreenState();
}

class _SlotFormScreenState extends State<SlotFormScreen> {
  final _label = TextEditingController(text: '아침');
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _daysMask = TimeSlot.everyday;
  final Set<String> _selectedMeds = {};

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    if (_selectedMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약을 1개 이상 선택해주세요')),
      );
      return;
    }
    await context.read<SlotsProvider>().create(
      label: _label.text.trim().isEmpty ? '시간 슬롯' : _label.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      daysOfWeek: _daysMask,
      medicationIds: _selectedMeds.toList(),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _dayChip(int dayBit, String label) {
    final selected = (_daysMask & dayBit) != 0;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 16)),
      selected: selected,
      onSelected: (_) => setState(() =>
          _daysMask = selected ? _daysMask & ~dayBit : _daysMask | dayBit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('시간 슬롯 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SeniorInput(controller: _label, label: '슬롯 이름', hint: '예: 아침'),
          const SizedBox(height: 24),
          const Text('시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SeniorButton(label: _time.format(context), onPressed: _pickTime),
          const SizedBox(height: 24),
          const Text('요일', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _dayChip(1, '월'), _dayChip(2, '화'), _dayChip(4, '수'),
            _dayChip(8, '목'), _dayChip(16, '금'), _dayChip(32, '토'), _dayChip(64, '일'),
          ]),
          const SizedBox(height: 24),
          const Text('이 시간에 드실 약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (meds.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('먼저 약을 등록해주세요')),
          ...meds.map((Medication m) => CheckboxListTile(
                title: Text(m.name, style: const TextStyle(fontSize: 18)),
                value: _selectedMeds.contains(m.id),
                onChanged: (v) => setState(() {
                  if (v == true) _selectedMeds.add(m.id);
                  else _selectedMeds.remove(m.id);
                }),
              )),
          const SizedBox(height: 32),
          SeniorButton(label: '저장', onPressed: _save, large: true),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 3: 슬롯 목록**

```dart
// lib/features/parent/slot/ui/slot_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import 'slots_provider.dart';
import 'slot_form_screen.dart';

class SlotListScreen extends StatelessWidget {
  const SlotListScreen({super.key});

  String _daysLabel(int mask) {
    if (mask == 127) return '매일';
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return List.generate(7, (i) => (mask & (1 << i)) != 0 ? labels[i] : null)
        .where((x) => x != null).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final slots = context.watch<SlotsProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('시간 관리')),
      body: slots.isEmpty
          ? const Center(child: Text('등록된 슬롯이 없어요', style: TextStyle(fontSize: 20)))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = slots[i];
                final hh = s.hour.toString().padLeft(2, '0');
                final mm = s.minute.toString().padLeft(2, '0');
                return Card(child: ListTile(
                  title: Text('${s.label} $hh:$mm',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  subtitle: Text(_daysLabel(s.daysOfWeek)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async => context.read<SlotsProvider>().remove(s.id),
                  ),
                ));
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SlotFormScreen())),
        label: const Text('새 시간 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/parent/slot/ui/
git commit -m "feat(parent/slot): 슬롯 폼 + 목록 + Provider (알림 예약 통합)"
```

---

## Phase 4: 부모 모드 UI — 메인 + 복용 체크 + 알림 통합

### Task 4.1: IntakeProvider — 오늘의 슬롯 + 복용 처리

**Files:**
- Create: `lib/features/parent/intake/ui/intake_provider.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/intake/ui/intake_provider.dart
import 'package:flutter/foundation.dart';
import '../../medication/data/medication_repository.dart';
import '../../medication/domain/medication.dart';
import '../../slot/data/slot_repository.dart';
import '../../slot/domain/time_slot.dart';
import '../data/dose_event_repository.dart';
import '../domain/dose_event.dart';

class TodaySlotView {
  final TimeSlot slot;
  final List<Medication> medications;
  final String status; // pending / taken / missed
  final DateTime scheduledAt;

  TodaySlotView({
    required this.slot,
    required this.medications,
    required this.status,
    required this.scheduledAt,
  });
}

class IntakeProvider extends ChangeNotifier {
  final DoseEventRepository _doseRepo;
  final SlotRepository _slotRepo;
  final MedicationRepository _medRepo;

  /// missed 이벤트 콜백 (Phase 7에서 SupabaseSync 연결)
  void Function(List<DoseEvent>)? onMissed;
  /// taken 이벤트 콜백 (Phase 7에서 SupabaseSync 연결)
  void Function(List<DoseEvent>)? onTaken;

  IntakeProvider(this._doseRepo, this._slotRepo, this._medRepo);

  List<TodaySlotView> _today = const [];
  List<TodaySlotView> get today => _today;

  Future<void> loadToday() async {
    final now = DateTime.now();
    // 1) 오래된 pending → missed
    final missed = await _doseRepo.markStaleAsMissed(now: now);
    if (missed.isNotEmpty) onMissed?.call(missed);

    // 2) 오늘 활성 슬롯
    final slots = _slotRepo.findActiveSlots();
    final today0 = DateTime(now.year, now.month, now.day);
    final result = <TodaySlotView>[];

    for (final slot in slots) {
      final bit = 1 << (today0.weekday - 1);
      if ((slot.daysOfWeek & bit) == 0) continue;

      final scheduled = DateTime(today0.year, today0.month, today0.day,
          slot.hour, slot.minute);

      // 슬롯의 약들
      final slotMeds = _slotRepo.findMedicationsForSlot(slot.id);
      final meds = <Medication>[];
      for (final sm in slotMeds) {
        final m = _medRepo.findById(sm.medicationId);
        if (m != null && m.deletedAt == null) meds.add(m);
      }
      if (meds.isEmpty) continue;

      // 각 약에 pending 보장
      for (final m in meds) {
        await _doseRepo.upsertPending(
          slotId: slot.id, medicationId: m.id, scheduledAt: scheduled,
        );
      }

      // 슬롯 전체 상태 집계
      final logs = _doseRepo.findByDate(today0);
      final logsForSlot = logs.where((l) =>
          l.slotId == slot.id && l.scheduledAt == scheduled).toList();
      final status = _aggregateStatus(logsForSlot);

      result.add(TodaySlotView(
        slot: slot, medications: meds, status: status, scheduledAt: scheduled,
      ));
    }

    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    _today = result;
    notifyListeners();
  }

  String _aggregateStatus(List<DoseEvent> logs) {
    if (logs.every((l) => l.status == DoseEvent.statusTaken)) return DoseEvent.statusTaken;
    if (logs.any((l) => l.status == DoseEvent.statusMissed)) return DoseEvent.statusMissed;
    return DoseEvent.statusPending;
  }

  Future<void> markSlotTaken(String slotId, DateTime date) async {
    final taken = await _doseRepo.markSlotTaken(
      slotId: slotId, date: date, now: DateTime.now(),
    );
    if (taken.isNotEmpty) onTaken?.call(taken);
    await loadToday();
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/intake/ui/intake_provider.dart
git commit -m "feat(parent/intake): IntakeProvider — 오늘 슬롯 + missed/taken 콜백 훅"
```

### Task 4.2: 메인 화면 — 오늘의 약

**Files:**
- Create: `lib/features/parent/intake/ui/home_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/intake/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../domain/dose_event.dart';
import 'intake_provider.dart';
import 'intake_check_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<IntakeProvider>().loadToday());
  }

  Color _statusColor(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return AppColors.jade;
      case DoseEvent.statusMissed: return AppColors.care;
      default: return AppColors.pillDeep;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return '복용 완료';
      case DoseEvent.statusMissed: return '미복용';
      default: return '복용 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = context.watch<IntakeProvider>().today;
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 약', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 72,
      ),
      body: today.isEmpty
          ? const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('오늘 드실 약이 없어요.\n약과 시간을 등록해주세요.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 22)),
            ))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: today.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final t = today[i];
                final hh = t.slot.hour.toString().padLeft(2, '0');
                final mm = t.slot.minute.toString().padLeft(2, '0');
                return Card(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => IntakeCheckScreen(slotView: t),
                      ));
                      if (context.mounted) context.read<IntakeProvider>().loadToday();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('$hh:$mm',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(t.slot.label,
                              style: const TextStyle(fontSize: 18, color: AppColors.ink2)),
                        ]),
                        const SizedBox(width: 24),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final m in t.medications)
                              Padding(padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• ${m.name}', style: const TextStyle(fontSize: 18))),
                          ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor(t.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(_statusLabel(t.status),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/intake/ui/home_screen.dart
git commit -m "feat(parent/home): 오늘의 약 메인 화면"
```

### Task 4.3: 복용 체크 화면

**Files:**
- Create: `lib/features/parent/intake/ui/intake_check_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/intake/ui/intake_check_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/notification/notification_scheduler.dart';
import '../../../../core/notification/notification_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import 'intake_provider.dart';

class IntakeCheckScreen extends StatelessWidget {
  final TodaySlotView slotView;
  const IntakeCheckScreen({super.key, required this.slotView});

  @override
  Widget build(BuildContext context) {
    final hh = slotView.slot.hour.toString().padLeft(2, '0');
    final mm = slotView.slot.minute.toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(title: Text('${slotView.slot.label} $hh:$mm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final m in slotView.medications)
            Card(margin: const EdgeInsets.only(bottom: 16),
              child: Padding(padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (m.photoPath != null)
                    ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(m.photoPath!),
                          width: 96, height: 96, fit: BoxFit.cover))
                  else
                    Container(width: 96, height: 96, color: AppColors.paper2,
                      child: const Icon(Icons.medication, size: 48, color: AppColors.pillDeep)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    if (m.memo != null)
                      Text(m.memo!, style: const TextStyle(fontSize: 16)),
                  ])),
                ])),
            ),
          const SizedBox(height: 24),
          SeniorButton(
            label: '복용 완료',
            large: true,
            color: AppColors.jade,
            onPressed: () async {
              // 오늘 dayOffset = 0 retry +10/+20 알림 cancel
              final hash = NotificationIdEncoder.hashSlotId(slotView.slot.id);
              await NotificationService.cancelMany(
                NotificationIdEncoder.idsForSlotInstance(slotHash: hash, dayOffset: 0),
              );
              final today = DateTime.now();
              await context.read<IntakeProvider>()
                  .markSlotTaken(slotView.slot.id,
                      DateTime(today.year, today.month, today.day));
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/intake/ui/intake_check_screen.dart
git commit -m "feat(parent/intake): 복용 체크 화면 + retry 알림 cancel"
```

### Task 4.4: 알림 탭 → 복용 체크 라우팅

**Files:**
- Modify: `lib/features/parent/intake/ui/home_screen.dart` (initState)

- [ ] **Step 1: HomeScreen.initState에 알림 핸들러 등록**

`_HomeScreenState.initState`를 다음으로 교체:

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() => context.read<IntakeProvider>().loadToday());
  NotificationService.onTap = (payload) {
    // payload: "slot:<slotId>"
    if (!payload.startsWith('slot:')) return;
    final slotId = payload.substring(5);
    final view = context.read<IntakeProvider>().today
        .where((t) => t.slot.id == slotId).firstOrNull;
    if (view != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => IntakeCheckScreen(slotView: view),
      ));
    }
  };
}
```

상단 import 추가:

```dart
import '../../../../core/notification/notification_service.dart';
```

> Dart의 `firstOrNull` 사용을 위해 `import 'package:collection/collection.dart';` 가 필요할 수 있음 — 만약 컴파일 에러시 `try { ... .first; } catch (_) { return; }` 형태로 변경.

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/intake/ui/home_screen.dart
git commit -m "feat(parent/home): 알림 탭 → 슬롯 복용 체크 라우팅"
```

---

## Phase 5: 부모 모드 UI — 캘린더 + 온보딩 + 설정

### Task 5.1: 이력 캘린더

**Files:**
- Create: `lib/features/parent/intake/ui/history_calendar_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/intake/ui/history_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/hive/hive_init.dart';
import '../../../../core/theme/tokens.dart';
import '../../monetization/ad_banner.dart';
import '../data/dose_event_repository.dart';
import '../domain/dose_event.dart';

class HistoryCalendarScreen extends StatefulWidget {
  const HistoryCalendarScreen({super.key});
  @override
  State<HistoryCalendarScreen> createState() => _HistoryCalendarScreenState();
}

class _HistoryCalendarScreenState extends State<HistoryCalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<DateTime, List<DoseEvent>> _byDay = {};

  @override
  void initState() {
    super.initState();
    _load(_focused);
  }

  Future<void> _load(DateTime month) async {
    final box = Hive.box<DoseEvent>(HiveInit.doseEventsBox);
    final repo = DoseEventRepository(box);
    final logs = repo.findByMonth(month);
    final map = <DateTime, List<DoseEvent>>{};
    for (final l in logs) {
      final key = DateTime(l.date.year, l.date.month, l.date.day);
      map.putIfAbsent(key, () => []).add(l);
    }
    setState(() => _byDay = map);
  }

  Color? _dayColor(DateTime day) {
    final list = _byDay[DateTime(day.year, day.month, day.day)];
    if (list == null || list.isEmpty) return null;
    if (list.any((l) => l.status == DoseEvent.statusMissed)) return AppColors.care;
    if (list.every((l) => l.status == DoseEvent.statusTaken)) return AppColors.jade;
    return AppColors.inkMute;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('복용 이력')),
      body: Column(children: [
        TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now(),
          focusedDay: _focused,
          selectedDayPredicate: (d) => isSameDay(_selected, d),
          onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
          onPageChanged: (foc) => _load(foc),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (_, day, __) {
              final c = _dayColor(day);
              if (c == null) return const SizedBox.shrink();
              return Positioned(bottom: 4,
                child: Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)));
            },
          ),
        ),
        const Divider(),
        if (_selected != null)
          Expanded(child: ListView(
            padding: const EdgeInsets.all(AppSizes.padding),
            children: (_byDay[DateTime(_selected!.year, _selected!.month, _selected!.day)] ?? [])
                .map((l) => ListTile(
                      leading: Icon(
                        l.status == DoseEvent.statusTaken ? Icons.check_circle :
                        l.status == DoseEvent.statusMissed ? Icons.cancel : Icons.schedule,
                        color: l.status == DoseEvent.statusTaken ? AppColors.jade :
                               l.status == DoseEvent.statusMissed ? AppColors.care : AppColors.inkMute,
                      ),
                      title: Text('약 ${l.medicationId}'),
                      subtitle: Text(l.scheduledAt.toString()),
                    )).toList(),
          )),
        const AdBanner(),
      ]),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/intake/ui/history_calendar_screen.dart
git commit -m "feat(parent/history): 복용 이력 캘린더 (Hive box 직접 조회)"
```

### Task 5.2: 온보딩 (권한 요청)

**Files:**
- Create: `lib/features/parent/onboarding/onboarding_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/hive/hive_init.dart';
import '../../../core/notification/notification_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/senior_button.dart';
import '../settings/data/settings_repository.dart';
import '../settings/domain/app_settings.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _allowPermissions() async {
    await NotificationService.requestPermissions();
    final box = Hive.box<AppSettings>(HiveInit.settingsBox);
    await SettingsRepository(box).setOnboardingDone(true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 60),
          const Icon(Icons.medication, size: 100, color: AppColors.pillDeep),
          const SizedBox(height: 32),
          const Text('한 알도, 잊지 않게',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text('어르신이 약을 잊지 않으시도록 정해진 시간에 알림을 보내드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.ink2)),
          const Spacer(),
          const Text('알림 권한이 필요해요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.ink2)),
          const SizedBox(height: 12),
          SeniorButton(label: '알림 받기 시작', onPressed: _allowPermissions, large: true),
          const SizedBox(height: 32),
        ]),
      )),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/onboarding/
git commit -m "feat(parent/onboarding): 권한 요청 + 인사말 화면"
```

### Task 5.3: 설정 화면

**Files:**
- Create: `lib/features/parent/settings/ui/settings_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/settings/ui/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import '../../monetization/ads_provider.dart';
import '../../pairing/ui/connect_child_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          // ── 자녀와 연결 ──
          Card(child: ListTile(
            leading: const Icon(Icons.family_restroom, color: AppColors.pillDeep, size: 32),
            title: const Text('자녀와 연결',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            subtitle: const Text('자녀가 부모님 복약을 원격으로 확인할 수 있어요'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConnectChildScreen())),
          )),
          const Divider(height: 32),
          // ── 광고 제거 ──
          if (!ads.removed) ...[
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('광고 제거 — ₩2,900',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            )),
            const SizedBox(height: 8),
            const Text('한 번 결제하시면 영구 제거됩니다.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            SeniorButton(label: '광고 제거 결제',
                onPressed: () => ads.purchaseRemoveAds(context)),
            const SizedBox(height: 12),
            SeniorButton(label: '구매 복원', color: AppColors.inkMute,
                onPressed: () => ads.restorePurchases()),
          ] else ...[
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('광고 제거됨 ✓',
                  style: TextStyle(fontSize: 22, color: AppColors.jade)),
            )),
          ],
          const Divider(height: 40),
          const Text('앱 정보', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('KYH 약 알림 v1.0.0', style: TextStyle(fontSize: 16)),
          const Text('Korean Young Health · 한 알도, 잊지 않게.',
              style: TextStyle(fontSize: 14, color: AppColors.ink2)),
        ],
      ),
    );
  }
}
```

> 주의: `AdsProvider`(Phase 12) + `ConnectChildScreen`(Phase 8) 컴파일은 그 phase 끝나야 통과. 그 전엔 stub 또는 import 주석.

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/settings/ui/
git commit -m "feat(parent/settings): 설정 화면 (자녀 연결 + 광고 제거 자리)"
```

---

## Phase 6: 모드 선택 + 진입점 + 라우팅

### Task 6.1: 모드 선택 화면 (화면 0)

**Files:**
- Create: `lib/features/mode_select/mode_select_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/mode_select/mode_select_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/hive/hive_init.dart';
import '../../core/theme/tokens.dart';
import '../parent/settings/data/settings_repository.dart';
import '../parent/settings/domain/app_settings.dart';

class ModeSelectScreen extends StatelessWidget {
  final void Function(String mode) onSelected;
  const ModeSelectScreen({super.key, required this.onSelected});

  Future<void> _select(BuildContext context, String mode) async {
    final box = Hive.box<AppSettings>(HiveInit.settingsBox);
    await SettingsRepository(box).setUserMode(mode);
    onSelected(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 80),
          const Icon(Icons.medication, size: 100, color: AppColors.pillDeep),
          const SizedBox(height: 32),
          const Text('한 알도, 잊지 않게',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('어떻게 사용하시나요?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.ink2)),
          const Spacer(),
          // 부모 큰 버튼
          SizedBox(height: 100, child: ElevatedButton(
            onPressed: () => _select(context, AppSettings.modeParent),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pillDeep, foregroundColor: Colors.white,
            ),
            child: const Text('부모님이세요?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 12),
          const Text('내가 약을 먹을 시간을 알려주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.ink2)),
          const SizedBox(height: 32),
          // 자녀 버튼 (조금 더 작게)
          SizedBox(height: 80, child: OutlinedButton(
            onPressed: () => _select(context, AppSettings.modeChild),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pillDeep,
              side: const BorderSide(color: AppColors.pillDeep, width: 2),
            ),
            child: const Text('자녀세요?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          const Text('부모님 약 복용 상태를 확인하고 싶어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.ink2)),
          const SizedBox(height: 60),
        ]),
      )),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/mode_select/
git commit -m "feat(mode-select): 첫 실행 모드 선택 화면 (부모/자녀)"
```

### Task 6.2: 부모 셸 (BottomNav 5탭)

**Files:**
- Create: `lib/features/parent/parent_shell.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/parent_shell.dart
import 'package:flutter/material.dart';
import 'intake/ui/home_screen.dart';
import 'intake/ui/history_calendar_screen.dart';
import 'medication/ui/medication_list_screen.dart';
import 'settings/ui/settings_screen.dart';
import 'slot/ui/slot_list_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});
  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _idx = 0;
  final _pages = const [
    HomeScreen(),
    MedicationListScreen(),
    SlotListScreen(),
    HistoryCalendarScreen(),
    SettingsScreen(),
  ];
  final _labels = const ['오늘', '약 관리', '시간 관리', '이력', '설정'];
  final _icons = const [
    Icons.today, Icons.medication, Icons.schedule,
    Icons.calendar_month, Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: List.generate(_pages.length, (i) =>
          NavigationDestination(icon: Icon(_icons[i], size: 28), label: _labels[i]),
        ),
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/parent_shell.dart
git commit -m "feat(parent): BottomNav 셸 (5개 탭)"
```

### Task 6.3: 진입점 — main.dart + app.dart (모드 분기)

**Files:**
- Create: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/firebase/firebase_init.dart';
import 'core/hive/hive_init.dart';
import 'core/notification/notification_service.dart';
import 'core/supabase/supabase_init.dart';
import 'core/time/timezone_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimezone();
  await initializeDateFormatting('ko_KR', null);
  await HiveInit.initialize();
  await SupabaseInit.initialize();
  await FirebaseInit.initialize();
  await NotificationService.initialize();
  await MobileAds.instance.initialize();
  runApp(const App());
}
```

- [ ] **Step 2: app.dart — 모드 분기 + Provider 주입**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'core/hive/hive_init.dart';
import 'core/theme/caregiver_theme.dart';
import 'core/theme/senior_theme.dart';
import 'features/child/child_shell.dart';
import 'features/mode_select/mode_select_screen.dart';
import 'features/parent/intake/data/dose_event_repository.dart';
import 'features/parent/intake/domain/dose_event.dart';
import 'features/parent/intake/ui/intake_provider.dart';
import 'features/parent/medication/data/medication_repository.dart';
import 'features/parent/medication/domain/medication.dart';
import 'features/parent/medication/ui/medications_provider.dart';
import 'features/parent/monetization/ads_provider.dart';
import 'features/parent/onboarding/onboarding_screen.dart';
import 'features/parent/parent_shell.dart';
import 'features/parent/settings/data/settings_repository.dart';
import 'features/parent/settings/domain/app_settings.dart';
import 'features/parent/slot/data/slot_repository.dart';
import 'features/parent/slot/domain/slot_medication.dart';
import 'features/parent/slot/domain/time_slot.dart';
import 'features/parent/slot/ui/slots_provider.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String? _mode;          // '' / 'parent' / 'child'
  bool _onboardingDone = false;
  late final SettingsRepository _settingsRepo;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box<AppSettings>(HiveInit.settingsBox);
    _settingsRepo = SettingsRepository(settingsBox);
    final s = _settingsRepo.current;
    _mode = s.userMode.isEmpty ? null : s.userMode;
    _onboardingDone = s.onboardingDone;
  }

  void _selectMode(String m) {
    setState(() => _mode = m);
  }

  void _completeOnboarding() => setState(() => _onboardingDone = true);

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return MaterialApp(
        theme: SeniorTheme.light(),
        home: ModeSelectScreen(onSelected: _selectMode),
      );
    }

    if (_mode == AppSettings.modeParent) {
      return _parentApp();
    }
    return _childApp();
  }

  Widget _parentApp() {
    final medRepo = MedicationRepository(Hive.box<Medication>(HiveInit.medicationsBox));
    final slotRepo = SlotRepository(
      Hive.box<TimeSlot>(HiveInit.slotsBox),
      Hive.box<SlotMedication>(HiveInit.slotMedicationsBox),
    );
    final doseRepo = DoseEventRepository(Hive.box<DoseEvent>(HiveInit.doseEventsBox));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationsProvider(medRepo)),
        ChangeNotifierProvider(create: (_) => SlotsProvider(slotRepo)),
        ChangeNotifierProvider(create: (_) => IntakeProvider(doseRepo, slotRepo, medRepo)),
        ChangeNotifierProvider(create: (_) => AdsProvider(_settingsRepo)..init()),
      ],
      child: MaterialApp(
        title: 'KYH 약 알림',
        theme: SeniorTheme.light(),
        home: _onboardingDone
            ? const ParentShell()
            : OnboardingScreen(onDone: _completeOnboarding),
      ),
    );
  }

  Widget _childApp() {
    return MaterialApp(
      title: 'KYH 약 알림 (자녀)',
      theme: CaregiverTheme.light(),
      home: const ChildShell(),
    );
  }
}
```

- [ ] **Step 3: 자녀 모드 stub (Phase 9에서 진짜 구현)**

```dart
// lib/features/child/child_shell.dart  ← TEMP STUB (Phase 9에서 교체)
import 'package:flutter/material.dart';

class ChildShell extends StatelessWidget {
  const ChildShell({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자녀 모드')),
      body: const Center(child: Text('자녀 모드 — Phase 9에서 구현됩니다')),
    );
  }
}
```

- [ ] **Step 4: 실행 검증**

```bash
flutter run
```

Expected:
1. 첫 실행 → 모드 선택 화면
2. "부모님이세요?" 탭 → 온보딩 → "알림 받기 시작" → 부모 메인 (오늘 비어 있음)
3. 앱 재시작 → 바로 부모 메인으로 진입 (모드 + 온보딩 저장됨)
4. (자녀 모드는 Phase 9까지 stub)

- [ ] **Step 5: 커밋**

```bash
git add lib/main.dart lib/app.dart lib/features/child/child_shell.dart
git commit -m "feat(app): 진입점 + 모드 분기 (부모/자녀) + Provider 주입"
```

---

> **여기까지 Phase 0~6 — 부모 모드 풀스택이 완성됨.** Phase 7부터는 Supabase 동기화/페어링/자녀 모드/FCM/수익화/출시.

---

## Phase 7: Supabase 동기화 (부모 → 원격 단방향)

### Task 7.1: 부모 anonymous 인증 (페어링 시점에 trigger)

**Files:**
- Create: `lib/core/supabase/parent_anonymous_auth.dart`

- [ ] **Step 1: 작성**

```dart
// lib/core/supabase/parent_anonymous_auth.dart
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../hive/hive_init.dart';
import '../../features/parent/settings/data/settings_repository.dart';
import '../../features/parent/settings/domain/app_settings.dart';
import 'supabase_init.dart';

class ParentAnonymousAuth {
  /// 페어링 시작 시점에 호출. 이미 가입돼 있으면 그대로, 없으면 anonymous sign-in.
  /// 성공 시 settings.pairedSupabaseUserId에 user.id 저장.
  static Future<String> ensureSignedIn() async {
    final settings = SettingsRepository(
      Hive.box<AppSettings>(HiveInit.settingsBox),
    );
    final cached = settings.current.pairedSupabaseUserId;
    final session = SupabaseInit.client.auth.currentSession;

    if (cached != null && session != null && session.user.id == cached) {
      return cached;
    }

    final res = await SupabaseInit.client.auth.signInAnonymously();
    final uid = res.user?.id;
    if (uid == null) {
      throw StateError('anonymous sign-in failed: user is null');
    }

    // parent_devices 테이블에 본인 row 생성 (RLS 통과)
    await SupabaseInit.client.from('parent_devices').upsert({
      'id': uid,
      'device_label': null,
    });

    await settings.setPairedSupabaseUserId(uid);
    return uid;
  }

  /// 페어링 모두 해제 시 호출 (옵션). 기본은 보존.
  static Future<void> signOut() async {
    await SupabaseInit.client.auth.signOut();
    final settings = SettingsRepository(Hive.box<AppSettings>(HiveInit.settingsBox));
    await settings.setPairedSupabaseUserId(null);
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/core/supabase/parent_anonymous_auth.dart
git commit -m "feat(supabase): 부모 anonymous 인증 + parent_devices 자동 등록"
```

### Task 7.2: ParentSyncService — medications + dose_events upsert

**Files:**
- Create: `lib/core/supabase/parent_sync_service.dart`

- [ ] **Step 1: 작성**

```dart
// lib/core/supabase/parent_sync_service.dart
import 'package:hive/hive.dart';
import '../hive/hive_init.dart';
import '../../features/parent/intake/domain/dose_event.dart';
import '../../features/parent/medication/domain/medication.dart';
import '../../features/parent/settings/domain/app_settings.dart';
import 'supabase_init.dart';

/// 부모 → Supabase 단방향 push.
/// 모든 메서드는 fire-and-forget — 실패해도 부모 앱 동작에 영향 없음 (try/catch로 무시).
/// 페어링 안 된 부모(pairedSupabaseUserId == null)는 함수가 아예 no-op 으로 끝남.
class ParentSyncService {
  String? _userId() {
    final settings = Hive.box<AppSettings>(HiveInit.settingsBox).get('app');
    return settings?.pairedSupabaseUserId;
  }

  bool get isLinked => _userId() != null;

  /// 약 추가/수정 시 호출
  Future<void> upsertMedication(Medication m) async {
    final uid = _userId();
    if (uid == null) return;
    try {
      await SupabaseInit.client.from('medications').upsert({
        'id': m.id,
        'parent_device_id': uid,
        'name': m.name,
        'updated_at': DateTime.now().toIso8601String(),
        'deleted_at': m.deletedAt?.toIso8601String(),
      });
    } catch (_) {/* fire-and-forget */}
  }

  /// 약 삭제 시 호출
  Future<void> markMedicationDeleted(String medicationId) async {
    final uid = _userId();
    if (uid == null) return;
    try {
      await SupabaseInit.client.from('medications')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', medicationId)
          .eq('parent_device_id', uid);
    } catch (_) {}
  }

  /// 복용 / 미복용 이벤트 발생 시 호출
  Future<void> insertDoseEvent(DoseEvent e) async {
    if (e.status != DoseEvent.statusTaken && e.status != DoseEvent.statusMissed) {
      return; // pending/skipped는 미러 안 함
    }
    final uid = _userId();
    if (uid == null) return;
    try {
      await SupabaseInit.client.from('dose_events').insert({
        'id': e.id.replaceAll('|', '-').replaceAll(':', '-'),
        'parent_device_id': uid,
        'medication_id': e.medicationId,
        'slot_id': e.slotId,
        'date': '${e.date.year.toString().padLeft(4, '0')}-'
            '${e.date.month.toString().padLeft(2, '0')}-'
            '${e.date.day.toString().padLeft(2, '0')}',
        'status': e.status,
        'occurred_at': (e.takenAt ?? DateTime.now()).toIso8601String(),
      });
    } catch (_) {}
  }
}
```

> 주: `dose_events.id`는 Supabase에선 UUID, Hive에선 `YYYY-MM-DD|slot|med` 형태이므로 `|`/`:`을 `-`로 변환해서 호환되는 문자열로 보냄. RLS는 parent_device_id 기준이라 ID 형식 자체는 자유.

- [ ] **Step 2: 커밋**

```bash
git add lib/core/supabase/parent_sync_service.dart
git commit -m "feat(supabase): ParentSyncService — 단방향 push (fire-and-forget)"
```

### Task 7.3: MedicationsProvider / IntakeProvider에 Sync 콜백 연결

**Files:**
- Modify: `lib/features/parent/medication/ui/medications_provider.dart`
- Modify: `lib/features/parent/intake/ui/intake_provider.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: MedicationsProvider 수정 (sync 주입)**

생성자/메서드 교체:

```dart
import '../../../../core/supabase/parent_sync_service.dart';

class MedicationsProvider extends ChangeNotifier {
  final MedicationRepository _repo;
  final ParentSyncService? _sync;
  MedicationsProvider(this._repo, {ParentSyncService? sync}) : _sync = sync {
    _repo.watch().listen((_) {
      _items = _repo.findActive();
      notifyListeners();
    });
    _items = _repo.findActive();
  }

  List<Medication> _items = const [];
  List<Medication> get items => _items;

  Future<void> add(Medication m) async {
    await _repo.insert(m);
    _items = _repo.findActive();
    notifyListeners();
    _sync?.upsertMedication(m);
  }

  Future<void> remove(String id) async {
    await _repo.softDelete(id);
    _items = _repo.findActive();
    notifyListeners();
    _sync?.markMedicationDeleted(id);
  }
}
```

- [ ] **Step 2: IntakeProvider — onMissed/onTaken 훅 연결**

`app.dart`의 `_parentApp()` 함수에서 `IntakeProvider` 생성 후:

```dart
final sync = ParentSyncService();
final intakeProvider = IntakeProvider(doseRepo, slotRepo, medRepo)
  ..onMissed = (events) {
    for (final e in events) sync.insertDoseEvent(e);
  }
  ..onTaken = (events) {
    for (final e in events) sync.insertDoseEvent(e);
  };
```

그리고 `MultiProvider`에 `ParentSyncService`도 주입:

```dart
return MultiProvider(
  providers: [
    Provider.value(value: sync),
    ChangeNotifierProvider(create: (_) => MedicationsProvider(medRepo, sync: sync)),
    ChangeNotifierProvider(create: (_) => SlotsProvider(slotRepo)),
    ChangeNotifierProvider.value(value: intakeProvider),
    ChangeNotifierProvider(create: (_) => AdsProvider(_settingsRepo)..init()),
  ],
  child: MaterialApp(...),
);
```

상단 `app.dart` import 추가:

```dart
import 'core/supabase/parent_sync_service.dart';
```

- [ ] **Step 3: 실행 검증**

```bash
flutter run
```

페어링 안 한 상태에서: 약 추가/복용 체크 정상 동작, Supabase 호출은 모두 no-op (네트워크 끊고도 정상). Supabase 콘솔 → Table Editor → medications 비어 있음.

- [ ] **Step 4: 커밋**

```bash
git add lib/features/parent/medication/ui/medications_provider.dart lib/app.dart
git commit -m "feat(parent): Provider에 ParentSyncService 콜백 연결 (fire-and-forget)"
```

### Task 7.4: 슬롯 변경 시 medications도 sync

**Files:**
- Modify: `lib/features/parent/slot/ui/slots_provider.dart`

> 슬롯 추가는 약을 새로 만드는 게 아니라 기존 약 ↔ 시간 매핑만 만듦. medications 자체는 약 폼에서 이미 sync됨. 따라서 SlotsProvider는 별도 sync 호출 없음.

- [ ] **Step 1: 확인 + 주석만 추가**

`SlotsProvider.create` 함수 끝에 주석 추가:

```dart
// 주: medications 미러는 MedicationsProvider.add 시점에 이미 push됨.
// 슬롯 ↔ 약 매핑(slot_medications)은 부모 로컬만 (Q3 결정 — Supabase 미러 X).
```

- [ ] **Step 2: 커밋 (변경 없으면 skip)**

```bash
git add -A
git commit -m "docs(parent/slot): SlotsProvider sync 정책 주석" --allow-empty
```

---

## Phase 8: 페어링 (부모 측 코드 발급 + 자녀 redeem 자리)

### Task 8.1: PairingRepository (RPC 래퍼)

**Files:**
- Create: `lib/features/parent/pairing/data/pairing_repository.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/parent/pairing/data/pairing_repository.dart
import '../../../../core/supabase/parent_anonymous_auth.dart';
import '../../../../core/supabase/supabase_init.dart';

class PairingInfo {
  final String pairingId;
  final String childUserId;
  final String? childDisplayName;
  final String? parentLabel;
  final DateTime pairedAt;

  PairingInfo({
    required this.pairingId,
    required this.childUserId,
    required this.childDisplayName,
    required this.parentLabel,
    required this.pairedAt,
  });
}

class PairingRepository {
  /// 부모 6자리 코드 발급 (10분 TTL).
  /// 호출 전 anonymous 가입 보장 — 이게 부모가 처음 자녀와 연결할 때 가입하는 시점.
  Future<String> createCode() async {
    await ParentAnonymousAuth.ensureSignedIn();
    final res = await SupabaseInit.client.rpc('create_pairing_code');
    return res as String;
  }

  /// 부모 측: 본인 페어링 목록 조회
  Future<List<PairingInfo>> listMine() async {
    final uid = SupabaseInit.client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await SupabaseInit.client
        .from('pairings')
        .select('id, child_user_id, parent_label, paired_at, child_users(display_name)')
        .eq('parent_device_id', uid);
    return (rows as List).map((r) => PairingInfo(
      pairingId: r['id'] as String,
      childUserId: r['child_user_id'] as String,
      childDisplayName: (r['child_users'] as Map?)?['display_name'] as String?,
      parentLabel: r['parent_label'] as String?,
      pairedAt: DateTime.parse(r['paired_at'] as String),
    )).toList();
  }

  /// 부모 측: 페어링 해제 (양쪽 끊김)
  Future<void> unpair(String pairingId) async {
    await SupabaseInit.client.from('pairings').delete().eq('id', pairingId);
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/parent/pairing/data/
git commit -m "feat(parent/pairing): PairingRepository (RPC + listMine + unpair)"
```

### Task 8.2: 자녀와 연결 화면 (코드 표시 + 카운트다운)

**Files:**
- Create: `lib/features/parent/pairing/ui/pairing_provider.dart`
- Create: `lib/features/parent/pairing/ui/connect_child_screen.dart`

- [ ] **Step 1: Provider**

```dart
// lib/features/parent/pairing/ui/pairing_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/pairing_repository.dart';

class PairingProvider extends ChangeNotifier {
  final PairingRepository _repo = PairingRepository();

  String? _code;
  String? get code => _code;
  DateTime? _codeExpiresAt;
  DateTime? get codeExpiresAt => _codeExpiresAt;

  List<PairingInfo> _pairings = const [];
  List<PairingInfo> get pairings => _pairings;

  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<void> issueCode() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _code = await _repo.createCode();
      _codeExpiresAt = DateTime.now().add(const Duration(minutes: 10));
    } catch (e) {
      _error = '코드를 발급할 수 없어요: $e';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadPairings() async {
    _pairings = await _repo.listMine();
    notifyListeners();
  }

  Future<void> unpair(String pairingId) async {
    await _repo.unpair(pairingId);
    await loadPairings();
  }
}
```

- [ ] **Step 2: 화면**

```dart
// lib/features/parent/pairing/ui/connect_child_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import 'pairing_provider.dart';

class ConnectChildScreen extends StatefulWidget {
  const ConnectChildScreen({super.key});
  @override
  State<ConnectChildScreen> createState() => _ConnectChildScreenState();
}

class _ConnectChildScreenState extends State<ConnectChildScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PairingProvider>().loadPairings());
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final exp = context.read<PairingProvider>().codeExpiresAt;
      if (exp == null) return;
      final r = exp.difference(DateTime.now());
      setState(() => _remaining = r.isNegative ? Duration.zero : r);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmtRemaining() {
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PairingProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('자녀와 연결')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── 코드 박스 ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line, width: 2),
            ),
            child: Column(children: [
              if (pp.code == null)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '자녀에게 보여드릴 6자리 코드를 받으세요.\n10분 안에 자녀가 입력해야 해요.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 16),
                  ))
              else ...[
                Text(pp.code!,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 60,
                        fontWeight: FontWeight.w800, letterSpacing: 6)),
                const SizedBox(height: 8),
                Text('남은 시간 ${_fmtRemaining()}',
                    style: const TextStyle(fontSize: 16, color: AppColors.ink2)),
              ]
            ]),
          ),
          const SizedBox(height: 16),
          if (pp.error != null)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(pp.error!, style: const TextStyle(color: AppColors.care))),
          SeniorButton(
            label: pp.loading ? '발급 중...' : '코드 받기',
            onPressed: pp.loading ? null : () async {
              await context.read<PairingProvider>().issueCode();
              _startTicker();
            },
          ),
          const Divider(height: 48),
          // ── 연결된 자녀 ──
          const Text('연결된 자녀',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (pp.pairings.isEmpty)
            const Padding(padding: EdgeInsets.all(8),
              child: Text('아직 연결된 자녀가 없어요',
                  style: TextStyle(color: AppColors.ink2)))
          else
            ...pp.pairings.map((p) => Card(child: ListTile(
              leading: const Icon(Icons.person, size: 32, color: AppColors.pillDeep),
              title: Text(
                  p.childDisplayName ?? '자녀',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              subtitle: Text('연결: ${p.pairedAt.toLocal()}'),
              trailing: TextButton(
                onPressed: () => context.read<PairingProvider>().unpair(p.pairingId),
                child: const Text('연결 해제'),
              ),
            ))),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 3: app.dart의 Provider에 PairingProvider 추가**

`_parentApp()`의 `MultiProvider.providers`에 추가:

```dart
ChangeNotifierProvider(create: (_) => PairingProvider()),
```

상단 import:

```dart
import 'features/parent/pairing/ui/pairing_provider.dart';
```

- [ ] **Step 4: 실행 검증**

```bash
flutter run
```

부모 모드 → 설정 → "자녀와 연결" → "코드 받기" 탭 → 6자리 코드 표시 + 10분 카운트다운. Supabase 콘솔 → pairing_codes 테이블에 row 1개 확인.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/parent/pairing/ui/ lib/app.dart
git commit -m "feat(parent/pairing): 자녀와 연결 화면 + 코드 발급 + 페어링 목록"
```

### Task 8.3: (자녀 측 redeem은 Phase 9.3에서 구현)

> redeem 로직은 자녀 측 "+ 부모님 추가" 화면 안에 있어 Phase 9에서 작성. 여기는 placeholder.

---

## Phase 9: 자녀 모드 — 인증 + 홈 + 부모 추가

### Task 9.1: 자녀 인증 — Google OAuth + 이메일 (Supabase)

**Files:**
- Create: `lib/features/child/auth/child_auth_service.dart`
- Create: `lib/features/child/auth/ui/child_login_screen.dart`

#### 사전: Google OAuth 셋업 (Supabase + Google Cloud)

콘솔 작업 (브라우저):

1. Google Cloud Console (https://console.cloud.google.com) → 새 프로젝트 → "API 및 서비스" → "OAuth 동의 화면" → "외부" 선택 → 앱 정보 입력 (앱 이름 `KYH 약 알림`, 사용자 지원 이메일 본인) → 저장.
2. "사용자 인증 정보" → "+ 사용자 인증 정보 만들기" → **OAuth 클라이언트 ID** → 애플리케이션 유형 "웹 애플리케이션" → 이름 `kyh-medi-supabase` → "승인된 리디렉션 URI"에 Supabase 콘솔 → Authentication → Google Provider 화면에서 보이는 콜백 URL 붙여넣기 (`https://<project>.supabase.co/auth/v1/callback`) → 만들기 → **Client ID + Client Secret 메모**.
3. Supabase 콘솔 → Authentication → Providers → Google → 위에서 받은 Client ID + Secret 입력 → 활성화 → 저장.
4. (선택) 안드로이드 앱에서 Google OAuth 콜백 받으려면 추가 redirect URI 필요. 단순화: Supabase의 "Email/Password" 옵션도 함께 활성화 → Google 실패 시 폴백.

- [ ] **Step 1: ChildAuthService**

```dart
// lib/features/child/auth/child_auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_init.dart';

class ChildAuthService {
  /// Google OAuth (인앱 브라우저)
  Future<void> signInWithGoogle() async {
    await SupabaseInit.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'kyhmedi://auth-callback',
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await SupabaseInit.client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName ?? ''},
    );
    return res;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return SupabaseInit.client.auth.signInWithPassword(
      email: email, password: password,
    );
  }

  /// 가입/로그인 후 child_users 테이블에 본인 row 보장
  Future<void> ensureChildUserRow({String? displayName}) async {
    final user = SupabaseInit.client.auth.currentUser;
    if (user == null) return;
    await SupabaseInit.client.from('child_users').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': displayName ?? user.userMetadata?['display_name'] ?? user.email,
    });
  }

  Future<void> signOut() => SupabaseInit.client.auth.signOut();

  Stream<AuthState> get onAuthStateChange => SupabaseInit.client.auth.onAuthStateChange;
  User? get currentUser => SupabaseInit.client.auth.currentUser;
}
```

- [ ] **Step 2: AndroidManifest에 OAuth deeplink 추가**

`android/app/src/main/AndroidManifest.xml`의 `<activity android:name=".MainActivity">` 안에 추가:

```xml
<intent-filter android:label="kyhmedi-auth">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="kyhmedi" android:host="auth-callback"/>
</intent-filter>
```

- [ ] **Step 3: 로그인 화면**

```dart
// lib/features/child/auth/ui/child_login_screen.dart
import 'package:flutter/material.dart';
import '../child_auth_service.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});
  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _auth = ChildAuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  Future<void> _go(Future<void> Function() action) async {
    setState(() { _loading = true; _error = null; });
    try {
      await action();
      await _auth.ensureChildUserRow(displayName: _name.text.trim());
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자녀 로그인'), bottom: TabBar(
        controller: _tab,
        tabs: const [Tab(text: 'Google'), Tab(text: '이메일')],
      )),
      body: TabBarView(controller: _tab, children: [
        _googleTab(),
        _emailTab(),
      ]),
    );
  }

  Widget _googleTab() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.family_restroom, size: 80, color: Colors.blueAccent),
      const SizedBox(height: 24),
      const Text('Google 계정으로 빠르게 시작',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 32),
      ElevatedButton.icon(
        icon: const Icon(Icons.login),
        label: const Text('Google로 로그인'),
        onPressed: _loading ? null : () => _go(_auth.signInWithGoogle),
      ),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
          child: Text(_error!, style: const TextStyle(color: Colors.red))),
    ]),
  );

  Widget _emailTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: _name, decoration: const InputDecoration(labelText: '이름 (가입 시)')),
      const SizedBox(height: 12),
      TextField(controller: _email, decoration: const InputDecoration(labelText: '이메일'),
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 12),
      TextField(controller: _password, decoration: const InputDecoration(labelText: '비밀번호'),
          obscureText: true),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _loading ? null : () => _go(() => _auth.signUpWithEmail(
            email: _email.text.trim(), password: _password.text,
            displayName: _name.text.trim())),
        child: const Text('가입하기'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _loading ? null : () => _go(() => _auth.signInWithEmail(
            email: _email.text.trim(), password: _password.text)),
        child: const Text('이미 계정이 있어요 — 로그인'),
      ),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
          child: Text(_error!, style: const TextStyle(color: Colors.red))),
    ]),
  );
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/child/auth/ android/app/src/main/AndroidManifest.xml
git commit -m "feat(child/auth): Google OAuth + Email 로그인/가입 + child_users 자동 등록"
```

### Task 9.2: 자녀 홈 — 부모 카드 목록

**Files:**
- Create: `lib/features/child/home/data/child_home_repository.dart`
- Create: `lib/features/child/home/ui/child_home_provider.dart`
- Create: `lib/features/child/home/ui/child_home_screen.dart`

- [ ] **Step 1: Repository**

```dart
// lib/features/child/home/data/child_home_repository.dart
import '../../../../core/supabase/supabase_init.dart';

class ParentSummary {
  final String pairingId;
  final String parentDeviceId;
  final String label;        // "엄마"
  final int totalToday;
  final int takenToday;
  final int missedToday;

  ParentSummary({
    required this.pairingId,
    required this.parentDeviceId,
    required this.label,
    required this.totalToday,
    required this.takenToday,
    required this.missedToday,
  });
}

class ChildHomeRepository {
  Future<List<ParentSummary>> listParents() async {
    final uid = SupabaseInit.client.auth.currentUser?.id;
    if (uid == null) return [];

    final pairs = await SupabaseInit.client.from('pairings')
        .select('id, parent_device_id, parent_label')
        .eq('child_user_id', uid);

    final today = DateTime.now();
    final ymd = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final result = <ParentSummary>[];
    for (final p in (pairs as List)) {
      final pid = p['parent_device_id'] as String;
      final events = await SupabaseInit.client.from('dose_events')
          .select('status')
          .eq('parent_device_id', pid)
          .eq('date', ymd);
      final list = (events as List).map((e) => e['status'] as String).toList();
      result.add(ParentSummary(
        pairingId: p['id'] as String,
        parentDeviceId: pid,
        label: (p['parent_label'] as String?) ?? '부모님',
        totalToday: list.length,
        takenToday: list.where((s) => s == 'taken').length,
        missedToday: list.where((s) => s == 'missed').length,
      ));
    }
    return result;
  }
}
```

- [ ] **Step 2: Provider**

```dart
// lib/features/child/home/ui/child_home_provider.dart
import 'package:flutter/foundation.dart';
import '../data/child_home_repository.dart';

class ChildHomeProvider extends ChangeNotifier {
  final ChildHomeRepository _repo = ChildHomeRepository();
  List<ParentSummary> _items = const [];
  List<ParentSummary> get items => _items;
  bool _loading = false;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true; notifyListeners();
    _items = await _repo.listParents();
    _loading = false; notifyListeners();
  }
}
```

- [ ] **Step 3: 화면**

```dart
// lib/features/child/home/ui/child_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/caregiver_card.dart';
import '../../add_parent/ui/add_parent_screen.dart';
import '../../parent_detail/ui/parent_detail_screen.dart';
import 'child_home_provider.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});
  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChildHomeProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ChildHomeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('부모님 모니터링')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ChildHomeProvider>().load(),
        child: p.items.isEmpty && !p.loading
            ? const Center(child: Padding(padding: EdgeInsets.all(40),
                child: Text('연결된 부모님이 아직 없어요.\n오른쪽 아래 + 버튼을 누르세요.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 16))))
            : ListView(children: [
                for (final s in p.items)
                  CaregiverCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ParentDetailScreen(
                        parentDeviceId: s.parentDeviceId, label: s.label,
                      ),
                    )),
                    child: Row(children: [
                      Container(width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.person, size: 32, color: Colors.blueAccent)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.label,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('오늘 ${s.takenToday}/${s.totalToday} 복용'
                              '${s.missedToday > 0 ? " · 미복용 ${s.missedToday}" : ""}'),
                        ])),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
              ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(context, MaterialPageRoute(
            builder: (_) => const AddParentScreen(),
          ));
          if (added == true && context.mounted) {
            context.read<ChildHomeProvider>().load();
          }
        },
        label: const Text('부모님 추가'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/child/home/
git commit -m "feat(child/home): 부모 카드 목록 + 오늘 진행률"
```

### Task 9.3: "부모님 추가" — 코드 입력 + redeem RPC

**Files:**
- Create: `lib/features/child/add_parent/ui/add_parent_screen.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/child/add_parent/ui/add_parent_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_init.dart';

class AddParentScreen extends StatefulWidget {
  const AddParentScreen({super.key});
  @override
  State<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _code = TextEditingController();
  final _label = TextEditingController(text: '엄마');
  bool _loading = false;
  String? _error;

  Future<void> _redeem() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = '6자리 코드를 정확히 입력해주세요');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseInit.client.rpc('redeem_pairing_code', params: {
        'p_code': _code.text.trim(),
        'p_label': _label.text.trim().isEmpty ? '부모님' : _label.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부모님 추가')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('부모님 폰의 "자녀와 연결" 화면에서 받은 6자리 코드를 입력해주세요.',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          TextField(controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 32, letterSpacing: 8, fontFamily: 'monospace'),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: '6자리 코드', counterText: '', border: OutlineInputBorder(),
              )),
          const SizedBox(height: 16),
          TextField(controller: _label,
              decoration: const InputDecoration(
                labelText: '부모님 별칭', hintText: '예: 엄마, 아빠',
                border: OutlineInputBorder(),
              )),
          const SizedBox(height: 24),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red))),
          ElevatedButton(
            onPressed: _loading ? null : _redeem,
            child: Text(_loading ? '연결 중...' : '연결하기'),
          ),
        ])),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/child/add_parent/
git commit -m "feat(child/add-parent): 6자리 코드 입력 + redeem RPC"
```

### Task 9.4: ChildShell — 자녀 진입점 (인증 분기)

**Files:**
- Replace: `lib/features/child/child_shell.dart`

- [ ] **Step 1: stub 교체**

```dart
// lib/features/child/child_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_init.dart';
import 'auth/child_auth_service.dart';
import 'auth/ui/child_login_screen.dart';
import 'home/ui/child_home_provider.dart';
import 'home/ui/child_home_screen.dart';

class ChildShell extends StatefulWidget {
  const ChildShell({super.key});
  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  bool _signedIn = SupabaseInit.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    SupabaseInit.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() => _signedIn = event.session?.user != null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const ChildLoginScreen();
    }
    return ChangeNotifierProvider(
      create: (_) => ChildHomeProvider(),
      child: const ChildHomeScreen(),
    );
  }
}
```

- [ ] **Step 2: 실행 검증**

```bash
flutter run
```

자녀 모드 → 로그인 화면 → Email 가입 (Google은 OAuth 셋업 마저 끝난 후 검증) → 홈 (빈 상태). 부모 모드에서 코드 받기 → 자녀 "+ 부모님 추가" → 코드 입력 → 홈에 부모 카드 뜸.

- [ ] **Step 3: 커밋**

```bash
git add lib/features/child/child_shell.dart
git commit -m "feat(child): ChildShell — 인증 상태 기반 라우팅"
```

---

## Phase 10: 자녀 모드 — 부모 상세 + Realtime

### Task 10.1: 부모 상세 화면 (오늘 슬롯별 ✅/❌/⏳)

**Files:**
- Create: `lib/features/child/parent_detail/data/parent_detail_repository.dart`
- Create: `lib/features/child/parent_detail/ui/parent_detail_provider.dart`
- Create: `lib/features/child/parent_detail/ui/parent_detail_screen.dart`

- [ ] **Step 1: Repository**

```dart
// lib/features/child/parent_detail/data/parent_detail_repository.dart
import '../../../../core/supabase/supabase_init.dart';

class DoseEventView {
  final String medicationName;
  final String slotId;
  final DateTime occurredAt;
  final String status;
  DoseEventView({
    required this.medicationName,
    required this.slotId,
    required this.occurredAt,
    required this.status,
  });
}

class ParentDetailRepository {
  Future<List<DoseEventView>> todayEvents(String parentDeviceId) async {
    final today = DateTime.now();
    final ymd = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final rows = await SupabaseInit.client.from('dose_events')
        .select('slot_id, status, occurred_at, medication_id, medications(name)')
        .eq('parent_device_id', parentDeviceId)
        .eq('date', ymd)
        .order('occurred_at');

    return (rows as List).map((r) => DoseEventView(
      medicationName: (r['medications'] as Map?)?['name'] as String? ?? '',
      slotId: r['slot_id'] as String,
      occurredAt: DateTime.parse(r['occurred_at'] as String),
      status: r['status'] as String,
    )).toList();
  }
}
```

- [ ] **Step 2: Provider (Realtime 구독 포함)**

```dart
// lib/features/child/parent_detail/ui/parent_detail_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_init.dart';
import '../data/parent_detail_repository.dart';

class ParentDetailProvider extends ChangeNotifier {
  final String parentDeviceId;
  final ParentDetailRepository _repo = ParentDetailRepository();
  RealtimeChannel? _channel;

  ParentDetailProvider(this.parentDeviceId);

  List<DoseEventView> _events = const [];
  List<DoseEventView> get events => _events;
  bool _loading = false;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true; notifyListeners();
    _events = await _repo.todayEvents(parentDeviceId);
    _loading = false; notifyListeners();
  }

  void subscribeRealtime() {
    _channel = SupabaseInit.client.channel('parent_detail:$parentDeviceId')
      ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dose_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'parent_device_id',
            value: parentDeviceId,
          ),
          callback: (_) => load())
      ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'medications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'parent_device_id',
            value: parentDeviceId,
          ),
          callback: (_) => load())
      ..subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
```

- [ ] **Step 3: 화면**

```dart
// lib/features/child/parent_detail/ui/parent_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/parent_detail_repository.dart';
import 'parent_detail_provider.dart';

class ParentDetailScreen extends StatelessWidget {
  final String parentDeviceId;
  final String label;

  const ParentDetailScreen({
    super.key, required this.parentDeviceId, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentDetailProvider(parentDeviceId)
        ..load()
        ..subscribeRealtime(),
      child: _Body(label: label),
    );
  }
}

class _Body extends StatelessWidget {
  final String label;
  const _Body({required this.label});

  IconData _icon(String s) => switch (s) {
    'taken' => Icons.check_circle,
    'missed' => Icons.cancel,
    _ => Icons.schedule,
  };

  Color _color(String s) => switch (s) {
    'taken' => Colors.green,
    'missed' => Colors.red,
    _ => Colors.grey,
  };

  String _label(String s) => switch (s) {
    'taken' => '복용 완료',
    'missed' => '미복용',
    _ => '대기 중',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentDetailProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('$label 의 오늘')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ParentDetailProvider>().load(),
        child: p.events.isEmpty && !p.loading
            ? const Center(child: Padding(padding: EdgeInsets.all(32),
                child: Text('오늘 아직 등록된 복용 이벤트가 없어요.',
                    style: TextStyle(fontSize: 16))))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: p.events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final e = p.events[i];
                  return Card(child: ListTile(
                    leading: Icon(_icon(e.status), color: _color(e.status), size: 32),
                    title: Text(e.medicationName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${_label(e.status)} · '
                        '${e.occurredAt.toLocal().hour.toString().padLeft(2, '0')}:'
                        '${e.occurredAt.toLocal().minute.toString().padLeft(2, '0')}'),
                  ));
                },
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/child/parent_detail/
git commit -m "feat(child/parent-detail): 오늘 현황 + Realtime 구독"
```

---

## Phase 11: FCM 푸시 + Edge Function

### Task 11.1: 자녀 FCM 토큰 등록

**Files:**
- Create: `lib/core/firebase/fcm_service.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: FcmService**

```dart
// lib/core/firebase/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../supabase/supabase_init.dart';

class FcmService {
  static Future<void> registerForCurrentUser() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await messaging.getToken();
    if (token == null) return;
    await _saveToken(token);

    messaging.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _saveToken(String token) async {
    final user = SupabaseInit.client.auth.currentUser;
    if (user == null) return;
    await SupabaseInit.client.from('child_users').upsert({
      'id': user.id,
      'fcm_token': token,
    });
  }
}
```

- [ ] **Step 2: app.dart의 ChildShell 진입 시 토큰 등록**

`features/child/child_shell.dart`의 `initState` 안에 추가:

```dart
import '../../core/firebase/fcm_service.dart';

// initState 안에서 _signedIn이 true가 되는 시점에:
SupabaseInit.client.auth.onAuthStateChange.listen((event) {
  if (!mounted) return;
  final newSignedIn = event.session?.user != null;
  setState(() => _signedIn = newSignedIn);
  if (newSignedIn) {
    FcmService.registerForCurrentUser();
  }
});
// 그리고 진입 시점에 이미 로그인돼 있으면 즉시 등록:
if (_signedIn) FcmService.registerForCurrentUser();
```

- [ ] **Step 3: 커밋**

```bash
git add lib/core/firebase/fcm_service.dart lib/features/child/child_shell.dart
git commit -m "feat(fcm): 자녀 토큰 등록 + child_users.fcm_token upsert"
```

### Task 11.2: Edge Function 작성 + 배포

**Files:**
- Create: `supabase/functions/on_dose_event_insert/index.ts`

- [ ] **Step 1: 함수 생성**

```bash
supabase functions new on_dose_event_insert
```

→ `supabase/functions/on_dose_event_insert/index.ts` 빈 파일.

- [ ] **Step 2: 작성**

```typescript
// supabase/functions/on_dose_event_insert/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!; // (나중에 set)

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('method not allowed', { status: 405 });
  }
  try {
    const body = await req.json();
    const record = body.record ?? body; // Database Webhook payload
    if (record?.status !== 'missed') {
      return new Response('skip (not missed)', { status: 200 });
    }

    // 약 이름
    const { data: med } = await supabase
      .from('medications')
      .select('name')
      .eq('id', record.medication_id)
      .single();

    // 페어링된 자녀
    const { data: pairs } = await supabase
      .from('pairings')
      .select('parent_label, child_users(fcm_token, display_name)')
      .eq('parent_device_id', record.parent_device_id);

    const sent: string[] = [];
    for (const p of pairs ?? []) {
      const token = (p as any).child_users?.fcm_token;
      if (!token) continue;
      const resp = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Authorization': `key=${FCM_SERVER_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          to: token,
          notification: {
            title: '복약 알림',
            body: `${(p as any).parent_label ?? '부모님'}이 ${med?.name ?? '약'}을(를) 못 드셨어요`,
          },
          data: {
            type: 'dose_missed',
            parent_device_id: record.parent_device_id,
            slot_id: record.slot_id,
            medication_id: record.medication_id,
          },
        }),
      });
      sent.push(`${token.slice(0, 12)}: ${resp.status}`);
    }
    return new Response(JSON.stringify({ ok: true, sent }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error(e);
    return new Response(`error: ${e}`, { status: 500 });
  }
});
```

- [ ] **Step 3: FCM Server Key 발급 + Secret 설정**

Firebase 콘솔 → 프로젝트 설정 → "Cloud Messaging" 탭 → "Cloud Messaging API (Legacy)" 활성화 → 서버 키 복사.

> 신규 프로젝트는 Legacy API가 비활성화 상태. Google Cloud Console → API 라이브러리 → "Cloud Messaging API" 활성화 후 Firebase 콘솔로 돌아오면 키가 보임.

```bash
supabase secrets set FCM_SERVER_KEY="AAAA-실제값"
```

- [ ] **Step 4: 함수 배포**

```bash
supabase functions deploy on_dose_event_insert --no-verify-jwt
```

(Webhook이 SERVICE_ROLE로 호출하므로 JWT 검증 비활성화)

- [ ] **Step 5: Database Webhook 등록 (Supabase 콘솔)**

콘솔 → Database → Webhooks → "Create a new hook":
- Name: `on_dose_event_insert`
- Table: `public.dose_events`
- Events: ✅ Insert
- Type: HTTP Request → Edge Function → `on_dose_event_insert`
- HTTP Headers: 자동 (SERVICE_ROLE 인증)
- 저장

- [ ] **Step 6: 커밋**

```bash
git add supabase/functions/
git commit -m "feat(edge): on_dose_event_insert — missed → FCM 푸시"
```

### Task 11.3: 자녀 폰 푸시 수신 처리

**Files:**
- Create: `lib/core/firebase/fcm_message_handler.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: 백그라운드 핸들러 + 포그라운드 표시**

```dart
// lib/core/firebase/fcm_message_handler.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // 백그라운드: Firebase는 시스템 알림을 자동 표시. 별도 처리 필요 없음.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FcmMessageHandler {
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForeground);
  }

  static Future<void> _onForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kyh_medi_caregiver', '자녀 알림',
          channelDescription: '부모 미복용 알림',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: main.dart에 등록**

`main()`의 `FirebaseInit.initialize()` 직후 추가:

```dart
await FcmMessageHandler.initialize();
```

상단 import:

```dart
import 'core/firebase/fcm_message_handler.dart';
```

- [ ] **Step 3: 시연 검증**

E2E 테스트:
1. 부모 폰: 약 등록 + 슬롯 (지금부터 5분 후) + 자녀와 연결 코드 발급
2. 자녀 폰: 가입 → 코드 입력 → 부모 추가
3. 부모 폰: 알림 발사 후 30분 안에 복용 안 함 → IntakeProvider.loadToday 호출 시 missed 마킹 → Supabase insert → Webhook → Edge Function → FCM
4. 자녀 폰: 알림 도착 ("어머님이 ○○약 못 드셨어요")

> 시간이 오래 걸리면 부모 폰 시간을 임의로 +30분으로 조작 후 메인 화면 새로고침으로 검증.

- [ ] **Step 4: 커밋**

```bash
git add lib/core/firebase/fcm_message_handler.dart lib/main.dart
git commit -m "feat(fcm): 백그라운드 + 포그라운드 메시지 핸들러"
```

---

## Phase 12: 수익화 — AdMob + IAP (부모 모드만)

### Task 12.1: AdMob 초기화 + AndroidManifest

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

> `MobileAds.instance.initialize()`는 이미 Phase 6의 main.dart에 추가됨.

- [ ] **Step 1: AndroidManifest에 AdMob app ID 메타**

`<application>` 안에 추가:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

(테스트 app ID. 출시 직전에 실제 ID로 교체.)

- [ ] **Step 2: 커밋**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore(admob): app ID 메타 추가 (테스트 ID)"
```

### Task 12.2: AdsProvider + AdBanner

**Files:**
- Create: `lib/features/parent/monetization/ads_provider.dart`
- Create: `lib/features/parent/monetization/ad_banner.dart`
- Create: `lib/features/parent/monetization/iap_service.dart`

- [ ] **Step 1: IapService**

```dart
// lib/features/parent/monetization/iap_service.dart
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  static const String productId = 'kyh_remove_ads_lifetime';
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetails?> queryProduct() async {
    final r = await _iap.queryProductDetails({productId});
    if (r.productDetails.isEmpty) return null;
    return r.productDetails.first;
  }

  Future<void> buy(ProductDetails p) async {
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
  }

  Future<void> restore() => _iap.restorePurchases();

  void listen(void Function(PurchaseDetails) onUpdate) {
    _sub = _iap.purchaseStream.listen((list) {
      for (final p in list) onUpdate(p);
    });
  }

  Future<void> complete(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) await _iap.completePurchase(p);
  }

  void dispose() => _sub?.cancel();
}
```

- [ ] **Step 2: AdsProvider**

```dart
// lib/features/parent/monetization/ads_provider.dart
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../settings/data/settings_repository.dart';
import 'iap_service.dart';

class AdsProvider extends ChangeNotifier {
  final SettingsRepository _settings;
  final IapService _iap = IapService();

  AdsProvider(this._settings);

  bool get removed => _settings.current.adsRemoved;

  Future<void> init() async {
    notifyListeners();
    _iap.listen((p) async {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == IapService.productId) {
          await _settings.setAdsRemoved(true);
          notifyListeners();
        }
      }
      await _iap.complete(p);
    });
  }

  Future<void> purchaseRemoveAds(BuildContext context) async {
    if (!await _iap.isAvailable()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제를 사용할 수 없어요')),
      );
      return;
    }
    final product = await _iap.queryProduct();
    if (product == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 정보를 불러올 수 없어요')),
      );
      return;
    }
    await _iap.buy(product);
  }

  Future<void> restorePurchases() => _iap.restore();

  @override
  void dispose() {
    _iap.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 3: AdBanner**

```dart
// lib/features/parent/monetization/ad_banner.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'ads_provider.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  // 테스트 단위 ID (출시 직전 실제 ID로)
  static const String _testUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: _testUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();
    if (ads.removed || !_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
```

- [ ] **Step 4: 실행 검증**

```bash
flutter run
```

부모 모드 → 약 목록 / 이력 / 설정 화면 하단에 테스트 광고 배너 표시. 메인/복용 체크/등록 폼/온보딩/모드 선택/자녀 모드 전체에는 안 보임.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/parent/monetization/
git commit -m "feat(parent/monetization): AdBanner + AdsProvider + IapService"
```

### Task 12.3: 광고 배너 화면별 적용 + IAP 시연 검증

**Files:**
- Modify: 위 화면들에 `AdBanner` 추가됨 (이미 Phase 3, 5에서 import + body에 배치됨)

- [ ] **Step 1: AdBanner가 다음 화면에만 노출되는지 점검**

| 화면 | 배너 노출 |
|------|-----------|
| 0. 모드 선택 | ❌ |
| 1. 온보딩 | ❌ |
| 2. 메인 (오늘의 약) | ❌ |
| 3. 복용 체크 | ❌ |
| 4. 약 목록 | ✅ |
| 5. 약 등록 폼 | ❌ |
| 6. 슬롯 관리 | ❌ |
| 7. 이력 캘린더 | ✅ |
| 8. 설정 | ✅ |
| 8b. 자녀와 연결 | ❌ |
| 9~12. 자녀 모드 전체 | ❌ |

`MedicationListScreen`, `HistoryCalendarScreen`, `SettingsScreen` 본문에 `AdBanner` 위젯 호출이 있는지 grep:

```bash
grep -nR "AdBanner()" lib/features/parent/
```

> `MedicationListScreen`과 `HistoryCalendarScreen`은 Phase 3/5에서 이미 추가됨. `SettingsScreen`은 추가 필요할 수 있음 — body의 `ListView` 끝에 `const AdBanner()` 한 줄 끼워넣기.

- [ ] **Step 2: IAP 시연은 AAB 업로드 후 (Phase 13.7)**

> 디버그 빌드는 IAP 결제 흐름 시연 불가. `flutter build appbundle` → 내부 테스트 트랙 업로드 → 옵트인 → 실기기 Play Store 설치 → 결제 검증.

- [ ] **Step 3: 커밋**

```bash
git add -A
git commit -m "chore(monetization): 화면별 AdBanner 노출 정책 점검" --allow-empty
```

---

## Phase 13: 출시 — Play 내부 테스트 트랙

### Task 13.1: 앱 아이콘

**Files:**
- Create: `assets/icon/icon.png` (1024×1024)
- Modify: `pubspec.yaml`

- [ ] **Step 1: 아이콘 PNG 준비**

1024×1024 PNG. 디자인은 베이지 + 주황 약봉투 미감. 무료 도구: https://favicon.io/favicon-generator/ 또는 Figma.

- [ ] **Step 2: `flutter_launcher_icons` 추가**

`pubspec.yaml` `dev_dependencies`에:

```yaml
  flutter_launcher_icons: ^0.13.1
```

`pubspec.yaml` 끝에:

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/icon.png"
  background_color: "#ECE8E1"
  theme_color: "#B86F40"
  adaptive_icon_background: "#ECE8E1"
  adaptive_icon_foreground: "assets/icon/icon.png"
```

- [ ] **Step 3: 아이콘 생성**

```bash
flutter pub get
dart run flutter_launcher_icons
```

Expected: `android/app/src/main/res/mipmap-*` 안에 아이콘 생성.

- [ ] **Step 4: 커밋**

```bash
git add pubspec.yaml assets/icon/ android/app/src/main/res/
git commit -m "chore(icon): 앱 런처 아이콘 생성"
```

### Task 13.2: 앱 이름 + 패키지 ID

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: android:label 변경**

`<application>` 태그의 `android:label`을 `"KYH 약 알림"`으로.

- [ ] **Step 2: applicationId 확인**

`android/app/build.gradle`에 `applicationId "com.kyh.medi"` (이미 `flutter create --org com.kyh.medi`로 설정됨).

- [ ] **Step 3: 커밋**

```bash
git add android/
git commit -m "chore(android): 앱 이름 'KYH 약 알림'"
```

### Task 13.3: 키스토어 + 서명 설정

**Files:**
- Create: `~/upload-keystore.jks` (절대 git X)
- Create: `android/key.properties` (절대 git X)
- Modify: `android/app/build.gradle`
- Modify: `.gitignore`

- [ ] **Step 1: 키스토어 생성**

```bash
keytool -genkey -v -keystore "$HOME/upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- 비밀번호 강하게 + 메모
- 이름/조직/도시 입력
- 알리아스 비밀번호 (키스토어와 동일 추천)

> **이 파일을 잃어버리면 앱 업데이트 영원히 못 함**. 별도 백업 필수 (USB / 클라우드 암호화).

- [ ] **Step 2: SHA-1 추출 → Firebase 콘솔 등록**

```bash
keytool -list -v -keystore "$HOME/upload-keystore.jks" -alias upload | grep SHA1
```

→ Firebase 콘솔 → 프로젝트 설정 → "내 앱" → Android 앱 → "지문 추가" → SHA-1 붙여넣기. (Google OAuth 제대로 작동하려면 필수)

→ 새 `google-services.json` 다운로드 → `android/app/`에 덮어쓰기.

- [ ] **Step 3: key.properties (gitignore)**

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\y00h\\upload-keystore.jks
```

- [ ] **Step 4: .gitignore 추가**

```
# Keystore
android/key.properties
android/app/upload-keystore.jks
**/key.properties
*.jks
```

- [ ] **Step 5: build.gradle 서명 설정**

`android/app/build.gradle`의 `android { ... }` 위에:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

`android { ... }` 안 `buildTypes` 위에:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

`buildTypes.release` 수정:

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

- [ ] **Step 6: 커밋 (.gitignore + build.gradle만, 키스토어/.properties는 X)**

```bash
git add .gitignore android/app/build.gradle android/app/google-services.json
git commit -m "chore(android): 릴리즈 서명 + SHA-1 Firebase 등록"
```

### Task 13.4: AAB 빌드

- [ ] **Step 1: 빌드**

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... 
```

> Supabase URL/anon key를 `defaultValue`에 박아놓은 경우 `--dart-define` 생략 가능.

Expected: `build/app/outputs/bundle/release/app-release.aab` 생성.

- [ ] **Step 2: 실기기 release 검증**

```bash
flutter install --release
```

체크: 모드 선택 → 부모 → 온보딩 → 약 등록 → 슬롯 → 알림 발사 → 복용 체크 → 캘린더 → 설정 → 자녀 연결 → 코드 발급. 자녀 모드도 별도 폰 (또는 같은 폰 데이터 초기화 후) 검증.

### Task 13.5: 개인정보처리방침 (GitHub Pages)

**Files:**
- Create: `docs/legal/privacy.md`

- [ ] **Step 1: 텍스트 작성**

```markdown
# KYH 약 알림 개인정보처리방침

최종 갱신: 2026-05-XX (출시일로 갱신)

## 1. 수집하는 개인정보

부모 모드는 어떠한 개인정보도 수집하지 않습니다 — 자녀와 연결 기능을 사용하지 않는 경우. 모든 데이터(약 정보, 복용 이력, 사진)는 부모님의 기기 안에만 저장됩니다.

자녀와 연결 기능을 사용하는 경우, 다음 데이터가 Supabase 클라우드에 저장됩니다:
- 약 이름, 복용/미복용 이벤트
- 자녀 측: 이메일 주소, Google 표시 이름, FCM 푸시 토큰
- **약 사진과 메모는 절대 클라우드로 전송되지 않으며 부모님 기기에만 보관됩니다.**

## 2. 권한 사용 목적

- **알림**: 약 복용 시각에 알림 (부모 모드)
- **카메라/사진**: 약 사진 등록 (선택, 부모 모드)
- **부팅 시 실행**: 재부팅 후 알림 재등록 (부모 모드)
- **인터넷**: 자녀와 연결 시 Supabase + Firebase 통신

## 3. 광고

부모 모드에 한해 Google AdMob 배너 광고를 표시합니다. 자녀 모드는 광고가 없습니다. 사용자는 인앱 결제(₩2,900)로 광고를 영구 제거할 수 있습니다.

광고 SDK에는 약 이름, 복용 이력, 사진 등 어떠한 의료 정보도 전달되지 않습니다.

## 4. 결제

광고 제거 상품은 Google Play 결제 시스템을 통해 처리됩니다.

## 5. 데이터 삭제 / 연결 해제

- 부모/자녀 모두 설정 화면에서 페어링을 해제하면 양쪽 데이터 연결이 끊어집니다.
- 자녀 계정 삭제 요청은 아래 이메일로 연락 부탁드립니다.

## 6. 문의

y0000h2@gmail.com
```

- [ ] **Step 2: GitHub 레포 + Pages**

GitHub에서 `kyh-medi-privacy` 빈 레포 생성 → 위 파일 푸시 → Settings → Pages → Source `Deploy from a branch` → main / docs → URL 받기.

또는 GitHub Gist에 마크다운 올리고 Gist URL 사용.

- [ ] **Step 3: 커밋 (이 프로젝트 레포에는 docs/legal/만)**

```bash
git add docs/legal/
git commit -m "docs(legal): 개인정보처리방침 v1.0"
```

### Task 13.6: Play Console 등록

(이전 단계: 개발자 계정 신원확인 완료 가정)

- [ ] **Step 1: 앱 만들기**

https://play.google.com/console → "앱 만들기":
- 앱 이름: `KYH 약 알림`
- 기본 언어: 한국어
- 앱: 앱
- 무료/유료: 무료
- 약관 동의

- [ ] **Step 2: 메인 스토어 등록정보**

- 짧은 설명 (80자): `한 알도, 잊지 않게. 어르신 약 알림 + 자녀가 안심하는 모니터링.`
- 자세한 설명 (4000자): 시니어 친화 디자인 + 자녀 모니터링 + 광고 제거 강조
- 그래픽 자산:
  - 아이콘 512×512
  - 피처 그래픽 1024×500
  - 폰 스크린샷 2~8장 (모드 선택 / 메인 / 복용 체크 / 자녀와 연결 / 자녀 홈)

- [ ] **Step 3: 콘텐츠 등급**

설문 진행 → "약 정보 (사용자 입력)" 정직 응답 → 보통 "전체 이용가".

- [ ] **Step 4: 데이터 안전 섹션**

자녀 페어링 시 클라우드 저장이 발생하므로 **거짓말하지 말고**:
- 데이터 수집: ✅ (이메일, 약 이름, 복용 이벤트, FCM 토큰)
- 공유: ❌
- 암호화: ✅ (Supabase RLS + HTTPS)
- 사용자 데이터 삭제 요청 가능: ✅ (이메일로 처리)

- [ ] **Step 5: 개인정보처리방침 URL 입력**

Task 13.5의 GitHub Pages URL.

- [ ] **Step 6: 광고 포함 여부**

"이 앱에 광고가 포함되어 있습니다" 체크.

### Task 13.7: 내부 테스트 업로드 + IAP 등록

- [ ] **Step 1: 내부 테스트 새 버전**

Play Console → 테스트 → 내부 테스트 → "새 버전 만들기":
- AAB 업로드 (`build/app/outputs/bundle/release/app-release.aab`)
- 출시 노트:

```
v1.0.0 — 첫 출시
- 어르신 약 알림 (부모 모드)
- 자녀 원격 모니터링 (페어링 + 미복용 푸시)
- 약 등록 (텍스트 + 사진, 부모 로컬만)
- 시간 슬롯별 복용 알림 (정시 + 10분 + 20분)
- 복용 이력 캘린더
- 광고 제거 인앱 결제 (₩2,900)
```

- [ ] **Step 2: 테스터 추가**

내부 테스트 → "테스터" → 이메일 목록 → 본인 + 가족 이메일 → 저장.

- [ ] **Step 3: 검토 + 출시**

상단 "검토 시작" → "변경사항 저장하고 출시".

- [ ] **Step 4: 옵트인 URL로 설치**

내부 테스트 페이지 → "옵트인 URL" → 본인 폰 브라우저 → "테스터가 되기" → "Play Store에서 다운로드".

- [ ] **Step 5: IAP 상품 등록 (배포 후)**

Play Console → 수익 창출 → 상품 → 인앱 상품 → "상품 만들기":
- 상품 ID: `kyh_remove_ads_lifetime`
- 이름: 광고 제거 (영구)
- 설명: 광고를 영구히 제거합니다.
- 가격: ₩2,900

- [ ] **Step 6: 최종 E2E 검증 (스펙 §9)**

부모 모드 13개 + 자녀 모니터링 10개 항목 모두 실기기로 통과 확인. 통과 못한 항목은 v1.0.1 패치 백로그로.

```bash
git tag v1.0.0
```

---

## Self-Review (이 v2.0 계획서)

### 1. 스펙 커버리지 (스펙 v2.0 §1~§13)

| 스펙 섹션 | 매핑 Task |
|---|---|
| §1 핵심 결정 9개 | A → Phase 13 / C → 1.4, 4.1 / Hive+Supabase → 1.4~1.8, 7.x / B 알림 3회 → 2.1, 4.4 / Provider → 4.1, etc / B 텍스트+사진 → 3.2 / A 배너+IAP → 12.x / 부모/자녀 모드 → 6.x / N:M 페어링 → 8.x, 9.x ✓ |
| §2 아키텍처 (부모 offline + 자녀 online) | Phase 1~6 (부모 풀 로컬), Phase 7~10 (Supabase / 자녀) ✓ |
| §3.1 Hive 박스 5개 | Task 1.4 ✓ |
| §3.2 Supabase 6테이블 + RLS + RPC | Task 0.7 ✓ |
| §3.5 단방향 동기화 | Task 7.1, 7.2, 7.3 (`onMissed`/`onTaken` 콜백) ✓ |
| §4 알림 엔진 + missed 자동화 | Task 2.1, 2.3, 4.1 (`markStaleAsMissed`), 4.4 ✓ |
| §4.7 Edge Function FCM | Task 11.2 ✓ |
| §5 화면 14개 (분기 1 + 부모 9 + 자녀 4) | 모드선택 → 6.1 / 부모 9개 → 3.x, 4.x, 5.x, 8.2 / 자녀 4개 → 9.1, 9.2, 9.3, 10.1 ✓ |
| §6 디자인 시스템 (시니어 + 자녀) | Task 1.1 (토큰), 1.2 (테마 분리), 3.1 (위젯) ✓ |
| §7 광고/IAP (부모만) | Phase 12 + 12.3의 노출 표 ✓ |
| §8 프로젝트 구조 | "파일 구조 (전체 맵, v2.0)" 섹션 + 각 Task의 경로 ✓ |
| §9 테스트 전략 | TDD: 1.3, 1.5, 1.6, 1.7, 2.1. 수동 E2E: Task 13.7 ✓ |
| §10 R1~R14 | R1: 2.2, 2.3 / R2: 1.3 / R3: 12.x 노출 정책 / R4: 13.7 / R5: 13.7 1차 목표 / R6: 2.2 / R7: 사전준비 / R8: 12.x 테스트 ID / R9: 모니터링은 콘솔에서 / R10: 0.8 + 11.2 / R11: 13.5 정책 / R12: 9.1 이메일 폴백 / R13: 11.2 콜드 스타트 허용 / R14: RLS 마이그레이션 0.7 ✓ |
| §11 일정 (소프트 데드라인) | Phase 0~13 순차 ✓ |

### 2. Placeholder 스캔

- "TBD/TODO/fill in details" 검색 → 없음 (placeholder 없이 모든 코드 풀로) ✓
- "비슷하게" / "같은 패턴" 만으로 끝나는 step 없음 ✓
- 각 코드 step에 실제 dart/sql/typescript/yaml 코드 포함 ✓

### 3. 타입 / 시그니처 일관성

- `Medication.id` String (UUID 문자열) — Hive 키, 모든 Repository/Provider/UI에서 일관 ✓
- `TimeSlot.id` String — 동일 ✓
- `DoseEvent.status` String 상수 (`statusPending`/`statusTaken`/`statusMissed`) — IntakeProvider, HomeScreen 모두 사용 ✓
- `NotificationIdEncoder.hashSlotId(String) → int` — Phase 2.1 정의, Phase 3.4 (SlotsProvider), Phase 4.3 (IntakeCheckScreen) 모두 사용 ✓
- `SettingsRepository` 메서드 (setUserMode/setOnboardingDone/setAdsRemoved/setPairedSupabaseUserId) — Phase 1.8 정의, Phase 5.2/5.3/6.1/7.1/12.2 모두 사용 ✓
- `ParentSyncService.upsertMedication / markMedicationDeleted / insertDoseEvent` — Phase 7.2 정의, Phase 7.3 (Provider 콜백)에서 사용 ✓
- `child_users.fcm_token` — Phase 0.7 스키마, Phase 11.1 upsert, Phase 11.2 Edge Function 모두 같은 컬럼 ✓
- `app.dart`의 `_parentApp` Provider 묶음에서 `IntakeProvider`를 `..onMissed = ...` 로 callback 주입할 때 `ParentSyncService`도 같이 주입 — Phase 7.3 ✓

### 4. 알아챈 누락 / 한계 (수용 가능)

- **자녀 알림 탭 → 앱 자동 라우팅 (FCM payload → 부모 상세 화면)**: Phase 11.3은 시스템 알림만 표시. 탭하면 앱 그냥 열리고 사용자가 손으로 부모 카드 탭. 보강은 v1.0.1.
- **부모 알림 탭 dayOffset 항상 0 가정**: Phase 4.4. 메인 화면이 오늘만 표시 → 탭 = 오늘. 미래 날짜 알림 탭 시나리오는 v1.0에서 발생 안 함. OK.
- **Google OAuth Android 콜백 deeplink는 시연 시 추가 디버깅 필요할 수 있음**: 안 되면 이메일 로그인이 풀 폴백. 9.1에 명시.
- **Supabase Anonymous Auth는 페어링 1번 후 그대로 유지**: 단말 초기화 시 부모 user_id 분실. v1.0.1에서 백업/복구.

문제 없음. 진행 가능.

---

## 실행 핸드오프

**계획서 완성. 저장 위치**: `C:\Users\y00h\IdeaProjects\kyh_medi\docs\superpowers\plans\2026-04-30-medication-reminder-plan.md` (v2.0)

**메모리에 사용자가 이미 결정한 실행 방식**: **1. Subagent-Driven**

→ 매 Task마다 신선한 서브에이전트를 보내고, 사용자가 Task 사이에 검토 체크포인트를 가짐.
→ **REQUIRED SUB-SKILL**: `superpowers:subagent-driven-development`

> 사용자는 서브에이전트를 처음 사용하므로, 첫 Task(Task 0.5)부터 "지금 Subagent를 띄웁니다 — 이 Task만 풀어서 결과를 갖고 옵니다" 식으로 매번 안내.

### 시작 순서

1. **Task 0.5 → 0.6 → 0.7 → 0.8 → 0.9 → 0.10 → 0.11**: 환경 + 셋업 (대부분 사람 손 작업: Supabase 콘솔, Firebase 콘솔). 서브에이전트는 코드 작성 부분만.
2. **Phase 1 (Task 1.1~1.8)**: 데이터 레이어. TDD 적용. Subagent에게 "Task 1.5만 풀어줘" 식으로 지시.
3. **Phase 2~6**: 부모 모드 풀스택 완성. 여기서 한 번 큰 마일스톤 — 사용자 폰에 부모 모드 동작 확인.
4. **Phase 7~10**: Supabase + 자녀 모드. 두 폰 (또는 두 계정) 필요.
5. **Phase 11**: FCM. Edge Function 배포 + 시연이 가장 까다로움.
6. **Phase 12 → 13**: 출시.

### 콘솔 작업 (사용자만 가능, 서브에이전트가 못 함)

다음 단계는 사용자가 직접 클릭/타이핑:

- Supabase 콘솔: 프로젝트 생성, OAuth 활성화, Webhook 등록 (Task 0.7, 11.2 Step 5)
- Firebase 콘솔: 프로젝트 생성, SHA-1 등록, FCM Server Key (Task 0.8, 13.3)
- Google Cloud Console: OAuth Client (Task 9.1)
- Play Console: 앱 만들기, 스토어 정보, 콘텐츠 등급, AAB 업로드 (Task 13.6, 13.7)
- AdMob 콘솔: 앱 등록, 광고 단위 ID (출시 직전)
- 키스토어 생성 + 비밀번호 (Task 13.3)
- 앱 아이콘 PNG 디자인 (Task 13.1)
- 스크린샷 캡처 (Task 13.6)

**다음 액션**: Task 0.5(프로젝트 스캐폴드)부터 시작할까요?


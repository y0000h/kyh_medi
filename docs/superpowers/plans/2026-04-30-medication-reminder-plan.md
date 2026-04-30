# 약 알림 앱 (KYH) 구현 계획서

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter로 어르신용 약 알림 앱을 개발하여 2026-05-03까지 Google Play 내부 테스트 트랙에 업로드한다.

**Architecture:** 3-layer (Presentation/Domain/Data) feature-first 구조. SQLite 로컬 영속성, `flutter_local_notifications`로 알림, Provider로 상태관리, AdMob 배너 + IAP 광고 제거 ₩2,900.

**Tech Stack:** Flutter 3.x, Dart 3.x, sqflite, provider, flutter_local_notifications, image_picker, google_mobile_ads, in_app_purchase, table_calendar, timezone, permission_handler.

---

## 0. 가이드 & 사전 준비

### 0.1 본 계획서 사용법
- **Phase 단위로 검토 → 실행 → 다음 Phase**. Phase 7개 + 각 Phase에 5~9개 Task.
- 각 Task의 step은 2~5분 단위. 막히면 그 Task를 격리해서 디버깅.
- TDD가 적용되는 Task는 데이터 레이어와 시간 계산 로직. UI는 수동 검증으로 대체 (스펙 §9 결정).

### 0.2 자바 개발자 빠른 매핑
| Java | Flutter/Dart |
|---|---|
| `String s = "x";` | `String s = "x";` (동일) |
| `final` | `final` (동일) |
| `List<String>` | `List<String>` (동일) |
| `Map<String, Object>` | `Map<String, dynamic>` |
| `null` 안전 | `String?` (`?` 붙이면 nullable, 안 붙이면 NotNull) |
| `Optional<X>` | `X?` 자체 + `?.`/`??` 연산자 |
| `CompletableFuture<X>` | `Future<X>` + `async/await` |
| `Stream<X>` | `Stream<X>` (RxJava 비슷) |
| Spring `@Component` | `ChangeNotifier` 클래스 + Provider로 주입 |
| Spring `@Repository` | 그냥 클래스 (DI 컨테이너 없이 생성자 주입) |
| `pom.xml` | `pubspec.yaml` |
| Maven `mvn` | `flutter pub` / `dart` |

### 0.3 사전 준비 (오늘 안에 시작)
- [ ] **Google Play 개발자 계정 등록** — https://play.google.com/console/signup ($25, 신원확인 1~2일 걸림)
- [ ] AdMob 계정은 Phase 6에서 생성 (당장 X)

---

## 파일 구조 (전체 맵)

```
kyh_medi/
├── android/                                # 자동 생성 (수정 일부)
│   └── app/
│       ├── build.gradle                    # AdMob app ID, signing config
│       └── src/main/AndroidManifest.xml    # 권한 + AdMob 메타
├── ios/                                    # 안 씀 (v2)
├── lib/
│   ├── main.dart                           # 진입점 + 초기화
│   ├── app.dart                            # MaterialApp + Theme
│   ├── core/
│   │   ├── theme/
│   │   │   ├── tokens.dart                 # 색·크기 토큰
│   │   │   └── app_theme.dart              # ThemeData
│   │   ├── database/
│   │   │   └── database_helper.dart        # sqflite 초기화 + 5개 테이블
│   │   ├── notification/
│   │   │   ├── notification_service.dart   # 권한 + 초기화 + show/cancel
│   │   │   └── notification_scheduler.dart # 슬롯 → 알림 ID 변환, 7일 예약
│   │   └── time/
│   │       └── timezone_init.dart          # Asia/Seoul 강제 설정
│   ├── features/
│   │   ├── medication/
│   │   │   ├── domain/medication.dart      # 모델
│   │   │   ├── data/medication_repository.dart
│   │   │   └── ui/
│   │   │       ├── medication_list_screen.dart
│   │   │       ├── medication_form_screen.dart
│   │   │       └── medications_provider.dart
│   │   ├── slot/
│   │   │   ├── domain/{time_slot.dart, slot_medication.dart}
│   │   │   ├── data/slot_repository.dart
│   │   │   └── ui/
│   │   │       ├── slot_list_screen.dart
│   │   │       ├── slot_form_screen.dart
│   │   │       └── slots_provider.dart
│   │   ├── intake/
│   │   │   ├── domain/intake_log.dart
│   │   │   ├── data/intake_repository.dart
│   │   │   └── ui/
│   │   │       ├── home_screen.dart            # 메인 (오늘의 약)
│   │   │       ├── intake_check_screen.dart    # 복용 체크
│   │   │       ├── history_calendar_screen.dart
│   │   │       └── intake_provider.dart
│   │   ├── onboarding/
│   │   │   ├── onboarding_screen.dart
│   │   │   └── onboarding_provider.dart
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   └── settings_repository.dart
│   │   └── monetization/
│   │       ├── ads_provider.dart           # 광고 제거 상태 관리
│   │       ├── ad_banner.dart              # 배너 위젯
│   │       └── iap_service.dart            # 광고 제거 결제
│   └── shared/
│       ├── widgets/
│       │   ├── senior_button.dart
│       │   └── senior_input.dart
│       └── utils/
│           └── date_utils.dart
├── test/
│   ├── core/
│   │   ├── notification_scheduler_test.dart
│   │   └── timezone_init_test.dart
│   └── features/
│       ├── medication/medication_repository_test.dart
│       ├── slot/slot_repository_test.dart
│       └── intake/intake_repository_test.dart
└── pubspec.yaml
```

---

## Phase 0: 환경 셋업 + 프로젝트 골조

### Task 0.1: Flutter SDK 설치 (Windows)

**Files:** N/A (시스템 설치)

- [ ] **Step 1: Flutter SDK ZIP 다운로드**

브라우저에서 https://docs.flutter.dev/get-started/install/windows/mobile 접속 → "Download Flutter SDK" → 최신 stable ZIP 다운로드 (예: `flutter_windows_3.x.x-stable.zip`).

- [ ] **Step 2: 압축 해제 (한글/공백 없는 경로 필수)**

`C:\src\flutter\` 위치에 압축 해제. `C:\Program Files\` 또는 `C:\Users\이름(한글)\` 같은 경로 절대 X.

- [ ] **Step 3: 환경변수 PATH 추가**

Windows 검색 → "환경 변수" → 사용자 변수 `Path` 편집 → `C:\src\flutter\bin` 추가. 새 터미널 열기.

- [ ] **Step 4: 설치 확인**

```bash
flutter --version
```
Expected: `Flutter 3.x.x • channel stable ...` 출력.

### Task 0.2: Android Studio + 안드로이드 SDK

**Files:** N/A

- [ ] **Step 1: Android Studio 설치**

https://developer.android.com/studio → "Download" → 설치. 처음 실행 시 "Standard" 옵션으로 SDK 자동 다운로드.

- [ ] **Step 2: Android SDK Command-line Tools 설치**

Android Studio → `More Actions` → `SDK Manager` → `SDK Tools` 탭 → `Android SDK Command-line Tools (latest)` 체크 → Apply.

- [ ] **Step 3: Flutter 플러그인 설치 (선택, 권장)**

Android Studio → `Settings` → `Plugins` → "Flutter" 검색 → Install (Dart 플러그인 같이 설치됨). IDE 재시작.

- [ ] **Step 4: 라이선스 수락**

```bash
flutter doctor --android-licenses
```
모든 항목에 `y` 입력.

### Task 0.3: 실기기 USB 디버깅 또는 에뮬레이터

**Files:** N/A

- [ ] **Step 1A: 실기기 사용 시 — 개발자 모드 활성화**

폰 `설정` → `휴대전화 정보` → `소프트웨어 정보` → `빌드 번호` **7번 탭** → 비밀번호 입력 → `개발자 옵션`에서 `USB 디버깅` ON. PC에 USB 연결.

- [ ] **Step 1B: 에뮬레이터 사용 시 — AVD 생성**

Android Studio → `More Actions` → `Virtual Device Manager` → `Create Device` → Pixel 7 선택 → System Image (UpsideDownCake/Tiramisu = API 33+ 권장) → Finish → 실행.

- [ ] **Step 2: 기기 인식 확인**

```bash
flutter devices
```
Expected: 실기기 또는 에뮬레이터 1개 이상 표시.

### Task 0.4: flutter doctor 통과

**Files:** N/A

- [ ] **Step 1: 진단 실행**

```bash
flutter doctor -v
```

- [ ] **Step 2: 모든 항목 ✓로 만들기**

빨간 X 또는 노란 ! 항목을 출력 메시지대로 해결. 흔한 막힘:
- `Android toolchain` 노란 경고: `flutter doctor --android-licenses` 다시 실행
- `cmdline-tools` 누락: SDK Manager에서 `Android SDK Command-line Tools` 설치
- `Android Studio not installed`: PATH에 안 잡혀 있으면 `flutter config --android-studio-dir "C:\Program Files\Android\Android Studio"`

Expected: `[✓]` Flutter, `[✓]` Android toolchain, `[✓]` Connected device 최소 3개는 통과.

### Task 0.5: 프로젝트 생성

**Files:**
- Create: `C:\Users\y00h\IdeaProjects\kyh_medi\` (이미 존재)

- [ ] **Step 1: Flutter 프로젝트 스캐폴드**

```bash
cd /c/Users/y00h/IdeaProjects/kyh_medi
flutter create --project-name kyh_medi --org com.kyh.medi --platforms android .
```

이미 `docs/`, `.git/`이 있어서 빈 폴더 아님 → Flutter가 충돌 경고할 수 있음. 충돌 시:
```bash
flutter create --project-name kyh_medi --org com.kyh.medi --platforms android --overwrite .
```
(주의: `--overwrite`는 위험. `docs/`는 안 건드림이 확인됨, 그래도 git 상태 확인 후 진행)

- [ ] **Step 2: 첫 실행 — 기본 카운터 앱**

```bash
flutter run
```
Expected: 실기기/에뮬레이터에 카운터 앱 뜸.

- [ ] **Step 3: 종료 후 git 커밋**

```bash
git add -A
git commit -m "chore: Flutter 프로젝트 스캐폴드"
```

### Task 0.6: pubspec.yaml 의존성 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml 의존성 블록 교체**

```yaml
name: kyh_medi
description: "한 알도, 잊지 않게. 어르신용 약 알림 앱."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.3.3
  path_provider: ^2.1.4
  path: ^1.9.0
  provider: ^6.1.2
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  permission_handler: ^11.3.1
  image_picker: ^1.1.2
  table_calendar: ^3.1.2
  intl: ^0.19.0
  google_mobile_ads: ^5.1.0
  in_app_purchase: ^3.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  sqflite_common_ffi: ^2.3.3   # 호스트 머신에서 단위 테스트용

flutter:
  uses-material-design: true
  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/PretendardVariable.ttf
```

- [ ] **Step 2: 폰트 다운로드 + 배치**

`assets/fonts/` 폴더 생성. https://github.com/orioncactus/pretendard/releases 에서 `Pretendard-1.3.x.zip` → `PretendardVariable.ttf` 추출 → `assets/fonts/`에 저장.

- [ ] **Step 3: pub get 실행**

```bash
flutter pub get
```
Expected: `Got dependencies!` 출력. 에러 시 버전 충돌 → 메시지 따라 해결.

- [ ] **Step 4: 커밋**

```bash
git add pubspec.yaml pubspec.lock assets/
git commit -m "chore: 핵심 의존성 + Pretendard 폰트 추가"
```

---

## Phase 1: 데이터 레이어 (TDD)

### Task 1.1: 디자인 토큰

**Files:**
- Create: `lib/core/theme/tokens.dart`

- [ ] **Step 1: 토큰 작성**

```dart
import 'package:flutter/material.dart';

class AppColors {
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
}

class AppSizes {
  static const double bodyFontSize = 18.0;
  static const double buttonFontSize = 22.0;
  static const double titleFontSize = 28.0;
  static const double minButtonHeight = 56.0;
  static const double largeButtonHeight = 80.0;
  static const double padding = 20.0;
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/core/theme/tokens.dart
git commit -m "feat(theme): 디자인 토큰 추가"
```

### Task 1.2: 앱 테마

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: 테마 작성**

```dart
import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
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

- [ ] **Step 2: 커밋**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat(theme): 시니어 모드 라이트 테마"
```

### Task 1.3: 타임존 초기화 + 단위 테스트

**Files:**
- Create: `lib/core/time/timezone_init.dart`
- Test: `test/core/timezone_init_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

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

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/core/timezone_init_test.dart
```
Expected: FAIL — `initializeTimezone` undefined.

- [ ] **Step 3: 최소 구현**

```dart
// lib/core/time/timezone_init.dart
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzl;

void initializeTimezone() {
  tz.initializeTimeZones();
  tzl.setLocalLocation(tzl.getLocation('Asia/Seoul'));
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/core/timezone_init_test.dart
```
Expected: PASS.

- [ ] **Step 5: 커밋**

```bash
git add lib/core/time/timezone_init.dart test/core/timezone_init_test.dart
git commit -m "feat(core): timezone Asia/Seoul 강제 초기화"
```

### Task 1.4: 데이터베이스 헬퍼 (5개 테이블 생성)

**Files:**
- Create: `lib/core/database/database_helper.dart`

- [ ] **Step 1: 작성**

```dart
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'kyh_medi.db';
  static const _dbVersion = 1;
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo_path TEXT,
        memo TEXT,
        color_hex TEXT,
        created_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE time_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        days_of_week INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        deleted_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE slot_medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slot_id INTEGER NOT NULL REFERENCES time_slots(id),
        medication_id INTEGER NOT NULL REFERENCES medications(id),
        dose_count INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE intake_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slot_id INTEGER NOT NULL REFERENCES time_slots(id),
        medication_id INTEGER NOT NULL REFERENCES medications(id),
        scheduled_at INTEGER NOT NULL,
        taken_at INTEGER,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_intake_scheduled_at ON intake_logs(scheduled_at)');
    await db.execute('CREATE INDEX idx_intake_slot_status ON intake_logs(slot_id, status)');
    await db.execute('CREATE INDEX idx_slotmed_slot ON slot_medications(slot_id)');
  }

  /// 테스트 전용: 메모리 DB 생성기
  static Future<Database> memoryInstance() async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
    return db;
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/core/database/database_helper.dart
git commit -m "feat(db): SQLite 헬퍼 + 5개 테이블 + 인덱스"
```

### Task 1.5: Medication 모델 + Repository (TDD)

**Files:**
- Create: `lib/features/medication/domain/medication.dart`
- Create: `lib/features/medication/data/medication_repository.dart`
- Test: `test/features/medication/medication_repository_test.dart`

- [ ] **Step 1: 모델 작성**

```dart
// lib/features/medication/domain/medication.dart
class Medication {
  final int? id;
  final String name;
  final String? photoPath;
  final String? memo;
  final String? colorHex;
  final int createdAt;
  final int? deletedAt;

  const Medication({
    this.id,
    required this.name,
    this.photoPath,
    this.memo,
    this.colorHex,
    required this.createdAt,
    this.deletedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'photo_path': photoPath,
        'memo': memo,
        'color_hex': colorHex,
        'created_at': createdAt,
        'deleted_at': deletedAt,
      };

  factory Medication.fromMap(Map<String, Object?> m) => Medication(
        id: m['id'] as int?,
        name: m['name'] as String,
        photoPath: m['photo_path'] as String?,
        memo: m['memo'] as String?,
        colorHex: m['color_hex'] as String?,
        createdAt: m['created_at'] as int,
        deletedAt: m['deleted_at'] as int?,
      );
}
```

- [ ] **Step 2: 실패 테스트 작성**

```dart
// test/features/medication/medication_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kyh_medi/core/database/database_helper.dart';
import 'package:kyh_medi/features/medication/data/medication_repository.dart';
import 'package:kyh_medi/features/medication/domain/medication.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert and findActive returns the inserted medication', () async {
    final db = await DatabaseHelper.memoryInstance();
    final repo = MedicationRepository(db);
    final id = await repo.insert(Medication(
      name: '혈압약',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    expect(id, greaterThan(0));
    final all = await repo.findActive();
    expect(all, hasLength(1));
    expect(all.first.name, '혈압약');
  });

  test('softDelete excludes from findActive', () async {
    final db = await DatabaseHelper.memoryInstance();
    final repo = MedicationRepository(db);
    final id = await repo.insert(Medication(
      name: '비타민',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await repo.softDelete(id);
    final all = await repo.findActive();
    expect(all, isEmpty);
  });
}
```

- [ ] **Step 3: 테스트 실패 확인**

```bash
flutter test test/features/medication/medication_repository_test.dart
```
Expected: FAIL — repository undefined.

- [ ] **Step 4: 구현**

```dart
// lib/features/medication/data/medication_repository.dart
import 'package:sqflite/sqflite.dart';
import '../domain/medication.dart';

class MedicationRepository {
  final Database _db;
  MedicationRepository(this._db);

  Future<int> insert(Medication m) async => _db.insert('medications', m.toMap());

  Future<List<Medication>> findActive() async {
    final rows = await _db.query(
      'medications',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return rows.map(Medication.fromMap).toList();
  }

  Future<Medication?> findById(int id) async {
    final rows = await _db.query('medications', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Medication.fromMap(rows.first);
  }

  Future<int> softDelete(int id) async => _db.update(
        'medications',
        {'deleted_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<int> update(Medication m) async => _db.update(
        'medications',
        m.toMap(),
        where: 'id = ?',
        whereArgs: [m.id],
      );
}
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
flutter test test/features/medication/medication_repository_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 6: 커밋**

```bash
git add lib/features/medication/ test/features/medication/
git commit -m "feat(medication): 모델 + Repository + 테스트"
```

### Task 1.6: TimeSlot + SlotMedication Repository (TDD)

**Files:**
- Create: `lib/features/slot/domain/time_slot.dart`
- Create: `lib/features/slot/domain/slot_medication.dart`
- Create: `lib/features/slot/data/slot_repository.dart`
- Test: `test/features/slot/slot_repository_test.dart`

- [ ] **Step 1: 모델들 작성**

```dart
// lib/features/slot/domain/time_slot.dart
class TimeSlot {
  final int? id;
  final String label;
  final int hour;
  final int minute;
  final int daysOfWeek; // 비트마스크: 월=1, 화=2, 수=4, 목=8, 금=16, 토=32, 일=64
  final bool enabled;
  final int? deletedAt;

  const TimeSlot({
    this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.enabled = true,
    this.deletedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'hour': hour,
        'minute': minute,
        'days_of_week': daysOfWeek,
        'enabled': enabled ? 1 : 0,
        'deleted_at': deletedAt,
      };

  factory TimeSlot.fromMap(Map<String, Object?> m) => TimeSlot(
        id: m['id'] as int?,
        label: m['label'] as String,
        hour: m['hour'] as int,
        minute: m['minute'] as int,
        daysOfWeek: m['days_of_week'] as int,
        enabled: (m['enabled'] as int) == 1,
        deletedAt: m['deleted_at'] as int?,
      );

  /// 비트마스크 매일 = 127 (월~일 모두)
  static const int everyday = 127;
}
```

```dart
// lib/features/slot/domain/slot_medication.dart
class SlotMedication {
  final int? id;
  final int slotId;
  final int medicationId;
  final int doseCount;

  const SlotMedication({
    this.id,
    required this.slotId,
    required this.medicationId,
    this.doseCount = 1,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'slot_id': slotId,
        'medication_id': medicationId,
        'dose_count': doseCount,
      };

  factory SlotMedication.fromMap(Map<String, Object?> m) => SlotMedication(
        id: m['id'] as int?,
        slotId: m['slot_id'] as int,
        medicationId: m['medication_id'] as int,
        doseCount: m['dose_count'] as int,
      );
}
```

- [ ] **Step 2: 실패 테스트**

```dart
// test/features/slot/slot_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kyh_medi/core/database/database_helper.dart';
import 'package:kyh_medi/features/slot/data/slot_repository.dart';
import 'package:kyh_medi/features/slot/domain/time_slot.dart';
import 'package:kyh_medi/features/slot/domain/slot_medication.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert slot returns id and findActive lists it', () async {
    final db = await DatabaseHelper.memoryInstance();
    final repo = SlotRepository(db);
    final id = await repo.insertSlot(const TimeSlot(
      label: '아침',
      hour: 8,
      minute: 0,
      daysOfWeek: TimeSlot.everyday,
    ));
    expect(id, greaterThan(0));
    final slots = await repo.findActiveSlots();
    expect(slots.first.label, '아침');
  });

  test('attach medication to slot', () async {
    final db = await DatabaseHelper.memoryInstance();
    final repo = SlotRepository(db);
    final slotId = await repo.insertSlot(const TimeSlot(
      label: '아침', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday,
    ));
    await db.insert('medications', {
      'name': '혈압약', 'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await repo.attachMedication(SlotMedication(slotId: slotId, medicationId: 1));
    final meds = await repo.findMedicationsForSlot(slotId);
    expect(meds, hasLength(1));
  });
}
```

- [ ] **Step 3: 실패 확인**

```bash
flutter test test/features/slot/slot_repository_test.dart
```
Expected: FAIL.

- [ ] **Step 4: 구현**

```dart
// lib/features/slot/data/slot_repository.dart
import 'package:sqflite/sqflite.dart';
import '../domain/time_slot.dart';
import '../domain/slot_medication.dart';

class SlotRepository {
  final Database _db;
  SlotRepository(this._db);

  Future<int> insertSlot(TimeSlot s) async => _db.insert('time_slots', s.toMap());

  Future<List<TimeSlot>> findActiveSlots() async {
    final rows = await _db.query(
      'time_slots',
      where: 'deleted_at IS NULL AND enabled = 1',
      orderBy: 'hour, minute',
    );
    return rows.map(TimeSlot.fromMap).toList();
  }

  Future<TimeSlot?> findSlotById(int id) async {
    final rows = await _db.query('time_slots', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TimeSlot.fromMap(rows.first);
  }

  Future<int> updateSlot(TimeSlot s) async =>
      _db.update('time_slots', s.toMap(), where: 'id = ?', whereArgs: [s.id]);

  Future<int> softDeleteSlot(int id) async => _db.update(
        'time_slots',
        {'deleted_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<int> attachMedication(SlotMedication sm) async =>
      _db.insert('slot_medications', sm.toMap());

  Future<int> detachMedication(int slotMedicationId) async =>
      _db.delete('slot_medications', where: 'id = ?', whereArgs: [slotMedicationId]);

  Future<List<SlotMedication>> findMedicationsForSlot(int slotId) async {
    final rows = await _db.query('slot_medications',
        where: 'slot_id = ?', whereArgs: [slotId]);
    return rows.map(SlotMedication.fromMap).toList();
  }
}
```

- [ ] **Step 5: 통과 확인 + 커밋**

```bash
flutter test test/features/slot/slot_repository_test.dart
git add lib/features/slot/ test/features/slot/
git commit -m "feat(slot): TimeSlot + SlotMedication + Repository + 테스트"
```

### Task 1.7: IntakeLog Repository (TDD)

**Files:**
- Create: `lib/features/intake/domain/intake_log.dart`
- Create: `lib/features/intake/data/intake_repository.dart`
- Test: `test/features/intake/intake_repository_test.dart`

- [ ] **Step 1: 모델 + 상태 enum**

```dart
// lib/features/intake/domain/intake_log.dart
enum IntakeStatus { pending, taken, missed, skipped }

class IntakeLog {
  final int? id;
  final int slotId;
  final int medicationId;
  final int scheduledAt;
  final int? takenAt;
  final IntakeStatus status;
  final int createdAt;

  const IntakeLog({
    this.id,
    required this.slotId,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'slot_id': slotId,
        'medication_id': medicationId,
        'scheduled_at': scheduledAt,
        'taken_at': takenAt,
        'status': status.name,
        'created_at': createdAt,
      };

  factory IntakeLog.fromMap(Map<String, Object?> m) => IntakeLog(
        id: m['id'] as int?,
        slotId: m['slot_id'] as int,
        medicationId: m['medication_id'] as int,
        scheduledAt: m['scheduled_at'] as int,
        takenAt: m['taken_at'] as int?,
        status: IntakeStatus.values.byName(m['status'] as String),
        createdAt: m['created_at'] as int,
      );
}
```

- [ ] **Step 2: 테스트 작성**

```dart
// test/features/intake/intake_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kyh_medi/core/database/database_helper.dart';
import 'package:kyh_medi/features/intake/data/intake_repository.dart';
import 'package:kyh_medi/features/intake/domain/intake_log.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upsertPending creates log if not exists', () async {
    final db = await DatabaseHelper.memoryInstance();
    final repo = IntakeRepository(db);
    final scheduled = DateTime(2026, 5, 1, 8, 0).millisecondsSinceEpoch;
    await repo.upsertPending(slotId: 1, medicationId: 1, scheduledAt: scheduled);
    final logs = await repo.findByDate(DateTime(2026, 5, 1));
    expect(logs, hasLength(1));
    expect(logs.first.status, IntakeStatus.pending);
  });

  test('markTaken updates status and takenAt', () async {
    final db = await DatabaseHelper.memoryInstance();
    final repo = IntakeRepository(db);
    final scheduled = DateTime(2026, 5, 1, 8, 0).millisecondsSinceEpoch;
    await repo.upsertPending(slotId: 1, medicationId: 1, scheduledAt: scheduled);
    await repo.markSlotTaken(slotId: 1, scheduledAt: scheduled, now: DateTime(2026, 5, 1, 8, 2));
    final logs = await repo.findByDate(DateTime(2026, 5, 1));
    expect(logs.first.status, IntakeStatus.taken);
    expect(logs.first.takenAt, isNotNull);
  });

  test('markStaleAsMissed flips pending older than 30 min to missed', () async {
    final db = await DatabaseHelper.memoryInstance();
    final repo = IntakeRepository(db);
    final scheduled = DateTime(2026, 5, 1, 8, 0).millisecondsSinceEpoch;
    await repo.upsertPending(slotId: 1, medicationId: 1, scheduledAt: scheduled);
    await repo.markStaleAsMissed(now: DateTime(2026, 5, 1, 8, 31));
    final logs = await repo.findByDate(DateTime(2026, 5, 1));
    expect(logs.first.status, IntakeStatus.missed);
  });
}
```

- [ ] **Step 3: 실패 확인**

```bash
flutter test test/features/intake/intake_repository_test.dart
```
Expected: FAIL.

- [ ] **Step 4: 구현**

```dart
// lib/features/intake/data/intake_repository.dart
import 'package:sqflite/sqflite.dart';
import '../domain/intake_log.dart';

class IntakeRepository {
  final Database _db;
  IntakeRepository(this._db);

  Future<int> upsertPending({
    required int slotId,
    required int medicationId,
    required int scheduledAt,
  }) async {
    final existing = await _db.query(
      'intake_logs',
      where: 'slot_id = ? AND medication_id = ? AND scheduled_at = ?',
      whereArgs: [slotId, medicationId, scheduledAt],
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return _db.insert('intake_logs', IntakeLog(
      slotId: slotId,
      medicationId: medicationId,
      scheduledAt: scheduledAt,
      status: IntakeStatus.pending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ).toMap());
  }

  Future<int> markSlotTaken({
    required int slotId,
    required int scheduledAt,
    required DateTime now,
  }) async {
    return _db.update(
      'intake_logs',
      {'status': IntakeStatus.taken.name, 'taken_at': now.millisecondsSinceEpoch},
      where: 'slot_id = ? AND scheduled_at = ? AND status = ?',
      whereArgs: [slotId, scheduledAt, IntakeStatus.pending.name],
    );
  }

  Future<int> markStaleAsMissed({required DateTime now}) async {
    final cutoff = now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch;
    return _db.update(
      'intake_logs',
      {'status': IntakeStatus.missed.name},
      where: 'status = ? AND scheduled_at <= ?',
      whereArgs: [IntakeStatus.pending.name, cutoff],
    );
  }

  Future<List<IntakeLog>> findByDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
    final rows = await _db.query(
      'intake_logs',
      where: 'scheduled_at BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'scheduled_at',
    );
    return rows.map(IntakeLog.fromMap).toList();
  }

  Future<List<IntakeLog>> findByMonth(DateTime monthAnchor) async {
    final start = DateTime(monthAnchor.year, monthAnchor.month, 1).millisecondsSinceEpoch;
    final end = DateTime(monthAnchor.year, monthAnchor.month + 1, 1)
        .subtract(const Duration(milliseconds: 1)).millisecondsSinceEpoch;
    final rows = await _db.query(
      'intake_logs',
      where: 'scheduled_at BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'scheduled_at',
    );
    return rows.map(IntakeLog.fromMap).toList();
  }
}
```

- [ ] **Step 5: 통과 확인 + 커밋**

```bash
flutter test test/features/intake/intake_repository_test.dart
git add lib/features/intake/ test/features/intake/
git commit -m "feat(intake): IntakeLog 모델 + Repository + 테스트"
```

### Task 1.8: Settings Repository

**Files:**
- Create: `lib/features/settings/settings_repository.dart`

- [ ] **Step 1: 작성**

```dart
// lib/features/settings/settings_repository.dart
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  final Database _db;
  SettingsRepository(this._db);

  Future<String?> get(String key) async {
    final rows = await _db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final v = await get(key);
    if (v == null) return fallback;
    return v == '1';
  }

  Future<void> setBool(String key, bool v) async => set(key, v ? '1' : '0');

  // 키 상수
  static const kAdsRemoved = 'ads_removed';
  static const kOnboardingDone = 'onboarding_done';
  static const kSeniorFontScale = 'senior_font_scale';
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/settings/settings_repository.dart
git commit -m "feat(settings): 키-값 Repository"
```

---

## Phase 2: 알림 엔진 (TDD)

### Task 2.1: 알림 ID 컨벤션 + 시간 계산 (TDD)

**Files:**
- Create: `lib/core/notification/notification_scheduler.dart`
- Test: `test/core/notification_scheduler_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

```dart
// test/core/notification_scheduler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kyh_medi/core/notification/notification_scheduler.dart';
import 'package:kyh_medi/features/slot/domain/time_slot.dart';

void main() {
  group('NotificationIdEncoder', () {
    test('encodes slot_id × 1000 + day_offset × 10 + retry_index', () {
      expect(NotificationIdEncoder.encode(slotId: 5, dayOffset: 1, retryIndex: 1), 5011);
      expect(NotificationIdEncoder.encode(slotId: 1, dayOffset: 0, retryIndex: 0), 1000);
      expect(NotificationIdEncoder.encode(slotId: 9, dayOffset: 6, retryIndex: 2), 9062);
    });

    test('idsForSlotInstance returns 3 IDs (retry 0/1/2)', () {
      final ids = NotificationIdEncoder.idsForSlotInstance(slotId: 5, dayOffset: 1);
      expect(ids, [5010, 5011, 5012]);
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

    test('next7DaysFor returns dates matching slot daysOfWeek bitmask', () {
      // 매일(127): 7일 다 매칭
      final from = DateTime(2026, 5, 1);
      final all = NotificationScheduler.next7DaysFor(
        slot: const TimeSlot(label: 'x', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday),
        from: from,
      );
      expect(all, hasLength(7));
    });

    test('next7DaysFor skips days not in bitmask', () {
      // 월(1) + 수(4) + 금(16) = 21
      final from = DateTime(2026, 5, 1); // 5/1은 금요일 (DateTime.weekday = 5)
      final result = NotificationScheduler.next7DaysFor(
        slot: const TimeSlot(label: 'x', hour: 8, minute: 0, daysOfWeek: 21),
        from: from,
      );
      // 5/1 금, 5/4 월, 5/6 수 = 3개
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
import '../../features/slot/domain/time_slot.dart';

class NotificationIdEncoder {
  static int encode({required int slotId, required int dayOffset, required int retryIndex}) {
    assert(slotId >= 0 && slotId < 1_000_000);
    assert(dayOffset >= 0 && dayOffset < 100);
    assert(retryIndex >= 0 && retryIndex < 10);
    return slotId * 1000 + dayOffset * 10 + retryIndex;
  }

  static List<int> idsForSlotInstance({required int slotId, required int dayOffset}) {
    final base = encode(slotId: slotId, dayOffset: dayOffset, retryIndex: 0);
    return [base, base + 1, base + 2];
  }
}

class NotificationScheduler {
  static const retryOffsetsMinutes = [0, 10, 20];

  /// 정시 + 10분 후 + 20분 후
  static List<DateTime> computeFireTimes(DateTime base) {
    return retryOffsetsMinutes.map((m) => base.add(Duration(minutes: m))).toList();
  }

  /// from 부터 7일치 중 슬롯 비트마스크에 매칭되는 날짜만 반환
  static List<DateTime> next7DaysFor({required TimeSlot slot, required DateTime from}) {
    final result = <DateTime>[];
    for (int offset = 0; offset < 7; offset++) {
      final d = from.add(Duration(days: offset));
      // DateTime.weekday: 월=1 ~ 일=7. 비트마스크: 월=1, 화=2, 수=4, 목=8, 금=16, 토=32, 일=64
      final bitForWeekday = 1 << (d.weekday - 1);
      if ((slot.daysOfWeek & bitForWeekday) != 0) {
        result.add(DateTime(d.year, d.month, d.day, slot.hour, slot.minute));
      }
    }
    return result;
  }
}
```

- [ ] **Step 4: 통과 확인 + 커밋**

```bash
flutter test test/core/notification_scheduler_test.dart
git add lib/core/notification/notification_scheduler.dart test/core/notification_scheduler_test.dart
git commit -m "feat(notification): ID 인코더 + 시간 계산 로직 + 테스트"
```

### Task 2.2: AndroidManifest 권한 추가

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: 권한 추가**

`<manifest>` 태그 안 (`<application>` 위)에 다음 추가:

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

- [ ] **Step 2: 알림 채널/리시버 등록**

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

### Task 2.3: NotificationService (권한 + 초기화 + show/cancel)

**Files:**
- Create: `lib/core/notification/notification_service.dart`

- [ ] **Step 1: 작성**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'kyh_medi_alerts';
  static const _channelName = '약 알림';
  static const _channelDesc = '복약 시간 알림';

  /// payload 파싱하기 위한 콜백 핸들러
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

  /// 권한 요청 (Android 13+: POST_NOTIFICATIONS)
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
git commit -m "feat(notification): NotificationService — 초기화 + 권한 + 스케줄링"
```

---

## Phase 3: UI — 약 등록 + 슬롯 관리

### Task 3.1: 공유 위젯 (SeniorButton, SeniorInput)

**Files:**
- Create: `lib/shared/widgets/senior_button.dart`
- Create: `lib/shared/widgets/senior_input.dart`

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

- [ ] **Step 3: 커밋**

```bash
git add lib/shared/widgets/
git commit -m "feat(shared): SeniorButton + SeniorInput 위젯"
```

### Task 3.2: 약 등록 폼 화면

**Files:**
- Create: `lib/features/medication/ui/medication_form_screen.dart`

- [ ] **Step 1: 작성**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../domain/medication.dart';
import '../data/medication_repository.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/senior_button.dart';
import '../../../shared/widgets/senior_input.dart';

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

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약 이름을 입력해주세요'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final db = await DatabaseHelper.instance();
    final repo = MedicationRepository(db);
    await repo.insert(Medication(
      name: _name.text.trim(),
      photoPath: _photoPath,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 약 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SeniorInput(controller: _name, label: '약 이름', hint: '예: 혈압약'),
            const SizedBox(height: 24),
            const Text('약 사진 (선택)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_photoPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_photoPath!), height: 200, fit: BoxFit.cover),
              ),
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
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/medication/ui/medication_form_screen.dart
git commit -m "feat(medication): 약 등록 폼 화면 (텍스트 + 사진)"
```

### Task 3.3: 약 목록 화면 + Provider

**Files:**
- Create: `lib/features/medication/ui/medications_provider.dart`
- Create: `lib/features/medication/ui/medication_list_screen.dart`

- [ ] **Step 1: Provider**

```dart
// medications_provider.dart
import 'package:flutter/foundation.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';

class MedicationsProvider extends ChangeNotifier {
  final MedicationRepository _repo;
  MedicationsProvider(this._repo);

  List<Medication> _items = [];
  List<Medication> get items => _items;

  Future<void> load() async {
    _items = await _repo.findActive();
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _repo.softDelete(id);
    await load();
  }
}
```

- [ ] **Step 2: 목록 화면**

```dart
// medication_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/tokens.dart';
import 'medications_provider.dart';
import 'medication_form_screen.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});
  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MedicationsProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('약 관리')),
      body: meds.isEmpty
          ? const Center(child: Text('아직 등록된 약이 없어요', style: TextStyle(fontSize: 20)))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: meds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final m = meds[i];
                return Card(
                  child: ListTile(
                    leading: m.photoPath != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(4),
                            child: Image.file(File(m.photoPath!), width: 48, height: 48, fit: BoxFit.cover))
                        : const Icon(Icons.medication, size: 36, color: AppColors.pillDeep),
                    title: Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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
                        if (ok == true && mounted) {
                          await context.read<MedicationsProvider>().remove(m.id!);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context, MaterialPageRoute(builder: (_) => const MedicationFormScreen()));
          if (saved == true && mounted) {
            await context.read<MedicationsProvider>().load();
          }
        },
        label: const Text('새 약 추가', style: TextStyle(fontSize: 18)),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 3: 커밋**

```bash
git add lib/features/medication/ui/
git commit -m "feat(medication): 약 목록 화면 + Provider"
```

### Task 3.4: 시간 슬롯 폼 + 목록 화면

**Files:**
- Create: `lib/features/slot/ui/slots_provider.dart`
- Create: `lib/features/slot/ui/slot_form_screen.dart`
- Create: `lib/features/slot/ui/slot_list_screen.dart`

- [ ] **Step 1: Provider**

```dart
// slots_provider.dart
import 'package:flutter/foundation.dart';
import '../data/slot_repository.dart';
import '../domain/time_slot.dart';
import '../domain/slot_medication.dart';

class SlotsProvider extends ChangeNotifier {
  final SlotRepository _repo;
  SlotsProvider(this._repo);

  List<TimeSlot> _slots = [];
  List<TimeSlot> get slots => _slots;

  Future<void> load() async {
    _slots = await _repo.findActiveSlots();
    notifyListeners();
  }

  Future<int> create(TimeSlot s, List<int> medicationIds) async {
    final id = await _repo.insertSlot(s);
    for (final mid in medicationIds) {
      await _repo.attachMedication(SlotMedication(slotId: id, medicationId: mid));
    }
    await load();
    return id;
  }

  Future<void> remove(int slotId) async {
    await _repo.softDeleteSlot(slotId);
    await load();
  }

  Future<List<SlotMedication>> medicationsFor(int slotId) =>
      _repo.findMedicationsForSlot(slotId);
}
```

- [ ] **Step 2: 슬롯 등록 폼**

```dart
// slot_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/senior_button.dart';
import '../../../shared/widgets/senior_input.dart';
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
  final Set<int> _selectedMeds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MedicationsProvider>().load());
  }

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
      TimeSlot(
        label: _label.text.trim().isEmpty ? '시간 슬롯' : _label.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        daysOfWeek: _daysMask,
      ),
      _selectedMeds.toList(),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _dayChip(int dayBit, String label) {
    final selected = (_daysMask & dayBit) != 0;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 16)),
      selected: selected,
      onSelected: (_) {
        setState(() => _daysMask = selected ? _daysMask & ~dayBit : _daysMask | dayBit);
      },
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
                  if (v == true) _selectedMeds.add(m.id!);
                  else _selectedMeds.remove(m.id!);
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
// slot_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/tokens.dart';
import 'slots_provider.dart';
import 'slot_form_screen.dart';

class SlotListScreen extends StatefulWidget {
  const SlotListScreen({super.key});
  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SlotsProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final slots = context.watch<SlotsProvider>().slots;
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
                return Card(
                  child: ListTile(
                    title: Text('${s.label} $hh:$mm', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    subtitle: Text(_daysLabel(s.daysOfWeek)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await context.read<SlotsProvider>().remove(s.id!);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotFormScreen()));
        },
        label: const Text('새 시간 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _daysLabel(int mask) {
    if (mask == 127) return '매일';
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return List.generate(7, (i) => (mask & (1 << i)) != 0 ? labels[i] : null)
        .where((x) => x != null).join(', ');
  }
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/features/slot/ui/
git commit -m "feat(slot): 슬롯 등록 폼 + 목록 + Provider"
```

---

## Phase 4: 메인 화면 + 복용 체크 + 알림 통합

### Task 4.1: IntakeProvider — 오늘의 슬롯 + 복용 처리

**Files:**
- Create: `lib/features/intake/ui/intake_provider.dart`

- [ ] **Step 1: 작성**

```dart
import 'package:flutter/foundation.dart';
import '../data/intake_repository.dart';
import '../domain/intake_log.dart';
import '../../slot/data/slot_repository.dart';
import '../../slot/domain/time_slot.dart';
import '../../medication/data/medication_repository.dart';
import '../../medication/domain/medication.dart';

class TodaySlotView {
  final TimeSlot slot;
  final List<Medication> medications;
  final IntakeStatus status; // pending / taken / missed
  final int scheduledAt;
  TodaySlotView({
    required this.slot,
    required this.medications,
    required this.status,
    required this.scheduledAt,
  });
}

class IntakeProvider extends ChangeNotifier {
  final IntakeRepository _intakeRepo;
  final SlotRepository _slotRepo;
  final MedicationRepository _medRepo;

  IntakeProvider(this._intakeRepo, this._slotRepo, this._medRepo);

  List<TodaySlotView> _today = [];
  List<TodaySlotView> get today => _today;

  Future<void> loadToday() async {
    final now = DateTime.now();
    // 1) 오래된 pending → missed 마킹
    await _intakeRepo.markStaleAsMissed(now: now);
    // 2) 활성 슬롯 가져오기
    final slots = await _slotRepo.findActiveSlots();
    final today = DateTime(now.year, now.month, now.day);
    final result = <TodaySlotView>[];

    for (final slot in slots) {
      // 오늘 요일이 슬롯 비트마스크에 매칭되는지
      final bit = 1 << (today.weekday - 1);
      if ((slot.daysOfWeek & bit) == 0) continue;

      final scheduled = DateTime(today.year, today.month, today.day, slot.hour, slot.minute);
      final scheduledMs = scheduled.millisecondsSinceEpoch;

      // 슬롯의 약들
      final slotMeds = await _slotRepo.findMedicationsForSlot(slot.id!);
      final meds = <Medication>[];
      for (final sm in slotMeds) {
        final m = await _medRepo.findById(sm.medicationId);
        if (m != null && m.deletedAt == null) meds.add(m);
      }
      if (meds.isEmpty) continue;

      // 각 약에 pending 로그 보장
      for (final m in meds) {
        await _intakeRepo.upsertPending(
          slotId: slot.id!, medicationId: m.id!, scheduledAt: scheduledMs,
        );
      }

      // 슬롯 전체 상태 결정
      final logs = await _intakeRepo.findByDate(today);
      final logsForSlot = logs.where((l) =>
          l.slotId == slot.id && l.scheduledAt == scheduledMs).toList();
      final status = _aggregateStatus(logsForSlot);

      result.add(TodaySlotView(
        slot: slot, medications: meds, status: status, scheduledAt: scheduledMs,
      ));
    }

    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    _today = result;
    notifyListeners();
  }

  IntakeStatus _aggregateStatus(List<IntakeLog> logs) {
    if (logs.every((l) => l.status == IntakeStatus.taken)) return IntakeStatus.taken;
    if (logs.any((l) => l.status == IntakeStatus.missed)) return IntakeStatus.missed;
    return IntakeStatus.pending;
  }

  Future<void> markSlotTaken(int slotId, int scheduledAt) async {
    await _intakeRepo.markSlotTaken(
      slotId: slotId, scheduledAt: scheduledAt, now: DateTime.now(),
    );
    await loadToday();
  }
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/intake/ui/intake_provider.dart
git commit -m "feat(intake): IntakeProvider — 오늘 슬롯 뷰 + 복용 처리"
```

### Task 4.2: 메인 화면 (오늘의 약)

**Files:**
- Create: `lib/features/intake/ui/home_screen.dart`

- [ ] **Step 1: 작성**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/tokens.dart';
import '../domain/intake_log.dart';
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

  Color _statusColor(IntakeStatus s) {
    switch (s) {
      case IntakeStatus.taken: return AppColors.jade;
      case IntakeStatus.missed: return AppColors.care;
      default: return AppColors.pillDeep;
    }
  }

  String _statusLabel(IntakeStatus s) {
    switch (s) {
      case IntakeStatus.taken: return '복용 완료';
      case IntakeStatus.missed: return '미복용';
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
                      if (mounted) context.read<IntakeProvider>().loadToday();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('$hh:$mm', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(t.slot.label, style: const TextStyle(fontSize: 18, color: AppColors.ink2)),
                        ]),
                        const SizedBox(width: 24),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
git add lib/features/intake/ui/home_screen.dart
git commit -m "feat(home): 오늘의 약 메인 화면"
```

### Task 4.3: 복용 체크 화면

**Files:**
- Create: `lib/features/intake/ui/intake_check_screen.dart`

- [ ] **Step 1: 작성**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/notification/notification_scheduler.dart';
import '../../../core/notification/notification_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/senior_button.dart';
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
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (m.photoPath != null)
                    ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(m.photoPath!), width: 96, height: 96, fit: BoxFit.cover))
                  else
                    Container(width: 96, height: 96, color: AppColors.paper2,
                      child: const Icon(Icons.medication, size: 48, color: AppColors.pillDeep)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    if (m.memo != null) Text(m.memo!, style: const TextStyle(fontSize: 16)),
                  ])),
                ])),
            ),
          const SizedBox(height: 24),
          SeniorButton(
            label: '복용 완료',
            large: true,
            color: AppColors.jade,
            onPressed: () async {
              // retry +10/+20 알림 cancel
              final today = DateTime.now();
              final dayOffset = today.difference(DateTime(today.year, today.month, today.day)).inDays;
              final ids = NotificationIdEncoder.idsForSlotInstance(
                slotId: slotView.slot.id!,
                dayOffset: 0, // 오늘
              );
              await NotificationService.cancelMany(ids);
              // 복용 완료 마킹
              await context.read<IntakeProvider>()
                  .markSlotTaken(slotView.slot.id!, slotView.scheduledAt);
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
git add lib/features/intake/ui/intake_check_screen.dart
git commit -m "feat(intake): 복용 체크 화면 + retry 알림 cancel"
```

### Task 4.4: 슬롯 등록 시 알림 자동 예약 (Slot↔Notification 연결)

**Files:**
- Modify: `lib/features/slot/ui/slots_provider.dart`

- [ ] **Step 1: SlotsProvider.create에 알림 예약 통합**

`SlotsProvider.create` 메서드 교체:

```dart
Future<int> create(TimeSlot s, List<int> medicationIds) async {
  final id = await _repo.insertSlot(s);
  for (final mid in medicationIds) {
    await _repo.attachMedication(SlotMedication(slotId: id, medicationId: mid));
  }
  // 7일치 알림 예약
  final saved = (await _repo.findSlotById(id))!;
  final fireDays = NotificationScheduler.next7DaysFor(slot: saved, from: DateTime.now());
  for (final day in fireDays) {
    final dayOffset = day.difference(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
    ).inDays;
    final fires = NotificationScheduler.computeFireTimes(day);
    for (int i = 0; i < fires.length; i++) {
      final notifId = NotificationIdEncoder.encode(
        slotId: id, dayOffset: dayOffset, retryIndex: i,
      );
      await NotificationService.scheduleAt(
        id: notifId,
        title: '${saved.label} 약 드실 시간이에요',
        body: '${saved.hour.toString().padLeft(2, '0')}:${saved.minute.toString().padLeft(2, '0')}',
        fireAt: fires[i],
        payload: 'slot:$id',
      );
    }
  }
  await load();
  return id;
}
```

상단 import 추가:
```dart
import '../../../core/notification/notification_scheduler.dart';
import '../../../core/notification/notification_service.dart';
```

`SlotsProvider.remove`도 알림 cancel하도록:

```dart
Future<void> remove(int slotId) async {
  await _repo.softDeleteSlot(slotId);
  for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
    await NotificationService.cancelMany(
      NotificationIdEncoder.idsForSlotInstance(slotId: slotId, dayOffset: dayOffset),
    );
  }
  await load();
}
```

- [ ] **Step 2: 커밋**

```bash
git add lib/features/slot/ui/slots_provider.dart
git commit -m "feat(slot): 슬롯 생성/삭제 시 알림 예약/취소 통합"
```

---

## Phase 5: 캘린더 + 온보딩 + 앱 진입점

### Task 5.1: 이력 캘린더 화면

**Files:**
- Create: `lib/features/intake/ui/history_calendar_screen.dart`

- [ ] **Step 1: 작성**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/tokens.dart';
import '../data/intake_repository.dart';
import '../domain/intake_log.dart';

class HistoryCalendarScreen extends StatefulWidget {
  const HistoryCalendarScreen({super.key});
  @override
  State<HistoryCalendarScreen> createState() => _HistoryCalendarScreenState();
}

class _HistoryCalendarScreenState extends State<HistoryCalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<DateTime, List<IntakeLog>> _byDay = {};

  @override
  void initState() {
    super.initState();
    _load(_focused);
  }

  Future<void> _load(DateTime month) async {
    final db = await DatabaseHelper.instance();
    final repo = IntakeRepository(db);
    final logs = await repo.findByMonth(month);
    final map = <DateTime, List<IntakeLog>>{};
    for (final l in logs) {
      final d = DateTime.fromMillisecondsSinceEpoch(l.scheduledAt);
      final key = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []).add(l);
    }
    setState(() => _byDay = map);
  }

  Color? _dayColor(DateTime day) {
    final list = _byDay[DateTime(day.year, day.month, day.day)];
    if (list == null || list.isEmpty) return null;
    if (list.any((l) => l.status == IntakeStatus.missed)) return AppColors.care;
    if (list.every((l) => l.status == IntakeStatus.taken)) return AppColors.jade;
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
                        l.status == IntakeStatus.taken ? Icons.check_circle :
                        l.status == IntakeStatus.missed ? Icons.cancel : Icons.schedule,
                        color: l.status == IntakeStatus.taken ? AppColors.jade :
                               l.status == IntakeStatus.missed ? AppColors.care : AppColors.inkMute,
                      ),
                      title: Text('약 #${l.medicationId}'),
                      subtitle: Text(DateTime.fromMillisecondsSinceEpoch(l.scheduledAt).toString()),
                    )).toList(),
          )),
      ]),
    );
  }
}
```

- [ ] **Step 2: 한국어 로케일 초기화**

`main.dart`에서 앱 시작 시 `await initializeDateFormatting('ko_KR', null);` 호출 필요. (Task 5.4에서 통합)

- [ ] **Step 3: 커밋**

```bash
git add lib/features/intake/ui/history_calendar_screen.dart
git commit -m "feat(history): 복용 이력 캘린더 화면"
```

### Task 5.2: 온보딩 화면 (권한 요청)

**Files:**
- Create: `lib/features/onboarding/onboarding_screen.dart`

- [ ] **Step 1: 작성**

```dart
import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/notification/notification_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/senior_button.dart';
import '../settings/settings_repository.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _allowPermissions() async {
    await NotificationService.requestPermissions();
    final db = await DatabaseHelper.instance();
    await SettingsRepository(db).setBool(SettingsRepository.kOnboardingDone, true);
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
git add lib/features/onboarding/
git commit -m "feat(onboarding): 권한 요청 + 인사말 화면"
```

### Task 5.3: 설정 화면

**Files:**
- Create: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: 작성**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/senior_button.dart';
import '../monetization/ads_provider.dart';

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
          if (!ads.removed) ...[
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('광고 제거 — ₩2,900', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            )),
            const SizedBox(height: 8),
            const Text('한 번 결제하시면 영구 제거됩니다.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            SeniorButton(
              label: '광고 제거 결제',
              onPressed: () => ads.purchaseRemoveAds(context),
            ),
            const SizedBox(height: 12),
            SeniorButton(
              label: '구매 복원',
              color: AppColors.inkMute,
              onPressed: () => ads.restorePurchases(),
            ),
          ] else ...[
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('광고 제거됨 ✓', style: TextStyle(fontSize: 22, color: AppColors.jade)),
            )),
          ],
          const Divider(height: 40),
          const Text('앱 정보', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('KYH 약 알림 v1.0.0', style: TextStyle(fontSize: 16)),
          const Text('Korean Young Health · 한 알도, 잊지 않게.', style: TextStyle(fontSize: 14, color: AppColors.ink2)),
        ],
      ),
    );
  }
}
```

> 주의: `AdsProvider`는 Phase 6에서 작성. 이 화면은 Phase 6 끝나야 컴파일됨.

- [ ] **Step 2: 커밋**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat(settings): 설정 화면 (광고 제거 자리)"
```

### Task 5.4: 앱 진입점 + 라우팅 + Provider 주입

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: app.dart**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/notification/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/intake/data/intake_repository.dart';
import 'features/intake/ui/history_calendar_screen.dart';
import 'features/intake/ui/home_screen.dart';
import 'features/intake/ui/intake_provider.dart';
import 'features/medication/data/medication_repository.dart';
import 'features/medication/ui/medication_list_screen.dart';
import 'features/medication/ui/medications_provider.dart';
import 'features/monetization/ads_provider.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_repository.dart';
import 'features/settings/settings_screen.dart';
import 'features/slot/data/slot_repository.dart';
import 'features/slot/ui/slot_list_screen.dart';
import 'features/slot/ui/slots_provider.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool? _onboardingDone;
  late final MedicationRepository _medRepo;
  late final SlotRepository _slotRepo;
  late final IntakeRepository _intakeRepo;
  late final SettingsRepository _settingsRepo;
  late final AdsProvider _ads;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    NotificationService.onTap = _handleNotificationTap;
  }

  Future<void> _bootstrap() async {
    final db = await DatabaseHelper.instance();
    _medRepo = MedicationRepository(db);
    _slotRepo = SlotRepository(db);
    _intakeRepo = IntakeRepository(db);
    _settingsRepo = SettingsRepository(db);
    _ads = AdsProvider(_settingsRepo);
    await _ads.init();
    final done = await _settingsRepo.getBool(SettingsRepository.kOnboardingDone);
    setState(() => _onboardingDone = done);
  }

  void _handleNotificationTap(String payload) {
    // 알림 페이로드 → 메인 화면 → 사용자가 카드 탭하여 들어감
    // (단순화: 알림 탭 시 그냥 앱 열림)
  }

  void _completeOnboarding() => setState(() => _onboardingDone = true);

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationsProvider(_medRepo)),
        ChangeNotifierProvider(create: (_) => SlotsProvider(_slotRepo)),
        ChangeNotifierProvider(create: (_) => IntakeProvider(_intakeRepo, _slotRepo, _medRepo)),
        ChangeNotifierProvider.value(value: _ads),
      ],
      child: MaterialApp(
        title: 'KYH 약 알림',
        theme: AppTheme.light(),
        home: _onboardingDone == true
            ? const _MainShell()
            : OnboardingScreen(onDone: _completeOnboarding),
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();
  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _idx = 0;
  final _pages = const [
    HomeScreen(),
    MedicationListScreen(),
    SlotListScreen(),
    HistoryCalendarScreen(),
    SettingsScreen(),
  ];
  final _labels = const ['오늘', '약 관리', '시간 관리', '이력', '설정'];
  final _icons = const [Icons.today, Icons.medication, Icons.schedule, Icons.calendar_month, Icons.settings];

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

- [ ] **Step 2: main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/notification/notification_service.dart';
import 'core/time/timezone_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimezone();
  await initializeDateFormatting('ko_KR', null);
  await NotificationService.initialize();
  runApp(const App());
}
```

- [ ] **Step 3: 첫 컴파일 (AdsProvider stub 필요)**

`AdsProvider`가 Phase 6 전이라 임시 stub:

```dart
// lib/features/monetization/ads_provider.dart (TEMP - Phase 6에서 교체)
import 'package:flutter/foundation.dart';
import '../settings/settings_repository.dart';

class AdsProvider extends ChangeNotifier {
  final SettingsRepository _settings;
  AdsProvider(this._settings);
  bool _removed = false;
  bool get removed => _removed;
  Future<void> init() async {
    _removed = await _settings.getBool(SettingsRepository.kAdsRemoved);
  }
  Future<void> purchaseRemoveAds(context) async {}
  Future<void> restorePurchases() async {}
}
```

- [ ] **Step 4: 실행 확인**

```bash
flutter run
```
Expected: 온보딩 → "알림 받기 시작" → 메인 (오늘 비어 있음). BottomNav 5개 탭 동작.

- [ ] **Step 5: 커밋**

```bash
git add lib/app.dart lib/main.dart lib/features/monetization/ads_provider.dart
git commit -m "feat(app): 진입점 + Provider 주입 + BottomNav 셸"
```

---

## Phase 6: 수익화 — AdMob + IAP

### Task 6.1: AdMob app ID 등록 + 초기화

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `lib/main.dart`

- [ ] **Step 1: AdMob 계정 생성**

https://apps.admob.com/ → "시작하기" → 약관 동의 → 앱 추가 → "Android" + "아직 Play Store에 게시되지 않음" → 앱 이름 "KYH 약 알림" → 앱 ID 받음 (`ca-app-pub-XXXX~YYYY` 형태).

- [ ] **Step 2: 배너 광고 단위 ID 생성**

콘솔에서 앱 클릭 → "광고 단위" → 배너 1개 생성 → 광고 단위 ID 받음 (`ca-app-pub-XXXX/ZZZZ`).

> **테스트 단계**: 위 실제 ID는 만들어만 두고, 코드엔 **테스트 ID**(`ca-app-pub-3940256099942544/6300978111`) 사용. AdMob 정책 위반 방지.

- [ ] **Step 3: AndroidManifest에 AdMob app ID 메타**

`<application>` 안에 추가:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```
(테스트 app ID. 출시 직전에 실제 ID로 교체)

- [ ] **Step 4: main.dart에 초기화**

`main()`에 추가:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ... main() 안에 ...
await MobileAds.instance.initialize();
```

- [ ] **Step 5: 커밋**

```bash
git add android/app/src/main/AndroidManifest.xml lib/main.dart
git commit -m "chore(admob): app ID 등록 + 초기화"
```

### Task 6.2: 배너 위젯 + 화면별 노출

**Files:**
- Create: `lib/features/monetization/ad_banner.dart`
- Modify: `lib/features/medication/ui/medication_list_screen.dart`
- Modify: `lib/features/intake/ui/history_calendar_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: AdBanner 위젯**

```dart
// lib/features/monetization/ad_banner.dart
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

- [ ] **Step 2: 약 목록 화면 하단에 배너**

`medication_list_screen.dart`의 `Scaffold`에 `bottomNavigationBar` 또는 `body`를 `Column` + `AdBanner`로 감싸기:

```dart
body: Column(children: [
  Expanded(child: meds.isEmpty ? ...existing... : ...existing list...),
  const AdBanner(),
]),
```

(상단 import: `import '../../monetization/ad_banner.dart';`)

- [ ] **Step 3: 이력 캘린더 / 설정 화면도 동일 패턴**

각 화면 body 마지막에 `AdBanner` 추가.

- [ ] **Step 4: 실행 + 광고 노출 확인**

```bash
flutter run
```
Expected: 약 목록/이력/설정 화면 하단에 테스트 광고 배너 표시. 메인/복용 체크/슬롯 등록/약 등록 화면에는 안 보임.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/monetization/ad_banner.dart lib/features/medication/ui/medication_list_screen.dart lib/features/intake/ui/history_calendar_screen.dart lib/features/settings/settings_screen.dart
git commit -m "feat(ads): 배너 위젯 + 정책에 따른 화면별 노출"
```

### Task 6.3: IAP — 광고 제거 결제

**Files:**
- Replace: `lib/features/monetization/ads_provider.dart`
- Create: `lib/features/monetization/iap_service.dart`

- [ ] **Step 1: Play Console에서 IAP 상품 등록**

(아직 AAB 미업로드 상태라 못 함 → Phase 7.5 끝나고 등록 → 그 후 시연/검증)

지금은 코드만 준비:

- [ ] **Step 2: IapService**

```dart
// lib/features/monetization/iap_service.dart
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

  Future<void> restore() async => _iap.restorePurchases();

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

- [ ] **Step 3: AdsProvider 실제 구현 교체**

```dart
// lib/features/monetization/ads_provider.dart (REPLACE stub)
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../settings/settings_repository.dart';
import 'iap_service.dart';

class AdsProvider extends ChangeNotifier {
  final SettingsRepository _settings;
  final IapService _iap = IapService();

  AdsProvider(this._settings);

  bool _removed = false;
  bool get removed => _removed;

  Future<void> init() async {
    _removed = await _settings.getBool(SettingsRepository.kAdsRemoved);
    notifyListeners();
    _iap.listen((p) async {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        if (p.productID == IapService.productId) {
          await _settings.setBool(SettingsRepository.kAdsRemoved, true);
          _removed = true;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 정보를 불러올 수 없어요')),
      );
      return;
    }
    await _iap.buy(product);
  }

  Future<void> restorePurchases() async => _iap.restore();

  @override
  void dispose() {
    _iap.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter run
```
Expected: 빌드 통과. 결제 흐름은 AAB 업로드 + IAP 등록 후 검증.

- [ ] **Step 5: 커밋**

```bash
git add lib/features/monetization/
git commit -m "feat(iap): 광고 제거 결제 + 영구 적용"
```

---

## Phase 7: 출시 — Play 내부 테스트 트랙

### Task 7.1: 앱 아이콘 + 스플래시

**Files:**
- Create: `assets/icon/icon.png` (1024×1024 PNG)
- Modify: `pubspec.yaml`

- [ ] **Step 1: 아이콘 PNG 준비**

1024×1024 PNG 1장. 디자인은 index.html의 약봉투 미감으로 (베이지 + 주황). 무료 도구 추천: https://favicon.io/favicon-generator/ (단일 글자) 또는 직접 Figma/PowerPoint로 그리기.

- [ ] **Step 2: flutter_launcher_icons 추가**

`pubspec.yaml`의 `dev_dependencies`에 추가:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

`pubspec.yaml` 끝에 설정 블록:

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
Expected: `android/app/src/main/res/mipmap-*` 안에 아이콘 생성됨.

- [ ] **Step 4: 커밋**

```bash
git add pubspec.yaml assets/icon/ android/app/src/main/res/
git commit -m "chore(icon): 앱 런처 아이콘 생성"
```

### Task 7.2: 앱 이름 + 패키지 이름

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: android:label 변경**

`<application>` 태그의 `android:label`을 `"KYH 약 알림"`으로.

- [ ] **Step 2: applicationId 확인**

`android/app/build.gradle`의 `applicationId "com.kyh.medi"` 확인. (`flutter create --org com.kyh.medi`로 이미 설정됨)

- [ ] **Step 3: 커밋**

```bash
git add android/
git commit -m "chore(android): 앱 이름 KYH 약 알림"
```

### Task 7.3: 키스토어 생성 + 서명 설정

**Files:**
- Create: `android/key.properties` (gitignore)
- Create: `android/app/upload-keystore.jks` (gitignore, 절대 분실/유출 금지)
- Modify: `android/app/build.gradle`
- Modify: `.gitignore`

- [ ] **Step 1: 키스토어 생성**

```bash
keytool -genkey -v -keystore "$HOME/upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
- 비밀번호 설정 (꼭 메모)
- 이름/조직/도시 입력
- 알리아스 비밀번호 (보통 키스토어 비밀번호와 동일)

→ `~/upload-keystore.jks` 파일 생성됨. **이 파일을 잃어버리면 앱 업데이트 영원히 못함**. 백업 필수.

- [ ] **Step 2: key.properties**

`android/key.properties` (절대 git에 X):

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\y00h\\upload-keystore.jks
```

- [ ] **Step 3: .gitignore 추가**

`.gitignore` 끝에 추가:

```
# Keystore
android/key.properties
android/app/upload-keystore.jks
**/key.properties
*.jks
```

- [ ] **Step 4: build.gradle 서명 설정**

`android/app/build.gradle`의 `android { ... }` 블록 위에 추가:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

`android { ... }` 안에서 `buildTypes`보다 먼저:

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

- [ ] **Step 5: 커밋 (.gitignore + build.gradle만, 키스토어/.properties는 X)**

```bash
git add .gitignore android/app/build.gradle
git commit -m "chore(android): 릴리즈 서명 설정 (키스토어 분리)"
```

### Task 7.4: AAB 빌드

- [ ] **Step 1: 빌드 실행**

```bash
flutter build appbundle --release
```
Expected: `build/app/outputs/bundle/release/app-release.aab` 생성.

- [ ] **Step 2: 빌드 검증 (실기기에서 release 모드)**

```bash
flutter install --release
```
Expected: 실기기에 release 빌드 설치됨. 알림/약 등록/복용 체크 동작 확인.

### Task 7.5: 개인정보처리방침 (GitHub Pages)

- [ ] **Step 1: 텍스트 작성**

다음 내용으로 `docs/privacy.md` 작성:

```markdown
# KYH 약 알림 개인정보처리방침

최종 갱신: 2026-05-03

## 1. 수집하는 개인정보
이 앱은 어떠한 개인정보도 수집하지 않습니다. 모든 데이터(약 정보, 복용 이력, 사진)는 사용자의 기기 안에만 저장되며, 외부 서버로 전송되지 않습니다.

## 2. 권한 사용 목적
- **알림**: 약 복용 시각에 알림을 보내기 위함.
- **카메라/사진**: 사용자가 약 사진을 등록할 때 사용 (선택적).
- **부팅 시 실행**: 기기 재부팅 후 알림을 다시 등록하기 위함.

## 3. 광고
- 본 앱은 Google AdMob 배너 광고를 표시합니다.
- AdMob은 광고 ID를 사용해 광고를 제공할 수 있습니다. 자세한 내용은 [Google 광고 정책](https://policies.google.com/technologies/ads) 참고.
- 사용자는 인앱 결제로 광고를 영구 제거할 수 있습니다.

## 4. 결제
- 광고 제거 상품(₩2,900)은 Google Play 결제 시스템을 통해 처리됩니다.

## 5. 문의
y0000h2@gmail.com
```

- [ ] **Step 2: GitHub 레포 생성 + Pages 활성화**

GitHub에서 `kyh-medi-privacy` 같은 이름으로 빈 레포 생성 → docs/privacy.md 푸시 → Settings → Pages → Source `Deploy from a branch` → main / docs → URL 받기 (예: `https://y00h.github.io/kyh-medi-privacy/privacy`).

또는 더 간단히 GitHub Gist에 마크다운 올려도 됨. URL을 Play Console에 제출.

- [ ] **Step 3: 커밋 (이 프로젝트 레포에는 docs/만)**

```bash
mkdir -p docs/legal
mv docs/privacy.md docs/legal/privacy.md  # 정리
git add docs/legal/
git commit -m "docs: 개인정보처리방침"
```

### Task 7.6: Play Console 등록 + 항목 입력

- [ ] **Step 1: Play Console 앱 생성**

https://play.google.com/console → "앱 만들기":
- 앱 이름: `KYH 약 알림`
- 기본 언어: 한국어
- 앱 또는 게임: 앱
- 무료 또는 유료: 무료
- 약관 동의

- [ ] **Step 2: 메인 스토어 등록정보**

- 짧은 설명 (80자): `한 알도, 잊지 않게. 어르신을 위한 가장 단순한 약 알림.`
- 자세한 설명 (4000자): 5월 가정의 달 컨셉 + 시니어 친화 + 광고 제거 옵션 등
- 그래픽 자산:
  - 아이콘 (512×512)
  - 피처 그래픽 (1024×500)
  - 폰 스크린샷 2~8장 (1080×1920 권장) — 실기기에서 메인/복용 체크/캘린더 캡처

- [ ] **Step 3: 콘텐츠 등급**

설문 진행 → "약 정보 (사용자 입력)" 항목 정직하게 응답 → 보통 "전체 이용가" 등급.

- [ ] **Step 4: 데이터 안전 섹션**

데이터 수집/공유 모두 "아니요" 선택. 권한 설명:
- 알림: 복약 알림
- 카메라: 약 사진 (선택)
- 사진/미디어: 약 사진 갤러리 선택 (선택)

- [ ] **Step 5: 개인정보처리방침 URL 입력**

Task 7.5의 Pages URL.

- [ ] **Step 6: 광고 포함 여부**

"이 앱에 광고가 포함되어 있습니다" 체크.

### Task 7.7: 내부 테스트 트랙 업로드

- [ ] **Step 1: 내부 테스트 트랙 생성**

Play Console → 좌측 "테스트" → "내부 테스트" → "새 버전 만들기":
- AAB 업로드 (`build/app/outputs/bundle/release/app-release.aab`)
- 출시 노트 (한국어):
  ```
  v1.0.0 — 첫 출시
  - 약 등록 (텍스트 + 사진)
  - 시간 슬롯별 복용 알림
  - 복용 이력 캘린더
  - 광고 제거 인앱 결제
  ```

- [ ] **Step 2: 테스터 추가**

내부 테스트 → "테스터" 탭 → "이메일 주소 목록 만들기" → 본인 + 가족 이메일 추가 → 저장.

- [ ] **Step 3: 검토 후 출시**

상단 "검토 시작" → "변경사항 저장하고 출시" → 승인 (보통 즉시 또는 몇 시간 내).

- [ ] **Step 4: 테스트 링크로 설치**

내부 테스트 페이지에서 "옵트인 URL" 복사 → 본인 폰 브라우저에서 열기 → "테스터가 되기" 동의 → "Play Store에서 다운로드".

Expected: 본인 폰의 Play Store에서 KYH 약 알림이 검색되어 설치됨. 🎉

- [ ] **Step 5: IAP 상품 등록 (배포 후)**

Play Console → 수익 창출 → 상품 → 인앱 상품 → "상품 만들기":
- 상품 ID: `kyh_remove_ads_lifetime`
- 이름: 광고 제거 (영구)
- 설명: 광고를 영구히 제거합니다.
- 가격: ₩2,900

- [ ] **Step 6: 최종 검증 체크리스트**

스펙 §9 E2E 체크리스트 12개 항목 모두 실기기로 수동 테스트. 통과 못하는 항목은 v1.0.1 패치로.

```bash
git tag v1.0.0
```

---

## Self-Review (이 계획서)

| 스펙 섹션 | 매핑된 Task |
|---|---|
| §1 결정사항 7개 | 모든 Phase에 분산 — A/C/A/B/A/B/A 결정이 코드에 반영됨 ✓ |
| §2 아키텍처 (3-layer) | Phase 1~3 (Repo/Provider/UI 분리) ✓ |
| §3 데이터 모델 5테이블 | Task 1.4 ✓ |
| §4 알림 엔진 | Phase 2 (T2.1 ID 인코더, T2.3 service, T4.4 통합) ✓ |
| §5 화면 8개 | T3.2(약폼), T3.3(약목록), T3.4(슬롯), T4.2(메인), T4.3(복용체크), T5.1(캘린더), T5.2(온보딩), T5.3(설정) ✓ |
| §6 디자인 시스템 | T1.1(토큰), T1.2(테마), T3.1(SeniorButton/Input) ✓ |
| §7 광고/IAP | Phase 6 (T6.1~6.3) ✓ |
| §8 프로젝트 구조 | 파일 구조 섹션 + 모든 Task의 경로 ✓ |
| §9 테스트 전략 | TDD가 적용된 Task: T1.3, T1.5, T1.6, T1.7, T2.1. UI는 수동 검증 ✓ |
| §10 R1~R8 | R1: T2.2 + T2.3 / R2: T1.3 / R3: T6.2 노출 정책 / R4: T7.5 / R5: T7.7 1차 목표 / R6: T2.2 권한 / R7: 0.3 사전준비 / R8: T6.1 테스트 ID |
| §11 D2 PASS/FAIL | Phase 4 종료가 D2 PASS 기준 그대로 |

**Placeholder scan**: 모든 step에 실제 코드/명령. "TBD/TODO" 없음. ✓

**Type consistency 체크**:
- `IntakeStatus` enum이 T1.7에서 정의되고 T4.1, T4.2, T4.3, T5.1에서 일관 사용 ✓
- `NotificationIdEncoder.encode/idsForSlotInstance` T2.1 정의, T4.3, T4.4 사용. ✓
- `Medication.id` nullable, `slot.id` nullable — `!`로 unwrap하는 곳 모두 insert 후 컨텍스트라 OK ✓
- `AdsProvider`는 T5.4에서 stub, T6.3에서 실제 구현으로 교체 — `purchaseRemoveAds(context)` 시그니처 일관 ✓

알아챈 누락 1건 — T4.4 알림 통합 시 retry 알림 cancel은 D=1 dayOffset 0만 cancel하는데, 실제로는 알림 탭이 미래 날짜일 수도 있음. 다만 v1.0 단순화 차원에서 "오늘 슬롯 카드 탭"만 가정 (메인 화면이 오늘만 표시하므로). 수용 가능.

---

## 실행 핸드오프

**계획서 완성. 저장 위치**: `C:\Users\y00h\IdeaProjects\kyh_medi\docs\superpowers\plans\2026-04-30-medication-reminder-plan.md`

**두 가지 실행 방식 중 하나 선택**:

### 1. Subagent-Driven (추천)
- 매 Task마다 신선한 서브에이전트 보냄 → 빠른 반복 + 컨텍스트 깨끗
- 각 Task 완료 후 사용자 검토 체크포인트
- **REQUIRED SUB-SKILL**: `superpowers:subagent-driven-development`

### 2. Inline Execution
- 이 세션 안에서 Task 직접 실행
- Phase 단위 체크포인트로 검토
- **REQUIRED SUB-SKILL**: `superpowers:executing-plans`

**어떤 방식으로 갈까요?**

본격 코딩은 Phase 0부터 시작 (Flutter SDK 설치). 어느 쪽이든 사용자님 폰/PC에서 직접 실행해야 하는 부분(SDK 설치, 권한 클릭, 키스토어 비밀번호 입력)은 제가 대신 못 해서 안내만 드리는 식으로 진행됩니다.

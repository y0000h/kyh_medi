# 약 알림 앱 (KYH) — 디자인 스펙

| | |
|---|---|
| **문서 버전** | v1.0 |
| **작성일** | 2026-04-30 |
| **목표 출시일** | 2026-05-03 (Play 내부 테스트 트랙) |
| **프로젝트 코드명** | `kyh_medi` (정식 앱명 TBD) |
| **브랜드** | KYH (Korean Young Health) |
| **타깃 플랫폼** | Android (v1.0). iOS는 v2 |
| **타깃 사용자** | 65세 이상 어르신 + 부모님께 설치해드리는 자녀 |

---

## 0. 컨텍스트

100세 시대, 한국 어르신의 다수가 만성질환 2개 이상 + 복합 처방. 약 한 번 깜빡함 = 응급실 방문으로 연결될 수 있는 진짜 문제. 시중 약 알림 앱은 어르신 친화적이지 않고 영어가 섞이거나 인터페이스가 복잡함.

**제품의 한 줄**: 한 알도, 잊지 않게. 어르신을 위한 가장 단순한 약 알림.

---

## 1. 핵심 결정 사항

| # | 결정 | 선택 |
|---|---|---|
| 1 | 출시 범위 | A — 3일 안에 Play Console 내부 테스트 트랙 업로드. AdMob/IAP 풀 패키지 |
| 2 | 데이터 모델 | C — 시간 슬롯 + 약별 체크박스 (하이브리드) |
| 3 | 저장소 | A — SQLite 로컬 only, 로그인 없음 |
| 4 | 알림 동작 | B — 정시 + 10분 후 + 20분 후 (총 3번), 미응답 시 자동 `missed` |
| 5 | 상태관리 | A — Provider |
| 6 | 약 등록 폼 | B — 텍스트 + 사진(선택) |
| 7 | 광고 | A — 배너만 + IAP 영구 광고 제거 ₩2,900 |

각 결정의 배경/대안은 본 스펙 작성 전 브레인스토밍 세션에서 검토함.

---

## 2. 시스템 아키텍처

### 2.1 레이어

```
┌────────────────────────────────────────────┐
│ Presentation: Screens(Widget) + Provider   │
├────────────────────────────────────────────┤
│ Domain: Service + Repository (interface)   │
├────────────────────────────────────────────┤
│ Data: SQLite (sqflite) + 로컬 파일(사진)   │
└────────────────────────────────────────────┘
```

상호작용: UI → Provider → Service → Repository → SQLite/Files
백그라운드 알림 콜백 → DB 업데이트 → Provider 갱신 → UI 리렌더

### 2.2 Spring 멘탈 모델 매핑 (자바 개발자용)

| Flutter | Spring 비유 |
|---|---|
| Provider (`ChangeNotifier`) | `@Component` + `ApplicationEventPublisher` |
| Repository | `@Repository` (Spring Data JPA) |
| Service | `@Service` |
| Widget | Controller + View 합친 것 |
| `main.dart` | `@SpringBootApplication` 진입점 |
| `pubspec.yaml` | `pom.xml` |

### 2.3 핵심 외부 라이브러리

| 패키지 | 용도 | 버전 (^) |
|---|---|---|
| `flutter_local_notifications` | 알림 엔진 | 17.x |
| `sqflite` | 로컬 DB | 2.x |
| `provider` | 상태관리 | 6.x |
| `image_picker` | 약 사진 입력 | 1.x |
| `path_provider` | 사진 저장 경로 | 2.x |
| `google_mobile_ads` | AdMob 배너 | 5.x |
| `in_app_purchase` | IAP | 3.x |
| `table_calendar` | 이력 캘린더 | 3.x |
| `timezone` | Asia/Seoul 시간대 | 0.9.x |
| `permission_handler` | 권한 요청 | 11.x |

**라이브러리 추가는 검증된 것만**. 신규 패키지 추가 시 사용자 검토 후 결정.

---

## 3. 데이터 모델 (SQLite)

### 3.1 테이블 5개

```sql
-- 약 마스터
CREATE TABLE medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  photo_path TEXT,                -- 로컬 파일 경로 (선택)
  memo TEXT,                      -- "식후 30분" 등
  color_hex TEXT,                 -- UI 구분용
  created_at INTEGER NOT NULL,
  deleted_at INTEGER              -- 소프트 삭제
);

-- 시간 슬롯 (아침/점심/저녁 + 사용자 정의)
CREATE TABLE time_slots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  label TEXT NOT NULL,            -- "아침", "점심", "저녁"
  hour INTEGER NOT NULL,          -- 0-23
  minute INTEGER NOT NULL,        -- 0-59
  days_of_week INTEGER NOT NULL,  -- 비트마스크: 월=1,화=2,수=4,목=8,금=16,토=32,일=64
  enabled INTEGER NOT NULL DEFAULT 1,
  deleted_at INTEGER
);

-- 슬롯 ↔ 약 N:M 매핑
CREATE TABLE slot_medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slot_id INTEGER NOT NULL REFERENCES time_slots(id),
  medication_id INTEGER NOT NULL REFERENCES medications(id),
  dose_count INTEGER NOT NULL DEFAULT 1
);

-- 복용 이력 (알림 트리거 시점에 lazy 생성)
CREATE TABLE intake_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slot_id INTEGER NOT NULL REFERENCES time_slots(id),
  medication_id INTEGER NOT NULL REFERENCES medications(id),
  scheduled_at INTEGER NOT NULL,  -- 원래 알림 시각 (epoch ms)
  taken_at INTEGER,               -- 실제 복용 시각 (NULL이면 미복용)
  status TEXT NOT NULL,           -- 'pending' | 'taken' | 'missed' | 'skipped'
  created_at INTEGER NOT NULL
);

-- 키-값 설정
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);
-- 예약된 키: ads_removed, senior_font_scale, last_db_version
```

### 3.2 인덱스
- `intake_logs(scheduled_at)` — 캘린더 조회용
- `intake_logs(slot_id, status)` — 미복용 처리 워커용
- `slot_medications(slot_id)` — 메인 화면 조회용

### 3.3 마이그레이션 정책
- `database_helper.dart`에 `_onUpgrade` 핸들러 + 버전별 SQL 모음
- v1.0은 init만, v1.1부터 마이그레이션 시작

---

## 4. 알림 엔진

### 4.1 예약 흐름
- 슬롯 등록/수정 시 → **다음 7일치 알림 미리 예약**
- 슬롯 1개 × 7일 × 3 retry = 최대 **21개 알림 예약**
- **앱 시작 시 보충 로직** (단순): 앱 실행될 때마다 "예약된 알림 중 가장 먼 시각"을 확인하고, 7일 미만이면 추가 예약. Workmanager는 v1.1+에서 도입.
- 어르신은 보통 매일 1회 이상 앱을 여시므로 이 단순 방식으로 충분 (만약 며칠간 앱 안 열면 OS가 알아서 알림은 발사함)

### 4.2 알림 ID 컨벤션

```
notification_id = slot_id × 1000 + day_offset × 10 + retry_index

예시: slot 5, 내일(+1), +10분 retry(retry=1)
  → 5 × 1000 + 1 × 10 + 1 = 5011
```

→ 같은 슬롯의 retry 알림을 ID 패턴(`base ~ base+2`)으로 일괄 cancel.

### 4.3 복용 체크 흐름
1. 어르신 알림 탭 → 앱 열림 → 그 슬롯 화면으로 자동 라우팅 (payload에 slot_id)
2. 슬롯의 약별 체크박스 표시 (큰 체크박스, 약 사진 함께)
3. **"복용 완료"** 큰 버튼 탭
4. 그 슬롯의 `+10분`/`+20분` retry 알림 cancel
5. `intake_logs` 업데이트 (`status = 'taken'`, `taken_at = now()`)

### 4.4 미복용 처리
- 알림은 **총 3번만 발사** (정시, +10분, +20분). 4번째 알림은 없음.
- 예정 시각 기준 +30분 이후에도 `intake_logs.taken_at`이 NULL이면 → 클라이언트 사이드 워커(앱 진입 시 + 화면 진입 시 trigger)가 `status = 'missed'`로 업데이트
- 이력 캘린더에 빨간 점 표시
- 별도 백그라운드 데몬은 안 씀 (배터리 부담 ↓, 구현 단순화)

### 4.5 시간대 (R2 대응)
- 앱 시작 시 `tz.initializeTimeZones()` + `tz.setLocalLocation(tz.getLocation('Asia/Seoul'))` 호출
- 누락 시 UTC로 예약돼 9시간 어긋남

### 4.6 사운드/진동
- v1.0: 시스템 기본 알림음 + 진동
- v1.1+: 커스텀 음성 알림 ("어머님, 약 드실 시간이에요")

---

## 5. 화면 구성 (8개)

### 5.1 화면 목록

| # | 화면 | 진입 경로 | 핵심 액션 |
|---|---|---|---|
| 1 | **온보딩** | 첫 실행 1회 | 권한 안내 + 요청 |
| 2 | **메인 — 오늘의 약** | 앱 시작 기본 화면 | 시간 슬롯 카드 보기 |
| 3 | **복용 체크** | 알림 탭 또는 메인에서 슬롯 카드 탭 | "복용 완료" |
| 4 | **약 목록** | 메인 → 메뉴 → 약 관리 | 약 추가/편집 |
| 5 | **약 등록 폼** | 약 목록 → "+ 새 약" | 약 정보 입력 |
| 6 | **시간 슬롯 관리** | 메인 → 메뉴 → 시간 관리 | 슬롯 + 약 묶기 |
| 7 | **이력 캘린더** | 메인 → 메뉴 → 이력 | 복용 패턴 보기 |
| 8 | **설정** | 메인 → 메뉴 → 설정 | 광고 제거 결제, 시니어 모드 |

> 메인 화면의 "메뉴" 진입 방식(BottomNavigationBar / Drawer / 상단 액션바)은 구현 계획서에서 결정. 시니어 친화 원칙상 BottomNav가 가장 직관적이라 1순위 후보.

### 5.2 화면별 핵심 위젯

- **메인(#2)**: `ListView` of `SlotCard` — 슬롯 시각 + 약 사진들 + 상태 뱃지(pending/taken/missed)
- **복용 체크(#3)**: 큰 약 사진 + 약 이름 (24pt+) + 약 메모 + **"복용 완료"** 버튼 (높이 80dp+)
- **약 등록 폼(#5)**: 약 이름 input + 사진 picker(카메라/갤러리/없음) + 메모 input + 색상 picker
- **이력 캘린더(#7)**: `table_calendar` + 일별 점 표시(초록/빨강/회색) + 날짜 탭 시 그날 슬롯 상세

### 5.3 라우팅
- `Navigator 1.0` (Flutter 기본). `go_router` 도입은 v1.1+로 미룸 — 8개 화면 규모는 기본 라우팅으로 충분.

---

## 6. 시니어 모드 디자인 시스템

| 항목 | 값 | 비고 |
|---|---|---|
| 본문 폰트 크기 | 18pt 이상 | Material 기본 14pt 대비 1.3× |
| 버튼 텍스트 크기 | 22pt 이상 | |
| 버튼 최소 높이 | 56dp | Material 기본 48dp 대비 ↑ |
| 색 대비 | WCAG AAA | 배경 #FBFAF6 / 텍스트 #1A1A1A → 16.1:1 |
| 컬러 팔레트 | index.html 그대로 | 베이지 + 다크잉크 + 주황 약봉투 |
| 폰트 (한글) | Pretendard Variable | 무료 상업이용 OK |
| 폰트 (영문 디스플레이) | Bricolage Grotesque | Google Fonts |
| 폰트 (메타/숫자) | JetBrains Mono | 무료 |
| 애니메이션 | 페이드만 | 슬라이드/확대축소 X (어지러움) |
| 한 화면 한 동작 | 강제 | 메인은 "복용 완료" 버튼 1개 |

### 디자인 자산 출처
- **저작권 안전 확보**:
  - 아이콘: Lucide / Phosphor Icons / Material Symbols (모두 MIT/Apache, 상업 이용 OK)
  - 일러스트: unDraw / Storyset
  - 폰트: 위 표 폰트 모두 무료
  - 컬러/스타일: 첨부 index.html에서 발전 (직접 작업물)
- **금지**: 외부 상용 앱(예: TodoMedison)의 이미지/아이콘 직접 사용 — 저작권 침해

---

## 7. 수익화

### 7.1 AdMob 배너

| 화면 | 배너 노출 |
|---|---|
| 1. 온보딩 | ❌ |
| 2. 메인 | ❌ |
| 3. 복용 체크 | ❌ (R3 의료광고 정책 회피) |
| 4. 약 목록 | ✅ 하단 |
| 5. 약 등록 폼 | ❌ |
| 6. 시간 슬롯 관리 | ❌ |
| 7. 이력 캘린더 | ✅ 하단 |
| 8. 설정 | ✅ 하단 |

- 사이즈: BANNER (50dp) — 잘못 탭 방지
- 광고 카테고리: 일반 카테고리 (의료/약 카테고리 회피)
- 사용자 입력 약 이름은 절대 광고 컨텍스트로 전달 X

### 7.2 IAP (광고 제거)

- 상품 ID: `kyh_remove_ads_lifetime`
- 가격: ₩2,900 영구 (`PRODUCT_TYPE_NON_CONSUMABLE`)
- 결제 완료 → `settings.ads_removed = '1'` → 모든 배너 즉시 숨김
- **구매 복원 버튼 필수** (Play 정책) — 설정 화면에 노출

---

## 8. 프로젝트 구조 (Feature-first)

```
lib/
├── main.dart
├── app.dart                       # MaterialApp + ThemeData
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── tokens.dart
│   ├── database/
│   │   ├── database_helper.dart
│   │   └── migrations/
│   ├── notification/
│   │   ├── notification_service.dart
│   │   └── notification_scheduler.dart
│   └── time/
│       └── timezone_init.dart
├── features/
│   ├── medication/
│   │   ├── data/                  # repository, dao
│   │   ├── domain/                # 모델
│   │   └── ui/                    # 화면 + provider
│   ├── slot/
│   │   ├── data/
│   │   ├── domain/
│   │   └── ui/
│   ├── intake/
│   │   ├── data/
│   │   ├── domain/
│   │   └── ui/
│   │       ├── home_screen.dart
│   │       ├── intake_check_screen.dart
│   │       └── history_calendar_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   └── monetization/
│       ├── ads_provider.dart
│       └── iap_service.dart
└── shared/
    ├── widgets/
    │   ├── senior_button.dart
    │   └── senior_input.dart
    └── utils/
        └── date_utils.dart
```

**원칙**: 한 화면 작업할 때 폴더 1개만 열면 됨. 비슷한 책임끼리 모이게.

---

## 9. 테스트 전략 (3일 한정)

| 종류 | 우선순위 | 대상 |
|---|---|---|
| 단위 테스트 | ✅ 필수 | NotificationScheduler 시간 계산, 모든 Repository CRUD |
| 통합 테스트 | ✅ 1개만 | 알림 예약 → 발사 → cancel 흐름 |
| 수동 E2E 체크리스트 | ✅ 필수 | 약 등록 → 슬롯 → 알림 → 복용 → 캘린더 → IAP |
| 위젯 테스트 | ❌ Skip | D3 잉여시간에만 |

### E2E 체크리스트 (수동)

- [ ] 첫 실행 시 권한 요청 화면 노출
- [ ] 권한 거부 시 graceful 처리 (앱 죽지 않음)
- [ ] 약 등록: 텍스트만 / 텍스트+사진 / 사진 권한 거부 케이스
- [ ] 시간 슬롯 생성 + 약 묶기
- [ ] 알림 트리거 (실시간 또는 시간 조작)
- [ ] 알림 탭 → 복용 체크 화면 진입
- [ ] "복용 완료" 탭 → retry 알림 cancel 확인
- [ ] +10분/+20분 retry 알림 정상 발사 (수동 시간 조작)
- [ ] 미복용 처리 → 캘린더 빨간 점
- [ ] 광고 표시되는 화면/안 되는 화면 확인
- [ ] IAP 구매 → 광고 즉시 사라짐
- [ ] IAP 복원 버튼 동작
- [ ] 폰 재부팅 후 알림 살아있는지 (BOOT_COMPLETED 권한)

---

## 10. 리스크 & 대응

| # | 리스크 | 대응 |
|---|---|---|
| R1 | Android 13+ 알림 권한 미요청 → 알림 무동작 | D2 첫 45분에 권한 요청 플로우 우선 구현 |
| R2 | Timezone 미초기화 → 9시간 어긋남 | 부팅 시 `tz.initializeTimeZones()` + 단위 테스트 |
| R3 | AdMob 의료/약 정보 광고 정책 위반 | 약 이름 등 입력값을 광고 SDK에 전달 X. 일반 카테고리. 광고 노출 화면도 핵심 사용 동선 외로 한정 |
| R4 | IAP 디버그 빌드에서 테스트 불가 | 내부 테스트 트랙 업로드 후 실기기 검증 |
| R5 | Play 신규 개발자 정책 (정식 출시까지 14일 + 12명 테스터) | 1차 목표는 내부 테스트 트랙. 공개 출시는 빌드 후순위 |
| R6 | 사진 권한 (Android 13+ `READ_MEDIA_IMAGES`) | 거부 시 graceful 폴백 (텍스트만 등록 가능) |
| R7 | Google Play 개발자 계정 신원확인 1~2일 지연 | **2026-04-30 안에 신청** ($25 결제). D3에 못 올라가는 가장 흔한 원인 |
| R8 | AdMob 첫 결제 24~48시간 지연 가능 | 시연은 테스트 광고 ID로 |

---

## 11. 일정 체크포인트

### D2 종료 시점 PASS/FAIL 기준

- ✅ **PASS 조건**: 약 등록 + 슬롯 등록 + 알림 트리거 + 복용 체크가 실기기에서 동작
- ⚠️ **FAIL 시 대응**: D3에 IAP 후순위, 광고 + 출시 우선. IAP는 v1.0.1 패치로 미룸
- 🎯 **핵심 KPI**: **출시 0회 → 1회**가 최우선

### v1.1+ 백로그 (출시 후)

- 가족 공유 알림 (자녀 폰에 부모님 미복용 알림)
- 카카오 알림톡 채널
- SMS 백업
- iOS 확장
- 위젯 (홈 화면)
- 커스텀 음성 알림
- 약 사진 OCR 자동 인식

---

## 12. 다음 단계

이 디자인 스펙 승인 후:
1. 사용자 최종 검토
2. **구현 계획서**(implementation plan) 작성 — Day 1 ~ Day 3 분 단위로 쪼갠 작업 시퀀스, 각 단계의 검증 기준 포함
3. Day 1 시작: Flutter SDK 설치부터

구현 계획서는 별도 문서(`2026-04-30-medication-reminder-plan.md`)로 작성 예정.

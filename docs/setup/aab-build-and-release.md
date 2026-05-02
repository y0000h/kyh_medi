# AAB 빌드 + 실기기 release 검증 가이드 (Phase 13.6)

> 키스토어 셋업(`docs/setup/keystore-setup.md`) 완료 후 실행.
> 시간: **약 15~20분** (첫 빌드는 NDK/CMake 캐시 다운로드로 더 길 수 있음).

---

## 0단계 — 사전 체크리스트

- [ ] `~/upload-keystore.jks` 존재 + 비밀번호 메모됨
- [ ] `android/key.properties` 작성 + `git status`에 안 보임
- [ ] Firebase 콘솔에 release SHA-1 등록 + 새 `google-services.json` 적용
- [ ] `assets/icon/icon.png` (1024×1024) 배치 + `dart run flutter_launcher_icons` 실행
- [ ] AdMob 콘솔에서 실제 app ID + 단위 ID 발급 (테스트 ID로 출시도 가능하지만 배포본은 실제 ID 권장)

---

## 1단계 — pubspec / manifest 최종 점검

### app ID 교체 (테스트 → 실제)

`android/app/src/main/AndroidManifest.xml`에서:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>  <!-- 테스트 -->
```

→ AdMob 콘솔 → 앱 → 앱 ID 복사 → `android:value`만 교체.

`lib/features/parent/monetization/ad_banner.dart`의 `_testUnitId`도 동일하게 교체:

```dart
static const String _testUnitId = 'ca-app-pub-3940256099942544/6300978111';
```

### 버전 확인

`pubspec.yaml`:

```yaml
version: 1.0.0+1
```

이미 `1.0.0+1`로 박혀있음. 업데이트 시 `1.0.1+2` 형태로 올림 (`+` 뒤 숫자가 versionCode, Play Console에 동일 versionCode 두 번 못 올림).

---

## 2단계 — AAB 빌드

```bash
cd C:/Users/y00h/IdeaProjects/kyh_medi
flutter clean
flutter pub get
flutter build appbundle --release
```

**Expected**:
- 첫 빌드: 5~15분 (Gradle/AAPT/CMake)
- 결과: `build/app/outputs/bundle/release/app-release.aab` (40~80MB 예상)
- 끝에 `√ Built build/app/outputs/bundle/release/app-release.aab`

### Supabase URL/anon key를 dart-define로 주입하는 경우 (선택)

지금 코드는 `lib/core/supabase/supabase_config.dart`에 anon key가 박혀있어서 `--dart-define` 없이도 빌드됨. 보안상 환경변수로 빼고 싶으면:

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://evkuwuyxqyjmaargifnx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

(코드에서 `String.fromEnvironment('SUPABASE_URL')`로 읽도록 변경 필요. v1.0.0은 박힌 상태로 출시 OK)

---

## 3단계 — 실기기 release 검증

AAB는 실기기에 직접 설치 못 함 (Play Store 거쳐야 함). 검증용으로는 `flutter install --release`가 release APK를 만들어 USB 연결 폰에 설치.

```bash
flutter install --release
```

또는 명시적으로:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 검증 체크리스트 (실기기, 부모 모드)

- [ ] cold launch 5초 안에 모드 선택 화면 (어제 ANR 검증)
- [ ] "부모님이세요?" 탭 → 온보딩 → 메인
- [ ] 약 등록 (텍스트 + 사진 picker)
- [ ] 시간 슬롯 추가 (1분 후) → 알림 발사 확인
- [ ] 알림 탭 → 복용 체크 화면 → 다 복용 → taken 마킹
- [ ] 캘린더 화면 — 오늘 날짜 점 색깔
- [ ] 광고 배너가 약 목록 / 캘린더 / 설정 하단에 표시
- [ ] 설정 → 자녀와 연결 → 6자리 코드 발급

### 검증 체크리스트 (실기기, 자녀 모드)

별도 폰 또는 같은 폰의 앱 데이터 초기화 후:

- [ ] 모드 선택 → "자녀세요?" → 로그인 화면
- [ ] Google 로그인 (release SHA-1이 Firebase에 등록되어 있어야 작동)
- [ ] 또는 이메일 가입 (Supabase Email Provider 활성화 필요)
- [ ] 홈 → "부모님 추가" → 부모 폰에서 받은 6자리 코드 입력 → 페어링 성공
- [ ] 홈에 부모 카드 표시
- [ ] 부모 폰에서 약 추가 → 자녀 폰 부모 상세 화면 Realtime 반영
- [ ] (FCM 셋업 완료 시) 부모 missed → 자녀 폰 푸시 도착

---

## 4단계 — 트러블슈팅

### "Keystore was tampered with, or password was incorrect"

`android/key.properties`의 `storePassword` / `keyPassword` 오타. Windows에선 백슬래시 `\\` 두 번 필수.

### "Manifest merger failed"

`AndroidManifest.xml`에 같은 권한이 중복 선언. 평소 lint 안 잡히는데 release만 fail. 중복 줄 제거.

### "Missing google-services.json"

`flutter_launcher_icons` 실행 후 `android/app/google-services.json`이 사라졌을 수 있음. Firebase 콘솔 → 다운로드 → 배치.

### `Verify that adb_forward is set up`

USB 연결 폰의 USB 디버깅 + 파일 전송 모드 확인.

### release 빌드만 크래시 (디버그는 OK)

Proguard / R8 코드 축소 영향. `android/app/build.gradle.kts`의 `release` 블록에 임시로:

```kotlin
buildTypes {
    release {
        signingConfig = ...
        isMinifyEnabled = false  // 임시
        isShrinkResources = false
    }
}
```

추가 후 재빌드. 통과하면 Proguard 규칙 추가가 진짜 fix. v1.0.0은 우선 minify 끈 채로 출시해도 OK (앱 크기만 더 큼).

### release 빌드 cold launch ANR (어제 디버그에서 본 것)

release는 보통 디버그보다 빠르므로 ANR 사라짐. 그래도 발생 시:
- `MultiProvider` 안 4개 Provider를 `FutureBuilder`로 감싸 비동기 warmup
- 또는 `_parentApp()` 진입 전 placeholder + Future로 분리

v1.0.1 백로그.

---

## 5단계 — 빌드 결과 확인

```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

→ 파일 크기 표시되면 OK. 다음은 Play Console 업로드 (`play-console-upload.md`).

## 결과 체크리스트

- [ ] AAB 빌드 성공 (`build/app/outputs/bundle/release/app-release.aab`)
- [ ] release APK 실기기 설치 + 부모 모드 풀 검증
- [ ] (별도 폰) 자녀 모드 풀 검증
- [ ] 부모-자녀 페어링 + Realtime 동기화 확인
- [ ] (FCM 셋업 완료 시) missed → 자녀 푸시 도착

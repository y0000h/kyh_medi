# 릴리즈 키스토어 셋업 가이드 (Phase 13.3 사용자 manual)

> Play Store에 올릴 AAB는 반드시 본인 release key로 서명되어야 함. 디버그 키스토어로는 업로드 불가.
> 시간: **약 15분**.

> ⚠️⚠️ **이 키스토어 파일을 잃어버리면 앱 업데이트 영원히 못 함.** Play Console에 업로드된 후에는 같은 키로만 새 버전 서명 가능. 비밀번호와 .jks 파일을 USB + 클라우드 암호화 등 **2곳 이상**에 백업.

---

## 1단계 — 키스토어 생성 (3분)

### Windows PowerShell

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -genkey -v `
  -keystore "$env:USERPROFILE\upload-keystore.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Git Bash / WSL

```bash
keytool -genkey -v -keystore "$HOME/upload-keystore.jks" \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 입력 흐름

| 프롬프트 | 권장 |
|---|---|
| 키 저장소 비밀번호 | **강한 비밀번호** + 메모 (영구) |
| 비밀번호 다시 입력 | 동일 |
| 이름과 성 | 본인 영문명 (예: `Younghoon Kang`) |
| 조직 단위 | `Dev` 또는 비워둠 |
| 조직 이름 | `KYH` 또는 비워둠 |
| 도시 | `Seoul` |
| 시/도 | `Seoul` |
| 두 자리 국가 코드 | `KR` |
| 정보가 정확합니까 | `y` |
| 키 비밀번호 (alias `upload`) | **저장소 비밀번호와 동일 권장** (Enter) |

→ 결과: `C:\Users\y00h\upload-keystore.jks` (홈 디렉토리). 절대 git에 올리지 마세요.

---

## 2단계 — SHA-1 추출 → Firebase 콘솔 등록 (5분)

Google OAuth가 release 빌드에서 작동하려면 release 키스토어의 SHA-1 지문을 Firebase 프로젝트에 추가해야 함.

```bash
keytool -list -v -keystore "$HOME/upload-keystore.jks" -alias upload
```

(비밀번호 입력 → 출력에서 `SHA1:` 라인 찾기. 콜론으로 구분된 40자리 hex)

### Firebase 콘솔에 추가

1. <https://console.firebase.google.com> → 프로젝트 `kyh-medi` → ⚙️ → 프로젝트 설정
2. **내 앱** → Android 앱(`com.kyh.medi.kyh_medi`) 클릭
3. **SHA 인증서 지문** 섹션 → **지문 추가**
4. SHA-1 붙여넣기 → 저장
5. **새 google-services.json 다운로드** → `android/app/google-services.json`에 덮어쓰기

> 지금 OAuth가 디버그 키 SHA-1으로 등록됐다면, release 키 SHA-1도 추가로 등록해야 둘 다 작동합니다 (지문 여러 개 등록 가능).

---

## 3단계 — `key.properties` 작성 (2분)

`android/key.properties` 파일을 만들고:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\y00h\\upload-keystore.jks
```

> ⚠️ Windows 경로의 백슬래시는 **두 번** (`\\`). properties 파일 escape 규칙.
> 이 파일은 `.gitignore`에 이미 등록됨. 확인: `git status`에 안 보여야 정상.

---

## 4단계 — 빌드 검증 (5분)

```bash
flutter build appbundle --release
```

성공 시 `build/app/outputs/bundle/release/app-release.aab` 생성.

### 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| `Keystore file ... not found` | `key.properties`의 `storeFile` 경로 오타. Windows 절대경로 + `\\` |
| `Wrong password` | `storePassword` / `keyPassword` 오타 |
| `flutter build appbundle` 통과인데 디버그 키로 서명됨 | `key.properties` 파일이 `android/` 폴더가 아닌 다른 곳에 있음 (rootProject = `android/`) |
| `flutter run --release`만 통과, AAB 빌드 fail | NDK 또는 Java 버전 차이. `android/app/build.gradle.kts`의 `compileOptions.sourceCompatibility = VERSION_17` 확인 |

확인 명령:

```bash
cd android && ./gradlew signingReport
```

→ release variant의 SHA-1이 본인 jks 키 SHA-1과 일치해야 함 (디버그 키 SHA-1과 다름).

---

## 5단계 — AAB 실기기 release 검증 (선택)

```bash
flutter install --release
```

→ USB 연결된 실기기에 release APK 설치 (AAB는 실기기 직접 설치 불가, Play Internal Testing 트랙 거쳐야 함).

체크리스트:
- 부모 모드 cold launch (어제 디버그 ANR이 release에서 사라지는지 확인)
- 약 등록 / 슬롯 / 알림 / 복용 체크 / 캘린더 / 설정
- 자녀 연결 → 자녀 폰에서 코드 입력 → 페어링
- 광고 배너가 약 목록 / 캘린더 / 설정 화면 하단에 보임

---

## 결과 체크리스트

- [ ] `~/upload-keystore.jks` 생성 + 백업 2곳
- [ ] 비밀번호 메모 (영구 보관)
- [ ] Firebase 콘솔에 release SHA-1 등록 + 새 `google-services.json` 받음
- [ ] `android/key.properties` 작성 (gitignore 안 됨 확인)
- [ ] `flutter build appbundle --release` 성공
- [ ] (선택) `flutter install --release` 실기기 검증

이 5개 다 ✅면 Phase 13.3+13.4가 끝납니다. 다음은 Play Console 업로드(Phase 13.7).

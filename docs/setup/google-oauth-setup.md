# Google OAuth 셋업 가이드 (Phase 9 진입 전 사용자 manual 작업)

> Phase 9.1 자녀 모드 인증(`ChildAuthService` + `ChildLoginScreen`)을 시작하기 위한 콘솔 셋업.
> 한 번만 하면 되며, 시간 약 10–15분.

**순서 정확히 지켜주세요** — 1단계에서 Supabase Callback URL을 먼저 복사해야 4단계에서 막히지 않습니다.

---

## 1단계 — Supabase에서 Callback URL 복사 (1분)

1. **<https://supabase.com/dashboard>** → 프로젝트 클릭
2. 왼쪽 사이드바 **Authentication** → **Sign In / Providers** (또는 **Providers**)
3. 목록에서 **Google** 항목 클릭해서 펼침 (토글은 켜지 마세요, 아직)
4. **"Callback URL (for OAuth)"** 표시됨. 옆에 복사 아이콘 클릭 → 메모장에 붙여넣기
   - 형태: `https://xxxxxxxxxx.supabase.co/auth/v1/callback`

이 URL을 4단계에서 쓸 거예요. 일단 이 탭은 **그대로 열어두세요**.

---

## 2단계 — Google Cloud 새 프로젝트 (2분)

1. **<https://console.cloud.google.com>** 접속 (본인 Gmail로 로그인)
2. 상단 가운데 **프로젝트 선택 드롭다운** 클릭 → **"새 프로젝트"**
3. 프로젝트 이름: **`kyh-medi`** → **만들기**
4. 잠시 후 알림에 "프로젝트 생성됨" 뜨면 거기 **선택** 또는 상단 드롭다운에서 `kyh-medi` 선택

> 만약 "결제 계정 활성화" 안내가 뜨면 **무시하세요**. OAuth 자체는 무료입니다.

---

## 3단계 — OAuth 동의 화면 설정 (3분)

1. 왼쪽 햄버거 메뉴(≡) → **"API 및 서비스"** → **"OAuth 동의 화면"**
2. User Type: **외부** 선택 → **만들기**
3. 다음 입력:
   - 앱 이름: **`KYH 약 알림`**
   - 사용자 지원 이메일: **본인 Gmail**
   - 개발자 연락처 정보: **본인 Gmail**
   - (다른 항목은 비워둠) → **저장하고 계속**
4. 범위 화면: 그냥 **저장하고 계속** (스코프 추가 안 함)
5. 테스트 사용자: **"+ ADD USERS"** → 본인 Gmail 입력 → 추가 → **저장하고 계속**
6. 요약 화면 → **대시보드로 돌아가기**

> ⚠️ 5단계에서 본인 이메일 안 넣으면 본인이 자기 앱 로그인하려고 해도 차단당합니다. 꼭 추가하세요.

---

## 4단계 — OAuth Client ID 만들기 (2분)

1. 왼쪽 사이드바 → **"사용자 인증 정보"**
2. 상단 **"+ 사용자 인증 정보 만들기"** → **"OAuth 클라이언트 ID"**
3. 다음 입력:
   - 애플리케이션 유형: **웹 애플리케이션**
   - 이름: **`kyh-medi-supabase`**
   - **"승인된 리디렉션 URI"** 섹션 → **"+ URI 추가"** → **1단계에서 복사한 Supabase Callback URL** 붙여넣기
4. **만들기** 클릭
5. 팝업이 뜨면 **Client ID** + **클라이언트 보안 비밀번호 (Client Secret)** 둘 다 메모장에 복사
   - 또는 "JSON 다운로드" 눌러서 파일 보관

---

## 5단계 — Supabase에 등록 (1분)

1. 처음 열어둔 Supabase 탭으로 돌아가기 (Authentication → Google Provider)
2. **Client ID** 입력
3. **Client Secret** 입력
4. **Enable Sign in with Google** 토글 **ON**
5. **Save**

---

## 끝나면

내일 세션에서 **"구글 OAuth 켰어"** 한마디 해주세요. 곧바로 Phase 9.1 (`ChildAuthService` + `ChildLoginScreen`) 코드 작성 시작합니다.

막힌 단계 있으면 단계 번호 + 화면 캡처 함께 알려주시면 같이 풀게요. 자주 막히는 지점:

- **결제 계정 안내 팝업** → 무시. OAuth는 무료.
- **테스트 사용자 미등록** → 본인 Gmail이 testing 모드에서 차단됨. 3단계 5번 확인.
- **redirect URI 형식 오타** → 끝에 `/auth/v1/callback`까지 정확히. 슬래시 빠지면 안 됨.
- **OAuth 동의 화면 게시 상태** → "테스트" 상태로 두면 됨. "프로덕션 게시"는 나중에 Play Console 출시 시점에.

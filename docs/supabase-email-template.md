# Supabase 이메일 OTP 템플릿 설정 (자녀 로그인용)

자녀 로그인의 이메일 OTP는 `signInWithOtp` API를 쓴다.
Supabase **기본 Magic Link 템플릿은 링크만 노출**하고 6자리 코드(`{{ .Token }}`) 변수를 표시하지 않는다.
사용자가 메일을 받았는데 "코드가 안 보인다" 하는 이유.

## 한 번만 설정하면 됨

1. [Supabase Dashboard](https://supabase.com/dashboard) → 본인 프로젝트 (`evkuwuyxqyjmaargifnx`)
2. 좌측 메뉴 → **Authentication** → **Email Templates**
3. **Magic Link** 탭 선택
4. Subject (제목) 갱신:
   ```
   KYH 약 알림 — 인증번호
   ```
5. Body (HTML) 아래 내용으로 통째로 교체:

```html
<div style="font-family: -apple-system, 'Segoe UI', sans-serif; max-width: 480px; margin: 0 auto; padding: 32px 24px; color: #1A1A1A;">
  <h2 style="margin: 0 0 16px; font-size: 22px;">KYH 약 알림 — 인증번호</h2>
  <p style="margin: 0 0 24px; font-size: 15px; color: #5A544A; line-height: 1.5;">
    아래 인증번호를 앱에 입력해주세요. 60분 동안 유효합니다.
  </p>

  <div style="background: #F5F1EC; border-radius: 12px; padding: 24px; text-align: center; margin: 0 0 24px;">
    <div style="font-size: 36px; font-weight: 800; letter-spacing: 6px; color: #C26644; font-family: 'Courier New', monospace;">
      {{ .Token }}
    </div>
  </div>

  <p style="margin: 0 0 16px; font-size: 14px; color: #5A544A;">
    또는 아래 링크를 눌러 바로 로그인하실 수도 있어요:
  </p>
  <p style="margin: 0;">
    <a href="{{ .ConfirmationURL }}"
       style="display: inline-block; padding: 12px 24px; background: #C26644; color: #fff; text-decoration: none; border-radius: 8px; font-weight: 600;">
      KYH 약 알림 앱에서 로그인하기
    </a>
  </p>
</div>
```

> 마지막 면책 문구("이 메일을 요청하신 적이 없다면…")는 Supabase가 자동으로 footer에 추가해줘서 우리 템플릿에서는 뺐다. 중복 방지.

6. **Save** 누르기.

## redirectTo URL 허용 목록

링크 클릭으로 자동 로그인되게 하려면:

1. 같은 페이지 → **URL Configuration** (또는 Authentication → URL Configuration)
2. **Redirect URLs** 항목에 추가:
   ```
   kyhmedi://auth-callback
   ```
3. Save.

## 검증

- 자녀 로그인 화면 → 이메일 입력 → "인증번호 받기"
- 받은 메일 본문 상단에 큰 6자리 숫자 코드가 보이면 OK
- 코드를 앱에 입력 → 로그인 성공
- 또는 메일의 "앱에서 로그인하기" 버튼 클릭 → 폰에서 자동으로 앱이 열리며 로그인

## 동작 안 할 때 점검

| 증상 | 원인 / 조치 |
|---|---|
| 메일 자체가 안 옴 | 스팸함 확인. Supabase 무료 티어는 분당 발송량 제한 있음 — 1분 정도 기다리고 재시도. |
| "코드가 안 보여요" | 위 템플릿이 적용 안 된 것. Email Templates의 **Magic Link** 탭에 저장됐는지 재확인. |
| 코드 입력해도 만료/실패 | 코드 유효시간 60분. 앱에서 "재발송" 눌러서 새 코드 받기. |
| 링크 클릭했는데 앱 안 열림 | `kyhmedi://auth-callback` 이 Redirect URLs 허용 목록에 있는지 확인. |

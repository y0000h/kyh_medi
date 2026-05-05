# 2026-05-05 — Design System Refresh

## Background

`core/theme/tokens.dart` is partial — just colors + a handful of sizes. Themes are bare-bones (only `textTheme` + `elevatedButtonTheme`). Screens repeat inline literals (`fontSize: 32`, `BorderRadius.circular(16)`, `EdgeInsets.all(20)`, `Colors.white`), so visual consistency drifts and cosmetic tweaks scatter across the codebase.

User feedback (2026-05-05 brainstorm):

- 팔레트 (cream + 주황) 가 옛날 — "70s diner" 결
- 전체적으로 "낡아 보임" — 정돈 안 된 느낌

## Goals

1. **Modernize the visual language** while keeping 어르신 가독성 (≥18pt body, high contrast, large touch targets) intact.
2. **Two themes share structure, differ in warmth.** 부모(senior) → refined warm earthy. 자녀(caregiver) → cool clinical (deep blue + emerald). Same spacing scale, radius scale, shadow scale, typography ramp.
3. **Make tokens the single source of truth.** All colors, spacing, radius, shadows, and text styles addressable through `core/theme/`. No more inline `BorderRadius.circular(16)` etc.
4. **Populate `ThemeData` fully** so most screens get the new look automatically (CardTheme, AppBarTheme, ChipTheme, InputDecorationTheme, etc.).

## Non-goals

- Dark mode (defer; can layer onto same token structure later).
- Animation tokens / motion design (defer).
- Iconography rework (continue using Material Icons set).
- Visual rewrite of every screen. Token + theme rewrite gets us most of the way; screens that still look off after that get separate touch-ups in a follow-up.
- Caregiver-mode screen polish beyond what already exists (caregiver UI is mostly stub today).

## Direction (chosen 2026-05-05)

**B (차등 적용):** 부모 모드는 따뜻한 톤 유지하되 modernize, 자녀 모드는 cool clinical. 둘은 spacing/radius/shadow/typography 구조가 동일.

## Token spec

### Color palettes

Two palettes, structurally identical (same role names), values differ.

#### 부모 (warm earthy modern)

| role | value | use |
|---|---|---|
| `bg` | `#F5F1EC` | scaffold background |
| `surface` | `#FFFFFF` | card / sheet background |
| `surfaceAlt` | `#FAF7F2` | alternate surface (input fields, secondary cards) |
| `border` | `#E0D9CC` | hairlines, dividers |
| `primary` | `#C26644` | brand, primary actions |
| `primaryDeep` | `#8A4A2D` | pressed primary, emphasis |
| `success` | `#5A8175` | 복용 완료 |
| `danger` | `#B33A3A` | 미복용, destructive |
| `warning` | `#C99A4A` | 복용 전, attention |
| `ink` | `#1A1A1A` | primary text |
| `ink2` | `#5A544A` | secondary text |
| `inkMute` | `#8A8378` | tertiary text, captions |

Notes: removes the dated `pill`/`pillDeep` distinction (was a cream/orange chiaroscuro), replaces `jade`/`care` with semantic `success`/`danger`, drops `bg2`/`paper2` variants.

#### 자녀 (cool clinical)

| role | value | use |
|---|---|---|
| `bg` | `#F4F6F8` | scaffold |
| `surface` | `#FFFFFF` | card / sheet |
| `surfaceAlt` | `#F9FAFB` | alternate |
| `border` | `#E2E6EB` | hairlines |
| `primary` | `#3B82C4` | brand, primary actions |
| `primaryDeep` | `#1E5A8C` | pressed primary |
| `success` | `#10B981` | success state |
| `danger` | `#EF4444` | destructive |
| `warning` | `#F59E0B` | attention |
| `ink` | `#0F172A` | primary text |
| `ink2` | `#334155` | secondary |
| `inkMute` | `#64748B` | tertiary |

Replaces today's `caregiverPrimary`/`caregiverBg`/`caregiverCard` (a 3-token sketch) with the same role surface as 부모.

### Spacing scale (4pt grid, shared)

| token | px |
|---|---|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 20 (default screen padding) |
| `xxl` | 24 |
| `x3l` | 32 |
| `x4l` | 40 |

Card internal padding defaults to `xl` (20). Inter-card gap defaults to `md`–`lg`. Screen edge padding `xl` (20).

### Radius scale (shared)

| token | px | use |
|---|---|---|
| `sm` | 6 | small chips, input fields |
| `md` | 12 | default buttons, small cards |
| `lg` | 16 | default cards |
| `xl` | 20 | bottom sheets, modals |
| `pill` | 999 | status badges, FAB |

### Shadow scale (shared, subtle)

| token | spec | use |
|---|---|---|
| `sm` | offset 0,1 / blur 2 / `rgba(0,0,0,0.04)` | very light lift |
| `md` | offset 0,2 / blur 8 / `rgba(0,0,0,0.06)` | default card |
| `lg` | offset 0,4 / blur 16 / `rgba(0,0,0,0.08)` | floating elements |

Cards use `md` and **drop their hairline border** (border was redundant with shadow).

### Typography (Pretendard)

#### 부모 (어르신, 큼)

| role | size | weight | letter-spacing | use |
|---|---|---|---|---|
| `displayLarge` | 32 | 800 | -0.5 | hero numbers (시간 등) |
| `titleLarge` | 24 | 700 | 0 | screen title, section header |
| `bodyLarge` | 18 | 400 | 0 | default body |
| `bodyMedium` | 16 | 400 | 0 | dense lists |
| `labelLarge` | 18 | 700 | 0 | button text |
| `labelMedium` | 13 | 700 | 0.6 | tags/chips ("아침"/"점심") — weight + spacing differentiates, no case transform (Korean) |
| `caption` | 14 | 400 | 0 | footnote, helper text |

#### 자녀 (보호자, 표준)

| role | size | weight | letter-spacing |
|---|---|---|---|
| `titleLarge` | 24 | 700 | 0 |
| `titleMedium` | 18 | 600 | 0 |
| `bodyLarge` | 15 | 400 | 0 |
| `labelLarge` | 15 | 600 | 0 |
| `caption` | 13 | 400 | 0 |

### Component theme rules

Both modes adopt these via `ThemeData`. Values differ where noted.

- **`appBarTheme`**: `surface` background, no shadow (`elevation: 0`), `ink` foreground, `titleLarge` style, `toolbarHeight: 64` (부모) / `56` (자녀).
- **`cardTheme`**: `surface` bg, `radius.lg`, `shadow.md`, no border, no margin (let parent handle spacing).
- **`elevatedButtonTheme`**: minHeight `56` (부모) / `48` (자녀), `radius.md`, primary bg, white fg, `labelLarge` style.
- **`outlinedButtonTheme`**: 1.5px primary border, `radius.md`, transparent bg, primary fg, same min height.
- **`textButtonTheme`**: `radius.md`, primary fg.
- **`inputDecorationTheme`**: filled (`surfaceAlt` bg), `radius.md`, no underline, hint = `inkMute`.
- **`dividerTheme`**: thickness `1`, color `border`, no indent default.
- **`chipTheme`**: `radius.pill`, label `labelMedium` (부모) / 12px w600 (자녀). Used for status badges via `StatusBadge` widget below.
- **`bottomNavigationBarTheme`** / **`navigationBarTheme`**: `surface` bg, primary indicator, ink labels.
- **`scaffoldBackgroundColor`**: `bg`.

## Architecture

### File layout

Replace single `core/theme/tokens.dart` with a small folder:

```
core/theme/
├── tokens/
│   ├── colors.dart       # SeniorPalette, CaregiverPalette
│   ├── spacing.dart      # AppSpacing (shared)
│   ├── radius.dart       # AppRadius (shared)
│   ├── shadows.dart      # AppShadows (shared)
│   └── typography.dart   # SeniorTypography, CaregiverTypography (TextTheme builders)
├── senior_theme.dart     # builds ThemeData for parent
├── caregiver_theme.dart  # builds ThemeData for child
├── semantic_colors.dart  # AppSemanticColors ThemeExtension
└── tokens.dart           # barrel: re-exports for convenience
```

Why a folder: each token type has a dedicated home, easy to find, easy to extend (e.g., adding `motion.dart` later for animation tokens). Single barrel `tokens.dart` keeps consumer imports concise.

### Semantic colors via ThemeExtension

`success` / `danger` / `warning` / `border` / `inkMute` are not part of Material's `ColorScheme`. We expose them via a `ThemeExtension` so they switch automatically with the active theme:

```dart
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color danger;
  final Color warning;
  final Color border;
  final Color ink2;
  final Color inkMute;
  // ... required ThemeExtension boilerplate (copyWith, lerp)
}
```

Both themes register their version: `extensions: [AppSemanticColors.senior]` / `[...caregiver]`.

Consumers: `Theme.of(context).extension<AppSemanticColors>()!.success`.

For `primary` / `primaryDeep` / `surface` / `bg` / `ink` we use the standard `ColorScheme` slots — no extension needed.

### Spacing / radius / shadows — static const

These don't change per mode, so a static class is simpler than another `ThemeExtension`:

```dart
class AppSpacing {
  static const double xs = 4;
  // ...
}
class AppRadius {
  static const Radius sm = Radius.circular(6);
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(12));
  // ...
}
class AppShadows {
  static const List<BoxShadow> md = [BoxShadow(...)];
  // ...
}
```

### Primitive widgets to add (`shared/widgets/`)

These codify the most repeated patterns and let screen code stay declarative.

1. **`StatusBadge(status: success|danger|warning|info, label: String)`** — pill badge with semantic color. Replaces inline `Container(decoration: BoxDecoration(color:..., borderRadius:...), child: Text(...))` repeated in `home_screen.dart`, `history_calendar_screen.dart`, etc.

2. **`SectionCard({Widget child, EdgeInsets? padding, VoidCallback? onTap})`** — `Card` + `InkWell` + default `xl` padding. Replaces the boilerplate in every list item.

3. **Update existing `SeniorButton`** — defer to theme for primary look. Final API:
   - `label: String` (required), `onPressed: VoidCallback?` (required)
   - `variant: SeniorButtonVariant.primary | .secondary | .destructive` (default primary). Secondary = outlined; destructive = `danger` bg.
   - `large: bool` for the existing 80px hero variant.
   - Drops the loose `color: Color?` parameter — every existing caller maps cleanly: `color: AppColors.inkMute` → `variant: secondary`. (Touched: `settings_screen.dart` "구매 복원" button.)

4. **Update existing `senior_input.dart`** — defer to `inputDecorationTheme` instead of styling locally.

`caregiver_card.dart` (existing, used by child mode) — keep but align with new tokens.

### Migration strategy

This spec rewrites tokens + themes + primitive widgets in one PR (atomic for cleanliness). Existing screens get edited in the same PR to consume the new API:

- All `AppColors.*` references that map to a Material role go to `Theme.of(context).colorScheme.*`.
- Semantic refs (`AppColors.jade`, `AppColors.care`) go to `Theme.of(context).extension<AppSemanticColors>()!.*`.
- Inline radii / paddings / sizes get tokens.
- `Container(decoration:..., color: status, borderRadius: ...)` → `StatusBadge(status: ...)`.
- `Card(child: InkWell(child: Padding(...)))` → `SectionCard(onTap: ..., child: ...)`.

Tradeoff acknowledged: the PR will touch ~15 files. Smaller staged migration would mean the app looks half-modernized for a window — uglier than current. Auto-mode user preferred shipping the full visual change at once.

## Out of this spec, into the implementation plan

- Order of file edits, validation gates, screenshot diffs.
- How to verify the change on emulator (screenshot 5 key screens before/after).
- Per-screen visual touch-ups identified during migration that go beyond mechanical token swap (e.g., HomeScreen card layout polish identified in the brainstorm Before/After).

## Acceptance criteria

- `flutter analyze` clean across all changed files.
- App launches in both modes; no `RangeError`/`null!` from missing theme extensions.
- Visual smoke check: HomeScreen, MedicationListScreen, SlotListScreen, ChatScreen, SettingsScreen render without obvious regressions.
- No file in `lib/features/` references a hex color literal or `BorderRadius.circular(N)` with a non-token value (one-time grep gate).
- versionCode bumped, AAB rebuilt for next internal-testing upload.

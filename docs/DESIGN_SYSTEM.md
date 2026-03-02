# InterVue — Design System

## Philosophy

Soft, smooth, minimal. Think Claude's web interface — clean surfaces, generous spacing, subtle depth through elevation not borders. No visual noise. Everything serves a purpose.

---

## Colors

### Base Palette

```dart
// Dark theme foundations
static const Color background =     Color(0xFF0F0F0F);  // near-black, app background
static const Color surface =        Color(0xFF1A1A1A);  // cards, panels
static const Color surfaceLight =   Color(0xFF242424);  // elevated cards, hover states
static const Color surfaceBorder =  Color(0xFF2E2E2E);  // very subtle borders (use sparingly)

// Text
static const Color textPrimary =    Color(0xFFE8E8E8);  // primary text, high emphasis
static const Color textSecondary =  Color(0xFF9A9A9A);  // secondary text, labels, captions
static const Color textTertiary =   Color(0xFF5A5A5A);  // disabled, placeholder text

// Accent — Crimson (one accent color, used intentionally)
static const Color accent =         Color(0xFFDC143C);  // Crimson — primary actions, active states
static const Color accentSoft =     Color(0x33DC143C);  // 20% opacity — backgrounds, highlights
static const Color accentHover =    Color(0xFFE8273E);  // slightly lighter for hover

// Semantic
static const Color success =        Color(0xFF2ECC71);  // green — strong grade, advance
static const Color warning =        Color(0xFFF39C12);  // amber — maybe grade, hold, yellow flag
static const Color error =          Color(0xFFE74C3C);  // red — reject, red flag, no grade
static const Color info =           Color(0xFF3498DB);  // blue — informational badges

// Score circle colors (1-5)
static const Color score1 =         Color(0xFFE74C3C);  // red
static const Color score2 =         Color(0xFFE67E22);  // orange
static const Color score3 =         Color(0xFFF39C12);  // amber
static const Color score4 =         Color(0xFF27AE60);  // green
static const Color score5 =         Color(0xFF2ECC71);  // bright green
```

### Usage Rules

- **Crimson accent** is used for: primary buttons, active tab indicators, selected states, important counts, the timer, links.
- **Do not** use accent for large surfaces. It should pop, not dominate.
- **Borders are rare.** Use elevation (surface → surfaceLight) and spacing to separate elements. When you must use a border, use `surfaceBorder` at 1px.
- **Status colors** (success/warning/error) are used for grades and flags only. Never for decorative purposes.

---

## Typography

Two fonts only. No exceptions.

```dart
// Titles — Hanuman
// Used for: screen titles, section headers, candidate names on cards
static TextStyle titleLarge = GoogleFonts.hanuman(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  color: textPrimary,
);

static TextStyle titleMedium = GoogleFonts.hanuman(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: textPrimary,
);

static TextStyle titleSmall = GoogleFonts.hanuman(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: textPrimary,
);

// Content — Jost
// Used for: body text, labels, inputs, questions, notes, everything else
static TextStyle bodyLarge = GoogleFonts.jost(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: textPrimary,
  height: 1.5,
);

static TextStyle bodyMedium = GoogleFonts.jost(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: textPrimary,
  height: 1.5,
);

static TextStyle bodySmall = GoogleFonts.jost(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: textSecondary,
  height: 1.4,
);

static TextStyle label = GoogleFonts.jost(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: textSecondary,
  letterSpacing: 0.5,
);

static TextStyle buttonText = GoogleFonts.jost(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: textPrimary,
);
```

### Typography Rules

- **Only 7 text styles total.** titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, label. Plus buttonText.
- **Never** create one-off text styles inline. Always reference the design system.
- **Hanuman is only for titles.** If it's not a screen title or section header, use Jost.
- **Font sizes:** Don't go below 12px or above 28px anywhere in the app.

---

## Spacing

Use a 4px base grid. All spacing values are multiples of 4.

```dart
static const double xs = 4;
static const double sm = 8;
static const double md = 16;
static const double lg = 24;
static const double xl = 32;
static const double xxl = 48;
```

### Spacing Rules

- **Card padding:** 16px (md) on all sides
- **Section spacing:** 24px (lg) between sections
- **Screen padding:** 32px (xl) horizontal, 24px (lg) vertical
- **Between list items:** 8px (sm)
- **Between form fields:** 16px (md)
- **Between label and input:** 8px (sm)

---

## Elevation & Surfaces

No drop shadows. Use surface color steps for hierarchy.

```
Level 0: background (0xFF0F0F0F) — page background
Level 1: surface (0xFF1A1A1A) — cards, panels, dialogs
Level 2: surfaceLight (0xFF242424) — hover states, elevated elements, selected items
```

### Card Style

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    // No border by default. Add only when needed:
    // border: Border.all(color: AppColors.surfaceBorder, width: 1),
  ),
  padding: EdgeInsets.all(AppSpacing.md),
  child: ...
)
```

- **Border radius:** 12px for cards, 8px for buttons and inputs, 20px for chips/badges
- **No shadows.** Period.

---

## Components Quick Reference

### Buttons

```
Primary:  Crimson background, white text, 8px radius, 44px height
Secondary: surface background, textPrimary text, surfaceBorder border, 8px radius, 44px height
Ghost:    transparent, textSecondary text, no border, 44px height
Danger:   error background (0xFFE74C3C), white text
```

- All buttons are 44px minimum height (touch target)
- Hover: lighten background by one surface step
- Active/pressed: darken slightly

### Input Fields

```
Background: surface
Border: surfaceBorder, 1px, 8px radius
Focus border: accent, 1.5px
Text: textPrimary
Placeholder: textTertiary
Padding: 12px horizontal, 14px vertical
```

- No labels above inputs. Use placeholder text or inline labels.
- Error state: error color border

### Chips / Toggle Chips

```
Unselected: surface background, surfaceBorder border, textSecondary text, 20px radius
Selected: accentSoft background, accent border, accent text, 20px radius
Height: 36px
Padding: 12px horizontal
```

- Used extensively for screening responses, filters, tags
- Single-select: only one can be active
- Multi-select: multiple can be active

### Score Circles

```
Size: 40px diameter
Unselected: surface background, surfaceBorder border, textTertiary number
Selected: filled with score color (score1-score5), white number
Spacing: 8px between circles
```

- The 5 circles sit in a row: ① ② ③ ④ ⑤
- Tap one → it fills with color, others reset
- Colors: 1=red, 2=orange, 3=amber, 4=green, 5=bright green

### Fraud Flag Dots

```
Size: 32px diameter
Unselected: surface background, colored border matching the flag color
Selected: filled with flag color
Spacing: 8px between dots
Labels underneath: "None" "Concern" "Suspect"
```

- Three dots: 🟢 (success) 🟡 (warning) 🔴 (error)
- Only one active at a time. Default: green (none)

### Status Badge

```
Padding: 6px horizontal, 2px vertical
Border radius: 20px
Font: label style
Background: status color at 20% opacity
Text: status color at full opacity
```

Status → color mapping:
- screening: info
- technical: accent
- assignment: warning
- finalReview: accent
- offer/hired: success
- rejected: error

### Toast

```
Position: bottom-center, 80px from bottom
Background: surfaceLight
Border radius: 8px
Text: bodyMedium
Duration: 2 seconds, fade out
Max width: 400px
```

---

## Animation

- **Page transitions:** 200ms fade
- **Card hover:** 150ms background color transition
- **Panel slide-in:** 250ms ease-out from right
- **Score/chip selection:** 100ms scale(1.05) then back
- **Toast:** 200ms fade in, 200ms fade out after duration
- **Collapse/expand (fraud probes):** 200ms height animation with opacity

---

## Layout

- **Max content width:** 1200px, centered
- **Sidebar:** None. Use top navigation.
- **Top bar:** Fixed, 64px height, background color, contains: logo/title (left), search (center), save indicator (right)
- **Minimum supported width:** 1024px. Below this, show a centered message: "InterVue works best on a larger screen."

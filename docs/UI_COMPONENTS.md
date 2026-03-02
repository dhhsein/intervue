# InterVue — UI Components

Reusable widgets used across multiple screens. Build these as standalone widgets in `lib/widgets/`.

---

## ScoreSelector

Tappable row of 5 circles for 1-5 scoring.

```
  ① ② ③ ④ ⑤
```

**Props:**
- `value`: int? (null = nothing selected)
- `onChanged`: Function(int?)
- `size`: double (default 40)

**Behavior:**
- Tap a circle to select it. Tap the same circle again to deselect (sets to null).
- Unselected: `surface` background, `surfaceBorder` border, `textTertiary` number
- Selected: filled with score color, white number, subtle scale animation (100ms, 1.05x)
- Score colors: 1=score1(red), 2=score2(orange), 3=score3(amber), 4=score4(green), 5=score5(bright green)
- Number is displayed inside the circle

---

## FraudFlagSelector

Three tappable dots for fraud assessment.

```
  🟢 None    🟡 Concern    🔴 Suspect
```

**Props:**
- `value`: FraudFlag (default: FraudFlag.none)
- `onChanged`: Function(FraudFlag)

**Behavior:**
- Only one can be active at a time
- Unselected: `surface` background, colored border (success/warning/error)
- Selected: filled with the flag color, white icon/checkmark inside
- Label text below each dot in `bodySmall` style
- Size: 32px diameter dots

---

## ToggleChips (Single Select)

A row of chip buttons where only one can be selected.

```
  [Yes, actively looking]  [Open but passive]  [Not sure]
```

**Props:**
- `options`: List<String>
- `value`: String? (currently selected)
- `onChanged`: Function(String?)

**Behavior:**
- Tap to select. Tap the selected chip again to deselect.
- Unselected: `surface` bg, `surfaceBorder` border, `textSecondary` text
- Selected: `accentSoft` bg, `accent` border, `accent` text
- Border radius: 20px
- Height: 36px
- Padding: 12px horizontal
- Chips wrap to next line if they overflow

---

## MultiSelectChips

Same as ToggleChips but multiple can be selected.

```
  [Growth ✓]  [Compensation]  [Domain interest ✓]  [Other]
```

**Props:**
- `options`: List<String>
- `values`: List<String> (currently selected)
- `onChanged`: Function(List<String>)
- `showOtherTextField`: bool (default false) — if true, shows a text field when "Other" is selected

**Behavior:**
- Tap to toggle selection
- Selected chips show a small checkmark before the text
- Same styling as ToggleChips

---

## GradeSelector

Three large tappable cards for screening grades.

```
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │  STRONG  │  │  MAYBE   │  │    NO    │
  │    ★     │  │    ○     │  │    ✕     │
  └──────────┘  └──────────┘  └──────────┘
```

**Props:**
- `value`: String? ("strong", "maybe", "no")
- `onChanged`: Function(String?)
- `options`: List<GradeOption> (label, icon, color)

**Behavior:**
- Each card is ~100px wide, ~80px tall
- Unselected: `surface` background, `surfaceBorder` border
- Selected: card's color at 20% opacity background, color border, color text
- Colors: strong=success, maybe=warning, no=error
- Icon is centered above the label
- Tap to select, tap again to deselect

**Also used for:**
- Recommendation: ADVANCE / HOLD / REJECT (same component, different labels)
- Assignment: HIRE / HOLD / REJECT

---

## RecommendationSelector

Identical to GradeSelector but with different labels and colors. Use the same component.

```
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ ADVANCE  │  │   HOLD   │  │  REJECT  │
  │    ▶     │  │    ⏸     │  │    ✕     │
  └──────────┘  └──────────┘  └──────────┘
```

---

## StatusBadge

Small colored pill showing candidate status.

```
  [Technical]  [Screening]  [Rejected]
```

**Props:**
- `status`: CandidateStatus

**Styling:**
- Padding: 6px horizontal, 2px vertical
- Border radius: 20px
- Background: status color at 20% opacity
- Text: status color, `label` style
- Color mapping defined in DESIGN_SYSTEM.md

---

## AutoSaveTextField

Text field that automatically saves after a debounce period.

**Props:**
- `initialValue`: String
- `onSave`: Function(String) — called after debounce
- `debounceMs`: int (default 500)
- `hint`: String
- `maxLines`: int (default 3)
- `label`: String?

**Behavior:**
- Standard text field with `surface` background, `surfaceBorder` border
- On each keystroke, reset a debounce timer
- After `debounceMs` of no typing, call `onSave` with current value
- While debounce is pending, set the global save indicator to "Saving..."
- After save completes, set it to "Saved ✓"

---

## CollapsibleSection

Expandable section used for fraud probes.

```
  [▶ Show Fraud Probe]           ← collapsed (default)

  [▼ Hide Fraud Probe]           ← expanded
  ┌─────────────────────────┐
  │ Ask: "Have you impl..." │
  │ Drill into RS256 vs...  │
  └─────────────────────────┘
```

**Props:**
- `title`: String (e.g., "Show Fraud Probe")
- `collapsedTitle`: String? (if different from expanded)
- `child`: Widget (the content to show/hide)
- `initiallyExpanded`: bool (default false)

**Behavior:**
- Tap the header to toggle
- Content animates in/out (200ms height + opacity)
- When expanded, the content area has `accentSoft` background and left border in `accent` color
- Arrow icon rotates 90° on toggle

---

## SaveIndicator

Global save status shown in the top bar.

```
  Saved ✓       ← idle state (after successful save)
  Saving...     ← during save
  Offline ✕     ← server unreachable
```

**Props:**
- Reads from `saveStatusProvider` (Riverpod)

**States:**
- `saved`: "Saved ✓" in `textTertiary`, subtle fade-in
- `saving`: "Saving..." in `textSecondary`, subtle pulse animation
- `error`: "Save failed" in `error` color
- `offline`: "Server offline" in `error` color

---

## SearchBar

Search input in the top bar.

**Props:**
- `onChanged`: Function(String)
- `hint`: String (default "Search candidates...")

**Styling:**
- Background: `surface`
- Border: none
- Border radius: 8px
- Icon: search icon in `textTertiary`
- Text: `bodyMedium`
- Width: 300px (fixed in top bar)
- Focus: `accent` ring (1.5px)

---

## EmptyState

Shown when a list or section has no data.

**Props:**
- `icon`: IconData
- `title`: String
- `subtitle`: String?
- `action`: Widget? (optional button)

**Styling:**
- Centered in the available space
- Icon: 48px, `textTertiary`
- Title: `bodyLarge`, `textSecondary`
- Subtitle: `bodySmall`, `textTertiary`
- Padding: 48px vertical

---

## CandidateCard

Card shown in the pipeline columns on the dashboard.

**Props:**
- `candidate`: Candidate
- `onTap`: Function()

**Styling:**
- Background: `surface`, border-radius 12px
- Padding: 16px
- Hover: background transitions to `surfaceLight`
- Content varies by stage (see WIREFRAMES.md — Dashboard)

**Content by stage:**
- Screening: name (titleSmall), screening grade badge, CTC range (bodySmall)
- Technical: name, tech average score with ScoreSelector visual, days since interview
- Assignment: name, assignment score or "Pending" with time remaining
- Final Review: name, tech score, assignment score

---

## NumberInput

Styled number input with prefix/suffix.

```
  [₹ _______ LPA]
```

**Props:**
- `value`: String
- `onChanged`: Function(String)
- `prefix`: String? (e.g., "₹")
- `suffix`: String? (e.g., "LPA")
- `hint`: String

**Styling:**
- Same as standard text input from DESIGN_SYSTEM.md
- Prefix and suffix are `textTertiary`, not editable
- Input only accepts numeric characters

---

## TechLevelMatrix

Grid of radio buttons for tech experience assessment (Q9).

```
                None    Basic    Intermediate    Advanced
  FastAPI       ○        ○           ●              ○
  SQLAlchemy    ○        ●           ○              ○
  Docker        ○        ○           ●              ○
  Kubernetes    ●        ○           ○              ○
  Terraform     ●        ○           ○              ○
```

**Props:**
- `technologies`: List<String>
- `levels`: List<String>
- `values`: Map<String, String> (tech → level)
- `onChanged`: Function(Map<String, String>)

**Styling:**
- Table layout with `bodyMedium` for tech names and `label` for column headers
- Radio buttons use `accent` color when selected
- Rows alternate between `surface` and `background` for readability

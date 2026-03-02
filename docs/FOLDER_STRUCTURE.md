# InterVue — Folder Structure

## Flutter Project

```
intervue/
├── docs/                              ← you are here (implementation docs, not shipped)
│   ├── IMPLEMENTATION_PLAN.md
│   ├── DESIGN_SYSTEM.md
│   ├── WIREFRAMES.md
│   ├── DATA_MODELS.md
│   ├── API_SPEC.md
│   ├── FOLDER_STRUCTURE.md
│   ├── GOTCHAS.md
│   └── UI_COMPONENTS.md
│
├── server/                            ← Dart shelf server (separate Dart package)
│   ├── pubspec.yaml
│   └── bin/
│       └── server.dart                ← ~200-250 lines, all server logic
│
├── sample_data/                       ← copied into data dir on first run
│   ├── config.json
│   ├── questions/
│   │   ├── screening.json
│   │   ├── technical.json
│   │   └── general.json
│   └── candidates/
│       ├── c_001_arjun_mehta/
│       │   └── candidate.json
│       ├── c_002_priya_sharma/
│       │   └── candidate.json
│       └── c_003_rahul_iyer/
│           └── candidate.json
│
├── lib/                               ← Flutter app source
│   ├── main.dart                      ← app entry, theme, router setup
│   │
│   ├── theme/
│   │   ├── app_theme.dart             ← ThemeData, dark theme config
│   │   ├── app_colors.dart            ← all color constants
│   │   ├── app_typography.dart        ← all text styles
│   │   └── app_spacing.dart           ← spacing constants
│   │
│   ├── models/                        ← data classes with json_serializable
│   │   ├── candidate.dart
│   │   ├── screening_data.dart
│   │   ├── technical_round.dart
│   │   ├── assignment_review.dart
│   │   ├── interview_question.dart
│   │   └── app_config.dart
│   │
│   ├── services/
│   │   ├── data_service.dart          ← abstract DataService interface
│   │   └── local_data_service.dart    ← implementation using dio → localhost:3001
│   │
│   ├── providers/                     ← Riverpod providers
│   │   ├── candidates_provider.dart   ← list, filter, CRUD
│   │   ├── questions_provider.dart    ← question bank loading
│   │   ├── interview_provider.dart    ← active interview session state
│   │   └── save_status_provider.dart  ← "Saved ✓" indicator state
│   │
│   ├── router/
│   │   └── app_router.dart            ← go_router route definitions
│   │
│   ├── screens/
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── pipeline_column.dart
│   │   │   └── candidate_card.dart
│   │   │
│   │   ├── candidate/
│   │   │   ├── candidate_detail_screen.dart
│   │   │   ├── tabs/
│   │   │   │   ├── profile_tab.dart
│   │   │   │   ├── screening_tab.dart
│   │   │   │   ├── technical_tab.dart
│   │   │   │   └── assignment_tab.dart
│   │   │   └── add_candidate_panel.dart
│   │   │
│   │   ├── interview/
│   │   │   ├── question_bank_screen.dart
│   │   │   ├── interview_session_screen.dart  ← THE critical screen
│   │   │   └── interview_summary_screen.dart
│   │   │
│   │   └── compare/
│   │       └── compare_screen.dart
│   │
│   └── widgets/                       ← reusable UI components
│       ├── score_selector.dart        ← tappable 1-5 circles
│       ├── fraud_flag_selector.dart   ← green/yellow/red dots
│       ├── toggle_chips.dart          ← single/multi select chip groups
│       ├── grade_selector.dart        ← STRONG/MAYBE/NO or ADVANCE/HOLD/REJECT
│       ├── recommendation_selector.dart
│       ├── status_badge.dart          ← colored status pill
│       ├── save_indicator.dart        ← "Saved ✓" / "Saving..."
│       ├── collapsible_section.dart   ← for fraud probes
│       ├── search_bar.dart
│       ├── auto_save_text_field.dart  ← text field with debounced save
│       └── empty_state.dart           ← placeholder for empty lists
│
├── pubspec.yaml
├── start.sh                           ← launches both server and web app
└── README.md
```

## Data Directory (~/intervue_data/)

This lives OUTSIDE the project. Created on first server run.

```
~/intervue_data/
├── config.json
├── questions/
│   ├── screening.json             ← loaded from sample_data/ on first run
│   ├── technical.json
│   └── general.json
├── candidates/
│   ├── c_001_arjun_mehta/
│   │   ├── candidate.json
│   │   ├── screening.json
│   │   ├── technical.json
│   │   ├── assignment.json
│   │   └── resume.pdf
│   ├── c_002_priya_sharma/
│   │   ├── candidate.json
│   │   └── screening.json
│   └── ...
└── exports/
    └── comparison_20250315.json
```

## Server Package (server/pubspec.yaml)

```yaml
name: intervue_server
description: Local data server for InterVue
version: 1.0.0
environment:
  sdk: ^3.2.0
dependencies:
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  args: ^2.4.2
  path: ^1.8.3
  mime: ^1.0.5
```

## Flutter Package (pubspec.yaml)

```yaml
name: intervue
description: Interview pipeline management tool
version: 1.0.0
environment:
  sdk: ^3.2.0
  flutter: ">=3.19.0"
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  json_annotation: ^4.8.0
  google_fonts: ^6.1.0
  intl: ^0.19.0
  url_launcher: ^6.2.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  json_serializable: ^6.7.0
  build_runner: ^2.4.0
  flutter_lints: ^3.0.0
```

## start.sh

```bash
#!/bin/bash
# Start InterVue — run from the project root

echo "Starting InterVue server on port 3001..."
(cd server && dart run bin/server.dart --data-dir ~/intervue_data) &
SERVER_PID=$!

echo "Starting Flutter web app..."
(cd build/web && python3 -m http.server 8080) &
WEB_PID=$!

echo ""
echo "InterVue is running:"
echo "  App:    http://localhost:8080"
echo "  Server: http://localhost:3001"
echo ""
echo "Press Ctrl+C to stop both."

trap "kill $SERVER_PID $WEB_PID 2>/dev/null; exit" INT TERM
wait
```

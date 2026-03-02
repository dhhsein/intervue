# InterVue — Implementation Plan

## Quick Start

```bash
# Terminal 1: Start the server
cd /Users/dan/Documents/intervue/server
dart run bin/server.dart --data-dir ~/intervue_data

# Terminal 2: Run Flutter web
cd /Users/dan/Documents/intervue
flutter run -d chrome
```

**Status:** ✅ Implementation Complete (Phases 1-5)

---

## What Is This

InterVue is a Flutter web app for managing interview pipelines. It runs locally with a Dart shelf server for file I/O. Dark theme only, minimal UI, optimized for speed during live interviews.

**This document is the master plan. It references other docs in this folder for details. Read this first, then consult the referenced docs as you implement each phase.**

## Reference Documents

| Document | Purpose |
|----------|---------|
| [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md) | Colors, typography, spacing, component specs |
| [WIREFRAMES.md](./WIREFRAMES.md) | Screen layouts and interaction patterns |
| [DATA_MODELS.md](./DATA_MODELS.md) | All Dart models with JSON serialization |
| [API_SPEC.md](./API_SPEC.md) | Local Dart server endpoints and CORS setup |
| [FOLDER_STRUCTURE.md](./FOLDER_STRUCTURE.md) | Project directory layout |
| [GOTCHAS.md](./GOTCHAS.md) | Known issues and required solutions |
| [UI_COMPONENTS.md](./UI_COMPONENTS.md) | Reusable widget specs with interaction details |
| `sample_data/` folder | Pre-loaded questions and sample candidates |
| `agent.md` (user-provided) | Coding conventions — follow all rules from this file |

## Tech Stack

```
Flutter Web (frontend)
├── State management: Riverpod (flutter_riverpod)
├── Routing: go_router
├── JSON: json_serializable + json_annotation
├── HTTP client: dio
├── Fonts: google_fonts (Jost for body, Hanuman for titles)
└── Theme: Material 3, dark only, Crimson accent

Dart Shelf Server (backend, localhost:3001)
├── shelf + shelf_router + shelf_cors_headers
├── dart:io for filesystem
├── dart:convert for JSON
└── Serves data from ~/intervue_data/
```

## Critical Rules

1. **Auto-save everything.** No save buttons. Every tap on a score, every note keystroke (debounced 500ms), every status change writes to the server immediately. Show a subtle "Saved ✓" indicator.
2. **UI-friendly inputs everywhere.** No typing where tapping will do. Scores are tappable circles. Status is a dropdown. Yes/no questions are toggle chips. Screening responses use preset option chips with an "Other" text field.
3. **Fraud probes are collapsed by default.** Tap to reveal. Candidates should not see these on screen share.
4. **Dark theme only.** No light theme toggle. Follow DESIGN_SYSTEM.md exactly.
5. **CORS middleware on the server from day one.** See GOTCHAS.md.
6. **DataService abstraction.** All data access goes through an abstract class. LocalDataService talks to the shelf server. This enables Firebase migration later.
7. **Data folder is outside the project.** Default: `~/intervue_data/`. Passed as `--data-dir` arg to the server.
8. **All sample data from `sample_data/` folder gets copied into the data directory on first run** if the data directory is empty.
9. **Browser navigation must work.** Use `context.push()` for forward navigation (e.g., dashboard → candidate detail) and `context.pop()` or back button text links for going back. This ensures browser back/forward buttons work correctly. Never use `context.go()` for hierarchical navigation — only for replacing the current route entirely (e.g., after logout).

---

## Phases

Each phase is scoped to be completable in a single Claude Code session. After completing a phase, verify all acceptance criteria before marking it done.

---

### Phase 1: Project Scaffold + Server + Data Layer ✅ COMPLETE

**Goal:** Flutter web project runs, Dart server runs, data flows end-to-end, sample data loads.

**Status:** ✅ Completed on 2026-03-02

**What Was Built:**

1. **Server** (`server/bin/server.dart` ~400 lines):
   - CORS middleware as FIRST in pipeline
   - All CRUD endpoints: candidates, screening, technical, assignment
   - Questions endpoint for all three banks (screening, technical, general)
   - Resume upload and file serving with path traversal protection
   - Config endpoint
   - `--data-dir` flag with default `~/intervue_data/`
   - Auto-copies `sample_data/` on first run

2. **Data Models** (`lib/models/`):
   - `candidate.dart` - Candidate, CandidateStatus, StatusChange, CandidateDetail, PipelineStage
   - `screening_data.dart` - ScreeningData, ScreeningGrade, ScreeningResponse, PhoneScreenData
   - `technical_round.dart` - TechnicalRound, QuestionScore, FraudFlag, OverallImpressions, FraudAssessment
   - `assignment_review.dart` - AssignmentReview, AssignmentStatus, AreaScore, GitHistoryCheck
   - `interview_question.dart` - InterviewQuestion, QuestionBank
   - `app_config.dart` - AppConfig
   - All with generated `.g.dart` files from json_serializable

3. **Services** (`lib/services/`):
   - `data_service.dart` - Abstract DataService interface
   - `local_data_service.dart` - Implementation using Dio to localhost:3001

4. **Providers** (`lib/providers/`):
   - `data_service_provider.dart` - DataService singleton
   - `candidates_provider.dart` - CandidatesNotifier, candidateDetailProvider, filteredCandidatesProvider, candidatesByStageProvider
   - `questions_provider.dart` - screeningQuestionsProvider, technicalQuestionsProvider, generalQuestionsProvider, questionsByCategoryProvider
   - `interview_provider.dart` - InterviewSession, InterviewNotifier, selectedQuestionsProvider
   - `save_status_provider.dart` - SaveStatus enum, SaveStatusNotifier

5. **Theme** (`lib/theme/`):
   - `app_colors.dart` - All colors from DESIGN_SYSTEM.md including score colors
   - `app_typography.dart` - Hanuman for titles, Jost for body
   - `app_spacing.dart` - 4px grid system
   - `app_theme.dart` - Full dark ThemeData with Material 3

6. **Router** (`lib/router/app_router.dart`):
   - Routes: `/`, `/candidate/:id`, `/candidate/:id/questions`, `/candidate/:id/interview`, `/candidate/:id/interview/summary`, `/compare`

7. **Screens** (`lib/screens/`):
   - `dashboard/dashboard_screen.dart` — Implemented in Phase 2
   - `candidate/candidate_detail_screen.dart` — Implemented in Phase 2
   - `interview/question_bank_screen.dart` — Implemented in Phase 4
   - `interview/interview_session_screen.dart` — Implemented in Phase 4
   - `interview/interview_summary_screen.dart` — Implemented in Phase 4
   - `compare/compare_screen.dart` — Implemented in Phase 5

8. **Sample Data** (`sample_data/`):
   - `config.json` - App configuration with email templates
   - `questions/screening.json` - 10 screening questions with input types
   - `questions/technical.json` - 14 technical questions with fraud probes
   - `questions/general.json` - 12 general questions
   - No sample candidates - fresh installs start with empty candidate list

9. **Scripts**:
   - `start.sh` - Launches server and Flutter web together

**Acceptance Criteria:**
- [x] `dart run bin/server.dart` starts without errors on port 3001
- [x] `flutter run -d chrome` opens the app without errors
- [x] `GET localhost:3001/api/candidates` returns empty array on fresh install
- [x] `GET localhost:3001/api/questions/technical` returns question bank JSON
- [x] No CORS errors in browser console
- [x] Theme applies correctly (dark background, Crimson accent, Jost font)
- [x] All routes navigate without errors (even if screens are empty)
- [x] `start.sh` launches both server and app

---

### Phase 2: Dashboard + Candidate Management ✅ COMPLETE

**Goal:** Kanban pipeline board works. Can add, view, and manage candidates.

**Status:** ✅ Completed on 2026-03-02

**What Was Built:**

1. **Widgets** (`lib/widgets/`):
   - `status_badge.dart` — Colored status pill badges
   - `grade_indicator.dart` — Strong/Maybe/No grade indicator
   - `save_indicator.dart` — Global save status in top bar
   - `search_bar.dart` — Search input for filtering candidates
   - `candidate_card.dart` — Pipeline cards with stage-specific content
   - `pipeline_column.dart` — Scrollable column for each pipeline stage
   - `add_candidate_panel.dart` — Slide-over panel for adding candidates with resume upload
   - `status_dropdown.dart` — Status change dropdown with all statuses
   - `reject_dialog.dart` — Rejection dialog with preset reasons + custom text
   - `settings_dialog.dart` — App settings dialog

2. **Dashboard Screen** (`lib/screens/dashboard/dashboard_screen.dart`):
   - Four pipeline columns: Screening, Technical, Assignment, Final Review
   - Candidate cards with stage-specific info (grade, score, status)
   - Search bar filters across all columns
   - Rejected/Hired summary at bottom
   - "Add Candidate" button opens slide-over panel
   - "Compare Finalists" link

3. **Candidate Detail Screen** (`lib/screens/candidate/candidate_detail_screen.dart`):
   - Header with name, email, phone, resume link
   - Status dropdown for changing candidate status
   - Tabbed layout: Profile | Screening | Technical | Assignment
   - Profile tab fully implemented with contact, compensation, availability, timeline

4. **Tabs** (`lib/screens/candidate/tabs/`):
   - `profile_tab.dart` — Full implementation with contact, compensation, availability, timeline
   - `screening_tab.dart` — Implemented in Phase 3
   - `technical_tab.dart` — Implemented in Phase 4
   - `assignment_tab.dart` — Implemented in Phase 5

**Acceptance Criteria:**
- [x] Dashboard shows sample candidates in correct pipeline columns
- [x] Search filters candidates by name across all columns
- [x] Can add a new candidate with name, email, phone, resume
- [x] Candidate detail view shows all profile information
- [x] Resume PDF opens in a new browser tab
- [x] Status changes persist across page refreshes
- [x] Rejecting a candidate moves them to rejected pool with reason and timestamp

**Note:** Browser navigation uses `context.push()` for forward navigation and `context.pop()` for back, ensuring browser back/forward buttons work correctly. See Critical Rule #9.

---

### Phase 3: Screening Round Flow ✅ COMPLETE

**Goal:** Can send screening emails, record responses with UI-friendly inputs, grade candidates.

**Status:** ✅ Completed on 2026-03-02

**What Was Built:**

1. **Reusable Widgets** (`lib/widgets/`):
   - `toggle_chips.dart` — Single-select chip buttons with tap-to-select/deselect
   - `multi_select_chips.dart` — Multi-select chips with optional "Other" text field
   - `number_input.dart` — Styled number input with prefix/suffix (₹, LPA, days)
   - `tech_level_matrix.dart` — Radio grid for tech experience levels
   - `grade_selector.dart` — Large tappable cards for STRONG/MAYBE/NO grades
   - `score_selector.dart` — 1-5 tappable circles with color-coded scores
   - `auto_save_text_field.dart` — Text field with 500ms debounce auto-save

2. **Screening Provider** (`lib/providers/screening_provider.dart`):
   - `screeningNotifierProvider` — Family provider for per-candidate screening state
   - Auto-save on every response update
   - Methods: updateResponse, updateGrade, updatePhoneScreen, markEmailSent

3. **Config Provider** (`lib/providers/config_provider.dart`):
   - Loads email templates from server config

4. **Screening Tab** (`lib/screens/candidate/tabs/screening_tab.dart`):
   - Header with screening dates and "Copy Screening Email" button
   - All 10 questions with UI-friendly inputs:
     - Q1-Q2, Q4, Q6-Q7: Toggle chips (single select)
     - Q3: Number pair (Current CTC / Expected CTC)
     - Q5: Multi-select chips with "Other" text field
     - Q8: Number input + negotiable toggle
     - Q9: Tech level matrix (5 techs × 4 levels)
     - Q10: Free text area
   - Each question has notes field with auto-save
   - Screening grade selector (STRONG/MAYBE/NO)
   - Phone screen section with:
     - Conducted toggle
     - Communication score (1-5)
     - Logistics confirmed chips (Salary/Notice/On-site)
     - Notes field

**Acceptance Criteria:**
- [x] All 10 screening questions render with appropriate UI inputs (not text fields)
- [x] Can fill in all screening responses using taps/selections (minimal typing)
- [x] Screening grade (Strong/Maybe/No) saves and shows on dashboard card
- [x] Phone screen section toggles visibility
- [x] "Copy Screening Email" generates correct email with candidate name
- [x] All data persists across page refreshes
- [x] Notes fields auto-save with debounce

---

### Phase 4: Question Bank + Interview Session ✅ COMPLETE

**Goal:** The live interview experience works — select questions, run the interview, score in real-time.

**Status:** ✅ Completed on 2026-03-02

**What Was Built:**

1. **Widgets** (`lib/widgets/`):
   - `collapsible_section.dart` — Animated collapsible sections for grouping questions

2. **Question Bank Screen** (`lib/screens/interview/question_bank_screen.dart`):
   - All questions from technical.json and general.json displayed
   - Grouped by category with collapsible sections
   - Each question shows: question text, "Assesses" tag, depth badge (Core/Nice-to-have/General)
   - Checkbox to select questions for an interview
   - Filter by depth: All, Core, Nice-to-have, General
   - "Start Interview with N Selected" button → navigates to interview session
   - Clear selection button

3. **Interview Session Screen** (`lib/screens/interview/interview_session_screen.dart`):
   - Top bar: candidate name, live timer (auto-starts), question counter (Q 3 of 6)
   - Question card: full question text, category badge
   - Fraud probe: collapsed by default, "Show Fraud Probe" toggles visibility with animation
   - Score selector: 5 tappable circles (1-5), color-coded
   - Fraud flag: 3 tappable options — None (green), Concern (yellow), Suspect (red)
   - Response quality quick chips: Detailed / Textbook / Vague / Wrong / No answer
   - Notes text area with auto-save
   - Navigation: Previous / Next buttons + keyboard arrow keys
   - Keyboard shortcuts: 1-5 for scoring, arrow keys for navigation
   - Skip Question button
   - Finish Round button → navigates to summary

4. **Interview Summary Screen** (`lib/screens/interview/interview_summary_screen.dart`):
   - Shows all questions with scores at a glance
   - Average score calculation
   - Overall impression ratings (Communication, Depth of Knowledge, Problem-Solving, Culture Fit)
   - Red flags and green flags text fields
   - Fraud assessment: Genuine / Some doubt / High suspicion
   - Recommendation: ADVANCE / HOLD / REJECT tappable cards
   - Save & Return to Candidate button — saves all data to server

5. **Technical Tab** (`lib/screens/candidate/tabs/technical_tab.dart`):
   - Shows "Start Technical Interview" button when no interview exists
   - Displays completed interview data:
     - Date, duration, recommendation badge
     - Average score, question count, fraud flag count
     - All question scores with notes and response quality
     - Overall impressions with score visualization
     - Red/green flags display
     - Fraud assessment display
   - "Run Another Interview" button

**Also Fixed:**
- Status badge colors updated per user requirements (New=yellow, Screening I-III=blues, Technical=orange, Assignment=magenta, In Review=cyan, Offered=green, Rejected=red, Hired=white)
- Phone/email in candidate header now clickable to copy
- Removed duplicate actions bar from profile tab (reject handled via status dropdown)

**Acceptance Criteria:**
- [x] Can browse question bank, filter by category/depth
- [x] Can select questions and start an interview session
- [x] Interview screen shows one question at a time with all input widgets
- [x] Timer runs and displays elapsed time
- [x] Fraud probe is hidden by default, togglable
- [x] Scores and notes auto-save per question
- [x] Can navigate between questions with buttons and keyboard
- [x] Post-interview summary shows all scores and accepts overall ratings
- [x] Recommendation saves and reflects on dashboard
- [x] Completed interview is viewable in candidate's Technical tab

---

### Phase 5: Assignment Round + Comparison View ✅ COMPLETE

**Goal:** Full assignment review flow and side-by-side candidate comparison.

**Status:** ✅ Completed on 2026-03-02

**What Was Built:**

1. **Assignment Provider** (`lib/providers/assignment_provider.dart`):
   - `AssignmentReviewNotifier` for state management with auto-save
   - Default scoring areas with weights (Code Quality 25%, Correctness 25%, Testing 20%, API Design 15%, DevOps 15%)
   - Methods for updating: status, dates, area scores, git check, fraud assessment, recommendation

2. **Assignment Tab** (`lib/screens/candidate/tabs/assignment_tab.dart`):
   - Header with status badge (Not Sent / Sent / Submitted / Reviewed)
   - Timeline section with date pickers for Sent, Due, and Submitted dates
   - On-time status toggle
   - Submission section with repo link input and copy/open buttons
   - Five scoring areas with:
     - Area name and weight badge (percentage)
     - ScoreSelector (1-5 tappable circles)
     - AutoSaveTextField for notes
   - Weighted score card showing calculated score prominently
   - Git history check section with commit pattern chips (Incremental / Bulk / Single) and suspicious toggle
   - Review call notes text area
   - Fraud assessment with three level buttons (Genuine / Some doubt / High suspicion)
   - Recommendation section with GradeSelector (HIRE / HOLD / REJECT cards)

3. **Compare Screen** (`lib/screens/compare/compare_screen.dart`):
   - Candidate selection view showing only Assignment/Final Review/Offer stage candidates
   - Checkbox selection UI (2-4 candidates limit)
   - Side-by-side comparison table with rows for:
     - Status
     - Technical Score (highlighted max)
     - Assignment Score (highlighted max)
     - Communication, Depth of Knowledge, Problem Solving, Culture Fit (all highlighted max)
     - Fraud Flags (highlighted min)
     - Expected CTC, Notice Period
     - Tech Recommendation, Assignment Recommendation (color-coded)
   - "View Details →" links to navigate to candidate detail pages
   - "Change Selection" button to go back to selection view

4. **Export Functionality**:
   - "Export Summary" button in comparison view app bar
   - Generates JSON file with all candidate details and metrics
   - Downloads via browser with timestamp in filename

**Acceptance Criteria:**
- [x] Assignment tab shows all scoring areas with weights
- [x] Weighted score auto-calculates as scores are entered
- [x] Git history and fraud assessment inputs work
- [x] Recommendation saves and reflects on dashboard
- [x] Comparison view shows 2-4 candidates side by side
- [x] Highest scores are visually highlighted
- [x] Export generates a downloadable JSON summary

---

## Post-Implementation Enhancements

Additional improvements made after Phase 5 completion:

**Screening Flow:**
- Competing offers question reduced to 3 options: "No offers", "Yes, but looking for better", "Has a better offer"
- Removed "Logistics confirmed" chips from phone screening section (Salary/Notice/On-site)
- Auto-status updates:
  - Copying screening email → sets status to `screening_sent`
  - Setting grade to STRONG → moves candidate to `pending_scheduling` stage (not directly to technical)
  - Setting grade to NO → shows rejection dialog and marks as `rejected`

**Pending Scheduling Status:**
- New status `pending_scheduling` added between screening and technical stages
- When a candidate passes screening (STRONG grade), they move to pending scheduling
- Technical tab shows "Schedule Technical Interview" message with a "Mark as Scheduled" button
- Once scheduled, candidate moves to `technical` status

**Technical Interview:**
- Selecting REJECT grade → marks candidate as `rejected` with reason "Failed technical interview"
- Dashboard technical column now shows grade badge (Advance/Hold/Reject) instead of numeric score
- Renamed "Recommendation" section to "Technical Grade" for consistency

**Assignment Review:**
- Renamed "Recommendation" section to "Assessment Grade" for consistency
- Selecting HIRE → moves candidate to `final_review` stage
- Selecting HOLD → keeps candidate in `assignment` stage
- Selecting REJECT → marks candidate as `rejected` with reason "Failed assignment review"

**Grading Terminology:**
- All phases now use consistent "Grade" terminology:
  - Screening Grade (STRONG/MAYBE/NO)
  - Technical Grade (ADVANCE/HOLD/REJECT)
  - Assessment Grade (HIRE/HOLD/REJECT)

**Dashboard:**
- Added refresh button to reload candidate data
- Swimlane header accent bar colors now match status badge colors:
  - Screening: Blue (#3498DB)
  - Technical: Yellow (#F1C40F)
  - Assignment: Purple (#9B59B6)
  - Final Review: Green (#2ECC71)

**UI Fixes:**
- Fixed grade selector icons to use Material Icons with proper outlined/filled states (was using text characters that rendered inconsistently)
- Status badge colors updated: Technical stage now uses yellow instead of orange

---

## Verification Checklist

End-to-end checks:

- [ ] Fresh start: delete data dir, restart server, sample data loads correctly
- [ ] Add a new candidate → screen them → mark as STRONG → verify "Pending Scheduling" status → mark as scheduled → run technical interview → advance to assignment → review assignment → compare with another candidate → hire
- [ ] All data persists across browser refreshes at every step
- [ ] No CORS errors in browser console
- [ ] Timer works correctly in interview session
- [ ] Resume PDFs open in new tab
- [ ] Screening email copies to clipboard with correct name
- [ ] Comparison view shows accurate scores
- [ ] Dashboard swimlane accent colors match status badge colors (Blue/Yellow/Purple/Green)
- [ ] All grading sections use consistent terminology (Screening Grade, Technical Grade, Assessment Grade)

# InterVue — Implementation Plan

## Quick Start (for continuing implementation)

```bash
# Terminal 1: Start the server
cd /Users/dan/Documents/intervue/server
dart run bin/server.dart --data-dir ~/intervue_data

# Terminal 2: Run Flutter web
cd /Users/dan/Documents/intervue
flutter run -d chrome
```

**Current Status:** Phase 3 ✅ Complete | **Next:** Phase 4 - Question Bank + Interview Session

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

7. **Placeholder Screens** (`lib/screens/`):
   - `dashboard/dashboard_screen.dart`
   - `candidate/candidate_detail_screen.dart`
   - `interview/question_bank_screen.dart`
   - `interview/interview_session_screen.dart`
   - `interview/interview_summary_screen.dart`
   - `compare/compare_screen.dart`

8. **Sample Data** (`sample_data/`):
   - `config.json` - App configuration with email templates
   - `questions/screening.json` - 10 screening questions with input types
   - `questions/technical.json` - 14 technical questions with fraud probes
   - `questions/general.json` - 12 general questions
   - `candidates/c_001_arjun_mehta/` - Status: technical, grade: strong
   - `candidates/c_002_priya_sharma/` - Status: screening_done, grade: maybe
   - `candidates/c_003_rahul_iyer/` - Status: assignment, has technical round data

9. **Scripts**:
   - `start.sh` - Launches server and Flutter web together

**Acceptance Criteria:**
- [x] `dart run bin/server.dart` starts without errors on port 3001
- [x] `flutter run -d chrome` opens the app without errors
- [x] `GET localhost:3001/api/candidates` returns sample candidate JSON
- [x] `GET localhost:3001/api/questions/technical` returns question bank JSON
- [x] No CORS errors in browser console
- [x] Theme applies correctly (dark background, Crimson accent, Jost font)
- [x] All routes navigate without errors (even if screens are empty)
- [x] `start.sh` launches both server and app

**To Start Fresh Session for Phase 2:**
```bash
# Terminal 1: Start server
cd server && dart run bin/server.dart --data-dir ~/intervue_data

# Terminal 2: Run Flutter web
flutter run -d chrome
```

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
   - `profile_tab.dart` — Full implementation with reject button
   - `screening_tab.dart` — Placeholder for Phase 3
   - `technical_tab.dart` — Placeholder for Phase 4
   - `assignment_tab.dart` — Placeholder for Phase 5

**Acceptance Criteria:**
- [x] Dashboard shows sample candidates in correct pipeline columns
- [x] Search filters candidates by name across all columns
- [x] Can add a new candidate with name, email, phone, resume
- [x] Candidate detail view shows all profile information
- [x] Resume PDF opens in a new browser tab
- [x] Status changes persist across page refreshes
- [x] Rejecting a candidate moves them to rejected pool with reason and timestamp

**Known Issue (to fix):** Browser back/forward navigation — need to use `context.push()` instead of `context.go()` for proper history support. See Critical Rule #9.

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

### Phase 4: Question Bank + Interview Session

**Goal:** The live interview experience works — select questions, run the interview, score in real-time.

**Tasks:**
1. Build Question Bank screen (see WIREFRAMES.md — Question Bank):
   - All questions from technical.json and general.json displayed
   - Grouped by category with collapsible sections
   - Each question shows: question text, "Assesses" tag, depth badge (Core/Nice-to-have)
   - Checkbox to select questions for an interview
   - Filter by: category, depth, tags
   - "Start Interview with N Selected" button → navigates to interview session
2. Build the Technical Interview Session screen (see WIREFRAMES.md — Interview Session):
   - **This is the most critical screen. Get it right.**
   - Top bar: candidate name, timer (auto-starts), question counter (Q3 of 7)
   - Question card: full question text, category badge
   - Fraud probe: collapsed by default, tap "Show Probe" to reveal, tap again to hide
   - Score selector: 5 tappable circles (1-5), highlighted on selection
   - Fraud flag: 3 tappable dots — green (none), yellow (some concern), red (strong suspicion)
   - Response quality quick chips: "Detailed + specific" / "Correct but textbook" / "Vague" / "Incorrect" / "No answer"
   - Notes text area: free text, auto-save on every keystroke (debounced 500ms)
   - Navigation: Previous / Next buttons, also keyboard arrows
   - "Skip Question" — marks as skipped, moves to next
   - "Finish Round" — shows summary with all scores, overall recommendation selector
3. Post-interview summary screen:
   - Shows all questions with scores at a glance
   - Overall impression ratings (Communication, Depth, Problem-Solving, Culture Fit) — each 1-5 tappable
   - Red flags and green flags: text fields
   - Fraud assessment: radio — "Genuine" / "Some doubt" / "High suspicion"
   - Recommendation: Three large tappable cards — ADVANCE / HOLD / REJECT
   - "Save & Return to Candidate" button
4. The interview data saves to the candidate's `technical.json` file
5. In Candidate Detail → Technical tab: show completed interview data in read-only view, with option to edit scores

**Acceptance Criteria:**
- [ ] Can browse question bank, filter by category/depth
- [ ] Can select questions and start an interview session
- [ ] Interview screen shows one question at a time with all input widgets
- [ ] Timer runs and displays elapsed time
- [ ] Fraud probe is hidden by default, togglable
- [ ] Scores and notes auto-save per question
- [ ] Can navigate between questions with buttons and keyboard
- [ ] Post-interview summary shows all scores and accepts overall ratings
- [ ] Recommendation saves and reflects on dashboard
- [ ] Completed interview is viewable in candidate's Technical tab

---

### Phase 5: Assignment Round + Comparison View

**Goal:** Full assignment review flow and side-by-side candidate comparison.

**Tasks:**
1. Build Assignment tab in Candidate Detail (see WIREFRAMES.md — Assignment Review):
   - Assignment status: "Not sent" / "Sent" / "Submitted" / "Reviewed"
   - "Mark as Sent" button with date picker
   - Submission details: repo link (text field), on-time toggle, submission date
   - Five scoring areas, each with:
     - Area name and weight shown
     - Score: 1-5 tappable circles
     - Notes: text field
   - Auto-calculated weighted score displayed prominently
   - Git history check: commit pattern radio ("Incremental" / "1-2 bulk commits" / "Single commit"), suspicious toggle
   - Review call notes: text area
   - Fraud assessment: same as technical round
   - Recommendation: HIRE / HOLD / REJECT tappable cards
2. Build Comparison View screen (see WIREFRAMES.md — Comparison):
   - Select 2-4 candidates from a list (only those in Assignment or Final Review stage)
   - Side-by-side table showing:
     - Technical round average score
     - Assignment weighted score
     - Individual dimension scores (communication, depth, etc.)
     - Fraud flags count
     - CTC expected
     - Notice period
     - Overall recommendation from each round
   - Highlight the highest score in each row
   - "View Details" link for each candidate
3. Build a simple export function:
   - "Export Summary" button on comparison view
   - Generates a JSON file with all compared candidates' data
   - Downloads via browser

**Acceptance Criteria:**
- [ ] Assignment tab shows all scoring areas with weights
- [ ] Weighted score auto-calculates as scores are entered
- [ ] Git history and fraud assessment inputs work
- [ ] Recommendation saves and reflects on dashboard
- [ ] Comparison view shows 2-4 candidates side by side
- [ ] Highest scores are visually highlighted
- [ ] Export generates a downloadable JSON summary

---

### Phase 6: Polish + Quality of Life

**Goal:** The app feels smooth and complete for daily use.

**Tasks:**
1. Add the "Saved ✓" / "Saving..." indicator in the top bar (global)
2. Implement keyboard shortcuts:
   - In interview session: `1-5` keys for score, `N` to focus notes, `→` next question, `←` previous
   - Global: `Cmd+K` or `/` for search
3. Add toast notifications for actions (candidate added, status changed, email copied)
4. Add empty states for all screens (no candidates yet, no interviews yet, etc.)
5. Add loading states (skeleton cards on dashboard while data loads)
6. Refine the screening email copy — support "Copy All" and "Copy Individual Question"
7. Add candidate count badges on pipeline columns
8. Add a "Quick Add" floating action button on dashboard
9. Smooth all transitions and animations (page transitions, card hover states, panel slides)
10. Test all auto-save paths — verify no data loss on browser refresh mid-interview
11. Responsive layout: app should work at 1024px+ width. Show a "Best viewed on desktop" message below 1024px
12. Error handling: show user-friendly error if server is not running

**Acceptance Criteria:**
- [ ] Save indicator shows on every auto-save
- [ ] Keyboard shortcuts work in interview session
- [ ] Toast notifications appear for key actions
- [ ] Empty states show helpful messages (not blank screens)
- [ ] Loading skeletons show while data loads
- [ ] No data loss on browser refresh during any flow
- [ ] App is usable at 1024px width
- [ ] Clear error message if server is unreachable

---

## Completion Checklist

After all phases, verify end-to-end:

- [ ] Fresh start: delete data dir, restart server, sample data loads correctly
- [ ] Add a new candidate → screen them → advance to technical → run interview → advance to assignment → review assignment → compare with another candidate → hire
- [ ] All data persists across browser refreshes at every step
- [ ] No CORS errors in browser console
- [ ] Timer works correctly in interview session
- [ ] Resume PDFs open in new tab
- [ ] Screening email copies to clipboard with correct name
- [ ] Comparison view shows accurate scores

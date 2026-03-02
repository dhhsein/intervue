# InterVue — Wireframes

All screens use dark theme. See DESIGN_SYSTEM.md for exact colors and typography.

---

## Screen 1: Dashboard (Home)

The primary view. Shows the entire pipeline at a glance.

```
┌──────────────────────────────────────────────────────────────────┐
│  ▪ InterVue                   [🔍 Search candidates...]   Saved ✓│
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Pipeline Overview                              [+ Add Candidate]│
│                                                                  │
│  ┌─ Screening (12) ─┐  ┌─ Technical (5) ──┐  ┌─ Assignment (3)─┐│
│  │                   │  │                  │  │                  ││
│  │ ┌───────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐││
│  │ │ Arjun Mehta   │ │  │ │ Priya Sharma │ │  │ │ Kavitha R    │││
│  │ │ ★ Strong      │ │  │ │ Score: 4.2   │ │  │ │ Score: 3.8   │││
│  │ │ ₹12L → ₹18L  │ │  │ │ 2 days ago   │ │  │ │ Submitted ✓  │││
│  │ └───────────────┘ │  │ └──────────────┘ │  │ └──────────────┘││
│  │ ┌───────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐││
│  │ │ Ravi Kumar    │ │  │ │ Mohan P      │ │  │ │ Sai T        │││
│  │ │ ○ Maybe       │ │  │ │ Score: 3.5   │ │  │ │ Pending...   │││
│  │ │ ₹8L → ₹14L   │ │  │ │ 1 day ago    │ │  │ │ 36hrs left   │││
│  │ └───────────────┘ │  │ └──────────────┘ │  │ └──────────────┘││
│  │ ┌───────────────┐ │  │                  │  │                  ││
│  │ │ Neha S        │ │  │  ...+3 more      │  │  ...+1 more     ││
│  │ │ ✕ No          │ │  │                  │  │                  ││
│  │ │ ₹15L → ₹25L  │ │  │                  │  │                  ││
│  │ └───────────────┘ │  │                  │  │                  ││
│  │                   │  │                  │  │                  ││
│  │  ...+9 more       │  │                  │  │                  ││
│  └───────────────────┘  └──────────────────┘  └──────────────────┘│
│                                                                  │
│  ┌─ Final Review (1)─┐                                           │
│  │ ┌──────────────┐  │    Rejected: 14    Hired: 0               │
│  │ │ Deepa K      │  │                                           │
│  │ │ Tech: 4.5    │  │    [Compare Finalists]                    │
│  │ │ Assign: 4.2  │  │                                           │
│  │ └──────────────┘  │                                           │
│  └───────────────────┘                                           │
└──────────────────────────────────────────────────────────────────┘
```

**Interactions:**
- Tap any candidate card → opens Candidate Detail
- Search bar filters all columns in real-time (by name)
- "+ Add Candidate" opens a slide-over panel from the right
- Pipeline columns scroll vertically if they overflow
- Candidate cards show contextual info based on their stage

**Candidate Card Variants by Stage:**
- Screening: Name, screening grade badge, CTC range
- Technical: Name, tech score, days since interview
- Assignment: Name, assignment score or "Pending" with time remaining
- Final Review: Name, tech score, assignment score

---

## Screen 2: Candidate Detail

Tabbed view with all candidate data. This is where you spend most time outside of active interviews.

```
┌──────────────────────────────────────────────────────────────────┐
│  ▪ InterVue                   [🔍 Search candidates...]   Saved ✓│
├──────────────────────────────────────────────────────────────────┤
│  ← Dashboard                                                    │
│                                                                  │
│  Arjun Mehta                                   Status: [Technical ▼]│
│  arjun.mehta@email.com  ·  +91-98765-43210  ·  [📄 Resume]      │
│                                                                  │
│  [Profile]  [Screening]  [Technical]  [Assignment]               │
│  ────────────────────────────────────────────────────────────    │
│                                                                  │
│  ┌─ PROFILE TAB ─────────────────────────────────────────────┐   │
│  │                                                           │   │
│  │  Contact          arjun.mehta@email.com                   │   │
│  │                   +91-98765-43210                          │   │
│  │                                                           │   │
│  │  Compensation     Current: ₹12 LPA    Expected: ₹18 LPA  │   │
│  │                                                           │   │
│  │  Notice Period    30 days (Negotiable)                    │   │
│  │                                                           │   │
│  │  Location         Chennai — no relocation needed          │   │
│  │                                                           │   │
│  │  Standing Offers  Has offer, unlikely to take             │   │
│  │                                                           │   │
│  │  Switch Reason    Growth · Domain interest                │   │
│  │                                                           │   │
│  │  Timeline                                                 │   │
│  │  • Added: Mar 1, 2025                                     │   │
│  │  • Screening completed: Mar 3                             │   │
│  │  • Technical round: Mar 6                                 │   │
│  │  • Advanced to assignment: Mar 6                          │   │
│  │                                                           │   │
│  │  [Reject Candidate ▼]                                     │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Screen 3: Screening Tab

Inside Candidate Detail. UI-friendly inputs for all 10 screening questions.

```
┌──────────────────────────────────────────────────────────────────┐
│  [Profile]  [Screening]  [Technical]  [Assignment]               │
│  ────────────────────────────────────────────────────────────    │
│                                                                  │
│  Screening                     [📋 Copy Screening Email]         │
│  Email sent: Mar 1  ·  Response: Mar 2  ·  Phone screen: Mar 3  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ Q1. Still actively exploring opportunities?               │   │
│  │                                                           │   │
│  │ [Yes, actively looking]  [Open but passive]  [Not sure]   │   │
│  │                                                           │   │
│  │ Notes: ____________________________________________       │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ Q2. On-site at IIT Madras, Chennai works?                 │   │
│  │                                                           │   │
│  │ [Already in Chennai] [Will relocate] [Needs discussion]   │   │
│  │ [Cannot relocate]                                         │   │
│  │                                                           │   │
│  │ Notes: ____________________________________________       │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ Q3. Compensation                                          │   │
│  │                                                           │   │
│  │ Current CTC:  [₹ _______ LPA]                            │   │
│  │ Expected CTC: [₹ _______ LPA]                            │   │
│  │                                                           │   │
│  │ Notes: ____________________________________________       │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ Q9. Tech experience                                       │   │
│  │                                                           │   │
│  │ FastAPI:     [None] [Basic] [Intermediate] [Advanced]     │   │
│  │ SQLAlchemy:  [None] [Basic] [Intermediate] [Advanced]     │   │
│  │ Docker:      [None] [Basic] [Intermediate] [Advanced]     │   │
│  │ Kubernetes:  [None] [Basic] [Intermediate] [Advanced]     │   │
│  │ Terraform:   [None] [Basic] [Intermediate] [Advanced]     │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ...more questions...                                            │
│                                                                  │
│  ── Screening Grade ──────────────────────────────────────────   │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │  STRONG  │  │  MAYBE   │  │    NO    │                       │
│  │    ★     │  │    ○     │  │    ✕     │                       │
│  │  (green) │  │  (amber) │  │   (red)  │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
│                                                                  │
│  ── Phone Screen (optional) ──────────────────────────────────   │
│                                                                  │
│  Phone screen conducted?  [Yes] [No]                             │
│                                                                  │
│  Communication:  ① ② ③ ④ ⑤                                      │
│  Logistics OK?   [Salary ✓] [Notice ✓] [On-site ✓]              │
│  Notes: ___________________________________________________     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Screen 4: Question Bank

Browse and select questions before starting an interview.

```
┌──────────────────────────────────────────────────────────────────┐
│  ▪ InterVue                   [🔍 Search candidates...]   Saved ✓│
├──────────────────────────────────────────────────────────────────┤
│  ← Arjun Mehta                                                   │
│                                                                  │
│  Question Bank              Selecting for: Arjun Mehta           │
│  Selected: 6 questions                                           │
│                                                                  │
│  Filter: [All ▼]  [Core only]  [Nice-to-have only]              │
│                                                                  │
│  ── Python Fundamentals & Design (4) ────────────────────────    │
│                                                                  │
│  ☑ ┌─────────────────────────────────────────────────────┐       │
│    │ FastAPI endpoint design + LLM timeout                │       │
│    │ Walk me through how you would design a FastAPI       │       │
│    │ endpoint that accepts a workout plan request...      │       │
│    │                                                      │       │
│    │ Assesses: System design, Pydantic, async, errors     │       │
│    │ [Core]                                               │       │
│    └──────────────────────────────────────────────────────┘       │
│                                                                  │
│  ☑ ┌─────────────────────────────────────────────────────┐       │
│    │ Sync vs async in FastAPI                             │       │
│    │ Explain the difference between sync and async...     │       │
│    │                                                      │       │
│    │ Assesses: Async/await, event loop, debugging         │       │
│    │ [Core]                                               │       │
│    └──────────────────────────────────────────────────────┘       │
│                                                                  │
│  ☐ ┌─────────────────────────────────────────────────────┐       │
│    │ Database migration strategy                          │       │
│    │ You need to add a new field to an existing table...  │       │
│    │ [Core]                                               │       │
│    └──────────────────────────────────────────────────────┘       │
│                                                                  │
│  ── Auth & Security (2) ─────────────────────────────────────    │
│  ...                                                             │
│                                                                  │
│  ── General Problem-Solving (12) ────────────────────────────    │
│  ...                                                             │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │            [▶ Start Interview with 6 Questions]          │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Screen 5: Technical Interview Session (MOST CRITICAL SCREEN)

This is open during a live call. Every pixel matters for speed.

```
┌──────────────────────────────────────────────────────────────────┐
│  Arjun Mehta — Technical Round        ⏱ 00:34:12     Q 3 of 6   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Auth & Security                                                 │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                                                          │    │
│  │  Our system uses Keycloak for internal APIs and Auth0    │    │
│  │  for mobile APIs, both issuing JWTs. How would you       │    │
│  │  design a middleware that handles both? What happens      │    │
│  │  when a token is expired but the user's session should   │    │
│  │  still be valid?                                         │    │
│  │                                                          │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
│  [▶ Show Fraud Probe]                                            │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐   │
│  │ Ask: "Have you implemented JWT validation from scratch?   │   │
│  │ What claims did you validate beyond expiry?" Drill into   │   │
│  │ RS256 vs HS256. Real implementers know the JWKS dance.    │   │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘   │
│                                                                  │
│  Score          ① ② ③ ④ ⑤                                       │
│                                                                  │
│  Fraud          🟢 None    🟡 Concern    🔴 Suspect               │
│                                                                  │
│  Response       [Detailed] [Textbook] [Vague] [Wrong] [No ans]  │
│                                                                  │
│  Notes                                                           │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ Knew RS256 well. Mentioned JWKS caching and key          │    │
│  │ rotation. Couldn't explain refresh token flow clearly.   │    │
│  │ ▊                                                        │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
│  [← Previous]    [Skip]    [Next →]          [Finish Round]      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Critical interactions:**
- Score circles: single tap to select, tap again to deselect
- Fraud dots: single tap, only one active (default: green)
- Response quality: single-select chips
- Fraud probe: collapsed by default. "Show Fraud Probe" toggles visibility with smooth animation. Text area has subtle different background (accentSoft) when visible.
- Notes: auto-save on every keystroke (debounced 500ms)
- Navigation: Previous/Next buttons AND keyboard ←/→ arrows
- Timer: runs continuously, shown in accent color (Crimson)
- "Finish Round" → goes to post-interview summary

---

## Screen 6: Post-Interview Summary

Shown after clicking "Finish Round" in the interview session.

```
┌──────────────────────────────────────────────────────────────────┐
│  Interview Summary — Arjun Mehta           Duration: 00:47:23    │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ── Questions ────────────────────────────────────────────────   │
│                                                                  │
│  1. FastAPI endpoint design           Score: ④   Flag: 🟢       │
│  2. Sync vs async                     Score: ③   Flag: 🟢       │
│  3. JWT middleware design             Score: ④   Flag: 🟡       │
│  4. Webhook idempotency              Score: ⑤   Flag: 🟢       │
│  5. Testing strategy                  Score: ④   Flag: 🟢       │
│  6. 500 error debugging (general)     Score: ④   Flag: 🟢       │
│                                                                  │
│  Average: 4.0 / 5                                                │
│                                                                  │
│  ── Overall Impressions ──────────────────────────────────────   │
│                                                                  │
│  Communication      ① ② ③ ④ ⑤                                   │
│  Depth of Knowledge ① ② ③ ④ ⑤                                   │
│  Problem-Solving    ① ② ③ ④ ⑤                                   │
│  Culture Fit        ① ② ③ ④ ⑤                                   │
│                                                                  │
│  Red Flags   _______________________________________________     │
│  Green Flags _______________________________________________     │
│                                                                  │
│  ── Fraud Assessment ─────────────────────────────────────────   │
│                                                                  │
│  [All genuine]   [Some doubt — explain below]   [High suspicion] │
│  Notes: ___________________________________________________     │
│                                                                  │
│  ── Recommendation ───────────────────────────────────────────   │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ ADVANCE  │  │   HOLD   │  │  REJECT  │                       │
│  │    ▶     │  │    ⏸     │  │    ✕     │                       │
│  │  (green) │  │  (amber) │  │   (red)  │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
│                                                                  │
│  [Save & Return to Candidate]                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Screen 7: Assignment Review Tab

Inside Candidate Detail, Assignment tab.

```
┌──────────────────────────────────────────────────────────────────┐
│  [Profile]  [Screening]  [Technical]  [Assignment]               │
│  ────────────────────────────────────────────────────────────    │
│                                                                  │
│  Assignment Review                    Status: [Submitted ▼]      │
│  Sent: Mar 8  ·  Due: Mar 10  ·  Submitted: Mar 9 (on time ✓)  │
│  Repo: [github.com/arjun/workout-api ↗]                         │
│                                                                  │
│  ── Scoring ──────────────────────────────────────────────────   │
│                                                                  │
│  Code Quality (25%)        ① ② ③ ④ ⑤                            │
│  Notes: ___________________________________________________     │
│                                                                  │
│  Correctness (25%)         ① ② ③ ④ ⑤                            │
│  Notes: ___________________________________________________     │
│                                                                  │
│  Testing (20%)             ① ② ③ ④ ⑤                            │
│  Notes: ___________________________________________________     │
│                                                                  │
│  API Design (15%)          ① ② ③ ④ ⑤                            │
│  Notes: ___________________________________________________     │
│                                                                  │
│  DevOps (15%)              ① ② ③ ④ ⑤                            │
│  Notes: ___________________________________________________     │
│                                                                  │
│  ┌──────────────────────┐                                        │
│  │ Weighted Score: 3.8  │                                        │
│  └──────────────────────┘                                        │
│                                                                  │
│  ── Git History ──────────────────────────────────────────────   │
│  Commit pattern: [Incremental] [Bulk] [Single commit]            │
│  Suspicious?     [No] [Yes]                                      │
│                                                                  │
│  ── Review Call ──────────────────────────────────────────────   │
│  Notes: ___________________________________________________     │
│                                                                  │
│  ── Recommendation ───────────────────────────────────────────   │
│  [HIRE]  [HOLD]  [REJECT]                                        │
└──────────────────────────────────────────────────────────────────┘
```

---

## Screen 8: Comparison View

Side-by-side comparison of finalists.

```
┌──────────────────────────────────────────────────────────────────┐
│  ▪ InterVue                                              Saved ✓ │
├──────────────────────────────────────────────────────────────────┤
│  ← Dashboard                                                     │
│                                                                  │
│  Compare Candidates                                              │
│  Select candidates to compare:                                   │
│  [☑ Priya S] [☑ Kavitha R] [☑ Sai T] [☐ Deepa K]               │
│                                                                  │
│  ┌─────────────────┬──────────┬──────────┬──────────┐            │
│  │                 │ Priya S  │ Kavitha R│  Sai T   │            │
│  ├─────────────────┼──────────┼──────────┼──────────┤            │
│  │ Tech Score      │  ★ 4.2   │   3.8    │   4.0    │            │
│  │ Assignment      │   4.1    │  ★ 4.5   │   3.6    │            │
│  │ Communication   │  ★ 5     │   3      │   4      │            │
│  │ Depth           │  ★ 4     │  ★ 4     │   3      │            │
│  │ Problem-Solving │   4      │  ★ 5     │   4      │            │
│  │ Culture Fit     │  ★ 5     │   4      │   3      │            │
│  │ Fraud Flags     │  ★ 0     │  ★ 0     │   1 🟡   │            │
│  ├─────────────────┼──────────┼──────────┼──────────┤            │
│  │ Expected CTC    │  ₹18L    │  ₹15L    │  ₹20L    │            │
│  │ Notice Period   │  30d     │  60d     │  45d     │            │
│  │ Tech Rec        │ Advance  │ Advance  │  Hold    │            │
│  │ Assign Rec      │  Hire    │  Hire    │  Hold    │            │
│  ├─────────────────┼──────────┼──────────┼──────────┤            │
│  │ Weighted Avg    │  ★ 4.3   │   4.1    │   3.7    │            │
│  └─────────────────┴──────────┴──────────┴──────────┘            │
│                                                                  │
│  ★ = highest in row                                              │
│                                                                  │
│  [View Priya] [View Kavitha] [View Sai]    [Export JSON]         │
└──────────────────────────────────────────────────────────────────┘
```

---

## Add Candidate Panel

Slides in from the right over the dashboard. Not a full screen.

```
                              ┌───────────────────────────┐
                              │  Add Candidate         ✕  │
                              │                           │
                              │  Name *                   │
                              │  [________________________]│
                              │                           │
                              │  Email *                  │
                              │  [________________________]│
                              │                           │
                              │  Phone                    │
                              │  [________________________]│
                              │                           │
                              │  Resume                   │
                              │  [📎 Upload PDF]           │
                              │  resume_arjun.pdf ✓       │
                              │                           │
                              │                           │
                              │  [Add Candidate]          │
                              └───────────────────────────┘
```

- Width: 400px
- Overlay dims the background
- Escape key or clicking outside closes it
- Only name and email are required

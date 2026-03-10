# Assignment Evaluation Prompt Template
### FastAPI Webhook Service — AI-Assisted Code Review

Copy the prompt below into Claude (or any LLM with web browsing / long context).
Replace `{{REPO_URL}}` with the candidate's public GitHub repository link.

---

## Prompt

```
You are a senior backend engineer conducting a code review of a take-home assignment.

## Assignment Brief

The candidate was asked to build a **FastAPI webhook ingestion service** that:
- Accepts incoming webhook payloads via a POST endpoint
- Validates payloads using Pydantic models
- Stores session data in a relational database (SQLite or PostgreSQL)
- Handles duplicate/idempotent webhook deliveries
- Provides a GET endpoint with pagination to retrieve stored sessions
- Includes a Dockerfile for containerized deployment
- Includes tests

## Repository to Review

{{REPO_URL}}

Fetch and analyze ALL files in this public GitHub repository. Examine:
- All Python source files
- Tests
- Dockerfile and docker-compose.yml (if present)
- README and any documentation
- requirements.txt / pyproject.toml / setup.cfg
- Git commit history (commit messages, frequency, patterns)

## Evaluation Instructions

Evaluate the submission across the following areas. For each **scored area**, provide:
- A score from 1 to 5 (1 = poor, 2 = below average, 3 = adequate, 4 = good, 5 = excellent)
- Specific observations with file/line references where possible

For **supplementary areas**, provide detailed qualitative notes only (no numeric score).

---

### SCORED AREAS (these carry weight in final assessment)

#### 1. Code Quality (weight: 25%)
- Clean, idiomatic Python — follows PEP 8 and project conventions
- Meaningful variable/function/class naming
- DRY principle — no unnecessary repetition
- Appropriate use of type hints
- Logical function/method decomposition

#### 2. Correctness (weight: 25%)
- Does the POST endpoint correctly ingest and store webhook payloads?
- Does idempotency handling actually work (unique constraints, pre-check, or both)?
- Does the GET endpoint return paginated results correctly?
- Are edge cases handled (empty payloads, missing fields, malformed JSON)?
- Does the application start and run without errors?

#### 3. Testing (weight: 20%)
- Are there meaningful tests (not just smoke tests)?
- Do tests cover happy path AND edge cases (duplicates, bad payloads, pagination boundaries)?
- Is test setup clean (fixtures, test database, teardown)?
- Test isolation — do tests depend on each other or on external state?
- Are there integration tests for the API endpoints?

#### 4. API Design (weight: 15%)
- Correct HTTP methods and status codes (201 for creation, 409 or 200 for duplicates, 422 for validation errors)
- RESTful URL structure
- Consistent response format (envelope, error schema)
- Pagination implementation (offset vs cursor, consistency under inserts)
- Input validation error messages are clear and actionable

#### 5. DevOps (weight: 15%)
- Dockerfile present and functional
- Efficient layer ordering (requirements before code copy)
- Non-root user in container
- docker-compose.yml for local development (if applicable)
- Environment variable configuration (not hardcoded secrets)
- .dockerignore present

---

### SUPPLEMENTARY AREAS (qualitative notes, no score)

#### 6. Error Handling & Resilience
- How does the app behave when the database is unavailable?
- Are exceptions caught and returned as appropriate HTTP errors (not 500s)?
- Is there any retry logic or graceful degradation?
- Are errors logged with useful context?

#### 7. Security Practices
- Is user input validated before database operations?
- Are SQL queries parameterized (or ORM-managed)?
- Are secrets/credentials hardcoded anywhere?
- Are dependencies pinned and free of known vulnerabilities?
- Is there any authentication/authorization (even if simple)?

#### 8. Documentation & Readability
- README explains how to run the project, run tests, and make API calls
- Code is self-documenting with clear naming
- Docstrings on non-obvious functions
- API documentation (OpenAPI/Swagger auto-generated is fine)

#### 9. Project Structure & Organization
- Logical folder layout (routes, models, services, tests separated)
- Separation of concerns (business logic not in route handlers)
- Configuration management (settings file, env vars)
- Clean dependency management (requirements.txt or pyproject.toml)

---

### GIT HISTORY ANALYSIS

Analyze the repository's commit history and report:
- **commitPattern**: One of "incremental" (many small, logical commits over time), "bulk" (a few large commits), or "single" (one or two commits with all code)
- **suspicious**: true/false — Flag as suspicious if:
  - All commits within a very short window (< 1 hour) despite significant code
  - Commit messages are generic ("update", "fix", "changes") throughout
  - Large blocks of code appear fully formed with no iteration
  - Code style/quality varies dramatically between files (suggesting multiple authors)
- **notes**: Specific observations about commit patterns, timing, and quality

---

### FRAUD ASSESSMENT

Evaluate the likelihood that the candidate genuinely wrote this code:
- **level**: One of "genuine", "some_doubt", or "high_suspicion"
- **notes**: Explain your reasoning. Look for:
  - Inconsistent coding style across files (mix of experienced and novice patterns)
  - Unusually perfect or boilerplate-heavy code with no personal style
  - Comments that look AI-generated (overly formal, explaining obvious things)
  - Test code quality dramatically different from application code quality
  - README quality mismatched with code quality
  - Copy-paste artifacts (leftover template comments, unrelated code)

---

### CANDIDATE-SPECIFIC DEBRIEF QUESTIONS

Based on the actual code in this repository, generate 5 targeted questions for a live debrief call. Each question should:
- Reference specific files, functions, or design decisions in their code
- Test whether the candidate truly understands what they wrote
- Include "what to look for" in a good answer and "red flags" for a bad answer
- Cover different aspects (architecture decisions, error handling, trade-offs, scaling)

Format each question with:
- The question text
- **What to look for**: What a genuine author would say
- **Red flags**: Signs they didn't write or understand the code

---

## OUTPUT FORMAT

Return your evaluation as a single JSON object with this exact structure:

```json
{
  "areaScores": {
    "code_quality": {
      "areaId": "code_quality",
      "displayName": "Code Quality",
      "weight": 25,
      "score": <1-5>,
      "notes": "<detailed observations with file references>"
    },
    "correctness": {
      "areaId": "correctness",
      "displayName": "Correctness",
      "weight": 25,
      "score": <1-5>,
      "notes": "<detailed observations>"
    },
    "testing": {
      "areaId": "testing",
      "displayName": "Testing",
      "weight": 20,
      "score": <1-5>,
      "notes": "<detailed observations>"
    },
    "api_design": {
      "areaId": "api_design",
      "displayName": "API Design",
      "weight": 15,
      "score": <1-5>,
      "notes": "<detailed observations>"
    },
    "devops": {
      "areaId": "devops",
      "displayName": "DevOps",
      "weight": 15,
      "score": <1-5>,
      "notes": "<detailed observations>"
    }
  },
  "supplementaryAnalysis": {
    "errorHandling": "<qualitative notes on error handling & resilience>",
    "security": "<qualitative notes on security practices>",
    "documentation": "<qualitative notes on documentation & readability>",
    "projectStructure": "<qualitative notes on project structure & organization>"
  },
  "gitCheck": {
    "commitPattern": "<incremental|bulk|single>",
    "suspicious": <true|false>,
    "notes": "<specific observations about commit history>"
  },
  "fraudAssessment": {
    "level": "<genuine|some_doubt|high_suspicion>",
    "notes": "<reasoning with specific evidence>"
  },
  "debriefQuestions": [
    {
      "question": "<question referencing their specific code>",
      "whatToLookFor": "<what a genuine author would say>",
      "redFlags": "<signs they didn't write it>"
    }
  ],
  "recommendation": "<strong_yes|yes|maybe|no|strong_no>",
  "recommendationReasoning": "<2-3 sentence justification>",
  "weightedScore": <calculated weighted average as float>
}
```

IMPORTANT:
- Be rigorous but fair. A "3" is a passing score — average, meets requirements.
- Only give a 5 for genuinely impressive work that goes beyond expectations.
- Only give a 1 for fundamentally broken or missing functionality.
- Reference specific files and code patterns in your notes.
- The supplementary analysis notes should be detailed enough to inform a debrief conversation.
- Debrief questions MUST reference actual code from the repository, not generic questions.
```

---

## How to Use

1. Copy the prompt above
2. Replace `{{REPO_URL}}` with the candidate's GitHub repository URL
3. Paste into Claude (or any LLM that can browse URLs / handle large context)
4. Copy the JSON output
5. Use the JSON to fill in the assignment review fields in InterVue:
   - `areaScores` → maps directly to the 5 scoring areas in the UI
   - `gitCheck` → maps to the Git History Check section
   - `fraudAssessment` → maps to the Fraud Assessment section
   - `recommendation` → maps to the final recommendation dropdown
   - `debriefQuestions` → use these during the live debrief call
   - `supplementaryAnalysis` → paste relevant parts into area notes for additional context

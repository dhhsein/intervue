# InterVue — API Specification (Local Dart Server)

## Server Setup

- **Runtime:** Dart (shelf + shelf_router)
- **Port:** 3001 (configurable via `--port` flag)
- **Data directory:** `~/intervue_data/` (configurable via `--data-dir` flag)
- **CORS:** Required from day one (see GOTCHAS.md)

### Startup

```bash
dart run bin/server.dart [--port 3001] [--data-dir ~/intervue_data]
```

### First Run Behavior

If the data directory does not exist or is empty:
1. Create the directory structure
2. Copy all files from `sample_data/` into the data directory
3. Log: "Initialized data directory with sample data at ~/intervue_data/"

---

## CORS Middleware (MUST be first in pipeline)

```dart
import 'package:shelf/shelf.dart';

Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await handler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};
```

---

## Endpoints

### Candidates

#### `GET /api/candidates`
Returns all candidates (summary only, not full nested data).

**Response 200:**
```json
{
  "candidates": [
    {
      "id": "c_20250301_arjun_mehta",
      "name": "Arjun Mehta",
      "email": "arjun@email.com",
      "phone": "+91-98765-43210",
      "status": "technical",
      "resumePath": "candidates/c_20250301_arjun_mehta/resume.pdf",
      "createdAt": "2025-03-01T10:00:00Z",
      "updatedAt": "2025-03-06T14:30:00Z",
      "screeningGrade": "strong",
      "technicalScore": 4.2,
      "assignmentScore": null,
      "timeline": [...]
    }
  ]
}
```

**Implementation:** Read all `candidate.json` files from `candidates/*/`. For each, optionally read `technical.json` and `assignment.json` to populate scores.

#### `GET /api/candidates/:id`
Returns full candidate data including screening, technical, and assignment data.

**Response 200:**
```json
{
  "candidate": { ... },
  "screening": { ... },
  "technical": { ... },
  "assignment": { ... }
}
```

**Implementation:** Read all JSON files from the candidate's folder.

#### `POST /api/candidates`
Creates a new candidate.

**Request body:**
```json
{
  "name": "Arjun Mehta",
  "email": "arjun@email.com",
  "phone": "+91-98765-43210"
}
```

**Implementation:**
1. Generate ID: `c_${yyyyMMdd}_${name_snake_case}`
2. Create folder: `candidates/{id}/`
3. Write `candidate.json`
4. Return the created candidate

**Response 201:** Created candidate JSON

#### `PUT /api/candidates/:id`
Updates candidate data. Accepts partial updates.

**Request body:** Any subset of candidate fields.

**Implementation:** Read existing `candidate.json`, merge with request body, write back. Update `updatedAt`. If `status` changed, append to `timeline`.

**Response 200:** Updated candidate JSON

#### `DELETE /api/candidates/:id`
Deletes a candidate and their folder.

**Response 204:** No content

---

### Screening

#### `GET /api/candidates/:id/screening`
**Response 200:** ScreeningData JSON or `{"screening": null}` if not started.

#### `PUT /api/candidates/:id/screening`
Creates or updates screening data.

**Request body:** Full or partial ScreeningData JSON.

**Implementation:** Read existing `screening.json` (or create new), merge, write back. Update candidate's `updatedAt`.

**Response 200:** Updated ScreeningData JSON

---

### Technical Round

#### `GET /api/candidates/:id/technical`
**Response 200:** TechnicalRound JSON or `{"technical": null}`.

#### `PUT /api/candidates/:id/technical`
Creates or updates technical round data.

**Request body:** Full or partial TechnicalRound JSON.

**Implementation:** Read existing `technical.json` (or create new), merge, write back.

**Response 200:** Updated TechnicalRound JSON

---

### Assignment

#### `GET /api/candidates/:id/assignment`
**Response 200:** AssignmentReview JSON or `{"assignment": null}`.

#### `PUT /api/candidates/:id/assignment`
Creates or updates assignment review data.

**Request body:** Full or partial AssignmentReview JSON.

**Response 200:** Updated AssignmentReview JSON

---

### Questions

#### `GET /api/questions/:bank`
Returns questions from a specific bank.

**Parameters:**
- `:bank` — one of: `screening`, `technical`, `general`

**Response 200:**
```json
{
  "questions": [
    {
      "id": "tech_python_01",
      "category": "Python Fundamentals & Design",
      "question": "Walk me through how you would design...",
      "assesses": "System design thinking, Pydantic modeling...",
      "fraudProbe": "Ask them to draw/write the Pydantic models...",
      "depth": "core",
      "tags": ["python", "fastapi", "system-design"],
      "bank": "technical"
    }
  ]
}
```

**Implementation:** Read from `questions/{bank}.json`.

---

### Files

#### `POST /api/candidates/:id/resume`
Upload a resume PDF.

**Request:** Multipart form data with file field `resume`.

**Implementation:**
1. Save file to `candidates/{id}/resume.pdf`
2. Update `candidate.json` with `resumePath`

**Response 200:**
```json
{
  "path": "candidates/c_20250301_arjun_mehta/resume.pdf"
}
```

#### `GET /api/files/:path`
Serve any file from the data directory. Used for resume PDFs.

**Example:** `GET /api/files/candidates/c_20250301_arjun_mehta/resume.pdf`

**Implementation:** Resolve path relative to data directory. Serve with correct Content-Type. **Validate that the resolved path is still within the data directory** (prevent path traversal).

**Response 200:** File content with appropriate Content-Type header.

---

### Config

#### `GET /api/config`
Returns app configuration (interviewer name, email templates, etc.)

**Response 200:**
```json
{
  "interviewerName": "Your Name",
  "companyName": "Acrophase",
  "emailTemplate": "Hi {name},\n\nThank you for your interest..."
}
```

#### `PUT /api/config`
Updates app configuration.

---

## Error Responses

All errors follow this format:

```json
{
  "error": "Candidate not found",
  "code": "NOT_FOUND"
}
```

HTTP status codes:
- 200: Success
- 201: Created
- 204: Deleted (no body)
- 400: Bad request (invalid JSON, missing required fields)
- 404: Not found
- 500: Server error

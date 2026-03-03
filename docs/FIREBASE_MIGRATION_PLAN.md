# Firebase Migration Plan — InterVue

## Summary

Migrate InterVue from a locally-hosted Flutter + Dart/Shelf server architecture to a fully cloud-based Firebase stack. The Dart backend server and local JSON file storage will be eliminated entirely. The Flutter web app will talk directly to Firebase services using client SDKs.

**Current architecture:**
```
Flutter Web UI → Riverpod Providers → LocalDataService (Dio HTTP) → Dart/Shelf Server → Local JSON Files
```

**Target architecture:**
```
Flutter Web UI → Riverpod Providers → FirestoreDataService → Cloud Firestore / Firebase Storage
```

**Firebase services used:**

| Service | Replaces |
|---|---|
| Firebase Hosting | `flutter run -d chrome` / local dev server |
| Cloud Firestore | `~/intervue_data/*.json` files |
| Firebase Storage | `~/intervue_data/candidates/{id}/resume.pdf` |
| Firebase Auth (Email/Password) | No auth (currently open) |
| Cloud Functions | `server/lib/resume_parser.dart` (PDF text extraction) |

**What stays the same:** All Flutter UI screens, all Riverpod providers (interface stays the same), all data models, GoRouter navigation, and the entire look and feel of the app. The `DataService` abstraction already in the codebase makes this a clean swap.

---

## 1. Firebase Project Setup

1. Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com)
2. Enable the following services:
   - **Authentication** → Email/Password sign-in method
   - **Cloud Firestore** → Start in production mode
   - **Firebase Storage** → Default bucket
   - **Cloud Functions** → Requires Blaze (pay-as-you-go) plan
3. Add a **Flutter web app** to the project
4. Copy the Firebase config (apiKey, projectId, etc.)
5. Install the Firebase CLI: `npm install -g firebase-tools`
6. Run `firebase init` in the project root (select Hosting, Firestore, Storage, Functions)
7. Create your single login account manually in the Firebase Auth console

---

## 2. Firestore Data Model

Uses **subcollections** to mirror the current file-based structure.

### Collection Structure

```
firestore-root/
├── config/
│   └── main                              ← single doc (interviewerName, companyName, templates, etc.)
│
├── questions/
│   ├── general                           ← doc with { questions: [...] }
│   ├── screening                         ← doc with { questions: [...] }
│   └── technical                         ← doc with { questions: [...] }
│
└── candidates/
    └── {candidateId}/                    ← candidate profile doc
        └── rounds/                       ← subcollection
            ├── screening                 ← doc with screening round data
            ├── technical                 ← doc with technical round data
            └── assignment                ← doc with assignment review data
```

### Mapping from Current JSON Files

| Current file path | Firestore path |
|---|---|
| `~/intervue_data/config.json` | `config/main` |
| `~/intervue_data/questions/general.json` | `questions/general` |
| `~/intervue_data/questions/screening.json` | `questions/screening` |
| `~/intervue_data/questions/technical.json` | `questions/technical` |
| `~/intervue_data/candidates/{id}/candidate.json` | `candidates/{id}` |
| `~/intervue_data/candidates/{id}/screening.json` | `candidates/{id}/rounds/screening` |
| `~/intervue_data/candidates/{id}/technical.json` | `candidates/{id}/rounds/technical` |
| `~/intervue_data/candidates/{id}/assignment.json` | `candidates/{id}/rounds/assignment` |
| `~/intervue_data/candidates/{id}/resume.pdf` | Firebase Storage: `candidates/{id}/resume.pdf` |

---

## 3. Authentication

### Approach

Single-user email/password authentication. One account created manually in the Firebase console.

### Implementation

- Create a `login_screen.dart` with email and password fields
- Create an `auth_provider.dart` using Riverpod to expose Firebase Auth state
- Wrap the GoRouter with an auth guard — redirect to `/login` if not authenticated
- On successful login, navigate to the dashboard (`/`)

### Firestore Security Rules

Since this is a single-user app, a simple "authenticated = full access" rule is sufficient:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 4. Code Changes — Service Layer

The existing `DataService` abstract class (`lib/services/data_service.dart`) provides a clean interface boundary. The migration creates a new implementation without changing the contract.

### New Files to Create

| File | Purpose |
|---|---|
| `lib/services/firestore_data_service.dart` | Implements `DataService` using Firestore + Storage SDKs |
| `lib/screens/login_screen.dart` | Email/password login page |
| `lib/providers/auth_provider.dart` | Firebase Auth state provider |

### Files to Modify

| File | Change |
|---|---|
| `lib/services/data_service.dart` | Minor updates if needed — method signatures stay the same |
| `lib/main.dart` | Initialize Firebase, swap `LocalDataService` → `FirestoreDataService` |
| `lib/router.dart` | Add auth guard redirect, add `/login` route |
| All model files | Add `toFirestore()` / `fromFirestore()` if needed (likely aliases for existing `toJson()` / `fromJson()`) |

### Files to Delete

| File/Directory | Reason |
|---|---|
| `server/` (entire directory) | Dart/Shelf backend no longer needed |
| `start.sh` | Replaced by `firebase deploy` |
| `lib/services/local_data_service.dart` | Replaced by `firestore_data_service.dart` |

### Provider Changes

Minimal. Providers already call `DataService` methods. The only change is swapping which implementation is injected:

```dart
// Before
final dataServiceProvider = Provider<DataService>((ref) => LocalDataService());

// After
final dataServiceProvider = Provider<DataService>((ref) => FirestoreDataService());
```

---

## 5. Resume Upload & Extraction

### Upload Flow (Client-Side)

1. User picks a PDF via `file_picker` (already a dependency)
2. Upload to Firebase Storage at path `candidates/{id}/resume.pdf`
3. Store the download URL in the candidate's Firestore document

### Extraction Flow (Cloud Function)

A single Cloud Function in Node.js handles PDF text extraction:

- **Trigger:** `onObjectFinalized` — fires when a file is uploaded to Storage
- **Filter:** Only process files matching `candidates/{id}/resume.pdf`
- **Logic:**
  1. Download the PDF from Storage
  2. Use `pdf-parse` (npm package) to extract text
  3. Regex-extract email and phone (port logic from `server/lib/resume_parser.dart`)
  4. Write extracted contact info back to the `candidates/{id}` Firestore document

### Cloud Function Directory

```
functions/
├── package.json
├── index.js          ← onObjectFinalized trigger + PDF parsing logic
└── .eslintrc.js
```

---

## 6. Firebase Hosting Configuration

### firebase.json

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ]
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions"
  }
}
```

The SPA rewrite rule ensures GoRouter handles all client-side routes.

### Build & Deploy

```bash
flutter build web --release
firebase deploy
```

Or deploy individually:

```bash
firebase deploy --only hosting      # just the web app
firebase deploy --only functions    # just the Cloud Function
firebase deploy --only firestore    # just security rules
```

---

## 7. Dependencies

### Add to `pubspec.yaml`

```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  firebase_storage: ^latest
```

### Remove from `pubspec.yaml`

```yaml
# No longer needed (no HTTP backend to call)
dio: ^5.4.0
```

### New: `functions/package.json`

```json
{
  "dependencies": {
    "firebase-admin": "^latest",
    "firebase-functions": "^latest",
    "pdf-parse": "^latest"
  }
}
```

---

## 8. Data Migration (One-Time)

A one-time script to seed Firestore from existing local JSON files:

1. Read all files from `~/intervue_data/`
2. Write config and question banks to their respective Firestore documents
3. For each candidate directory:
   - Write `candidate.json` data to `candidates/{id}`
   - Write `screening.json` to `candidates/{id}/rounds/screening`
   - Write `technical.json` to `candidates/{id}/rounds/technical`
   - Write `assignment.json` to `candidates/{id}/rounds/assignment`
   - Upload `resume.pdf` to Firebase Storage at `candidates/{id}/resume.pdf`

This can be a simple Dart or Node.js script run locally with Firebase Admin SDK credentials.

---

## 9. Effort Estimate

| Area | Effort | Notes |
|---|---|---|
| Firebase project setup | Small | Console configuration + CLI init |
| `FirestoreDataService` | **Large** | Core migration — ~15-20 methods to reimplement |
| Login screen + auth guard | Small | Simple email/password form + route guard |
| Cloud Function (resume parser) | Medium | Port regex logic to Node.js + PDF parsing |
| Model updates | Small | `toJson`/`fromJson` already exist, minor additions |
| Provider changes | Minimal | Swap one service binding |
| Hosting config | Small | `firebase.json` + build command |
| Data migration script | Small | One-time local script |
| Remove server code | Small | Delete `server/`, `start.sh` |

The `FirestoreDataService` is the largest single piece of work since it reimplements every data operation currently handled by the Dart server.

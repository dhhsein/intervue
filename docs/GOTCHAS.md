# InterVue — Gotchas & Required Solutions

These are known issues that MUST be addressed in the implementation. Each one has bitten someone before. Solve them proactively, not reactively.

---

## 1. CORS (Phase 1 — Critical)

**Problem:** Flutter web on `localhost:8080` making HTTP requests to the Dart server on `localhost:3001` is a cross-origin request. The browser will silently block it.

**Solution:** Add CORS middleware as the FIRST middleware in the shelf pipeline. Not second, not after the router — first.

```dart
final handler = const Pipeline()
    .addMiddleware(corsMiddleware())     // ← FIRST
    .addMiddleware(logRequests())
    .addHandler(router.call);
```

The middleware must handle OPTIONS preflight requests by returning 200 immediately. See API_SPEC.md for the full implementation.

**How you'll know it's broken:** Network tab shows `OPTIONS` requests with no response, or `GET/PUT` requests failing with no error message. Console shows "CORS policy" errors.

---

## 2. Auto-Save Data Loss (Phase 2-4 — Critical)

**Problem:** If the user is typing notes during an interview and closes the tab, refreshes, or the browser crashes, unsaved text is lost.

**Solution:**
- Every interaction (score tap, chip select, status change) saves immediately — no debounce.
- Text fields (notes, summaries) save with 500ms debounce after the last keystroke.
- Show a "Saving..." indicator during the debounce, "Saved ✓" after confirmation.
- On the interview session screen, save the entire question's state on every change, not just the changed field.
- Use `beforeunload` event to warn if there's an unsaved debounce pending:

```dart
// In interview_session_screen.dart
import 'dart:html' as html;

@override
void initState() {
  super.initState();
  html.window.onBeforeUnload.listen((event) {
    if (_hasPendingSave) {
      event.preventDefault();
      // Modern browsers ignore custom messages but still show a prompt
    }
  });
}
```

---

## 3. Data Directory Location (Phase 1)

**Problem:** If the data directory is inside the Flutter project, it can get wiped by `flutter clean`, `git clean`, or rebuilds.

**Solution:**
- Default data directory: `~/intervue_data/`
- The server accepts `--data-dir` flag to override
- The server NEVER writes to or reads from the project directory for data
- On first run, copy `sample_data/` contents into the data directory
- Log the data directory path on startup so it's obvious where data lives

---

## 4. File Upload (Phase 2)

**Problem:** Flutter web's file picker works differently from mobile. You can't use `dart:io` File in the browser.

**Solution:**
- Use `html.FileUploadInputElement` for file picking in Flutter web
- Read the file as bytes in the browser, then POST as multipart to the server
- The server handles writing to disk

```dart
// Simplified file picker for web
import 'dart:html' as html;

Future<Uint8List?> pickFile() async {
  final input = html.FileUploadInputElement()..accept = '.pdf';
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;
  return reader.result as Uint8List;
}
```

---

## 5. PDF Viewing (Phase 2)

**Problem:** Embedding a PDF viewer in Flutter web is complex and flaky.

**Solution:** Don't embed it. Open PDFs in a new browser tab.

```dart
import 'package:url_launcher/url_launcher.dart';

void openResume(String candidateId, String filename) {
  launchUrl(Uri.parse('http://localhost:3001/api/files/candidates/$candidateId/$filename'));
}
```

The server must set the correct `Content-Type: application/pdf` header and `Content-Disposition: inline` so the browser renders it instead of downloading.

---

## 6. Timer Persistence (Phase 4)

**Problem:** The interview timer resets if the user navigates away from the interview screen and comes back.

**Solution:**
- Store the interview start time in the `TechnicalRound` data (saved on server)
- On screen load, calculate elapsed = now - startTime
- Timer displays calculated elapsed, not a local counter
- This also means the timer survives page refreshes

---

## 7. Concurrent Saves (Phase 2-4)

**Problem:** If the user taps a score and types a note within 500ms, the score save and the debounced note save could race and the earlier save might overwrite the later one.

**Solution:**
- Save the entire question state as a unit, not individual fields
- Queue saves: if a save is in-flight, don't start another. Queue the latest state and save it when the current one completes.
- Simple implementation:

```dart
class SaveQueue {
  Future<void>? _currentSave;
  Map<String, dynamic>? _pendingData;

  Future<void> save(String endpoint, Map<String, dynamic> data) async {
    _pendingData = data;
    if (_currentSave != null) return; // will be saved when current completes

    while (_pendingData != null) {
      final toSave = _pendingData!;
      _pendingData = null;
      _currentSave = _dio.put(endpoint, data: toSave);
      await _currentSave;
      _currentSave = null;
    }
  }
}
```

---

## 8. Path Traversal Security (Phase 1)

**Problem:** The `GET /api/files/:path` endpoint could be exploited to read any file on the system if the path isn't validated.

**Solution:**
- Resolve the requested path relative to the data directory
- Check that the resolved absolute path starts with the data directory path
- Reject any request where the resolved path escapes the data directory

```dart
final resolvedPath = path.normalize(path.join(dataDir, requestedPath));
if (!resolvedPath.startsWith(path.normalize(dataDir))) {
  return Response.forbidden('Invalid path');
}
```

---

## 9. Hot Reload vs Server (Development)

**Problem:** Flutter web hot reload works. The Dart shelf server does NOT hot reload. If you change server code, you must restart it manually.

**Solution:**
- Keep the server simple (~200-250 lines). Once it works, you'll rarely change it.
- During development, run the server in a separate terminal so you can restart it independently.
- All business logic lives in the Flutter app, not the server. The server is just CRUD + file serving.

---

## 10. Browser Back Button (Phase 2)

**Problem:** In a single-page app, the browser back button can navigate away from the interview session unexpectedly, losing state.

**Solution:**
- go_router handles browser history correctly by default
- For the interview session, show a confirmation dialog if there are unsaved changes:

```dart
return WillPopScope(
  onWillPop: () async {
    if (_hasUnsavedChanges) {
      return await showDialog(...); // "Leave interview? Unsaved data will be lost."
    }
    return true;
  },
  child: ...
);
```

Since we auto-save aggressively, this should rarely trigger. But it's a safety net.

---

## 11. JSON Merge Strategy (Phase 1)

**Problem:** PUT endpoints accept partial updates. Naive replacement would delete fields not included in the request.

**Solution:**
- Server always reads the existing file first
- Deep-merges the request body into existing data
- Writes the merged result back
- For lists (like `timeline`), append rather than replace
- For maps (like `areaScores`), merge at the key level

---

## 12. Sample Data on Fresh Start (Phase 1)

**Problem:** An empty app with no data is confusing and makes it hard to verify the UI works.

**Solution:**
- `sample_data/` folder contains pre-built question banks and 3 sample candidates at different stages
- On first server run (data dir doesn't exist or is empty), copy sample_data/ contents into data dir
- Sample candidates should have realistic data at different pipeline stages so the dashboard looks populated
- This also serves as a functional test: if the sample data renders correctly, the data layer works

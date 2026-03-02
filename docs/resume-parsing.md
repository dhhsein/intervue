# Resume Parsing: Contact Info Extraction

## Overview

Add server-side PDF parsing to extract email and phone numbers from uploaded resumes, with an "Extract from Resume" button in the candidate creation form.

## Current State

- Resumes are uploaded as PDF files only
- No PDF parsing libraries are currently installed
- Contact info (email, phone) is manually entered in the form
- Resumes stored at: `{dataDir}/candidates/{candidateId}/resume.pdf`

## Implementation Approach

- **Parsing Location**: Server-side (Dart)
- **Trigger**: On-demand button click

---

## 1. Server-Side Changes

### 1.1 Add PDF Dependency

**File:** `server/pubspec.yaml`

```yaml
dependencies:
  # ... existing deps
  pdf: ^3.10.0  # Pure Dart PDF library
```

### 1.2 Create Resume Parser Utility

**File:** `server/lib/resume_parser.dart` (NEW)

```dart
import 'dart:io';
import 'package:pdf/pdf.dart';

class ResumeParser {
  /// Extract all text content from a PDF file
  static Future<String> extractText(File pdfFile) async {
    // Implementation using pdf package
    // Returns concatenated text from all pages
  }

  /// Find email address in text using regex
  static String? findEmail(String text) {
    final emailRegex = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final match = emailRegex.firstMatch(text);
    return match?.group(0);
  }

  /// Find phone number in text using regex
  static String? findPhone(String text) {
    // Match various phone formats:
    // +1 (123) 456-7890, 123-456-7890, +91 98765 43210, etc.
    final phoneRegex = RegExp(
      r'(?:\+\d{1,3}[\s-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}|'
      r'(?:\+\d{1,3}[\s-]?)?\d{5}[\s-]?\d{5}'
    );
    final match = phoneRegex.firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Extract contact info from PDF file
  static Future<Map<String, String?>> extractContactInfo(File pdfFile) async {
    final text = await extractText(pdfFile);
    return {
      'email': findEmail(text),
      'phone': findPhone(text),
    };
  }
}
```

### 1.3 Add Extract Endpoint

**File:** `server/bin/server.dart`

Add new endpoint after existing resume routes:

```dart
// Extract contact info from resume
router.get('/api/candidates/<id>/resume/extract', (Request request, String id) async {
  final candidateDir = Directory(path.join(dataDir, 'candidates', id));
  final resumeFile = File(path.join(candidateDir.path, 'resume.pdf'));

  if (!await resumeFile.exists()) {
    return Response.notFound(
      jsonEncode({'error': 'Resume not found'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  try {
    final contactInfo = await ResumeParser.extractContactInfo(resumeFile);
    return Response.ok(
      jsonEncode(contactInfo),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to parse resume: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
});
```

---

## 2. Client-Side Changes

### 2.1 Add Service Method Signature

**File:** `lib/services/data_service.dart`

```dart
abstract class DataService {
  // ... existing methods

  /// Extract contact info (email, phone) from uploaded resume
  Future<Map<String, String?>> extractResumeInfo(String candidateId);
}
```

### 2.2 Implement Service Method

**File:** `lib/services/local_data_service.dart`

```dart
@override
Future<Map<String, String?>> extractResumeInfo(String candidateId) async {
  final response = await _dio.get('/api/candidates/$candidateId/resume/extract');
  return Map<String, String?>.from(response.data);
}
```

### 2.3 Update Candidate Creation Form

**File:** `lib/widgets/add_candidate_panel.dart`

Add "Extract from Resume" button and logic:

```dart
// Add state variable
bool _isExtracting = false;

// Add method
Future<void> _extractFromResume() async {
  if (_resumeFile == null || _candidateId == null) return;

  setState(() => _isExtracting = true);

  try {
    final dataService = ref.read(dataServiceProvider);
    final info = await dataService.extractResumeInfo(_candidateId!);

    if (info['email'] != null && _emailController.text.isEmpty) {
      _emailController.text = info['email']!;
    }
    if (info['phone'] != null && _phoneController.text.isEmpty) {
      _phoneController.text = info['phone']!;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Extracted: ${info.entries.where((e) => e.value != null).length} fields')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isExtracting = false);
  }
}

// Add button in UI (next to email/phone fields or after resume upload)
if (_resumeFile != null)
  TextButton.icon(
    onPressed: _isExtracting ? null : _extractFromResume,
    icon: _isExtracting
      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
      : Icon(Icons.auto_fix_high),
    label: Text('Extract from Resume'),
  ),
```

---

## 3. Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│  User Flow                                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. User uploads resume PDF                                 │
│          ↓                                                  │
│  2. Resume saved to server                                  │
│          ↓                                                  │
│  3. User clicks "Extract from Resume"                       │
│          ↓                                                  │
│  4. Client calls GET /api/candidates/{id}/resume/extract    │
│          ↓                                                  │
│  5. Server parses PDF → extracts text → regex match         │
│          ↓                                                  │
│  6. Returns { email, phone }                                │
│          ↓                                                  │
│  7. Client auto-fills empty form fields                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Files to Modify/Create

| File | Action | Description |
|------|--------|-------------|
| `server/pubspec.yaml` | Modify | Add `pdf: ^3.10.0` dependency |
| `server/lib/resume_parser.dart` | **Create** | PDF parsing utility class |
| `server/bin/server.dart` | Modify | Add `/resume/extract` endpoint |
| `lib/services/data_service.dart` | Modify | Add method signature |
| `lib/services/local_data_service.dart` | Modify | Implement extraction call |
| `lib/widgets/add_candidate_panel.dart` | Modify | Add extract button & logic |

---

## 5. Considerations

### Error Handling
- If extraction fails or finds nothing, show a message but don't block the workflow
- Handle corrupted PDFs gracefully
- Handle scanned images (no extractable text) with appropriate message

### UX Decisions
- Only show button when resume is uploaded
- Only auto-fill empty fields (don't overwrite user input)
- Show what was extracted in the success message

### Edge Cases
- **Multiple emails found**: Take the first one (usually personal email appears first)
- **Multiple phones found**: Take the first one
- **No text in PDF**: Return null values, show "Could not extract text from resume"
- **Scanned PDF**: Same as above (no OCR support initially)

### Future Enhancements
- Add OCR support for scanned resumes (would require additional library)
- Extract more fields: name, address, LinkedIn URL
- Confidence scoring for extracted values
- Let user pick from multiple matches

---

## 6. Testing Checklist

- [ ] Upload PDF with clear text - email and phone extracted
- [ ] Upload PDF with only email - only email extracted
- [ ] Upload PDF with neither - appropriate message shown
- [ ] Upload scanned PDF - graceful failure message
- [ ] Extract with fields already filled - existing values preserved
- [ ] Extract with empty fields - fields populated
- [ ] Network error during extraction - error message shown
- [ ] Corrupted PDF - error handled gracefully

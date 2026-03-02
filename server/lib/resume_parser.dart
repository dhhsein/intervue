import 'dart:io';

class ResumeParser {
  /// Extract all text content from a PDF file using pdftotext (poppler-utils).
  /// Falls back to returning empty string if extraction fails.
  static Future<String> extractText(File pdfFile) async {
    try {
      // Use pdftotext from poppler-utils (commonly available on macOS/Linux)
      // Install via: brew install poppler (macOS) or apt install poppler-utils (Linux)
      final result = await Process.run(
        'pdftotext',
        ['-layout', pdfFile.path, '-'],
        stdoutEncoding: const SystemEncoding(),
      );

      if (result.exitCode == 0) {
        return result.stdout as String;
      }

      // If pdftotext is not available, try using textutil on macOS
      if (Platform.isMacOS) {
        final macResult = await Process.run(
          'mdimport',
          ['-d1', pdfFile.path],
          stdoutEncoding: const SystemEncoding(),
        );
        if (macResult.exitCode == 0) {
          return macResult.stdout as String;
        }
      }

      return '';
    } catch (e) {
      // Return empty string if any extraction method fails
      return '';
    }
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
      r'(?:\+\d{1,3}[\s-]?)?\d{5}[\s-]?\d{5}',
    );
    final match = phoneRegex.firstMatch(text);
    if (match == null) return null;

    // Clean up the phone number, keeping only digits and leading +
    final raw = match.group(0) ?? '';
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.isNotEmpty ? cleaned : null;
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

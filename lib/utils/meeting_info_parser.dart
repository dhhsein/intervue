/// Utility to parse Google Calendar invite text and extract meeting information.
class MeetingInfoParser {
  /// Parsed meeting information
  final DateTime? meetingTime;
  final int? durationMinutes;
  final String? meetingLink;
  final String? errorMessage;

  MeetingInfoParser._({
    this.meetingTime,
    this.durationMinutes,
    this.meetingLink,
    this.errorMessage,
  });

  bool get isValid =>
      meetingTime != null && durationMinutes != null && meetingLink != null;

  /// Parse Google Calendar invite text.
  ///
  /// Expected format:
  /// ```
  /// Test interview
  /// Monday, 2 March · 9:30 – 10:30pm
  /// Time zone: Asia/Kolkata
  /// Google Meet joining info
  /// Video call link: https://meet.google.com/qqv-bvab-zjo
  /// ```
  factory MeetingInfoParser.parse(String text) {
    if (text.trim().isEmpty) {
      return MeetingInfoParser._(errorMessage: 'Please paste calendar invite text');
    }

    // Extract Google Meet link
    final meetLinkRegex = RegExp(
      r'(?:https?://)?meet\.google\.com/([a-z]{3}-[a-z]{4}-[a-z]{3})',
      caseSensitive: false,
    );
    final meetLinkMatch = meetLinkRegex.firstMatch(text);
    final meetingLink = meetLinkMatch != null
        ? 'https://meet.google.com/${meetLinkMatch.group(1)}'
        : null;

    // Try to extract date and time
    DateTime? meetingTime;
    int? durationMinutes;

    // Primary format: "Monday, 2 March · 9:30 – 10:30pm"
    // or "Monday, 2 March · 9:30am – 10:30am"
    final googleCalendarRegex = RegExp(
      r'(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),?\s+'
      r'(\d{1,2})\s+'
      r'(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
      r'(?:\s+(\d{4}))?'  // Optional year
      r'\s*[·\-–]\s*'
      r'(\d{1,2}):(\d{2})\s*(am|pm)?'  // Start time
      r'\s*[–\-]\s*'
      r'(\d{1,2}):(\d{2})\s*(am|pm)?',  // End time
      caseSensitive: false,
    );

    final googleMatch = googleCalendarRegex.firstMatch(text);
    if (googleMatch != null) {
      final day = int.parse(googleMatch.group(1)!);
      final month = _parseMonth(googleMatch.group(2)!);
      final year = googleMatch.group(3) != null
          ? int.parse(googleMatch.group(3)!)
          : DateTime.now().year;
      var startHour = int.parse(googleMatch.group(4)!);
      final startMinute = int.parse(googleMatch.group(5)!);
      final startAmPm = googleMatch.group(6)?.toLowerCase();
      var endHour = int.parse(googleMatch.group(7)!);
      final endMinute = int.parse(googleMatch.group(8)!);
      final endAmPm = googleMatch.group(9)?.toLowerCase();

      // Determine AM/PM - if end has pm/am, use it to infer start if not specified
      final effectiveEndAmPm = endAmPm ?? startAmPm;
      final effectiveStartAmPm = startAmPm ?? endAmPm;

      // Convert to 24-hour format
      if (effectiveStartAmPm == 'pm' && startHour != 12) startHour += 12;
      if (effectiveStartAmPm == 'am' && startHour == 12) startHour = 0;
      if (effectiveEndAmPm == 'pm' && endHour != 12) endHour += 12;
      if (effectiveEndAmPm == 'am' && endHour == 12) endHour = 0;

      meetingTime = DateTime(year, month, day, startHour, startMinute);
      final endTime = DateTime(year, month, day, endHour, endMinute);
      durationMinutes = endTime.difference(meetingTime).inMinutes;
      if (durationMinutes < 0) {
        // Handle overnight meetings
        durationMinutes += 24 * 60;
      }
    }

    // Build error message if any field is missing
    final missing = <String>[];
    if (meetingTime == null) missing.add('meeting time');
    if (durationMinutes == null) missing.add('duration');
    if (meetingLink == null) missing.add('Google Meet link');

    final errorMessage = missing.isNotEmpty
        ? 'Could not extract: ${missing.join(', ')}'
        : null;

    return MeetingInfoParser._(
      meetingTime: meetingTime,
      durationMinutes: durationMinutes,
      meetingLink: meetingLink,
      errorMessage: errorMessage,
    );
  }

  static int _parseMonth(String monthStr) {
    final month = monthStr.toLowerCase();
    if (month.startsWith('jan')) return 1;
    if (month.startsWith('feb')) return 2;
    if (month.startsWith('mar')) return 3;
    if (month.startsWith('apr')) return 4;
    if (month.startsWith('may')) return 5;
    if (month.startsWith('jun')) return 6;
    if (month.startsWith('jul')) return 7;
    if (month.startsWith('aug')) return 8;
    if (month.startsWith('sep')) return 9;
    if (month.startsWith('oct')) return 10;
    if (month.startsWith('nov')) return 11;
    if (month.startsWith('dec')) return 12;
    return 1;
  }
}

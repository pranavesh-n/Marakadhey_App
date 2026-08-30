import 'package:intl/intl.dart';

class DetectedDeadline {
  final DateTime date;
  final String formattedDisplay; // e.g. "21-09-2026"
  final String rawMatch;
  final int? hour;
  final int? minute;
  final String? ampm;

  DetectedDeadline({
    required this.date,
    required this.formattedDisplay,
    required this.rawMatch,
    this.hour,
    this.minute,
    this.ampm,
  });
}

class DateExtractorService {
  static const List<String> _monthNames = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december'
  ];

  static const List<String> _monthAbbrs = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'sept', 'oct', 'nov', 'dec'
  ];

  static int _monthIndexFromName(String name) {
    final lower = name.toLowerCase().trim();
    for (int i = 0; i < _monthNames.length; i++) {
      if (_monthNames[i] == lower) return i + 1;
    }
    for (int i = 0; i < _monthAbbrs.length; i++) {
      if (_monthAbbrs[i] == lower) {
        if (i == 9) return 9; // 'sept'
        if (i > 9) return i; // 'oct', 'nov', 'dec'
        return i + 1;
      }
    }
    return -1;
  }

  /// Extracts the most likely future deadline date and time from any text snippet
  static DetectedDeadline? extractDeadline(String text) {
    if (text.trim().isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final timeInfo = _extractTime(text);

    List<DetectedDeadline> candidates = [];

    // 1. Check relative keywords: "tomorrow", "today"
    final lower = text.toLowerCase();
    if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      final targetDate = today.add(const Duration(days: 1));
      candidates.add(DetectedDeadline(
        date: targetDate,
        formattedDisplay: DateFormat('dd-MM-yyyy').format(targetDate),
        rawMatch: 'Tomorrow',
        hour: timeInfo?['hour'],
        minute: timeInfo?['minute'],
        ampm: timeInfo?['ampm'],
      ));
    }

    // 2. Pattern A: Month Day Year (e.g. "September 21, 2026", "Sept 21", "October 5 2026", "Dec 31st")
    final monthDayYearRegExp = RegExp(
      r'(?:due\s+|deadline:?\s+|by\s+|on\s+|until\s+|closes?\s+|ends?\s+)?\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sept|sep|oct|nov|dec)\.?\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?\b',
      caseSensitive: false,
    );

    for (final match in monthDayYearRegExp.allMatches(text)) {
      final monthStr = match.group(1)!;
      final day = int.tryParse(match.group(2)!);
      final yearStr = match.group(3);
      final month = _monthIndexFromName(monthStr);

      if (month > 0 && day != null && day >= 1 && day <= 31) {
        int year = yearStr != null ? int.parse(yearStr) : now.year;
        if (yearStr == null) {
          final candidate = DateTime(year, month, day);
          if (candidate.isBefore(today)) {
            year += 1; // Roll to next year if month/day has already passed
          }
        }
        final targetDate = DateTime(year, month, day);
        candidates.add(DetectedDeadline(
          date: targetDate,
          formattedDisplay: DateFormat('dd-MM-yyyy').format(targetDate),
          rawMatch: match.group(0)!,
          hour: timeInfo?['hour'],
          minute: timeInfo?['minute'],
          ampm: timeInfo?['ampm'],
        ));
      }
    }

    // 3. Pattern B: Day Month Year (e.g. "21 September 2026", "21st Sep", "21-Sep-2026", "5 October")
    final dayMonthYearRegExp = RegExp(
      r'(?:due\s+|deadline:?\s+|by\s+|on\s+|until\s+|closes?\s+|ends?\s+)?\b(\d{1,2})(?:st|nd|rd|th)?[\s\-\/]+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sept|sep|oct|nov|dec)\.?(?:[\s\-\/]+(\d{4}))?\b',
      caseSensitive: false,
    );

    for (final match in dayMonthYearRegExp.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final monthStr = match.group(2)!;
      final yearStr = match.group(3);
      final month = _monthIndexFromName(monthStr);

      if (month > 0 && day != null && day >= 1 && day <= 31) {
        int year = yearStr != null ? int.parse(yearStr) : now.year;
        if (yearStr == null) {
          final candidate = DateTime(year, month, day);
          if (candidate.isBefore(today)) {
            year += 1;
          }
        }
        final targetDate = DateTime(year, month, day);
        candidates.add(DetectedDeadline(
          date: targetDate,
          formattedDisplay: DateFormat('dd-MM-yyyy').format(targetDate),
          rawMatch: match.group(0)!,
          hour: timeInfo?['hour'],
          minute: timeInfo?['minute'],
          ampm: timeInfo?['ampm'],
        ));
      }
    }

    // 4. Numeric standard dates: YYYY-MM-DD or YYYY/MM/DD
    final isoDateRegExp = RegExp(r'\b(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})\b');
    for (final match in isoDateRegExp.allMatches(text)) {
      final y = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final d = int.parse(match.group(3)!);
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        final targetDate = DateTime(y, m, d);
        candidates.add(DetectedDeadline(
          date: targetDate,
          formattedDisplay: DateFormat('dd-MM-yyyy').format(targetDate),
          rawMatch: match.group(0)!,
          hour: timeInfo?['hour'],
          minute: timeInfo?['minute'],
          ampm: timeInfo?['ampm'],
        ));
      }
    }

    // 5. Numeric standard dates: DD-MM-YYYY or DD/MM/YYYY or MM/DD/YYYY
    final ddmmyyyyRegExp = RegExp(r'\b(\d{1,2})[-\/](\d{1,2})[-\/](\d{4})\b');
    for (final match in ddmmyyyyRegExp.allMatches(text)) {
      final p1 = int.parse(match.group(1)!);
      final p2 = int.parse(match.group(2)!);
      final y = int.parse(match.group(3)!);

      int d = p1;
      int m = p2;
      if (p1 <= 12 && p2 > 12) {
        // MM/DD/YYYY format
        m = p1;
        d = p2;
      }

      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        final targetDate = DateTime(y, m, d);
        candidates.add(DetectedDeadline(
          date: targetDate,
          formattedDisplay: DateFormat('dd-MM-yyyy').format(targetDate),
          rawMatch: match.group(0)!,
          hour: timeInfo?['hour'],
          minute: timeInfo?['minute'],
          ampm: timeInfo?['ampm'],
        ));
      }
    }

    if (candidates.isEmpty) return null;

    // Separate into future candidates (today or future) vs past
    final futureCandidates = candidates.where((c) => !c.date.isBefore(today)).toList();

    if (futureCandidates.isNotEmpty) {
      // Prioritize deadline containing intent keywords e.g. "due", "deadline", "by"
      final keywordCandidate = futureCandidates.firstWhere(
        (c) => RegExp(r'(due|deadline|by|on|until|closes|ends)', caseSensitive: false).hasMatch(c.rawMatch),
        orElse: () => futureCandidates.first,
      );

      // Return the closest future deadline
      futureCandidates.sort((a, b) => a.date.compareTo(b.date));
      if (RegExp(r'(due|deadline|by|on|until|closes|ends)', caseSensitive: false).hasMatch(keywordCandidate.rawMatch)) {
        return keywordCandidate;
      }
      return futureCandidates.first;
    }

    // If all matched dates are in past, return the latest one (or first found)
    return candidates.first;
  }

  static Map<String, dynamic>? _extractTime(String text) {
    final timeMatch = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|AM|PM)\b').firstMatch(text);
    if (timeMatch != null) {
      int h = int.parse(timeMatch.group(1)!);
      int m = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      String ampm = timeMatch.group(3)!.toUpperCase();

      if (h > 12) {
        ampm = 'PM';
        h -= 12;
      }
      if (h == 0) h = 12;

      return {
        'hour': h,
        'minute': m,
        'ampm': ampm,
      };
    }

    // 24-hour format e.g. 18:00
    final time24Match = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b').firstMatch(text);
    if (time24Match != null) {
      int h = int.parse(time24Match.group(1)!);
      int m = int.parse(time24Match.group(2)!);
      String ampm = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;

      return {
        'hour': h,
        'minute': m,
        'ampm': ampm,
      };
    }

    return null;
  }
}


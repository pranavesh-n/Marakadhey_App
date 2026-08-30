import 'package:flutter_test/flutter_test.dart';
import 'package:marakadhey_mobile/services/date_extractor_service.dart';

void main() {
  group('DateExtractorService All-Month & Future Deadline Tests', () {
    test('Extracts explicit month names (e.g. September 21, 2026)', () {
      final sample = 'GroqCloud decommissioned Compound model today, Sept 21, 2026.';
      final result = DateExtractorService.extractDeadline(sample);

      expect(result, isNotNull);
      expect(result!.date.year, equals(2026));
      expect(result.date.month, equals(9));
      expect(result.date.day, equals(21));
      expect(result.formattedDisplay, equals('21-09-2026'));
    });

    test('Extracts all 12 calendar month names correctly', () {
      final months = [
        'January 10, 2027',
        'February 14, 2027',
        'March 20, 2027',
        'April 5, 2027',
        'May 1, 2027',
        'June 15, 2027',
        'July 4, 2027',
        'August 15, 2027',
        'September 30, 2027',
        'October 31, 2027',
        'November 25, 2027',
        'December 25, 2027',
      ];

      for (int i = 0; i < months.length; i++) {
        final res = DateExtractorService.extractDeadline('Due by ${months[i]}');
        expect(res, isNotNull, reason: 'Failed to extract from ${months[i]}');
        expect(res!.date.month, equals(i + 1));
        expect(res.date.year, equals(2027));
      }
    });

    test('Extracts numeric DD-MM-YYYY and ISO YYYY-MM-DD formats', () {
      final res1 = DateExtractorService.extractDeadline('Application closes on 25-11-2026');
      expect(res1, isNotNull);
      expect(res1!.date.day, equals(25));
      expect(res1.date.month, equals(11));
      expect(res1.date.year, equals(2026));

      final res2 = DateExtractorService.extractDeadline('Deadline: 2026-12-31 23:59');
      expect(res2, isNotNull);
      expect(res2!.date.day, equals(31));
      expect(res2.date.month, equals(12));
      expect(res2.date.year, equals(2026));
    });

    test('Extracts relative date "Tomorrow"', () {
      final res = DateExtractorService.extractDeadline('Submit proposal tomorrow at 5pm');
      final expected = DateTime.now().add(const Duration(days: 1));
      expect(res, isNotNull);
      expect(res!.date.day, equals(expected.day));
      expect(res.date.month, equals(expected.month));
      expect(res.hour, equals(5));
      expect(res.ampm, equals('PM'));
    });

    test('Prioritizes upcoming future deadlines when multiple dates exist', () {
      final text = 'Posted on January 1, 2020. Last date to apply is December 15, 2026.';
      final res = DateExtractorService.extractDeadline(text);
      expect(res, isNotNull);
      expect(res!.date.year, equals(2026));
      expect(res.date.month, equals(12));
      expect(res.date.day, equals(15));
    });
  });
}

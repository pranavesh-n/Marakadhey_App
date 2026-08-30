import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marakadhey_mobile/models/opportunity.dart';
import 'package:marakadhey_mobile/providers/opportunity_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Weekly Recurrence & Custom Days Logic Tests', () {
    test('Opportunity serialization preserves repeatPattern and customDays', () {
      final opp = Opportunity(
        id: 'test_1',
        title: 'Weekly Sync',
        category: 'Work',
        deadline: DateTime(2026, 9, 1, 10, 0),
        isRecurring: true,
        recurrenceRule: 'weekly',
        repeatPattern: 'custom',
        customDays: ['Mon', 'Wed', 'Fri'],
      );

      final map = opp.toMap();
      expect(map['isRecurring'], isTrue);
      expect(map['recurrenceRule'], equals('weekly'));
      expect(map['repeatPattern'], equals('custom'));
      expect(map['customDays'], equals(['Mon', 'Wed', 'Fri']));

      final fromMap = Opportunity.fromMap(map);
      expect(fromMap.repeatPattern, equals('custom'));
      expect(fromMap.customDays, equals(['Mon', 'Wed', 'Fri']));
    });

    test('OpportunityProvider computes next recurrence for custom days correctly', () async {
      final provider = OpportunityProvider();
      
      // Let's create an opportunity scheduled on Monday
      final mondayDate = DateTime(2026, 8, 31, 10, 0); // 2026-08-31 is Monday
      expect(mondayDate.weekday, equals(DateTime.monday));

      await provider.addOpportunity(
        title: 'Custom Routine',
        category: 'Internship',
        deadline: mondayDate,
        isRecurring: true,
        recurrenceRule: 'weekly',
        repeatPattern: 'custom',
        customDays: ['Mon', 'Wed', 'Fri'],
        sendNotification: false,
      );

      expect(provider.opportunities.isNotEmpty, isTrue);
      final opp = provider.opportunities.first;

      // Completing on Monday should advance it to Wednesday
      await provider.toggleComplete(opp.id);

      final updated = provider.opportunities.first;
      expect(updated.status, equals(OpportunityStatus.pending));
      expect(updated.deadline.weekday, equals(DateTime.wednesday));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marakadhey_mobile/models/opportunity.dart';
import 'package:marakadhey_mobile/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('JSON Export and Import roundtrip works correctly', () async {
    final now = DateTime.now();
    final testOpp = Opportunity(
      id: 'opp_test_1',
      title: 'Google Summer of Code 2026',
      description: 'Open source stipend program',
      websiteUrl: 'https://summerofcode.withgoogle.com',
      category: 'Internship',
      priority: Priority.high,
      status: OpportunityStatus.pending,
      deadline: now.add(const Duration(days: 7)),
      tags: ['gsoc', 'google', 'internship'],
      checklist: [
        ChecklistItem(id: 'chk_1', task: 'Draft proposal', completed: true),
        ChecklistItem(id: 'chk_2', task: 'Submit application', completed: false),
      ],
      history: [
        HistoryEntry(id: 'h_1', action: 'CREATED', timestamp: now.toIso8601String()),
      ],
      createdAt: now,
      updatedAt: now,
    );

    // Save test opportunity
    await StorageService.saveOpportunities([testOpp], userId: 'usr_test_123');

    // 1. Test Export
    final exportedJson = await StorageService.exportBackup(userId: 'usr_test_123');
    expect(exportedJson.contains('Google Summer of Code 2026'), isTrue);
    expect(exportedJson.contains('Draft proposal'), isTrue);
    expect(exportedJson.contains('HIGH'), isTrue);

    // Clear storage to test clean import
    await StorageService.clearOpportunities(userId: 'usr_test_123');
    final afterClear = await StorageService.getOpportunities(userId: 'usr_test_123');
    expect(afterClear.isEmpty, isTrue);

    // 2. Test Import
    final importSuccess = await StorageService.importBackup(exportedJson, userId: 'usr_test_123');
    expect(importSuccess, isTrue);

    // 3. Verify restored data
    final restoredOpps = await StorageService.getOpportunities(userId: 'usr_test_123');
    expect(restoredOpps.length, 1);
    expect(restoredOpps.first.title, 'Google Summer of Code 2026');
    expect(restoredOpps.first.priority, Priority.high);
    expect(restoredOpps.first.tags.contains('gsoc'), isTrue);
    expect(restoredOpps.first.checklist.length, 2);
    expect(restoredOpps.first.checklist.first.completed, isTrue);
    expect(restoredOpps.first.checklist.last.completed, isFalse);
  });
}

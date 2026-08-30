import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/opportunity.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class OpportunityProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  String? _currentUserId;
  List<Opportunity> _opportunities = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String _selectedPriority = 'ALL';
  String _selectedStatusFilter = 'ALL'; // ALL, PENDING, COMPLETED, URGENT, TODAY, UPCOMING, RECURRING

  bool _hideCompletedFromInbox = true;
  bool _markCompletedOnOpen = true;
  bool _autoDelete90Days = true;

  String? get currentUserId => _currentUserId;
  List<Opportunity> get opportunities => _opportunities;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedPriority => _selectedPriority;
  String get selectedStatusFilter => _selectedStatusFilter;
  bool get hideCompletedFromInbox => _hideCompletedFromInbox;
  bool get markCompletedOnOpen => _markCompletedOnOpen;
  bool get autoDelete90Days => _autoDelete90Days;

  // Counts & Stats
  int get totalCount => _opportunities.length;
  int get pendingCount => _opportunities.where((o) => o.status == OpportunityStatus.pending).length;
  int get completedCount => _opportunities.where((o) => o.status == OpportunityStatus.completed).length;

  int get urgentCount {
    final now = DateTime.now();
    final urgentThreshold = now.add(const Duration(hours: 48));
    return _opportunities.where((o) =>
        o.status == OpportunityStatus.pending &&
        o.deadline.isAfter(now) &&
        o.deadline.isBefore(urgentThreshold)).length;
  }

  int get todayCount {
    final now = DateTime.now();
    return _opportunities.where((o) {
      if (o.status != OpportunityStatus.pending) return false;
      return o.deadline.year == now.year &&
          o.deadline.month == now.month &&
          o.deadline.day == now.day;
    }).length;
  }

  int get recurringCount =>
      _opportunities.where((o) => o.isRecurring && o.status == OpportunityStatus.pending).length;

  Map<String, int> get categoryCounts {
    final Map<String, int> counts = {};
    for (final opp in _opportunities) {
      counts[opp.category] = (counts[opp.category] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get priorityCounts {
    final Map<String, int> counts = {'HIGH': 0, 'MEDIUM': 0, 'LOW': 0};
    for (final opp in _opportunities) {
      final key = opp.priority.toShortString();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  int get highPriorityCount => _opportunities.where((o) => o.priority == Priority.high).length;
  int get mediumPriorityCount => _opportunities.where((o) => o.priority == Priority.medium).length;
  int get lowPriorityCount => _opportunities.where((o) => o.priority == Priority.low).length;
  int get upcomingCount => _opportunities.where((o) => o.status == OpportunityStatus.pending && o.deadline.isAfter(DateTime.now())).length;
  String get selectedFilter => _selectedStatusFilter.toLowerCase();
  void setSelectedFilter(String f) {
    _selectedStatusFilter = f.toUpperCase();
    notifyListeners();
  }
  Map<String, int> get categoryStats => categoryCounts;

  // Filtered Opportunities List
  List<Opportunity> get filteredOpportunities {
    return _opportunities.where((opp) {
      // 1. Search Query Filter (Title, URL, Description, Tags, Category)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = opp.title.toLowerCase().contains(query);
        final matchesDesc = opp.description?.toLowerCase().contains(query) ?? false;
        final matchesUrl = opp.websiteUrl?.toLowerCase().contains(query) ?? false;
        final matchesCategory = opp.category.toLowerCase().contains(query);
        final matchesTags = opp.tags.any((t) => t.toLowerCase().contains(query));

        if (!matchesTitle && !matchesDesc && !matchesUrl && !matchesCategory && !matchesTags) {
          return false;
        }
      }

      // 2. Category Filter
      if (_selectedCategory != 'ALL' && opp.category != _selectedCategory) {
        return false;
      }

      // 3. Priority Filter
      if (_selectedPriority != 'ALL' && opp.priority.toShortString() != _selectedPriority) {
        return false;
      }

      // 4. Status Filter Tab
      final now = DateTime.now();
      switch (_selectedStatusFilter) {
        case 'PENDING':
          return opp.status == OpportunityStatus.pending;
        case 'COMPLETED':
          return opp.status == OpportunityStatus.completed;
        case 'URGENT':
          return opp.status == OpportunityStatus.pending &&
              opp.deadline.isAfter(now) &&
              opp.deadline.isBefore(now.add(const Duration(hours: 48)));
        case 'TODAY':
          return opp.status == OpportunityStatus.pending &&
              opp.deadline.year == now.year &&
              opp.deadline.month == now.month &&
              opp.deadline.day == now.day;
        case 'UPCOMING':
          return opp.status == OpportunityStatus.pending && opp.deadline.isAfter(now);
        case 'RECURRING':
          return opp.isRecurring;
        case 'ALL':
        default:
          if (_hideCompletedFromInbox && opp.status == OpportunityStatus.completed) {
            return false;
          }
          return true;
      }
    }).toList()
      ..sort((a, b) {
        // Pinned items first
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        // Then by deadline ascending
        return a.deadline.compareTo(b.deadline);
      });
  }

  OpportunityProvider() {
    loadOpportunities();
  }

  /// Switch the active logged-in user
  void setUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      loadOpportunities();
    }
  }

  /// Load opportunities for the active user
  Future<void> loadOpportunities() async {
    _isLoading = true;
    notifyListeners();

    _hideCompletedFromInbox = await StorageService.getHideCompletedFromInbox();
    _markCompletedOnOpen = await StorageService.getMarkCompletedOnOpen();
    _autoDelete90Days = await StorageService.getAutoDelete90Days();

    _opportunities = await StorageService.getOpportunities(userId: _currentUserId);

    // Auto-delete completed reminders older than 90 days if enabled
    if (_autoDelete90Days) {
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final beforeCount = _opportunities.length;
      _opportunities.removeWhere((o) => o.status == OpportunityStatus.completed && o.updatedAt.isBefore(cutoff));
      if (_opportunities.length != beforeCount) {
        await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
      }
    }

    _isLoading = false;
    notifyListeners();

    // Reschedule alarms for this user's pending opportunities
    NotificationService.rescheduleAll(_opportunities);
  }

  Future<void> setHideCompletedFromInbox(bool val) async {
    _hideCompletedFromInbox = val;
    await StorageService.setHideCompletedFromInbox(val);
    notifyListeners();
  }

  Future<void> setMarkCompletedOnOpen(bool val) async {
    _markCompletedOnOpen = val;
    await StorageService.setMarkCompletedOnOpen(val);
    notifyListeners();
  }

  Future<void> setAutoDelete90Days(bool val) async {
    _autoDelete90Days = val;
    await StorageService.setAutoDelete90Days(val);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedPriority(String priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void setSelectedStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    notifyListeners();
  }

  /// Add a new opportunity
  Future<void> addOpportunity({
    required String title,
    String? description,
    String? websiteUrl,
    required String category,
    Priority priority = Priority.medium,
    required DateTime deadline,
    bool isRecurring = false,
    String? recurrenceRule,
    String? repeatPattern,
    List<String> customDays = const [],
    int repeatIntervalDays = 1,
    int leadTimeMinutes = 0,
    List<String> tags = const [],
    bool sendNotification = true,
  }) async {
    final newId = 'opp_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 4)}';
    final now = DateTime.now();

    final opp = Opportunity(
      id: newId,
      title: title,
      description: description,
      websiteUrl: websiteUrl,
      category: category,
      priority: priority,
      status: OpportunityStatus.pending,
      deadline: deadline,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      repeatPattern: repeatPattern,
      customDays: customDays,
      repeatIntervalDays: repeatIntervalDays,
      leadTimeMinutes: leadTimeMinutes,
      tags: tags,
      history: [
        HistoryEntry(
          id: 'h_${DateTime.now().millisecondsSinceEpoch}',
          action: 'CREATED',
          timestamp: now.toIso8601String(),
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    _opportunities.insert(0, opp);
    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();

    if (sendNotification) {
      await NotificationService.scheduleOpportunityReminder(opp);
    }
  }

  /// Update existing opportunity
  Future<void> updateOpportunity(Opportunity updated) async {
    final index = _opportunities.indexWhere((o) => o.id == updated.id);
    if (index != -1) {
      final now = DateTime.now();
      final updatedWithHistory = updated.copyWith(
        updatedAt: now,
        history: [
          ...updated.history,
          HistoryEntry(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}',
            action: 'UPDATED',
            timestamp: now.toIso8601String(),
          ),
        ],
      );

      _opportunities[index] = updatedWithHistory;
      await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
      notifyListeners();

      if (updatedWithHistory.status == OpportunityStatus.pending) {
        await NotificationService.scheduleOpportunityReminder(updatedWithHistory);
      } else {
        await NotificationService.cancelOpportunityReminder(updatedWithHistory);
      }
    }
  }

  /// Toggle completion (handles recurrence calculation)
  Future<void> toggleComplete(String id) async {
    final index = _opportunities.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final opp = _opportunities[index];
    final bool isCompleted = opp.status == OpportunityStatus.completed;
    final now = DateTime.now();

    if (!isCompleted && opp.isRecurring) {
      final DateTime nextDeadline = _computeNextRecurrence(opp);

      final updated = opp.copyWith(
        deadline: nextDeadline,
        status: OpportunityStatus.pending,
        updatedAt: now,
        history: [
          ...opp.history,
          HistoryEntry(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}',
            action: 'COMPLETED & RECURRED',
            timestamp: now.toIso8601String(),
            note: 'Next scheduled for $nextDeadline',
          ),
        ],
      );

      _opportunities[index] = updated;
      await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
      notifyListeners();
      await NotificationService.scheduleOpportunityReminder(updated);
    } else {
      final newStatus = isCompleted ? OpportunityStatus.pending : OpportunityStatus.completed;
      final updated = opp.copyWith(
        status: newStatus,
        updatedAt: now,
        history: [
          ...opp.history,
          HistoryEntry(
            id: 'h_${DateTime.now().millisecondsSinceEpoch}',
            action: isCompleted ? 'UNCOMPLETED' : 'COMPLETED',
            timestamp: now.toIso8601String(),
          ),
        ],
      );

      _opportunities[index] = updated;
      await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
      notifyListeners();

      if (newStatus == OpportunityStatus.completed) {
        await NotificationService.cancelOpportunityReminder(opp);
      } else {
        await NotificationService.scheduleOpportunityReminder(updated);
      }
    }
  }

  /// Calculate next recurrence date
  DateTime _computeNextRecurrence(Opportunity opp) {
    DateTime base = opp.deadline.isAfter(DateTime.now()) ? opp.deadline : DateTime.now();

    final rule = (opp.recurrenceRule ?? '').toLowerCase();
    switch (rule) {
      case 'daily':
        return base.add(Duration(days: opp.repeatIntervalDays > 0 ? opp.repeatIntervalDays : 1));

      case 'weekly':
        if (opp.repeatPattern == 'weekdays') {
          DateTime next = base.add(const Duration(days: 1));
          while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
            next = next.add(const Duration(days: 1));
          }
          return next;
        } else if (opp.repeatPattern == 'weekends') {
          DateTime next = base.add(const Duration(days: 1));
          while (next.weekday != DateTime.saturday && next.weekday != DateTime.sunday) {
            next = next.add(const Duration(days: 1));
          }
          return next;
        } else if (opp.repeatPattern == 'custom' && opp.customDays.isNotEmpty) {
          final targetWeekdays = opp.customDays.map((d) {
            final key = d.toLowerCase();
            if (key.startsWith('mon')) return DateTime.monday;
            if (key.startsWith('tue')) return DateTime.tuesday;
            if (key.startsWith('wed')) return DateTime.wednesday;
            if (key.startsWith('thu')) return DateTime.thursday;
            if (key.startsWith('fri')) return DateTime.friday;
            if (key.startsWith('sat')) return DateTime.saturday;
            if (key.startsWith('sun')) return DateTime.sunday;
            return DateTime.monday;
          }).toSet();

          DateTime next = base.add(const Duration(days: 1));
          for (int i = 0; i < 7; i++) {
            if (targetWeekdays.contains(next.weekday)) {
              return next;
            }
            next = next.add(const Duration(days: 1));
          }
          return base.add(const Duration(days: 7));
        } else {
          return base.add(const Duration(days: 7));
        }

      case 'monthly':
        return DateTime(base.year, base.month + 1, base.day, base.hour, base.minute);

      case 'quarterly':
        return DateTime(base.year, base.month + 3, base.day, base.hour, base.minute);

      case 'yearly':
        return DateTime(base.year + 1, base.month, base.day, base.hour, base.minute);

      default:
        return base.add(const Duration(days: 7));
    }
  }

  /// Snooze opportunity by N minutes
  Future<void> snoozeOpportunity(String id, int minutes) async {
    final index = _opportunities.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final opp = _opportunities[index];
    final now = DateTime.now();
    final newDeadline = (opp.deadline.isAfter(now) ? opp.deadline : now).add(Duration(minutes: minutes));

    final updated = opp.copyWith(
      deadline: newDeadline,
      status: OpportunityStatus.pending,
      updatedAt: now,
      history: [
        ...opp.history,
        HistoryEntry(
          id: 'h_${DateTime.now().millisecondsSinceEpoch}',
          action: 'SNOOZED',
          timestamp: now.toIso8601String(),
          note: 'Snoozed by $minutes mins',
        ),
      ],
    );

    _opportunities[index] = updated;
    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();
    await NotificationService.scheduleOpportunityReminder(updated);
  }

  /// Toggle pin
  Future<void> togglePin(String id) async {
    final index = _opportunities.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final opp = _opportunities[index];
    final updated = opp.copyWith(pinned: !opp.pinned, updatedAt: DateTime.now());
    _opportunities[index] = updated;
    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();
  }

  /// Delete opportunity
  Future<void> deleteOpportunity(String id) async {
    final opp = _opportunities.firstWhere((o) => o.id == id, orElse: () => _opportunities.first);
    await NotificationService.cancelOpportunityReminder(opp);

    _opportunities.removeWhere((o) => o.id == id);
    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();
  }

  /// Add checklist item to opportunity
  Future<void> addChecklistItem(String oppId, String task) async {
    final index = _opportunities.indexWhere((o) => o.id == oppId);
    if (index == -1) return;

    final opp = _opportunities[index];
    final newItem = ChecklistItem(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
      task: task,
      completed: false,
    );

    final updated = opp.copyWith(
      checklist: [...opp.checklist, newItem],
      updatedAt: DateTime.now(),
    );

    _opportunities[index] = updated;
    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();
  }

  /// Toggle checklist item
  Future<void> toggleChecklistItem(String oppId, String itemId) async {
    final index = _opportunities.indexWhere((o) => o.id == oppId);
    if (index == -1) return;

    final opp = _opportunities[index];
    final updatedChecklist = opp.checklist.map((chk) {
      if (chk.id == itemId) {
        return chk.copyWith(completed: !chk.completed);
      }
      return chk;
    }).toList();

    final updated = opp.copyWith(
      checklist: updatedChecklist,
      updatedAt: DateTime.now(),
    );

    _opportunities[index] = updated;
    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();
  }

  /// Batch delete
  Future<void> batchDelete(List<String> ids) async {
    final idSet = ids.toSet();
    for (final id in ids) {
      final opp = _opportunities.firstWhere((o) => o.id == id, orElse: () => _opportunities.first);
      await NotificationService.cancelOpportunityReminder(opp);
    }
    _opportunities.removeWhere((o) => idSet.contains(o.id));
    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();
  }

  /// Batch complete
  Future<void> batchComplete(List<String> ids) async {
    final idSet = ids.toSet();
    final now = DateTime.now();
    _opportunities = _opportunities.map((opp) {
      if (idSet.contains(opp.id)) {
        return opp.copyWith(status: OpportunityStatus.completed, updatedAt: now);
      }
      return opp;
    }).toList();

    await StorageService.saveOpportunities(_opportunities, userId: _currentUserId);
    notifyListeners();
  }

  /// Reset all data for current user
  Future<void> resetAllData() async {
    await StorageService.clearOpportunities(userId: _currentUserId);
    _opportunities = [];
    notifyListeners();
  }

  /// Import backup
  Future<bool> importData(String jsonString) async {
    final success = await StorageService.importBackup(jsonString, userId: _currentUserId);
    if (success) {
      await loadOpportunities();
    }
    return success;
  }
}

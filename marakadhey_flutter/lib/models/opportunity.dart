import 'dart:convert';

enum Priority { high, medium, low }

extension PriorityExtension on Priority {
  String toShortString() {
    switch (this) {
      case Priority.high:
        return 'HIGH';
      case Priority.medium:
        return 'MEDIUM';
      case Priority.low:
        return 'LOW';
    }
  }

  static Priority fromString(String? str) {
    if (str == null) return Priority.medium;
    switch (str.toUpperCase()) {
      case 'HIGH':
        return Priority.high;
      case 'LOW':
        return Priority.low;
      case 'MEDIUM':
      default:
        return Priority.medium;
    }
  }
}

enum OpportunityStatus { pending, inProgress, completed, archived }

extension OpportunityStatusExtension on OpportunityStatus {
  String toShortString() {
    switch (this) {
      case OpportunityStatus.pending:
        return 'PENDING';
      case OpportunityStatus.inProgress:
        return 'IN_PROGRESS';
      case OpportunityStatus.completed:
        return 'COMPLETED';
      case OpportunityStatus.archived:
        return 'ARCHIVED';
    }
  }

  static OpportunityStatus fromString(String? str) {
    if (str == null) return OpportunityStatus.pending;
    switch (str.toUpperCase()) {
      case 'IN_PROGRESS':
        return OpportunityStatus.inProgress;
      case 'COMPLETED':
        return OpportunityStatus.completed;
      case 'ARCHIVED':
        return OpportunityStatus.archived;
      case 'PENDING':
      default:
        return OpportunityStatus.pending;
    }
  }
}

class ChecklistItem {
  final String id;
  final String task;
  final bool completed;

  ChecklistItem({
    required this.id,
    required this.task,
    this.completed = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? task,
    bool? completed,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      task: task ?? this.task,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'completed': completed,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      task: map['task'] ?? '',
      completed: map['completed'] ?? false,
    );
  }
}

class HistoryEntry {
  final String id;
  final String action;
  final String timestamp;
  final String? note;

  HistoryEntry({
    required this.id,
    required this.action,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'timestamp': timestamp,
      if (note != null) 'note': note,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      timestamp: map['timestamp'] ?? '',
      note: map['note'],
    );
  }
}

class Opportunity {
  final String id;
  final String title;
  final String? description;
  final String? websiteUrl;
  final String category;
  final Priority priority;
  final OpportunityStatus status;
  final DateTime deadline;
  final bool isRecurring;
  final String? recurrenceRule; // 'none', 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final String? repeatPattern; // 'weekdays', 'weekends', 'custom'
  final List<String> customDays; // ['Mon', 'Wed', 'Fri']
  final int repeatIntervalDays;
  final int leadTimeMinutes;
  final List<ChecklistItem> checklist;
  final List<String> tags;
  final bool pinned;
  final List<HistoryEntry> history;
  final DateTime createdAt;
  final DateTime updatedAt;

  Opportunity({
    required this.id,
    required this.title,
    this.description,
    this.websiteUrl,
    required this.category,
    this.priority = Priority.medium,
    this.status = OpportunityStatus.pending,
    required this.deadline,
    this.isRecurring = false,
    this.recurrenceRule,
    this.repeatPattern,
    this.customDays = const [],
    this.repeatIntervalDays = 1,
    this.leadTimeMinutes = 0,
    this.checklist = const [],
    this.tags = const [],
    this.pinned = false,
    this.history = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Opportunity copyWith({
    String? id,
    String? title,
    String? description,
    String? websiteUrl,
    String? category,
    Priority? priority,
    OpportunityStatus? status,
    DateTime? deadline,
    bool? isRecurring,
    String? recurrenceRule,
    String? repeatPattern,
    List<String>? customDays,
    int? repeatIntervalDays,
    int? leadTimeMinutes,
    List<ChecklistItem>? checklist,
    List<String>? tags,
    bool? pinned,
    List<HistoryEntry>? history,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Opportunity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      repeatPattern: repeatPattern ?? this.repeatPattern,
      customDays: customDays ?? this.customDays,
      repeatIntervalDays: repeatIntervalDays ?? this.repeatIntervalDays,
      leadTimeMinutes: leadTimeMinutes ?? this.leadTimeMinutes,
      checklist: checklist ?? this.checklist,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'category': category,
      'priority': priority.toShortString(),
      'status': status.toShortString(),
      'deadline': deadline.toIso8601String(),
      'isRecurring': isRecurring,
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
      if (repeatPattern != null) 'repeatPattern': repeatPattern,
      'customDays': customDays,
      'repeatIntervalDays': repeatIntervalDays,
      'leadTimeMinutes': leadTimeMinutes,
      'checklist': checklist.map((x) => x.toMap()).toList(),
      'tags': tags,
      'pinned': pinned,
      'history': history.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Opportunity.fromMap(Map<String, dynamic> map) {
    return Opportunity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      websiteUrl: map['websiteUrl'],
      category: map['category'] ?? 'Internship',
      priority: PriorityExtension.fromString(map['priority']),
      status: OpportunityStatusExtension.fromString(map['status']),
      deadline: DateTime.tryParse(map['deadline'] ?? '') ?? DateTime.now(),
      isRecurring: map['isRecurring'] ?? false,
      recurrenceRule: map['recurrenceRule'],
      repeatPattern: map['repeatPattern'],
      customDays: List<String>.from(map['customDays'] ?? []),
      repeatIntervalDays: map['repeatIntervalDays'] ?? 1,
      leadTimeMinutes: map['leadTimeMinutes'] ?? 0,
      checklist: (map['checklist'] as List<dynamic>?)
              ?.map((x) => ChecklistItem.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      tags: List<String>.from(map['tags'] ?? []),
      pinned: map['pinned'] ?? false,
      history: (map['history'] as List<dynamic>?)
              ?.map((x) => HistoryEntry.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory Opportunity.fromJson(String source) => Opportunity.fromMap(json.decode(source));
}

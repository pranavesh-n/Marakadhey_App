import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/categories.dart';
import '../models/opportunity.dart';
import '../providers/opportunity_provider.dart';
import '../services/share_receiver_service.dart';
import '../services/url_metadata_service.dart';
import '../widgets/header_widget.dart';

class AddReminderScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialTitle;
  final VoidCallback? onNavigateToInbox;

  const AddReminderScreen({
    super.key,
    this.initialUrl,
    this.initialTitle,
    this.onNavigateToInbox,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedHour = '09';
  String _selectedMinute = '00';
  String _selectedAmPm = 'AM';

  Priority _selectedPriority = Priority.medium;
  String _selectedCategory = 'Internship';
  String _selectedRecurrence = 'none';
  int _leadTimeMinutes = 0;
  List<String> _tags = [];
  final bool _pushNotifications = true;

  bool _isScanning = false;
  String? _detectedTitle;
  StreamSubscription? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _initTimeToCurrent(offsetMinutes: 5);

    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlController.text = widget.initialUrl!;
      if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
        _titleController.text = widget.initialTitle!;
      } else {
        _handleScanUrl();
      }
    }

    final initialPayload = ShareReceiverService.consumeLatestPayload();
    if (initialPayload != null) {
      if (initialPayload.url.isNotEmpty) {
        _urlController.text = initialPayload.url;
      }
      if (initialPayload.title != null && initialPayload.title!.isNotEmpty) {
        _titleController.text = initialPayload.title!;
        _detectedTitle = initialPayload.title;
        _autoDetectDateTimeFromText(initialPayload.title!);
      } else if (initialPayload.url.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleScanUrl());
      }
    }

    _shareSubscription = ShareReceiverService.sharedStream.listen((payload) {
      if (mounted) {
        setState(() {
          if (payload.url.isNotEmpty) {
            _urlController.text = payload.url;
          }
          if (payload.title != null && payload.title!.isNotEmpty) {
            _titleController.text = payload.title!;
            _detectedTitle = payload.title;
            _autoDetectDateTimeFromText(payload.title!);
          } else if (payload.url.isNotEmpty) {
            _handleScanUrl();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _titleController.dispose();
    _urlController.dispose();
    _tagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initTimeToCurrent({int offsetMinutes = 5}) {
    final now = DateTime.now().add(Duration(minutes: offsetMinutes));
    _selectedDate = now;
    int h = now.hour;
    _selectedAmPm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    _selectedHour = h.toString().padLeft(2, '0');
    _selectedMinute = now.minute.toString().padLeft(2, '0');
  }

  void _autoDetectDateTimeFromText(String text) {
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm|AM|PM)?').firstMatch(text);
    if (timeMatch != null) {
      int h = int.parse(timeMatch.group(1)!);
      int m = int.parse(timeMatch.group(2)!);
      String? ampm = timeMatch.group(3)?.toUpperCase();
      if (ampm == null) {
        ampm = h >= 12 ? 'PM' : 'AM';
        if (h > 12) h -= 12;
        if (h == 0) h = 12;
      }
      setState(() {
        _selectedHour = h.toString().padLeft(2, '0');
        _selectedMinute = m.toString().padLeft(2, '0');
        _selectedAmPm = ampm ?? 'PM';
      });
    }
  }

  void _handlePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      if (preset == 'today-eve') {
        _selectedDate = now;
        _selectedHour = '06';
        _selectedMinute = '00';
        _selectedAmPm = 'PM';
      } else if (preset == 'tomorrow') {
        _selectedDate = now.add(const Duration(days: 1));
        _selectedHour = '09';
        _selectedMinute = '00';
        _selectedAmPm = 'AM';
      } else if (preset == '3days') {
        _selectedDate = now.add(const Duration(days: 3));
        _selectedHour = '09';
        _selectedMinute = '00';
        _selectedAmPm = 'AM';
      } else if (preset == '1week') {
        _selectedDate = now.add(const Duration(days: 7));
        _selectedHour = '09';
        _selectedMinute = '00';
        _selectedAmPm = 'AM';
      } else if (preset == '1month') {
        _selectedDate = DateTime(now.year, now.month + 1, now.day);
        _selectedHour = '09';
        _selectedMinute = '00';
        _selectedAmPm = 'AM';
      }
    });
  }

  Future<void> _handleScanUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a full URL starting with https://')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _detectedTitle = null;
    });

    final foundTitle = await UrlMetadataService.fetchTitle(url);

    setState(() {
      _isScanning = false;
      if (foundTitle != null && foundTitle.isNotEmpty) {
        _detectedTitle = foundTitle;
        _titleController.text = foundTitle;
        _autoDetectDateTimeFromText(foundTitle);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not auto-read title. Please type it in.')),
        );
      }
    });
  }

  DateTime _computeDateTime() {
    int h = int.parse(_selectedHour);
    if (_selectedAmPm == 'PM' && h < 12) h += 12;
    if (_selectedAmPm == 'AM' && h == 12) h = 0;
    final m = int.parse(_selectedMinute);
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      h,
      m,
    );
  }

  Future<void> _handleSave({DateTime? overrideDeadline}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showErrorDialog(
        title: 'Title Required',
        message: 'Please enter a title or position name for this opportunity before saving.',
      );
      return;
    }

    final deadline = overrideDeadline ?? _computeDateTime();
    final now = DateTime.now();

    if (deadline.isBefore(now)) {
      _showPastTimeDialog(deadline: deadline, title: title);
      return;
    }

    final provider = context.read<OpportunityProvider>();
    final savedCategory = _selectedCategory;

    await provider.addOpportunity(
      title: title,
      deadline: deadline,
      category: _selectedCategory,
      priority: _selectedPriority,
      websiteUrl: _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null,
      description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      isRecurring: _selectedRecurrence != 'none',
      recurrenceRule: _selectedRecurrence != 'none' ? _selectedRecurrence : null,
      leadTimeMinutes: _leadTimeMinutes,
      tags: _tags,
      sendNotification: _pushNotifications,
    );

    setState(() {
      _titleController.clear();
      _urlController.clear();
      _tagController.clear();
      _notesController.clear();
      _detectedTitle = null;
      _tags = [];
      _initTimeToCurrent(offsetMinutes: 5);
      _selectedPriority = Priority.medium;
      _selectedCategory = 'Internship';
      _selectedRecurrence = 'none';
    });

    if (mounted) {
      _showSuccessDialog(
        title: title,
        deadline: deadline,
        category: savedCategory,
      );
    }
  }

  void _showSuccessDialog({
    required String title,
    required DateTime deadline,
    required String category,
  }) {
    final catColor = AppColors.getCategoryColor(category);
    final formattedTime = DateFormat('MMM dd, yyyy • hh:mm a').format(deadline);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reminder Saved Successfully! ✓',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(color: catColor, fontWeight: FontWeight.w800, fontSize: 10),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.alarm_on_rounded, size: 16, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'Alarm set for: $formattedTime',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Add Another', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF475569))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onNavigateToInbox?.call();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View in Inbox', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPastTimeDialog({
    required DateTime deadline,
    required String title,
  }) {
    final formattedTime = DateFormat('yyyy-MM-dd hh:mm a').format(deadline);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFFEF4444), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Past Time Detected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The selected deadline ($formattedTime) is in the past.\n\nHardware alarms & notifications can only ring for future deadlines.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text('Set to 5 Mins from Now & Save', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final newTarget = DateTime.now().add(const Duration(minutes: 5));
                    _handleSave(overrideDeadline: newTarget);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Change Time Manually', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const MarakadheyHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card 1: Main Opportunity Information
                      _buildModernCard(
                        title: 'OPPORTUNITY DETAILS',
                        icon: Icons.bookmark_added_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Input
                            _buildFieldLabel('TITLE / POSITION'),
                            TextField(
                              controller: _titleController,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              decoration: _modernInputDecoration(
                                hintText: 'e.g. Google Summer Internship / Rhodes Scholarship',
                                prefixIcon: Icons.title_rounded,
                              ),
                            ),
                            if (_detectedTitle != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFED7AA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 15),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Captured: "$_detectedTitle"',
                                        style: const TextStyle(color: Color(0xFF9A3412), fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // URL Input + Scan Action
                            _buildFieldLabel('WEBPAGE LINK (OPTIONAL)'),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _urlController,
                                    keyboardType: TextInputType.url,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    decoration: _modernInputDecoration(
                                      hintText: 'https://careers.google.com/...',
                                      prefixIcon: Icons.link_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                    ),
                                    onPressed: _isScanning ? null : _handleScanUrl,
                                    child: _isScanning
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.auto_fix_high_rounded, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Category & Priority Grid
                            Row(
                              children: [
                                // Category
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('CATEGORY'),
                                      Container(
                                        height: 46,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedCategory,
                                            isExpanded: true,
                                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                            items: AppConstants.categories.map((c) {
                                              return DropdownMenuItem(
                                                value: c,
                                                child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                              );
                                            }).toList(),
                                            onChanged: (v) {
                                              if (v != null) setState(() => _selectedCategory = v);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Priority
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('PRIORITY'),
                                      Container(
                                        height: 46,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<Priority>(
                                            value: _selectedPriority,
                                            isExpanded: true,
                                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                            items: const [
                                              DropdownMenuItem(
                                                value: Priority.high,
                                                child: Text('🔴 High', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                                              ),
                                              DropdownMenuItem(
                                                value: Priority.medium,
                                                child: Text('🟡 Medium', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
                                              ),
                                              DropdownMenuItem(
                                                value: Priority.low,
                                                child: Text('🟢 Low', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                                              ),
                                            ],
                                            onChanged: (v) {
                                              if (v != null) setState(() => _selectedPriority = v);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Card 2: Date & Alarm Time (with Auto-Capture & all 60 minutes)
                      _buildModernCard(
                        title: 'DEADLINE & HARDWARE ALARM',
                        icon: Icons.alarm_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Picker
                            _buildFieldLabel('DEADLINE DATE'),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat('yyyy-MM-dd (EEEE)').format(_selectedDate),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Time Picker Row (All 60 Minutes + Clock Dial)
                            _buildFieldLabel('EXACT ALARM TIME'),
                            Row(
                              children: [
                                // Hour
                                Expanded(
                                  flex: 3,
                                  child: _buildTimeDropdown(
                                    value: _selectedHour,
                                    items: AppConstants.hours,
                                    onChanged: (v) => setState(() => _selectedHour = v!),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(':', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                ),
                                // Minute (All 00 to 59 minutes!)
                                Expanded(
                                  flex: 3,
                                  child: _buildTimeDropdown(
                                    value: _selectedMinute,
                                    items: AppConstants.minutes,
                                    onChanged: (v) => setState(() => _selectedMinute = v!),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // AM / PM
                                Expanded(
                                  flex: 3,
                                  child: _buildTimeDropdown(
                                    value: _selectedAmPm,
                                    items: const ['AM', 'PM'],
                                    onChanged: (v) => setState(() => _selectedAmPm = v!),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Interactive Clock Dial Button
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    int initialHour = int.parse(_selectedHour);
                                    if (_selectedAmPm == 'PM' && initialHour < 12) initialHour += 12;
                                    if (_selectedAmPm == 'AM' && initialHour == 12) initialHour = 0;
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(hour: initialHour, minute: int.parse(_selectedMinute)),
                                    );
                                    if (pickedTime != null) {
                                      final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
                                      int h = pickedTime.hourOfPeriod;
                                      if (h == 0) h = 12;
                                      setState(() {
                                        _selectedHour = h.toString().padLeft(2, '0');
                                        _selectedMinute = pickedTime.minute.toString().padLeft(2, '0');
                                        _selectedAmPm = period;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 46,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFED7AA)),
                                    ),
                                    child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 22),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Quick Presets Bar
                            _buildFieldLabel('QUICK SCHEDULE PRESETS'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildPresetPill('Today Evening (6 PM)', 'today-eve'),
                                  const SizedBox(width: 6),
                                  _buildPresetPill('Tomorrow (9 AM)', 'tomorrow'),
                                  const SizedBox(width: 6),
                                  _buildPresetPill('In 3 Days', '3days'),
                                  const SizedBox(width: 6),
                                  _buildPresetPill('In 1 Week', '1week'),
                                  const SizedBox(width: 6),
                                  _buildPresetPill('In 1 Month', '1month'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Lead Time Reminder
                            _buildFieldLabel('REMIND ME IN ADVANCE'),
                            Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _leadTimeMinutes,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                  items: AppConstants.leadTimeOptions.entries.map((e) {
                                    return DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _leadTimeMinutes = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Card 3: Optional Notes & Recurrence
                      _buildModernCard(
                        title: 'ADDITIONAL DETAILS (OPTIONAL)',
                        icon: Icons.notes_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('PREPARATION NOTES / CHECKLIST'),
                            TextField(
                              controller: _notesController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              decoration: _modernInputDecoration(
                                hintText: 'e.g. Keep resume and portfolio ready...',
                                prefixIcon: Icons.edit_note_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Repeat / Recurrence
                            Row(
                              children: [
                                const Text('Repeat Reminder:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedRecurrence,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                                        items: const [
                                          DropdownMenuItem(value: 'none', child: Text('Never (One-time)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                          DropdownMenuItem(value: 'daily', child: Text('Daily', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                          DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                          DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                        ],
                                        onChanged: (v) {
                                          if (v != null) setState(() => _selectedRecurrence = v);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main Action Button (Floating High-Impact CTA)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _handleSave,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm_add_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Save Opportunity & Set Alarm',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF475569),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration({required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
    );
  }

  Widget _buildTimeDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
          items: items.map((it) {
            return DropdownMenuItem(
              value: it,
              child: Center(
                child: Text(
                  it,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPresetPill(String label, String presetKey, {bool isUrgent = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _handlePreset(presetKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUrgent ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUrgent ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isUrgent ? AppColors.primary : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

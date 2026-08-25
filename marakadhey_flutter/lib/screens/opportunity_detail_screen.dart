import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../models/opportunity.dart';
import '../providers/opportunity_provider.dart';
import '../widgets/countdown_badge.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;

  const OpportunityDetailScreen({
    super.key,
    required this.opportunityId,
  });

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) return;
    try {
      final uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _handleAddTask(OpportunityProvider provider) {
    final task = _taskController.text.trim();
    if (task.isNotEmpty) {
      provider.addChecklistItem(widget.opportunityId, task);
      _taskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();
    final opp = provider.opportunities.firstWhere(
      (o) => o.id == widget.opportunityId,
      orElse: () => Opportunity(
        id: '',
        title: 'Not Found',
        category: 'Other',
        deadline: DateTime.now(),
      ),
    );

    if (opp.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Opportunity was deleted')),
      );
    }

    final isCompleted = opp.status == OpportunityStatus.completed;
    final categoryColor = AppColors.getCategoryColor(opp.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
        title: const Text(
          'Opportunity Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              opp.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: opp.pinned ? AppColors.primary : Colors.white,
            ),
            onPressed: () => provider.togglePin(opp.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              Share.share('Reminder: ${opp.title}\nCategory: ${opp.category}\nDeadline: ${opp.deadline}\n${opp.websiteUrl ?? ''}\n— Tracked via Marakadhey Mobile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Opportunity?'),
                  content: Text('Delete "${opp.title}" permanently?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await provider.deleteOpportunity(opp.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        opp.category.toUpperCase(),
                        style: TextStyle(color: categoryColor, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${opp.priority.toShortString()} PRIORITY',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.secondary),
                      ),
                    ),
                    const Spacer(),
                    CountdownBadge(deadline: opp.deadline, isCompleted: isCompleted),
                  ],
                ),
                const SizedBox(height: 12),

                // Opportunity Title
                Text(
                  opp.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Webpage URL Card
                if (opp.websiteUrl?.isNotEmpty == true) ...[
                  InkWell(
                    onTap: () => _openUrl(opp.websiteUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ORIGINAL WEBPAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                Text(
                                  opp.websiteUrl!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Deadline & Reminders Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alarm, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DEADLINE & ALARM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy @ h:mm a').format(opp.deadline),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (opp.isRecurring) ...[
                        const Divider(height: 20, color: AppColors.surfaceBorder),
                        Row(
                          children: [
                            const Icon(Icons.repeat, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('RECURRENCE SCHEDULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                  Text(
                                    'Repeats ${(opp.recurrenceRule ?? 'weekly').toUpperCase()}${opp.repeatPattern != null ? ' (${opp.repeatPattern})' : ''}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Section
                if (opp.description?.isNotEmpty == true) ...[
                  _buildSectionHeader('Notes & Description'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      opp.description!,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tags Section
                if (opp.tags.isNotEmpty) ...[
                  _buildSectionHeader('Tags'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: opp.tags.map((t) {
                      return Chip(
                        label: Text('#$t', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        backgroundColor: const Color(0xFFFFF7ED),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Checklist Section
                _buildSectionHeader('Checklist & Sub-Tasks'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      // Checklist items
                      if (opp.checklist.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No sub-tasks added yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        )
                      else
                        ...opp.checklist.map((chk) {
                          return CheckboxListTile(
                            value: chk.completed,
                            activeColor: AppColors.statusCompleted,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              chk.task,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: chk.completed ? TextDecoration.lineThrough : null,
                                color: chk.completed ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                            onChanged: (_) => provider.toggleChecklistItem(opp.id, chk.id),
                          );
                        }),
                      const Divider(color: AppColors.surfaceBorder),
                      // Add new task input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _taskController,
                              decoration: const InputDecoration(
                                hintText: 'Add a sub-task (e.g. Prepare resume)...',
                                hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _handleAddTask(provider),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.primary),
                            onPressed: () => _handleAddTask(provider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Activity History Log
                if (opp.history.isNotEmpty) ...[
                  _buildSectionHeader('Activity History'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      children: opp.history.reversed.map((h) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.history, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${h.action}${h.note != null ? ' — ${h.note}' : ''}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(DateTime.tryParse(h.timestamp) ?? DateTime.now()),
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons at bottom
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted ? AppColors.secondary : AppColors.statusCompleted,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(isCompleted ? Icons.undo : Icons.check_circle_outline),
                        label: Text(
                          isCompleted ? 'Mark as Pending' : 'Complete Opportunity',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => provider.toggleComplete(opp.id),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.snooze),
                      label: const Text('Snooze 1h', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        provider.snoozeOpportunity(opp.id, 60);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Snoozed for 1 hour')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

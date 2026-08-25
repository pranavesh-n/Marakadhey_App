import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../models/opportunity.dart';
import '../providers/opportunity_provider.dart';
import '../screens/opportunity_detail_screen.dart';
import 'countdown_badge.dart';

class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;

  const OpportunityCard({
    super.key,
    required this.opportunity,
  });

  Color _getPriorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return const Color(0xFFEF4444);
      case Priority.medium:
        return const Color(0xFFF59E0B);
      case Priority.low:
        return const Color(0xFF10B981);
    }
  }

  Future<void> _openUrl(BuildContext context, String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) return;
    try {
      final uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          final provider = context.read<OpportunityProvider>();
          if (provider.markCompletedOnOpen && opportunity.status == OpportunityStatus.pending) {
            await provider.toggleComplete(opportunity.id);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OpportunityProvider>();
    final isCompleted = opportunity.status == OpportunityStatus.completed;
    final priorityColor = _getPriorityColor(opportunity.priority);
    final categoryColor = AppColors.getCategoryColor(opportunity.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: opportunity.pinned
              ? AppColors.primary
              : const Color(0xFFE2E8F0),
          width: opportunity.pinned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OpportunityDetailScreen(opportunityId: opportunity.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges Row
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        opportunity.category.toUpperCase(),
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            opportunity.priority.toShortString(),
                            style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (opportunity.isRecurring) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat_rounded, color: Color(0xFF2563EB), size: 12),
                            const SizedBox(width: 3),
                            Text(
                              (opportunity.recurrenceRule ?? 'Repeat').toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Pin Button
                    IconButton(
                      icon: Icon(
                        opportunity.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 18,
                        color: opportunity.pinned ? AppColors.primary : const Color(0xFF94A3B8),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => provider.togglePin(opportunity.id),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Checkbox & Title Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => provider.toggleComplete(opportunity.id),
                      child: Container(
                        margin: const EdgeInsets.only(top: 2, right: 12),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opportunity.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              height: 1.25,
                            ),
                          ),
                          if (opportunity.websiteUrl?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _openUrl(context, opportunity.websiteUrl),
                              child: Row(
                                children: [
                                  const Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      opportunity.websiteUrl!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer Row: Countdown badge, Sub-tasks, Quick actions
                Row(
                  children: [
                    CountdownBadge(
                      deadline: opportunity.deadline,
                      isCompleted: isCompleted,
                    ),
                    if (opportunity.checklist.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_box_outlined, size: 12, color: Color(0xFF475569)),
                            const SizedBox(width: 4),
                            Text(
                              '${opportunity.checklist.where((c) => c.completed).length}/${opportunity.checklist.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Snooze Dropdown
                    PopupMenuButton<int>(
                      icon: const Icon(Icons.snooze_rounded, size: 19, color: Color(0xFF64748B)),
                      tooltip: 'Snooze reminder',
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (mins) {
                        provider.snoozeOpportunity(opportunity.id, mins);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Snoozed for ${mins >= 1440 ? '${mins ~/ 1440} day(s)' : mins >= 60 ? '${mins ~/ 60} hour(s)' : '$mins mins'}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 15, child: Text('Snooze 15 minutes')),
                        const PopupMenuItem(value: 60, child: Text('Snooze 1 hour')),
                        const PopupMenuItem(value: 180, child: Text('Snooze 3 hours')),
                        const PopupMenuItem(value: 1440, child: Text('Snooze 1 day (Tomorrow)')),
                        const PopupMenuItem(value: 10080, child: Text('Snooze 1 week')),
                      ],
                    ),
                    // Share Button
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final text = 'Reminder: ${opportunity.title}\nCategory: ${opportunity.category}\nDeadline: ${opportunity.deadline}\n${opportunity.websiteUrl ?? ''}\n— Tracked via Marakadhey Mobile';
                        Share.share(text);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

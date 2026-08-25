import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/opportunity.dart';
import '../providers/opportunity_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/opportunity_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();
    final total = provider.totalCount;
    final pending = provider.pendingCount;
    final completed = provider.completedCount;
    final completionRate = total > 0 ? ((completed / total) * 100).toInt() : 0;

    final urgentOpportunities = provider.opportunities
        .where((o) =>
            o.status != OpportunityStatus.completed &&
            o.deadline.isAfter(DateTime.now()) &&
            o.deadline.isBefore(DateTime.now().add(const Duration(hours: 48))))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const MarakadheyHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard & Analytics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track your deadlines, progress stats, and opportunity breakdown.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      // Metrics Cards Grid
                      Row(
                        children: [
                          _buildMetricCard(
                            title: 'TOTAL TRACKED',
                            value: total.toString(),
                            icon: Icons.track_changes_rounded,
                            color: const Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 10),
                          _buildMetricCard(
                            title: 'PENDING',
                            value: pending.toString(),
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildMetricCard(
                            title: 'COMPLETED',
                            value: completed.toString(),
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 10),
                          _buildMetricCard(
                            title: 'SUCCESS RATE',
                            value: '$completionRate%',
                            icon: Icons.pie_chart_rounded,
                            color: const Color(0xFF6366F1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Urgent Deadlines Section (Next 48 Hours)
                      if (urgentOpportunities.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFEF4444)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Urgent Deadlines (Next 48h) — ${urgentOpportunities.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...urgentOpportunities.map((o) => OpportunityCard(opportunity: o)),
                        const SizedBox(height: 16),
                      ],

                      // Category Breakdown Section
                      _buildSectionHeader('Opportunities by Category'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: total == 0
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No opportunities tracked yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                ),
                              )
                            : Column(
                                children: provider.categoryStats.entries.map((e) {
                                  final cat = e.key;
                                  final count = e.value;
                                  final catColor = AppColors.getCategoryColor(cat);
                                  final pct = total > 0 ? (count / total) : 0.0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: catColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  cat,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '$count (${(pct * 100).toInt()}%)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            minHeight: 7,
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Priority Distribution Section
                      _buildSectionHeader('Priority Breakdown'),
                      Row(
                        children: [
                          _buildPriorityPill('High Priority', provider.highPriorityCount, const Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          _buildPriorityPill('Medium Priority', provider.mediumPriorityCount, const Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          _buildPriorityPill('Low Priority', provider.lowPriorityCount, const Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 30),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

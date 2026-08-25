import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CountdownBadge extends StatelessWidget {
  final DateTime deadline;
  final bool isCompleted;

  const CountdownBadge({
    super.key,
    required this.deadline,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 12),
            SizedBox(width: 4),
            Text(
              'Completed',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final difference = deadline.difference(now);

    String label;
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;

    if (difference.isNegative) {
      label = 'Expired';
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFDC2626);
      borderColor = const Color(0xFFFECACA);
      icon = Icons.error_outline;
    } else if (difference.inHours < 24) {
      if (difference.inHours == 0) {
        label = 'Due in ${difference.inMinutes}m';
      } else {
        label = 'Due in ${difference.inHours}h ${difference.inMinutes % 60}m';
      }
      bgColor = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFEA580C);
      borderColor = const Color(0xFFFED7AA);
      icon = Icons.alarm;
    } else if (difference.inDays < 7) {
      label = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
      bgColor = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF2563EB);
      borderColor = const Color(0xFFBFDBFE);
      icon = Icons.calendar_today;
    } else {
      label = DateFormat('MMM d, yyyy').format(deadline);
      bgColor = const Color(0xFFF8FAFC);
      textColor = const Color(0xFF64748B);
      borderColor = const Color(0xFFE2E8F0);
      icon = Icons.event;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

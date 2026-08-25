import 'package:flutter/material.dart';

class AppColors {
  // Brand colors matching Marakadhey extension
  static const Color primary = Color(0xFFFF6B00); // Brand Orange
  static const Color primaryDark = Color(0xFFE05300);
  static const Color primaryLight = Color(0xFFFFE8D6);

  static const Color secondary = Color(0xFF1E293B); // Navy Blue Slate
  static const Color secondaryDark = Color(0xFF0F172A);
  static const Color headerBg = Color(0xFF1E293B);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFCBD5E1);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444); // Red
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber
  static const Color priorityLow = Color(0xFF10B981); // Green

  // Status Colors
  static const Color statusPending = Color(0xFF3B82F6); // Blue
  static const Color statusCompleted = Color(0xFF10B981); // Green
  static const Color statusArchived = Color(0xFF6B7280); // Gray

  // Category Colors
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'internship':
        return const Color(0xFF6366F1); // Indigo
      case 'job':
        return const Color(0xFF0EA5E9); // Sky
      case 'scholarship':
        return const Color(0xFF8B5CF6); // Purple
      case 'hackathon':
        return const Color(0xFFEC4899); // Pink
      case 'webinar':
        return const Color(0xFF14B8A6); // Teal
      case 'certification':
        return const Color(0xFFF97316); // Orange
      case 'exam':
        return const Color(0xFFEF4444); // Red
      case 'application':
      case 'registration':
        return const Color(0xFFF59E0B); // Amber
      case 'assignment':
        return const Color(0xFF10B981); // Emerald
      case 'conference':
        return const Color(0xFF3B82F6); // Blue
      case 'personal':
        return const Color(0xFF64748B); // Slate
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

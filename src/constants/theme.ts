import { DimensionValue } from 'react-native';

// Marakadhey v2.3.1 Exact Zip File Theme System
export const Colors = {
  // Brand Base Colors (Cute Zip File Look)
  headerBg: '#1F2937',      // Dark Navy Header
  headerBorder: '#FF6B00',  // Orange Accent Line (3px)
  taglineText: '#9CA3AF',   // Header tagline gray
  
  background: '#F3F4F6',    // Light app background
  surface: '#FFFFFF',       // Card background
  surfaceElevated: '#FFFFFF', // Elevated card / Modal background
  surfaceBorder: '#E5E7EB',   // Soft container borders
  
  // Brand Primary (Marakadhey Orange)
  primary: '#FF6B00',
  primaryHover: '#E05E00',
  primaryGlow: 'rgba(255, 107, 0, 0.15)',
  secondary: '#1F2937',
  
  // Priority Indicators & Legacy Tokens
  priorityHigh: '#EF4444',
  priorityHighBg: '#FEF2F2',
  priorityHighText: '#EF4444',
  priorityHighGlow: 'rgba(239, 68, 68, 0.15)',

  priorityMedium: '#D97706',
  priorityMediumBg: '#FFFBEB',
  priorityMediumText: '#D97706',
  priorityMediumGlow: 'rgba(217, 119, 6, 0.15)',

  priorityLow: '#3B82F6',
  priorityLowBg: '#EFF6FF',
  priorityLowText: '#3B82F6',
  priorityLowGlow: 'rgba(59, 130, 246, 0.15)',

  // Status Colors (Zip File Exact)
  statusCompletedBg: '#F3F4F6',
  statusCompletedText: '#4B5563',
  statusOverdueBg: '#FEF2F2',
  statusOverdueText: '#DC2626',
  statusTodayBg: '#FFF7ED',
  statusTodayText: '#C2410C',
  statusUpcomingBg: '#F0FDF4',
  statusUpcomingText: '#15803D',

  // Typography Text Colors
  textPrimary: '#1F2937',
  textSecondary: '#4B5563',
  textMuted: '#6B7280',
  textLight: '#9CA3AF',
  textWhite: '#FFFFFF',

  // System Colors
  success: '#10B981',
  danger: '#EF4444',
  warning: '#F59E0B',
  info: '#3B82F6',
  
  // Presets & Pill Buttons
  presetBg: '#E5E7EB',
  presetText: '#1F2937',

  // Overlay & Glassmorphism
  glassBackground: 'rgba(255, 255, 255, 0.95)',
  overlay: 'rgba(31, 41, 55, 0.7)',
};

export const CategoryMeta: Record<string, { label: string; color: string; icon: string }> = {
  Internship: { label: 'Internship', color: '#FF6B00', icon: 'briefcase' },
  Job: { label: 'Job Application', color: '#10B981', icon: 'building' },
  Scholarship: { label: 'Scholarship', color: '#3B82F6', icon: 'award' },
  Webinar: { label: 'Webinar', color: '#8B5CF6', icon: 'video' },
  Hackathon: { label: 'Hackathon', color: '#EC4899', icon: 'code' },
  Certification: { label: 'Certification', color: '#06B6D4', icon: 'award' },
  Personal: { label: 'Personal', color: '#F59E0B', icon: 'user' },
  Other: { label: 'General', color: '#6B7280', icon: 'bookmark' },
};

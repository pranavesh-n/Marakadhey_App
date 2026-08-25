import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Linking } from 'react-native';
import { Opportunity } from '../types/opportunity';
import { Colors, CategoryMeta } from '../constants/theme';
import { CountdownTimer } from './CountdownTimer';
import { CheckCircle2, Circle, Clock, Pin, ExternalLink } from 'lucide-react-native';

interface CardProps {
  opportunity: Opportunity;
  onPress: () => void;
  onToggleComplete: () => void;
  onSnooze: () => void;
  onTogglePin: () => void;
}

export const OpportunityCard: React.FC<CardProps> = ({
  opportunity,
  onPress,
  onToggleComplete,
  onSnooze,
  onTogglePin,
}) => {
  const categoryInfo = CategoryMeta[opportunity.category] || CategoryMeta.Other;
  const isCompleted = opportunity.status === 'COMPLETED';

  const priorityColor =
    opportunity.priority === 'HIGH'
      ? Colors.priorityHigh
      : opportunity.priority === 'MEDIUM'
      ? Colors.priorityMedium
      : Colors.priorityLow;

  const priorityBg =
    opportunity.priority === 'HIGH'
      ? Colors.priorityHighBg
      : opportunity.priority === 'MEDIUM'
      ? Colors.priorityMediumBg
      : Colors.priorityLowBg;

  const priorityText =
    opportunity.priority === 'HIGH'
      ? Colors.priorityHighText
      : opportunity.priority === 'MEDIUM'
      ? Colors.priorityMediumText
      : Colors.priorityLowText;

  const handleOpenUrl = (e: any) => {
    e.stopPropagation();
    if (opportunity.websiteUrl) {
      Linking.openURL(opportunity.websiteUrl);
    }
  };

  return (
    <TouchableOpacity
      activeOpacity={0.88}
      onPress={onPress}
      style={[
        styles.card,
        { borderLeftColor: priorityColor },
        isCompleted && styles.completedCard,
        opportunity.pinned && styles.pinnedCard,
      ]}
    >
      {/* Top Meta Bar */}
      <View style={styles.topBar}>
        <View style={styles.leftPills}>
          {/* Priority Pill */}
          <View style={[styles.priorityPill, { backgroundColor: priorityBg }]}>
            <View style={[styles.dot, { backgroundColor: priorityColor }]} />
            <Text style={[styles.priorityText, { color: priorityText }]}>
              {opportunity.priority}
            </Text>
          </View>

          {/* Category Badge */}
          <View style={[styles.categoryBadge, { backgroundColor: categoryInfo.color + '15' }]}>
            <Text style={[styles.categoryText, { color: categoryInfo.color }]}>
              {categoryInfo.label}
            </Text>
          </View>
        </View>

        {/* Action icons (Pin & Complete toggle) */}
        <View style={styles.rightActions}>
          <TouchableOpacity
            onPress={onTogglePin}
            style={styles.iconBtn}
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          >
            <Pin
              size={17}
              color={opportunity.pinned ? Colors.primary : Colors.textMuted}
              fill={opportunity.pinned ? Colors.primary : 'transparent'}
            />
          </TouchableOpacity>

          <TouchableOpacity
            onPress={onToggleComplete}
            style={styles.iconBtn}
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          >
            {isCompleted ? (
              <CheckCircle2 size={20} color={Colors.success} fill={Colors.success + '20'} />
            ) : (
              <Circle size={20} color={Colors.textMuted} />
            )}
          </TouchableOpacity>
        </View>
      </View>

      {/* Title & Description */}
      <Text style={[styles.title, isCompleted && styles.completedText]} numberOfLines={2}>
        {opportunity.title}
      </Text>

      {opportunity.description ? (
        <Text style={styles.description} numberOfLines={2}>
          {opportunity.description}
        </Text>
      ) : null}

      {/* URL Launcher & Tags */}
      <View style={styles.linksRow}>
        {opportunity.websiteUrl ? (
          <TouchableOpacity style={styles.linkContainer} onPress={handleOpenUrl}>
            <ExternalLink size={12} color={Colors.primary} />
            <Text style={styles.linkText} numberOfLines={1}>
              {opportunity.websiteUrl.replace(/^https?:\/\//, '')}
            </Text>
          </TouchableOpacity>
        ) : null}

        {opportunity.tags &&
          opportunity.tags.length > 0 &&
          opportunity.tags.map((tag) => (
            <View key={tag} style={styles.tagChipSmall}>
              <Text style={styles.tagChipSmallText}>#{tag}</Text>
            </View>
          ))}
      </View>

      {/* Footer Info & Countdown */}
      <View style={styles.footer}>
        <CountdownTimer deadline={opportunity.deadline} compact />

        <TouchableOpacity style={styles.snoozeBtn} onPress={onSnooze}>
          <Clock size={13} color={Colors.textSecondary} />
          <Text style={styles.snoozeText}>+1h Snooze</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    borderLeftWidth: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 2,
  },
  completedCard: {
    backgroundColor: '#F9FAFB',
    opacity: 0.75,
    borderLeftColor: Colors.textMuted,
  },
  pinnedCard: {
    borderColor: Colors.primary,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  leftPills: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  priorityPill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    gap: 4,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  priorityText: {
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 0.4,
  },
  categoryBadge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  categoryText: {
    fontSize: 11,
    fontWeight: '700',
  },
  rightActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  iconBtn: {
    padding: 4,
  },
  title: {
    color: Colors.textPrimary,
    fontSize: 15,
    fontWeight: '800',
    marginBottom: 4,
    lineHeight: 20,
  },
  completedText: {
    textDecorationLine: 'line-through',
    color: Colors.textMuted,
  },
  description: {
    color: Colors.textSecondary,
    fontSize: 13,
    lineHeight: 18,
    marginBottom: 8,
  },
  linksRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginBottom: 8,
  },
  linkContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFF7ED',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#FFEDD5',
  },
  linkText: {
    color: Colors.primary,
    fontSize: 11,
    fontWeight: '700',
    maxWidth: 150,
  },
  tagChipSmall: {
    backgroundColor: '#F3F4F6',
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 6,
  },
  tagChipSmallText: {
    color: Colors.textSecondary,
    fontSize: 10,
    fontWeight: '700',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 4,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  snoozeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: '#F3F4F6',
  },
  snoozeText: {
    color: Colors.textSecondary,
    fontSize: 11,
    fontWeight: '700',
  },
});

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  SafeAreaView,
  StatusBar,
  Linking,
  Alert,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useOpportunities } from '../../context/OpportunityContext';
import { useAuth } from '../../context/AuthContext';
import { Colors, CategoryMeta } from '../../constants/theme';
import { CountdownTimer } from '../../components/CountdownTimer';
import { generateGoogleCalendarLink, generateOutlookCalendarLink } from '../../utils/calendar';
import { ShareService } from '../../services/shareService';
import {
  ChevronLeft,
  ExternalLink,
  CheckCircle2,
  Circle,
  Clock,
  Pin,
  Trash2,
  Plus,
  Sparkles,
  History,
  FileText,
  Share2,
  Calendar,
} from 'lucide-react-native';

export default function OpportunityDetailsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { user } = useAuth();
  const {
    opportunities,
    toggleComplete,
    snoozeOpportunity,
    togglePin,
    deleteOpportunity,
    toggleChecklistItem,
    addChecklistItem,
  } = useOpportunities();

  const [newTaskInput, setNewTaskInput] = useState('');

  const opportunity = opportunities.find((o) => o.id === id);

  if (!opportunity) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.notFoundContainer}>
          <Text style={styles.notFoundTitle}>Opportunity Not Found</Text>
          <Text style={styles.notFoundSub}>This reminder may have been deleted or archived.</Text>
          <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
            <Text style={styles.backBtnText}>Go Back</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const categoryInfo = CategoryMeta[opportunity.category] || CategoryMeta.Other;
  const isCompleted = opportunity.status === 'COMPLETED';

  const priorityColor =
    opportunity.priority === 'HIGH'
      ? Colors.priorityHigh
      : opportunity.priority === 'MEDIUM'
      ? Colors.priorityMedium
      : Colors.priorityLow;

  const handleOpenUrl = () => {
    if (opportunity.websiteUrl) {
      Linking.openURL(opportunity.websiteUrl);
    }
  };

  const handleShare = async () => {
    if (user) {
      await ShareService.shareOpportunityNative(opportunity, user);
    } else {
      Alert.alert('Sign in required to share reminders.');
    }
  };

  const handleOpenGCal = () => {
    const link = generateGoogleCalendarLink(opportunity);
    if (link) Linking.openURL(link);
  };

  const handleOpenOutlook = () => {
    const link = generateOutlookCalendarLink(opportunity);
    if (link) Linking.openURL(link);
  };

  const handleDelete = () => {
    Alert.alert('Delete Opportunity', 'Are you sure you want to remove this opportunity reminder?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => {
          deleteOpportunity(opportunity.id);
          router.back();
        },
      },
    ]);
  };

  const handleAddSubtask = () => {
    if (newTaskInput.trim()) {
      addChecklistItem(opportunity.id, newTaskInput.trim());
      setNewTaskInput('');
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.background} />

      {/* Top Header Bar */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.iconCircle} onPress={() => router.back()}>
          <ChevronLeft size={22} color={Colors.textPrimary} />
        </TouchableOpacity>

        <View style={styles.headerActions}>
          <TouchableOpacity style={styles.iconCircle} onPress={handleShare} activeOpacity={0.8}>
            <Share2 size={17} color={Colors.primary} />
          </TouchableOpacity>

          <TouchableOpacity style={styles.iconCircle} onPress={() => togglePin(opportunity.id)}>
            <Pin
              size={17}
              color={opportunity.pinned ? Colors.primary : Colors.textMuted}
              fill={opportunity.pinned ? Colors.primary : 'transparent'}
            />
          </TouchableOpacity>

          <TouchableOpacity style={styles.iconCircle} onPress={handleDelete}>
            <Trash2 size={17} color={Colors.danger} />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        {/* Priority & Category Badges */}
        <View style={styles.badgeRow}>
          <View
            style={[
              styles.priorityPill,
              { backgroundColor: priorityColor + '20', borderColor: priorityColor },
            ]}
          >
            <View style={[styles.dot, { backgroundColor: priorityColor }]} />
            <Text style={[styles.priorityText, { color: priorityColor }]}>
              {opportunity.priority} PRIORITY
            </Text>
          </View>

          <View style={[styles.categoryBadge, { backgroundColor: categoryInfo.color + '20' }]}>
            <Text style={[styles.categoryText, { color: categoryInfo.color }]}>
              {categoryInfo.label}
            </Text>
          </View>
        </View>

        {/* Opportunity Title */}
        <Text style={styles.title}>{opportunity.title}</Text>

        {/* Website Launcher Link Button */}
        {opportunity.websiteUrl ? (
          <TouchableOpacity style={styles.linkCard} onPress={handleOpenUrl}>
            <ExternalLink size={15} color={Colors.primary} />
            <Text style={styles.linkText} numberOfLines={1}>
              {opportunity.websiteUrl}
            </Text>
          </TouchableOpacity>
        ) : null}

        {/* Live Countdown Hero Widget */}
        <View style={styles.countdownSection}>
          <Text style={styles.sectionLabel}>LIVE DEADLINE COUNTDOWN</Text>
          <CountdownTimer deadline={opportunity.deadline} />
          <Text style={styles.deadlineFormatted}>
            Target Deadline: {new Date(opportunity.deadline).toLocaleString()}
          </Text>
        </View>

        {/* Action Controls: Complete & Snooze */}
        <View style={styles.actionButtonsRow}>
          <TouchableOpacity
            style={[styles.primaryActionBtn, isCompleted && styles.completedActionBtn]}
            onPress={() => toggleComplete(opportunity.id)}
          >
            {isCompleted ? <CheckCircle2 size={18} color="#FFF" /> : <Circle size={18} color="#FFF" />}
            <Text style={styles.primaryActionText}>
              {isCompleted ? 'Marked Completed ✓' : 'Mark Complete'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.snoozeActionBtn}
            onPress={() => snoozeOpportunity(opportunity.id, 60)}
          >
            <Clock size={16} color={Colors.textSecondary} />
            <Text style={styles.snoozeActionText}>+1h Snooze</Text>
          </TouchableOpacity>
        </View>

        {/* Checklist Subtasks Section */}
        <View style={styles.cardBox}>
          <View style={styles.boxTitleRow}>
            <Sparkles size={16} color={Colors.primary} />
            <Text style={styles.boxTitle}>Action Checklist & Subtasks</Text>
          </View>

          {opportunity.checklist?.map((item) => (
            <TouchableOpacity
              key={item.id}
              style={styles.checkItemRow}
              onPress={() => toggleChecklistItem(opportunity.id, item.id)}
            >
              {item.completed ? (
                <CheckCircle2 size={18} color={Colors.success} fill={Colors.success + '25'} />
              ) : (
                <Circle size={18} color={Colors.textMuted} />
              )}
              <Text style={[styles.checkItemText, item.completed && styles.checkItemCompleted]}>
                {item.task}
              </Text>
            </TouchableOpacity>
          ))}

          {/* Add Subtask Input */}
          <View style={styles.addSubtaskRow}>
            <TextInput
              style={styles.subtaskInput}
              placeholder="Add subtask (e.g. Request recommendation)..."
              placeholderTextColor={Colors.textMuted}
              value={newTaskInput}
              onChangeText={setNewTaskInput}
              onSubmitEditing={handleAddSubtask}
            />
            <TouchableOpacity style={styles.addSubtaskBtn} onPress={handleAddSubtask}>
              <Plus size={16} color="#FFF" />
            </TouchableOpacity>
          </View>
        </View>

        {/* Description & Notes */}
        {opportunity.description ? (
          <View style={styles.cardBox}>
            <View style={styles.boxTitleRow}>
              <FileText size={16} color={Colors.primary} />
              <Text style={styles.boxTitle}>Notes & Context</Text>
            </View>
            <Text style={styles.boxBody}>{opportunity.description}</Text>
          </View>
        ) : null}

        {/* Calendar Sync Launchers */}
        <View style={styles.cardBox}>
          <View style={styles.boxTitleRow}>
            <Calendar size={16} color={Colors.primary} />
            <Text style={styles.boxTitle}>Export to Calendar</Text>
          </View>
          <View style={styles.calBtnRow}>
            <TouchableOpacity style={styles.calBtn} onPress={handleOpenGCal}>
              <Text style={styles.calBtnText}>📅 Google Calendar</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.calBtn} onPress={handleOpenOutlook}>
              <Text style={styles.calBtnText}>📅 Outlook Calendar</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Protection History Timeline */}
        <View style={styles.cardBox}>
          <View style={styles.boxTitleRow}>
            <History size={16} color={Colors.textSecondary} />
            <Text style={styles.boxTitle}>Protection History Log</Text>
          </View>

          {opportunity.history?.map((h) => (
            <View key={h.id} style={styles.historyRow}>
              <View style={styles.historyDot} />
              <View style={{ flex: 1 }}>
                <Text style={styles.historyAction}>
                  {h.action} {h.note ? `• ${h.note}` : ''}
                </Text>
                <Text style={styles.historyTime}>{new Date(h.timestamp).toLocaleString()}</Text>
              </View>
            </View>
          ))}
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  iconCircle: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: Colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  headerActions: {
    flexDirection: 'row',
    gap: 8,
  },
  container: {
    flex: 1,
    paddingHorizontal: 16,
  },
  badgeRow: {
    flexDirection: 'row',
    gap: 8,
    marginVertical: 8,
  },
  priorityPill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    borderWidth: 1,
    gap: 6,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  priorityText: {
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  categoryBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  categoryText: {
    fontSize: 11,
    fontWeight: '700',
  },
  title: {
    color: Colors.textPrimary,
    fontSize: 20,
    fontWeight: '900',
    marginBottom: 10,
    lineHeight: 26,
  },
  linkCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: 'rgba(255, 107, 0, 0.1)',
    paddingHorizontal: 12,
    paddingVertical: 9,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: 'rgba(255, 107, 0, 0.25)',
    marginBottom: 14,
  },
  linkText: {
    color: Colors.primary,
    fontSize: 12,
    fontWeight: '700',
    flex: 1,
  },
  countdownSection: {
    backgroundColor: Colors.surfaceElevated,
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    marginBottom: 14,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  sectionLabel: {
    color: Colors.textMuted,
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 1,
    marginBottom: 8,
  },
  deadlineFormatted: {
    color: Colors.textSecondary,
    fontSize: 11,
    fontWeight: '600',
    marginTop: 6,
  },
  actionButtonsRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 14,
  },
  primaryActionBtn: {
    flex: 2,
    backgroundColor: Colors.primary,
    borderRadius: 12,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  completedActionBtn: {
    backgroundColor: Colors.success,
  },
  primaryActionText: {
    color: '#FFF',
    fontSize: 13,
    fontWeight: '800',
  },
  snoozeActionBtn: {
    flex: 1,
    backgroundColor: Colors.surface,
    borderRadius: 12,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  snoozeActionText: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '700',
  },
  cardBox: {
    backgroundColor: Colors.surface,
    borderRadius: 14,
    padding: 14,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  boxTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 10,
  },
  boxTitle: {
    color: Colors.textPrimary,
    fontSize: 13,
    fontWeight: '800',
  },
  boxBody: {
    color: Colors.textSecondary,
    fontSize: 13,
    lineHeight: 19,
  },
  checkItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 7,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  checkItemText: {
    color: Colors.textPrimary,
    fontSize: 13,
    flex: 1,
  },
  checkItemCompleted: {
    textDecorationLine: 'line-through',
    color: Colors.textMuted,
  },
  addSubtaskRow: {
    flexDirection: 'row',
    gap: 6,
    marginTop: 10,
  },
  subtaskInput: {
    flex: 1,
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 7,
    color: Colors.textPrimary,
    fontSize: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  addSubtaskBtn: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  calBtnRow: {
    flexDirection: 'row',
    gap: 8,
  },
  calBtn: {
    flex: 1,
    backgroundColor: '#F3F4F6',
    borderRadius: 8,
    paddingVertical: 9,
    alignItems: 'center',
  },
  calBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  historyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginVertical: 4,
  },
  historyDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: Colors.primary,
  },
  historyAction: {
    color: Colors.textPrimary,
    fontSize: 12,
    fontWeight: '700',
  },
  historyTime: {
    color: Colors.textMuted,
    fontSize: 10,
  },
  notFoundContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    gap: 8,
  },
  notFoundTitle: {
    color: Colors.textPrimary,
    fontSize: 18,
    fontWeight: '800',
  },
  notFoundSub: {
    color: Colors.textMuted,
    fontSize: 13,
    textAlign: 'center',
  },
  backBtn: {
    backgroundColor: Colors.primary,
    paddingHorizontal: 18,
    paddingVertical: 10,
    borderRadius: 10,
    marginTop: 10,
  },
  backBtnText: {
    color: '#FFF',
    fontWeight: '700',
  },
});

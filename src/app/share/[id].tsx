import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
  ActivityIndicator,
  Linking,
  Alert,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Colors, CategoryMeta } from '../../constants/theme';
import { CountdownTimer } from '../../components/CountdownTimer';
import { ShareService } from '../../services/shareService';
import { useOpportunities } from '../../context/OpportunityContext';
import { useAuth } from '../../context/AuthContext';
import { SharedReminder } from '../../types/opportunity';
import {
  ChevronLeft,
  ExternalLink,
  PlusCircle,
  Clock,
  Sparkles,
  User,
  Share2,
} from 'lucide-react-native';

export default function SharedReminderScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { user } = useAuth();
  const { addOpportunity } = useOpportunities();

  const [loading, setLoading] = useState(true);
  const [sharedReminder, setSharedReminder] = useState<SharedReminder | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    ShareService.fetchSharedReminder(id)
      .then((data) => {
        setSharedReminder(data);
      })
      .finally(() => setLoading(false));
  }, [id]);

  const handleSaveToMyReminders = async () => {
    if (!sharedReminder) return;

    if (!user) {
      Alert.alert(
        'Sign In Required',
        'Please sign in to save this shared reminder to your Marakadhey account.',
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Sign In', onPress: () => router.push('/login') },
        ]
      );
      return;
    }

    setSaving(true);
    try {
      await addOpportunity({
        title: sharedReminder.title,
        description: sharedReminder.description,
        websiteUrl: sharedReminder.websiteUrl,
        category: sharedReminder.category,
        priority: sharedReminder.priority,
        status: 'PENDING',
        deadline: sharedReminder.deadline,
        isRecurring: Boolean(sharedReminder.isRecurring),
        recurrenceRule: sharedReminder.recurrenceRule as any,
        checklist: [],
        reminderTimes: [sharedReminder.deadline],
        tags: sharedReminder.tags || [],
        calendarSynced: false,
        pinned: false,
      });
      setSaved(true);
      Alert.alert('Saved!', 'This opportunity has been added to your reminders.');
    } catch (e: any) {
      Alert.alert('Error', e.message || 'Could not save reminder.');
    } finally {
      setSaving(false);
    }
  };

  const handleOpenUrl = () => {
    if (sharedReminder?.websiteUrl) {
      Linking.openURL(sharedReminder.websiteUrl);
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.centerBox}>
          <ActivityIndicator size="large" color={Colors.primary} />
          <Text style={styles.loadingText}>Loading Shared Reminder...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!sharedReminder) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.centerBox}>
          <Text style={styles.notFoundTitle}>Reminder Not Found</Text>
          <Text style={styles.notFoundSub}>
            This shared reminder link is invalid, expired, or has been removed.
          </Text>
          <TouchableOpacity style={styles.primaryBtn} onPress={() => router.replace('/(tabs)')}>
            <Text style={styles.primaryBtnText}>Go to Home</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const categoryInfo = CategoryMeta[sharedReminder.category] || CategoryMeta.Other;
  const priorityColor =
    sharedReminder.priority === 'HIGH'
      ? Colors.priorityHigh
      : sharedReminder.priority === 'MEDIUM'
      ? Colors.priorityMedium
      : Colors.priorityLow;

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.background} />

      {/* Top Bar */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.iconCircle} onPress={() => router.back()}>
          <ChevronLeft size={22} color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Shared Opportunity</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        {/* Creator Banner */}
        <View style={styles.creatorCard}>
          <User size={16} color={Colors.primary} />
          <Text style={styles.creatorText}>
            Shared by <Text style={{ fontWeight: '800' }}>{sharedReminder.ownerDisplayName || 'A Marakadhey Hunter'}</Text>
          </Text>
        </View>

        {/* Priority & Category */}
        <View style={styles.badgeRow}>
          <View
            style={[
              styles.priorityPill,
              { backgroundColor: priorityColor + '20', borderColor: priorityColor },
            ]}
          >
            <View style={[styles.dot, { backgroundColor: priorityColor }]} />
            <Text style={[styles.priorityText, { color: priorityColor }]}>
              {sharedReminder.priority} PRIORITY
            </Text>
          </View>

          <View style={[styles.categoryBadge, { backgroundColor: categoryInfo.color + '20' }]}>
            <Text style={[styles.categoryText, { color: categoryInfo.color }]}>
              {categoryInfo.label}
            </Text>
          </View>
        </View>

        {/* Title */}
        <Text style={styles.title}>{sharedReminder.title}</Text>

        {/* Website Launcher */}
        {sharedReminder.websiteUrl ? (
          <TouchableOpacity style={styles.linkCard} onPress={handleOpenUrl}>
            <ExternalLink size={16} color={Colors.primary} />
            <Text style={styles.linkText} numberOfLines={1}>
              {sharedReminder.websiteUrl}
            </Text>
          </TouchableOpacity>
        ) : null}

        {/* Live Countdown */}
        <View style={styles.countdownSection}>
          <Text style={styles.sectionLabel}>LIVE DEADLINE COUNTDOWN</Text>
          <CountdownTimer deadline={sharedReminder.deadline} />
          <Text style={styles.deadlineFormatted}>
            Target Deadline: {new Date(sharedReminder.deadline).toLocaleString()}
          </Text>
        </View>

        {/* Save to My Reminders Action Button */}
        <TouchableOpacity
          style={[styles.saveActionBtn, saved && styles.savedActionBtn]}
          onPress={handleSaveToMyReminders}
          disabled={saving || saved}
        >
          {saving ? (
            <ActivityIndicator size="small" color="#FFF" />
          ) : (
            <>
              <PlusCircle size={20} color="#FFF" />
              <Text style={styles.saveActionBtnText}>
                {saved ? 'Added to Your Reminders ✓' : 'Save to My Reminders'}
              </Text>
            </>
          )}
        </TouchableOpacity>

        {/* Description */}
        {sharedReminder.description ? (
          <View style={styles.cardBox}>
            <Text style={styles.boxTitle}>Notes & Eligibility Context</Text>
            <Text style={styles.boxBody}>{sharedReminder.description}</Text>
          </View>
        ) : null}

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
    paddingVertical: 12,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  container: {
    flex: 1,
    paddingHorizontal: 16,
  },
  centerBox: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    gap: 12,
  },
  loadingText: {
    color: Colors.textSecondary,
    fontSize: 14,
    fontWeight: '600',
  },
  notFoundTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  notFoundSub: {
    fontSize: 14,
    color: Colors.textMuted,
    textAlign: 'center',
    lineHeight: 20,
  },
  primaryBtn: {
    backgroundColor: Colors.primary,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 12,
    marginTop: 8,
  },
  primaryBtnText: {
    color: '#FFF',
    fontWeight: '700',
    fontSize: 14,
  },
  creatorCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#FFF7ED',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FFEDD5',
    marginBottom: 12,
  },
  creatorText: {
    color: Colors.primary,
    fontSize: 13,
    fontWeight: '600',
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
    fontSize: 11,
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
    fontSize: 22,
    fontWeight: '900',
    marginBottom: 12,
    lineHeight: 28,
  },
  linkCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: 'rgba(255, 107, 0, 0.1)',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(255, 107, 0, 0.25)',
    marginBottom: 16,
  },
  linkText: {
    color: Colors.primary,
    fontSize: 13,
    fontWeight: '700',
    flex: 1,
  },
  countdownSection: {
    backgroundColor: Colors.surfaceElevated,
    borderRadius: 20,
    padding: 16,
    alignItems: 'center',
    marginBottom: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  sectionLabel: {
    color: Colors.textMuted,
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 1,
    marginBottom: 10,
  },
  deadlineFormatted: {
    color: Colors.textSecondary,
    fontSize: 11,
    fontWeight: '600',
    marginTop: 8,
  },
  saveActionBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 16,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginBottom: 16,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 6,
    elevation: 3,
  },
  savedActionBtn: {
    backgroundColor: Colors.success,
  },
  saveActionBtnText: {
    color: '#FFF',
    fontSize: 15,
    fontWeight: '800',
  },
  cardBox: {
    backgroundColor: Colors.surface,
    borderRadius: 20,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 8,
  },
  boxTitle: {
    color: Colors.textPrimary,
    fontSize: 15,
    fontWeight: '800',
  },
  boxBody: {
    color: Colors.textSecondary,
    fontSize: 14,
    lineHeight: 20,
  },
});

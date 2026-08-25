import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useOpportunities } from '../../context/OpportunityContext';
import { Colors } from '../../constants/theme';
import { MarakadheyHeader } from '../../components/Header';
import { OpportunityCard } from '../../components/OpportunityCard';
import { Search, X, AlertCircle, Sparkles, SlidersHorizontal } from 'lucide-react-native';

export default function InboxScreen() {
  const router = useRouter();
  const {
    opportunities,
    toggleComplete,
    snoozeOpportunity,
    togglePin,
    searchQuery,
    setSearchQuery,
  } = useOpportunities();

  const [filterStatus, setFilterStatus] = useState<'all' | 'pending' | 'completed'>('pending');
  const [sortBy, setSortBy] = useState<'newest' | 'oldest' | 'duesoon' | 'highprio'>('newest');

  const now = new Date();
  const twentyFourHoursFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

  // Filter Due in 24 Hours
  const dueSoonOpps = opportunities.filter((o) => {
    if (o.status !== 'PENDING') return false;
    const d = new Date(o.deadline);
    return d.getTime() >= now.getTime() && d.getTime() <= twentyFourHoursFromNow.getTime();
  });

  // Filtered List
  const filteredOpps = opportunities.filter((opp) => {
    if (filterStatus === 'pending' && opp.status !== 'PENDING') return false;
    if (filterStatus === 'completed' && opp.status !== 'COMPLETED') return false;

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const titleMatch = opp.title.toLowerCase().includes(q);
      const catMatch = opp.category.toLowerCase().includes(q);
      const tagMatch = opp.tags?.some((t) => t.toLowerCase().includes(q));
      return titleMatch || catMatch || tagMatch;
    }

    return true;
  });

  // Sorted List
  const sortedOpps = [...filteredOpps].sort((a, b) => {
    if (a.pinned !== b.pinned) return a.pinned ? -1 : 1;

    if (sortBy === 'newest') {
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    }
    if (sortBy === 'oldest') {
      return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
    }
    if (sortBy === 'duesoon') {
      return new Date(a.deadline).getTime() - new Date(b.deadline).getTime();
    }
    if (sortBy === 'highprio') {
      const prioOrder = { HIGH: 1, MEDIUM: 2, LOW: 3 };
      return (prioOrder[a.priority] || 2) - (prioOrder[b.priority] || 2);
    }
    return 0;
  });

  const pendingCount = opportunities.filter((o) => o.status === 'PENDING').length;
  const completedCount = opportunities.filter((o) => o.status === 'COMPLETED').length;

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.headerBg} />
      <MarakadheyHeader />

      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        <View style={styles.responsiveContainer}>
          {/* Search Box */}
          <View style={styles.searchBox}>
            <Search size={18} color={Colors.textMuted} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search reminders by title, category, #tag..."
              placeholderTextColor={Colors.textLight}
              value={searchQuery}
              onChangeText={setSearchQuery}
            />
            {searchQuery.length > 0 && (
              <TouchableOpacity onPress={() => setSearchQuery('')} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                <X size={18} color={Colors.textMuted} />
              </TouchableOpacity>
            )}
          </View>

          {/* Filter Segment & Sort Chips */}
          <View style={styles.controlsRow}>
            <View style={styles.pillsGroup}>
              <TouchableOpacity
                style={[styles.pill, filterStatus === 'pending' && styles.pillActive]}
                onPress={() => setFilterStatus('pending')}
                activeOpacity={0.8}
              >
                <Text style={[styles.pillText, filterStatus === 'pending' && styles.pillTextActive]}>
                  Pending ({pendingCount})
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.pill, filterStatus === 'all' && styles.pillActive]}
                onPress={() => setFilterStatus('all')}
                activeOpacity={0.8}
              >
                <Text style={[styles.pillText, filterStatus === 'all' && styles.pillTextActive]}>
                  All ({opportunities.length})
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.pill, filterStatus === 'completed' && styles.pillActive]}
                onPress={() => setFilterStatus('completed')}
                activeOpacity={0.8}
              >
                <Text style={[styles.pillText, filterStatus === 'completed' && styles.pillTextActive]}>
                  Done ({completedCount})
                </Text>
              </TouchableOpacity>
            </View>

            {/* Sort Scroll Chips */}
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.sortScroll}>
              {[
                { id: 'newest', label: 'Newest' },
                { id: 'duesoon', label: 'Due Soon' },
                { id: 'highprio', label: 'High Priority' },
                { id: 'oldest', label: 'Oldest' },
              ].map((s) => (
                <TouchableOpacity
                  key={s.id}
                  style={[styles.sortChip, sortBy === s.id && styles.sortChipActive]}
                  onPress={() => setSortBy(s.id as any)}
                  activeOpacity={0.8}
                >
                  <Text style={[styles.sortChipText, sortBy === s.id && styles.sortChipTextActive]}>
                    {s.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          {/* Due in 24 Hours Banner */}
          {dueSoonOpps.length > 0 && filterStatus !== 'completed' && (
            <View style={styles.dueSoonBanner}>
              <View style={styles.dueSoonHeader}>
                <AlertCircle size={16} color="#DC2626" />
                <Text style={styles.dueSoonTitle}>Due in 24 Hours ({dueSoonOpps.length})</Text>
              </View>
              {dueSoonOpps.map((opp) => (
                <OpportunityCard
                  key={opp.id}
                  opportunity={opp}
                  onPress={() => router.push(`/opportunity/${opp.id}` as any)}
                  onToggleComplete={() => toggleComplete(opp.id)}
                  onSnooze={() => snoozeOpportunity(opp.id, 60)}
                  onTogglePin={() => togglePin(opp.id)}
                />
              ))}
            </View>
          )}

          {/* Reminders List */}
          {sortedOpps.length === 0 ? (
            <View style={styles.emptyStateCard}>
              <Sparkles size={36} color={Colors.primary} />
              <Text style={styles.emptyTitle}>
                {filterStatus === 'completed'
                  ? 'No completed reminders yet'
                  : 'Your inbox is clear! 🎉'}
              </Text>
              <Text style={styles.emptySubtitle}>
                {filterStatus === 'completed'
                  ? 'Completed deadlines and tasks will show up here.'
                  : 'Add an opportunity in the Add Reminder tab to stay on track.'}
              </Text>
            </View>
          ) : (
            sortedOpps.map((opp) => (
              <OpportunityCard
                key={opp.id}
                opportunity={opp}
                onPress={() => router.push(`/opportunity/${opp.id}` as any)}
                onToggleComplete={() => toggleComplete(opp.id)}
                onSnooze={() => snoozeOpportunity(opp.id, 60)}
                onTogglePin={() => togglePin(opp.id)}
              />
            ))
          )}

          <View style={{ height: 40 }} />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  container: {
    flex: 1,
    padding: 14,
  },
  responsiveContainer: {
    width: '100%',
    maxWidth: 640,
    alignSelf: 'center',
    gap: 12,
  },
  searchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    borderRadius: 10,
    paddingHorizontal: 12,
    height: 44,
    gap: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  searchInput: {
    flex: 1,
    fontSize: 13,
    color: Colors.textPrimary,
  },
  controlsRow: {
    gap: 10,
  },
  pillsGroup: {
    flexDirection: 'row',
    gap: 8,
  },
  pill: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 20,
    backgroundColor: '#E5E7EB',
  },
  pillActive: {
    backgroundColor: Colors.primary,
  },
  pillText: {
    fontSize: 12,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  pillTextActive: {
    color: '#FFFFFF',
  },
  sortScroll: {
    marginVertical: 2,
  },
  sortChip: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginRight: 6,
  },
  sortChipActive: {
    borderColor: Colors.primary,
    backgroundColor: '#FFF7ED',
  },
  sortChipText: {
    fontSize: 11,
    fontWeight: '700',
    color: Colors.textSecondary,
  },
  sortChipTextActive: {
    color: Colors.primary,
    fontWeight: '800',
  },
  dueSoonBanner: {
    backgroundColor: '#FEF2F2',
    borderRadius: 14,
    padding: 12,
    borderWidth: 1,
    borderColor: '#FCA5A5',
    gap: 8,
  },
  dueSoonHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  dueSoonTitle: {
    fontSize: 12,
    fontWeight: '800',
    color: '#DC2626',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  emptyStateCard: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    padding: 36,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 8,
    marginTop: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  emptySubtitle: {
    fontSize: 13,
    color: Colors.textMuted,
    textAlign: 'center',
    lineHeight: 18,
  },
});

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  SafeAreaView,
  StatusBar,
  DimensionValue,
  TouchableOpacity,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '../../constants/theme';
import { MarakadheyHeader } from '../../components/Header';
import { useOpportunities } from '../../context/OpportunityContext';
import { Clock, CheckCircle2, AlertTriangle, ArrowRight, Flame, BarChart3 } from 'lucide-react-native';
import { CountdownTimer } from '../../components/CountdownTimer';

export default function DashboardScreen() {
  const router = useRouter();
  const { opportunities } = useOpportunities();
  const now = new Date();

  // Stats Calculations
  const totalCount = opportunities.length;
  const pendingOpps = opportunities.filter((o) => o.status === 'PENDING');
  const completedOpps = opportunities.filter((o) => o.status === 'COMPLETED');
  const pendingCount = pendingOpps.length;
  const completedCount = completedOpps.length;

  const completionPct = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

  // Next Upcoming Deadline
  const sortedUpcoming = [...pendingOpps]
    .filter((o) => new Date(o.deadline).getTime() >= now.getTime())
    .sort((a, b) => new Date(a.deadline).getTime() - new Date(b.deadline).getTime());
  const nextOpp = sortedUpcoming[0];

  // Urgency Breakdown
  const overdueCount = pendingOpps.filter((o) => new Date(o.deadline).getTime() < now.getTime()).length;
  const todayCount = pendingOpps.filter((o) => {
    const d = new Date(o.deadline);
    return (
      d.getTime() >= now.getTime() &&
      d.getDate() === now.getDate() &&
      d.getMonth() === now.getMonth() &&
      d.getFullYear() === now.getFullYear()
    );
  }).length;
  const upcomingCount = pendingOpps.filter((o) => {
    const d = new Date(o.deadline);
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return d.getTime() >= tomorrow.getTime();
  }).length;

  // Priority Distribution
  const highCount = opportunities.filter((o) => o.priority === 'HIGH').length;
  const medCount = opportunities.filter((o) => o.priority === 'MEDIUM').length;
  const lowCount = opportunities.filter((o) => o.priority === 'LOW').length;

  // Category Distribution
  const categoryCounts: Record<string, number> = {};
  opportunities.forEach((o) => {
    categoryCounts[o.category] = (categoryCounts[o.category] || 0) + 1;
  });

  const getBarPct = (val: number, max: number): DimensionValue => {
    if (max === 0) return '0%';
    return `${Math.min(100, Math.round((val / max) * 100))}%` as DimensionValue;
  };

  const maxUrgency = Math.max(overdueCount, todayCount, upcomingCount, 1);
  const maxPrio = Math.max(highCount, medCount, lowCount, 1);

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.headerBg} />
      <MarakadheyHeader />

      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        <View style={styles.responsiveContainer}>
          {/* Summary Stats Grid */}
          <View style={styles.statsGrid}>
            <View style={[styles.statCard, { borderLeftColor: Colors.secondary }]}>
              <Text style={styles.statNum}>{totalCount}</Text>
              <Text style={styles.statLabel}>Total</Text>
            </View>

            <View style={[styles.statCard, { borderLeftColor: Colors.primary }]}>
              <Text style={[styles.statNum, { color: Colors.primary }]}>{pendingCount}</Text>
              <Text style={styles.statLabel}>Pending</Text>
            </View>

            <View style={[styles.statCard, { borderLeftColor: '#10B981' }]}>
              <Text style={[styles.statNum, { color: '#10B981' }]}>{completedCount}</Text>
              <Text style={styles.statLabel}>Completed</Text>
            </View>
          </View>

          {/* Next Deadline Hero Card */}
          <View style={styles.metricCard}>
            <View style={styles.metricTitleRow}>
              <Clock size={16} color={Colors.primary} />
              <Text style={styles.metricTitle}>NEXT UPCOMING DEADLINE</Text>
            </View>

            {nextOpp ? (
              <TouchableOpacity
                style={styles.nextDeadlineBox}
                onPress={() => router.push(`/opportunity/${nextOpp.id}` as any)}
                activeOpacity={0.85}
              >
                <View style={styles.nextDeadlineTop}>
                  <Text style={styles.nextTitle} numberOfLines={1}>
                    {nextOpp.title}
                  </Text>
                  <ArrowRight size={16} color={Colors.primary} />
                </View>
                <Text style={styles.nextDate}>
                  {new Date(nextOpp.deadline).toLocaleDateString()} at{' '}
                  {new Date(nextOpp.deadline).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </Text>
                <View style={{ marginTop: 10 }}>
                  <CountdownTimer deadline={nextOpp.deadline} compact />
                </View>
              </TouchableOpacity>
            ) : (
              <Text style={styles.emptyText}>No upcoming deadlines scheduled</Text>
            )}
          </View>

          {/* Completion Rate Card */}
          <View style={styles.metricCard}>
            <View style={styles.progressHeader}>
              <Text style={styles.metricTitle}>COMPLETION PROGRESS</Text>
              <Text style={styles.progressPct}>{completionPct}%</Text>
            </View>
            <View style={styles.progressBarBg}>
              <View style={[styles.progressBarFill, { width: `${completionPct}%` }]} />
            </View>
          </View>

          {/* Urgency Breakdown */}
          <View style={styles.metricCard}>
            <Text style={styles.sectionTitle}>DEADLINE URGENCY</Text>
            <View style={styles.chartGroup}>
              <View style={styles.chartRow}>
                <Text style={styles.chartLabel}>Overdue</Text>
                <View style={styles.barBg}>
                  <View
                    style={[
                      styles.barFill,
                      { width: getBarPct(overdueCount, maxUrgency), backgroundColor: '#EF4444' },
                    ]}
                  />
                </View>
                <Text style={styles.chartVal}>{overdueCount}</Text>
              </View>

              <View style={styles.chartRow}>
                <Text style={styles.chartLabel}>Due Today</Text>
                <View style={styles.barBg}>
                  <View
                    style={[
                      styles.barFill,
                      { width: getBarPct(todayCount, maxUrgency), backgroundColor: '#F59E0B' },
                    ]}
                  />
                </View>
                <Text style={styles.chartVal}>{todayCount}</Text>
              </View>

              <View style={styles.chartRow}>
                <Text style={styles.chartLabel}>Upcoming</Text>
                <View style={styles.barBg}>
                  <View
                    style={[
                      styles.barFill,
                      { width: getBarPct(upcomingCount, maxUrgency), backgroundColor: '#10B981' },
                    ]}
                  />
                </View>
                <Text style={styles.chartVal}>{upcomingCount}</Text>
              </View>
            </View>
          </View>

          {/* Priority Distribution */}
          <View style={styles.metricCard}>
            <Text style={styles.sectionTitle}>PRIORITY DISTRIBUTION</Text>
            <View style={styles.chartGroup}>
              <View style={styles.chartRow}>
                <Text style={styles.chartLabel}>High Priority</Text>
                <View style={styles.barBg}>
                  <View
                    style={[
                      styles.barFill,
                      { width: getBarPct(highCount, maxPrio), backgroundColor: '#EF4444' },
                    ]}
                  />
                </View>
                <Text style={styles.chartVal}>{highCount}</Text>
              </View>

              <View style={styles.chartRow}>
                <Text style={styles.chartLabel}>Medium Priority</Text>
                <View style={styles.barBg}>
                  <View
                    style={[
                      styles.barFill,
                      { width: getBarPct(medCount, maxPrio), backgroundColor: Colors.primary },
                    ]}
                  />
                </View>
                <Text style={styles.chartVal}>{medCount}</Text>
              </View>

              <View style={styles.chartRow}>
                <Text style={styles.chartLabel}>Low Priority</Text>
                <View style={styles.barBg}>
                  <View
                    style={[
                      styles.barFill,
                      { width: getBarPct(lowCount, maxPrio), backgroundColor: '#3B82F6' },
                    ]}
                  />
                </View>
                <Text style={styles.chartVal}>{lowCount}</Text>
              </View>
            </View>
          </View>

          {/* Category Distribution */}
          <View style={styles.metricCard}>
            <Text style={styles.sectionTitle}>CATEGORY BREAKDOWN</Text>
            <View style={styles.chartGroup}>
              {Object.entries(categoryCounts).map(([cat, count]) => (
                <View key={cat} style={styles.chartRow}>
                  <Text style={styles.chartLabel}>{cat}</Text>
                  <View style={styles.barBg}>
                    <View
                      style={[
                        styles.barFill,
                        { width: getBarPct(count, totalCount), backgroundColor: Colors.primary },
                      ]}
                    />
                  </View>
                  <Text style={styles.chartVal}>{count}</Text>
                </View>
              ))}
            </View>
          </View>

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
  statsGrid: {
    flexDirection: 'row',
    gap: 8,
  },
  statCard: {
    flex: 1,
    backgroundColor: Colors.surface,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    borderLeftWidth: 4,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  statNum: {
    fontSize: 22,
    fontWeight: '900',
    color: Colors.textPrimary,
  },
  statLabel: {
    fontSize: 11,
    color: Colors.textMuted,
    fontWeight: '700',
    marginTop: 2,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  metricCard: {
    backgroundColor: Colors.surface,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  metricTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  metricTitle: {
    fontSize: 11,
    fontWeight: '800',
    color: Colors.secondary,
    letterSpacing: 0.5,
  },
  nextDeadlineBox: {
    backgroundColor: '#FFF7ED',
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#FFEDD5',
  },
  nextDeadlineTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  nextTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: Colors.primary,
    flex: 1,
    marginRight: 6,
  },
  nextDate: {
    fontSize: 12,
    color: Colors.textSecondary,
    marginTop: 3,
  },
  emptyText: {
    fontSize: 13,
    color: Colors.textMuted,
    fontStyle: 'italic',
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  progressPct: {
    fontSize: 15,
    fontWeight: '900',
    color: Colors.primary,
  },
  progressBarBg: {
    height: 8,
    backgroundColor: '#E5E7EB',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: Colors.primary,
    borderRadius: 4,
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '800',
    color: Colors.secondary,
    letterSpacing: 0.5,
  },
  chartGroup: {
    gap: 8,
  },
  chartRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  chartLabel: {
    width: 90,
    fontSize: 12,
    fontWeight: '600',
    color: Colors.textSecondary,
  },
  barBg: {
    flex: 1,
    height: 8,
    backgroundColor: '#E5E7EB',
    borderRadius: 4,
    overflow: 'hidden',
  },
  barFill: {
    height: '100%',
    borderRadius: 4,
  },
  chartVal: {
    width: 24,
    fontSize: 12,
    fontWeight: '700',
    color: Colors.textPrimary,
    textAlign: 'right',
  },
});

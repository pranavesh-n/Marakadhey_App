import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useOpportunities } from '../../context/OpportunityContext';
import { Colors } from '../../constants/theme';
import { OpportunityCard } from '../../components/OpportunityCard';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon } from 'lucide-react-native';

export default function CalendarScreen() {
  const router = useRouter();
  const { opportunities, toggleComplete, snoozeOpportunity, togglePin } = useOpportunities();

  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());

  // Month navigation helpers
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  const prevMonth = () => {
    setCurrentDate(new Date(year, month - 1, 1));
  };

  const nextMonth = () => {
    setCurrentDate(new Date(year, month + 1, 1));
  };

  // Days in month calculation
  const firstDayIndex = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  // Map deadlines to calendar days
  const deadlineMap: Record<number, { high: boolean; medium: boolean; low: boolean; count: number }> = {};

  opportunities.forEach((opp) => {
    const oppDate = new Date(opp.deadline);
    if (oppDate.getFullYear() === year && oppDate.getMonth() === month && opp.status === 'PENDING') {
      const day = oppDate.getDate();
      if (!deadlineMap[day]) {
        deadlineMap[day] = { high: false, medium: false, low: false, count: 0 };
      }
      deadlineMap[day].count += 1;
      if (opp.priority === 'HIGH') deadlineMap[day].high = true;
      if (opp.priority === 'MEDIUM') deadlineMap[day].medium = true;
      if (opp.priority === 'LOW') deadlineMap[day].low = true;
    }
  });

  // Opportunities due on selected date
  const selectedDayOpps = opportunities.filter((opp) => {
    const d = new Date(opp.deadline);
    return (
      d.getDate() === selectedDate.getDate() &&
      d.getMonth() === selectedDate.getMonth() &&
      d.getFullYear() === selectedDate.getFullYear()
    );
  });

  const isSameDay = (d1: Date, d2: Date) =>
    d1.getDate() === d2.getDate() &&
    d1.getMonth() === d2.getMonth() &&
    d1.getFullYear() === d2.getFullYear();

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.background} />
      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Opportunity Calendar</Text>
          <View style={styles.monthSelector}>
            <TouchableOpacity onPress={prevMonth} style={styles.navArrow}>
              <ChevronLeft size={20} color={Colors.textSecondary} />
            </TouchableOpacity>
            <Text style={styles.monthTitle}>
              {monthNames[month]} {year}
            </Text>
            <TouchableOpacity onPress={nextMonth} style={styles.navArrow}>
              <ChevronRight size={20} color={Colors.textSecondary} />
            </TouchableOpacity>
          </View>
        </View>

        {/* Days of Week Header */}
        <View style={styles.weekHeader}>
          {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
            <Text key={day} style={styles.weekDayText}>
              {day}
            </Text>
          ))}
        </View>

        {/* Calendar Grid */}
        <View style={styles.grid}>
          {/* Empty padding slots */}
          {Array.from({ length: firstDayIndex }).map((_, i) => (
            <View key={`empty-${i}`} style={styles.dayCellEmpty} />
          ))}

          {/* Actual Month Days */}
          {Array.from({ length: daysInMonth }).map((_, i) => {
            const dayNum = i + 1;
            const thisDayDate = new Date(year, month, dayNum);
            const isSelected = isSameDay(thisDayDate, selectedDate);
            const isToday = isSameDay(thisDayDate, new Date());
            const hasDeadlines = deadlineMap[dayNum];

            return (
              <TouchableOpacity
                key={dayNum}
                style={[
                  styles.dayCell,
                  isToday && styles.todayCell,
                  isSelected && styles.selectedCell,
                ]}
                onPress={() => setSelectedDate(thisDayDate)}
              >
                <Text
                  style={[
                    styles.dayNumber,
                    isToday && styles.todayText,
                    isSelected && styles.selectedText,
                  ]}
                >
                  {dayNum}
                </Text>

                {/* Priority Dots */}
                {hasDeadlines ? (
                  <View style={styles.dotsRow}>
                    {hasDeadlines.high && (
                      <View style={[styles.dot, { backgroundColor: Colors.priorityHigh }]} />
                    )}
                    {hasDeadlines.medium && (
                      <View style={[styles.dot, { backgroundColor: Colors.priorityMedium }]} />
                    )}
                    {hasDeadlines.low && (
                      <View style={[styles.dot, { backgroundColor: Colors.priorityLow }]} />
                    )}
                  </View>
                ) : (
                  <View style={{ height: 6 }} />
                )}
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Agenda / Timeline Section */}
        <View style={styles.agendaHeader}>
          <CalendarIcon size={18} color={Colors.primary} />
          <Text style={styles.agendaTitle}>
            Agenda for {selectedDate.toDateString()} ({selectedDayOpps.length})
          </Text>
        </View>

        {selectedDayOpps.length === 0 ? (
          <View style={styles.emptyAgenda}>
            <Text style={styles.emptyAgendaText}>No deadlines scheduled for this day.</Text>
          </View>
        ) : (
          selectedDayOpps.map((opp) => (
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
    paddingHorizontal: 16,
    paddingTop: 10,
    width: '100%',
    maxWidth: 640,
    alignSelf: 'center',
  },
  header: {
    marginBottom: 16,
  },
  headerTitle: {
    color: Colors.textPrimary,
    fontSize: 22,
    fontWeight: '900',
    marginBottom: 10,
  },
  monthSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: Colors.surface,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  navArrow: {
    padding: 6,
  },
  monthTitle: {
    color: Colors.textPrimary,
    fontSize: 16,
    fontWeight: '800',
  },
  weekHeader: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 8,
  },
  weekDayText: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    width: 40,
    textAlign: 'center',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    backgroundColor: Colors.surface,
    borderRadius: 20,
    padding: 10,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginBottom: 20,
  },
  dayCellEmpty: {
    width: '14.28%',
    height: 48,
  },
  dayCell: {
    width: '14.28%',
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
  },
  todayCell: {
    borderWidth: 1,
    borderColor: Colors.primary,
  },
  selectedCell: {
    backgroundColor: Colors.primary,
  },
  dayNumber: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '700',
  },
  todayText: {
    color: Colors.primary,
    fontWeight: '900',
  },
  selectedText: {
    color: '#FFF',
    fontWeight: '900',
  },
  dotsRow: {
    flexDirection: 'row',
    gap: 3,
    marginTop: 2,
    height: 6,
  },
  dot: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
  },
  agendaHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  agendaTitle: {
    color: Colors.textPrimary,
    fontSize: 16,
    fontWeight: '800',
  },
  emptyAgenda: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  emptyAgendaText: {
    color: Colors.textMuted,
    fontSize: 13,
  },
});

import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../constants/theme';

interface CountdownProps {
  deadline: string;
  compact?: boolean;
}

export const CountdownTimer: React.FC<CountdownProps> = ({ deadline, compact = false }) => {
  const [timeLeft, setTimeLeft] = useState(calculateTimeLeft());

  function calculateTimeLeft() {
    const diff = new Date(deadline).getTime() - new Date().getTime();
    if (diff <= 0) {
      return { days: 0, hours: 0, minutes: 0, seconds: 0, isOverdue: true };
    }
    return {
      days: Math.floor(diff / (1000 * 60 * 60 * 24)),
      hours: Math.floor((diff / (1000 * 60 * 60)) % 24),
      minutes: Math.floor((diff / 1000 / 60) % 60),
      seconds: Math.floor((diff / 1000) % 60),
      isOverdue: false,
    };
  }

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft(calculateTimeLeft());
    }, 1000);
    return () => clearInterval(timer);
  }, [deadline]);

  if (timeLeft.isOverdue) {
    return (
      <View style={[styles.badge, styles.overdueBadge]}>
        <Text style={styles.overdueText}>⚠️ OVERDUE</Text>
      </View>
    );
  }

  if (compact) {
    return (
      <View style={styles.compactContainer}>
        <Text style={styles.compactText}>
          ⏳ {timeLeft.days > 0 ? `${timeLeft.days}d ` : ''}
          {timeLeft.hours}h {timeLeft.minutes}m
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.timeBox}>
        <Text style={styles.timeValue}>{String(timeLeft.days).padStart(2, '0')}</Text>
        <Text style={styles.timeLabel}>DAYS</Text>
      </View>
      <Text style={styles.colon}>:</Text>
      <View style={styles.timeBox}>
        <Text style={styles.timeValue}>{String(timeLeft.hours).padStart(2, '0')}</Text>
        <Text style={styles.timeLabel}>HRS</Text>
      </View>
      <Text style={styles.colon}>:</Text>
      <View style={styles.timeBox}>
        <Text style={styles.timeValue}>{String(timeLeft.minutes).padStart(2, '0')}</Text>
        <Text style={styles.timeLabel}>MINS</Text>
      </View>
      <Text style={styles.colon}>:</Text>
      <View style={styles.timeBox}>
        <Text style={styles.timeValue}>{String(timeLeft.seconds).padStart(2, '0')}</Text>
        <Text style={styles.timeLabel}>SECS</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255, 107, 0, 0.1)',
    borderRadius: 16,
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 107, 0, 0.3)',
  },
  timeBox: {
    alignItems: 'center',
    minWidth: 44,
  },
  timeValue: {
    color: Colors.primary,
    fontSize: 20,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  timeLabel: {
    color: Colors.textSecondary,
    fontSize: 9,
    fontWeight: '700',
    marginTop: 2,
  },
  colon: {
    color: Colors.primary,
    fontSize: 18,
    fontWeight: '700',
    marginHorizontal: 4,
    marginBottom: 10,
  },
  compactContainer: {
    backgroundColor: 'rgba(255, 107, 0, 0.15)',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 107, 0, 0.25)',
  },
  compactText: {
    color: Colors.primary,
    fontSize: 12,
    fontWeight: '700',
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  overdueBadge: {
    backgroundColor: 'rgba(239, 68, 68, 0.2)',
    borderWidth: 1,
    borderColor: Colors.danger,
  },
  overdueText: {
    color: Colors.danger,
    fontSize: 12,
    fontWeight: '800',
  },
});

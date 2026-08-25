import React from 'react';
import { Tabs } from 'expo-router';
import { View, StyleSheet, Text } from 'react-native';
import { PlusCircle, Inbox, LayoutDashboard, Settings, Calendar } from 'lucide-react-native';
import { Colors } from '../../constants/theme';
import { useOpportunities } from '../../context/OpportunityContext';

export default function TabLayout() {
  const { opportunities } = useOpportunities();
  const pendingCount = opportunities.filter((o) => o.status === 'PENDING').length;

  return (
    <View style={{ flex: 1, backgroundColor: Colors.background }}>
      <Tabs
        screenOptions={{
          headerShown: false,
          tabBarShowLabel: true,
          tabBarActiveTintColor: Colors.primary,
          tabBarInactiveTintColor: Colors.textMuted,
          tabBarStyle: {
            backgroundColor: '#FFFFFF',
            borderTopColor: Colors.surfaceBorder,
            borderTopWidth: 1,
            height: 60,
            paddingBottom: 6,
            paddingTop: 6,
          },
          tabBarLabelStyle: {
            fontSize: 11,
            fontWeight: '700',
          },
        }}
      >
        <Tabs.Screen
          name="index"
          options={{
            title: 'Add Reminder',
            tabBarIcon: ({ color, size }) => <PlusCircle size={size || 20} color={color} />,
          }}
        />

        <Tabs.Screen
          name="inbox"
          options={{
            title: 'Inbox',
            tabBarBadge: pendingCount > 0 ? pendingCount : undefined,
            tabBarBadgeStyle: {
              backgroundColor: Colors.primary,
              color: '#FFFFFF',
              fontSize: 10,
              fontWeight: '800',
            },
            tabBarIcon: ({ color, size }) => <Inbox size={size || 20} color={color} />,
          }}
        />

        <Tabs.Screen
          name="dashboard"
          options={{
            title: 'Dashboard',
            tabBarIcon: ({ color, size }) => <LayoutDashboard size={size || 20} color={color} />,
          }}
        />

        <Tabs.Screen
          name="calendar"
          options={{
            href: null,
          }}
        />

        <Tabs.Screen
          name="settings"
          options={{
            title: 'Settings',
            tabBarIcon: ({ color, size }) => <Settings size={size || 20} color={color} />,
          }}
        />

        {/* Hide deprecated profile screen from tabs */}
        <Tabs.Screen
          name="profile"
          options={{
            href: null,
          }}
        />
      </Tabs>
    </View>
  );
}

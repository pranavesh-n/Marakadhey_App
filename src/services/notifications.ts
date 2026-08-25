/**
 * Notifications Service
 * Manages expo-notifications for device-side push alarms.
 * No server polling. The phone's OS schedules and fires the alarm locally.
 */
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { Opportunity } from '../types/opportunity';

// Configure foreground notification behavior
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export const NotificationService = {
  /**
   * Request push notification permissions & configure Android channel.
   * Called once on app start.
   */
  async requestPermissions(): Promise<boolean> {
    if (Platform.OS === 'web') return false;
    try {
      if (Platform.OS === 'android') {
        await Notifications.setNotificationChannelAsync('marakadhey-reminders', {
          name: 'Marakadhey Deadlines & Reminders',
          importance: Notifications.AndroidImportance.MAX,
          vibrationPattern: [0, 250, 250, 250],
          lightColor: '#FF6B00',
          lockscreenVisibility: Notifications.AndroidNotificationVisibility.PUBLIC,
          bypassDnd: true,
        });
      }

      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      if (existingStatus === 'granted') return true;
      const { status } = await Notifications.requestPermissionsAsync();
      return status === 'granted';
    } catch (e) {
      console.warn('[Notifications] requestPermissions error:', e);
      return false;
    }
  },

  /**
   * Schedule a local device notification for a reminder at its deadline (or lead-time offset).
   * Returns the notification identifier.
   */
  async scheduleReminder(opportunity: Opportunity): Promise<string | null> {
    if (Platform.OS === 'web') return null;
    try {
      let triggerDate = new Date(opportunity.deadline);
      if (opportunity.leadTimeMinutes && opportunity.leadTimeMinutes > 0) {
        triggerDate = new Date(triggerDate.getTime() - opportunity.leadTimeMinutes * 60 * 1000);
      }

      // If trigger date has passed, do not schedule
      if (isNaN(triggerDate.getTime()) || triggerDate.getTime() <= Date.now()) {
        return null;
      }

      const id = await Notifications.scheduleNotificationAsync({
        content: {
          title: `⏰ ${opportunity.title}`,
          body: opportunity.description
            ? opportunity.description.substring(0, 100)
            : 'Your deadline is approaching. Don\'t miss this opportunity!',
          data: { opportunityId: opportunity.id, url: opportunity.websiteUrl || '' },
          sound: true,
          priority: Notifications.AndroidNotificationPriority.MAX,
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: triggerDate,
          channelId: 'marakadhey-reminders',
        },
      });
      return id;
    } catch (e) {
      console.warn('[Notifications] scheduleReminder error:', e);
      return null;
    }
  },

  /**
   * Cancel a previously scheduled notification by its ID.
   */
  async cancelReminder(notificationId: string): Promise<void> {
    if (Platform.OS === 'web' || !notificationId) return;
    try {
      await Notifications.cancelScheduledNotificationAsync(notificationId);
    } catch (e) {
      console.warn('[Notifications] cancelReminder error:', e);
    }
  },

  /**
   * Cancel all notifications for logged out user
   */
  async cancelAllUserReminders(): Promise<void> {
    if (Platform.OS === 'web') return;
    try {
      await Notifications.cancelAllScheduledNotificationsAsync();
    } catch (e) {
      console.warn('[Notifications] cancelAllUserReminders error:', e);
    }
  },

  /**
   * Re-schedule all pending opportunities on startup.
   */
  async rescheduleAll(opportunities: Opportunity[]): Promise<Record<string, string>> {
    if (Platform.OS === 'web') return {};
    const idMap: Record<string, string> = {};
    try {
      await Notifications.cancelAllScheduledNotificationsAsync();
      const pending = opportunities.filter(
        (o) => o.status === 'PENDING' || o.status === 'IN_PROGRESS'
      );
      for (const opp of pending) {
        const notifId = await NotificationService.scheduleReminder(opp);
        if (notifId) idMap[opp.id] = notifId;
      }
    } catch (e) {
      console.warn('[Notifications] rescheduleAll error:', e);
    }
    return idMap;
  },
};

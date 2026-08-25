/**
 * Share Service
 * Safely shares opportunities without exposing private user data paths.
 */
import { Opportunity, SharedReminder, UserProfile } from '../types/opportunity';
import { FirestoreService } from './firestoreService';
import * as Sharing from 'expo-sharing';
import { Platform, Share } from 'react-native';

export const ShareService = {
  /**
   * Create a public shared reminder document in Firestore and return deep-link
   */
  async createShareLink(opportunity: Opportunity, user: UserProfile): Promise<{ shareId: string; url: string }> {
    const shareId = 'sh_' + Date.now().toString(36) + '_' + Math.random().toString(36).substring(2, 6);
    
    const sharedData: SharedReminder = {
      shareId,
      ownerUid: user.uid,
      ownerDisplayName: user.displayName || 'Marakadhey User',
      title: opportunity.title,
      description: opportunity.description || '',
      websiteUrl: opportunity.websiteUrl || '',
      category: opportunity.category,
      priority: opportunity.priority,
      deadline: opportunity.deadline,
      isRecurring: opportunity.isRecurring,
      recurrenceRule: opportunity.recurrenceRule,
      tags: opportunity.tags || [],
      createdAt: new Date().toISOString(),
    };

    await FirestoreService.createSharedReminder(sharedData);

    const url = `marakadheyapp://share/${shareId}`;
    return { shareId, url };
  },

  /**
   * Native share sheet trigger
   */
  async shareOpportunityNative(opportunity: Opportunity, user: UserProfile): Promise<void> {
    try {
      const { url } = await this.createShareLink(opportunity, user);
      const message = `🔔 ${opportunity.title}\nDeadline: ${new Date(opportunity.deadline).toLocaleDateString()}\n\nView or add to your Marakadhey app: ${url}`;

      if (Platform.OS === 'web') {
        if (navigator.clipboard) {
          await navigator.clipboard.writeText(url);
          alert('Share link copied to clipboard: ' + url);
        }
      } else {
        await Share.share({
          message,
          title: `Reminder: ${opportunity.title}`,
          url,
        });
      }
    } catch (e: any) {
      console.warn('[ShareService] shareOpportunityNative error:', e);
    }
  },

  /**
   * Fetch shared reminder
   */
  async fetchSharedReminder(shareId: string): Promise<SharedReminder | null> {
    return await FirestoreService.getSharedReminder(shareId);
  },
};

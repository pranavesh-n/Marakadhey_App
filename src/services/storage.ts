import AsyncStorage from '@react-native-async-storage/async-storage';
import { Opportunity, UserProfile } from '../types/opportunity';

const getOppKey = (userId?: string) => `@marakadhey_opps_v2_${userId || 'guest'}`;

export const StorageService = {
  async getOpportunities(userId?: string): Promise<Opportunity[]> {
    try {
      const key = getOppKey(userId);
      const jsonValue = await AsyncStorage.getItem(key);
      if (jsonValue != null) {
        return JSON.parse(jsonValue);
      }
      return [];
    } catch (e) {
      console.error('Failed to load opportunities from storage', e);
      return [];
    }
  },

  async saveOpportunities(opportunities: Opportunity[], userId?: string): Promise<void> {
    try {
      const key = getOppKey(userId);
      await AsyncStorage.setItem(key, JSON.stringify(opportunities));
    } catch (e) {
      console.error('Failed to save opportunities to storage', e);
    }
  },

  async clearUserOpportunities(userId?: string): Promise<void> {
    try {
      const key = getOppKey(userId);
      await AsyncStorage.removeItem(key);
    } catch (e) {
      console.error('Failed to clear user opportunities', e);
    }
  },

  async clearAll(): Promise<void> {
    try {
      await AsyncStorage.clear();
    } catch (e) {
      console.error('Failed to clear storage', e);
    }
  }
};

/**
 * OpportunityContext
 * Manages all reminder/opportunity state per Firebase UID.
 * - Loads from Firestore (cloud) when signed in
 * - Offloads reminder alarms to device hardware via expo-notifications
 * - Enforces data isolation per user
 * - All mutations triggered explicitly
 */
import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';
import { Alert } from 'react-native';
import { Opportunity, Priority, Category, Status, ChecklistItem, HistoryEntry } from '../types/opportunity';
import { StorageService } from '../services/storage';
import { NotificationService } from '../services/notifications';
import { FirestoreService } from '../services/firestoreService';
import { useAuth } from './AuthContext';

interface OpportunityContextType {
  opportunities: Opportunity[];
  loading: boolean;
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  selectedCategory: Category | 'ALL';
  setSelectedCategory: (cat: Category | 'ALL') => void;
  selectedPriority: Priority | 'ALL';
  setSelectedPriority: (priority: Priority | 'ALL') => void;
  addOpportunity: (opp: Omit<Opportunity, 'id' | 'createdAt' | 'updatedAt' | 'history'>) => Promise<void>;
  updateOpportunity: (id: string, updates: Partial<Opportunity>) => Promise<void>;
  deleteOpportunity: (id: string) => Promise<void>;
  toggleComplete: (id: string) => Promise<void>;
  snoozeOpportunity: (id: string, minutes: number) => Promise<void>;
  togglePin: (id: string) => Promise<void>;
  toggleChecklistItem: (oppId: string, itemId: string) => Promise<void>;
  addChecklistItem: (oppId: string, task: string) => Promise<void>;
  batchDelete: (ids: string[]) => Promise<void>;
  batchComplete: (ids: string[]) => Promise<void>;
  batchArchive: (ids: string[]) => Promise<void>;
  resetToSampleData: () => Promise<void>;
  uncompletedCount: number;
}

const MAX_UNCOMPLETED_DEADLINES = 200;

const OpportunityContext = createContext<OpportunityContextType | undefined>(undefined);

export const OpportunityProvider = ({ children }: { children: ReactNode }) => {
  const { user } = useAuth();
  const [opportunities, setOpportunities] = useState<Opportunity[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<Category | 'ALL'>('ALL');
  const [selectedPriority, setSelectedPriority] = useState<Priority | 'ALL'>('ALL');

  // Load data on user change
  useEffect(() => {
    setOpportunities([]);
    if (user?.uid) {
      loadData(user.uid);
    } else {
      setOpportunities([]);
      setLoading(false);
    }
    NotificationService.requestPermissions();
  }, [user?.uid]);

  const loadData = async (userId: string) => {
    setLoading(true);
    try {
      // Fetch Firestore cloud data for this user
      const cloudData = await FirestoreService.getOpportunities(userId);
      if (cloudData.length > 0) {
        setOpportunities(cloudData);
        await StorageService.saveOpportunities(cloudData, userId);
        await NotificationService.rescheduleAll(cloudData);
      } else {
        // Fallback to local storage for offline support
        const localData = await StorageService.getOpportunities(userId);
        if (localData.length > 0) {
          setOpportunities(localData);
          await NotificationService.rescheduleAll(localData);
          for (const opp of localData) {
            await FirestoreService.saveOpportunity(userId, opp);
          }
        } else {
          setOpportunities([]);
        }
      }
    } catch (e) {
      console.warn('[OpportunityContext] loadData error:', e);
      const localData = await StorageService.getOpportunities(userId);
      setOpportunities(localData);
    } finally {
      setLoading(false);
    }
  };

  const persist = useCallback(
    async (updated: Opportunity[]) => {
      setOpportunities(updated);
      if (user?.uid) {
        await StorageService.saveOpportunities(updated, user.uid);
      }
    },
    [user?.uid]
  );

  const uncompletedCount = opportunities.filter(
    (opp) => opp.status !== 'COMPLETED' && opp.status !== 'ARCHIVED'
  ).length;

  const addOpportunity = async (
    newOppData: Omit<Opportunity, 'id' | 'createdAt' | 'updatedAt' | 'history'>
  ) => {
    if (uncompletedCount >= MAX_UNCOMPLETED_DEADLINES) {
      Alert.alert(
        'Limit Reached',
        `You have ${MAX_UNCOMPLETED_DEADLINES} uncompleted reminders. Complete or archive some to add more.`
      );
      return;
    }

    const id = 'opp_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6);
    const timestamp = new Date().toISOString();
    const initialHistory: HistoryEntry = { id: 'h_' + Date.now(), action: 'CREATED', timestamp };

    const newOpportunity: Opportunity = {
      ...newOppData,
      id,
      ownerUid: user?.uid,
      history: [initialHistory],
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    const updated = [newOpportunity, ...opportunities];
    await persist(updated);

    if (user?.uid) {
      await FirestoreService.addOpportunity(user.uid, newOpportunity);
    }

    // Schedule notification if pending
    if (newOpportunity.status === 'PENDING') {
      await NotificationService.scheduleReminder(newOpportunity);
    }
  };

  const updateOpportunity = async (id: string, updates: Partial<Opportunity>) => {
    const timestamp = new Date().toISOString();
    let updatedOppItem: Opportunity | undefined;

    const updated: Opportunity[] = opportunities.map((opp) => {
      if (opp.id === id) {
        const updateHistory: HistoryEntry = { id: 'h_' + Date.now(), action: 'UPDATED', timestamp };
        const item: Opportunity = {
          ...opp,
          ...updates,
          updatedAt: timestamp,
          history: [...opp.history, updateHistory],
        };
        updatedOppItem = item;
        return item;
      }
      return opp;
    });

    await persist(updated);

    if (updatedOppItem && user?.uid) {
      await FirestoreService.updateOpportunity(user.uid, id, updatedOppItem);
      if (updatedOppItem.status === 'PENDING') {
        await NotificationService.scheduleReminder(updatedOppItem);
      }
    }
  };

  const deleteOpportunity = async (id: string) => {
    const updated = opportunities.filter((opp) => opp.id !== id);
    await persist(updated);
    if (user?.uid) {
      await FirestoreService.deleteOpportunity(user.uid, id);
    }
  };

  const toggleComplete = async (id: string) => {
    const timestamp = new Date().toISOString();
    let updatedOppItem: Opportunity | undefined;

    const updated: Opportunity[] = opportunities.map((opp) => {
      if (opp.id === id) {
        const isCompleted = opp.status === 'COMPLETED';
        const newStatus: Status = isCompleted ? 'PENDING' : 'COMPLETED';
        const item: Opportunity = {
          ...opp,
          status: newStatus,
          updatedAt: timestamp,
          history: [
            ...opp.history,
            {
              id: 'h_' + Date.now(),
              action: isCompleted ? 'UNCOMPLETED' : 'COMPLETED',
              timestamp,
            },
          ],
        };
        updatedOppItem = item;
        return item;
      }
      return opp;
    });

    await persist(updated);

    if (updatedOppItem && user?.uid) {
      await FirestoreService.updateOpportunity(user.uid, id, updatedOppItem);
      if (updatedOppItem.status === 'PENDING') {
        await NotificationService.scheduleReminder(updatedOppItem);
      }
    }
  };

  const snoozeOpportunity = async (id: string, minutes: number) => {
    const timestamp = new Date().toISOString();
    let updatedOppItem: Opportunity | undefined;

    const updated: Opportunity[] = opportunities.map((opp) => {
      if (opp.id === id) {
        const newDeadline = new Date(new Date(opp.deadline).getTime() + minutes * 60 * 1000).toISOString();
        const item: Opportunity = {
          ...opp,
          deadline: newDeadline,
          updatedAt: timestamp,
          history: [
            ...opp.history,
            { id: 'h_' + Date.now(), action: 'SNOOZED', timestamp, note: `Snoozed ${minutes}m` },
          ],
        };
        updatedOppItem = item;
        return item;
      }
      return opp;
    });

    await persist(updated);

    if (updatedOppItem) {
      if (user?.uid) {
        await FirestoreService.updateOpportunity(user.uid, id, updatedOppItem);
      }
      await NotificationService.scheduleReminder(updatedOppItem);
    }
  };

  const togglePin = async (id: string) => {
    const timestamp = new Date().toISOString();
    const updated: Opportunity[] = opportunities.map((opp) => {
      if (opp.id === id) {
        return { ...opp, pinned: !opp.pinned, updatedAt: timestamp };
      }
      return opp;
    });
    await persist(updated);
    const pinned = updated.find((o) => o.id === id);
    if (pinned && user?.uid) {
      await FirestoreService.updateOpportunity(user.uid, id, pinned);
    }
  };

  const toggleChecklistItem = async (oppId: string, itemId: string) => {
    const timestamp = new Date().toISOString();
    let updatedOpp: Opportunity | undefined;
    const updated: Opportunity[] = opportunities.map((opp) => {
      if (opp.id === oppId) {
        const item = {
          ...opp,
          checklist: opp.checklist.map((chk) =>
            chk.id === itemId ? { ...chk, completed: !chk.completed } : chk
          ),
          updatedAt: timestamp,
        };
        updatedOpp = item;
        return item;
      }
      return opp;
    });
    await persist(updated);
    if (updatedOpp && user?.uid) {
      await FirestoreService.updateOpportunity(user.uid, oppId, updatedOpp);
    }
  };

  const addChecklistItem = async (oppId: string, task: string) => {
    const timestamp = new Date().toISOString();
    const newItem: ChecklistItem = { id: 'chk_' + Date.now(), task, completed: false };
    let updatedOpp: Opportunity | undefined;
    const updated: Opportunity[] = opportunities.map((opp) => {
      if (opp.id === oppId) {
        const item = { ...opp, checklist: [...opp.checklist, newItem], updatedAt: timestamp };
        updatedOpp = item;
        return item;
      }
      return opp;
    });
    await persist(updated);
    if (updatedOpp && user?.uid) {
      await FirestoreService.updateOpportunity(user.uid, oppId, updatedOpp);
    }
  };

  const batchDelete = async (ids: string[]) => {
    const idSet = new Set(ids);
    await persist(opportunities.filter((opp) => !idSet.has(opp.id)));
    if (user?.uid) {
      await Promise.all(ids.map((id) => FirestoreService.deleteOpportunity(user.uid, id)));
    }
  };

  const batchComplete = async (ids: string[]) => {
    const idSet = new Set(ids);
    const timestamp = new Date().toISOString();
    const updated = opportunities.map((opp) =>
      idSet.has(opp.id) ? { ...opp, status: 'COMPLETED' as Status, updatedAt: timestamp } : opp
    );
    await persist(updated);
    if (user?.uid) {
      await Promise.all(
        ids.map((id) => {
          const opp = updated.find((o) => o.id === id);
          return opp ? FirestoreService.updateOpportunity(user.uid, id, opp) : Promise.resolve();
        })
      );
    }
  };

  const batchArchive = async (ids: string[]) => {
    const idSet = new Set(ids);
    const timestamp = new Date().toISOString();
    const updated = opportunities.map((opp) =>
      idSet.has(opp.id) ? { ...opp, status: 'ARCHIVED' as Status, updatedAt: timestamp } : opp
    );
    await persist(updated);
    if (user?.uid) {
      await Promise.all(
        ids.map((id) => {
          const opp = updated.find((o) => o.id === id);
          return opp ? FirestoreService.updateOpportunity(user.uid, id, opp) : Promise.resolve();
        })
      );
    }
  };

  const resetToSampleData = async () => {
    if (user?.uid) {
      await StorageService.clearUserOpportunities(user.uid);
    }
    setOpportunities([]);
  };

  return (
    <OpportunityContext.Provider
      value={{
        opportunities,
        loading,
        searchQuery,
        setSearchQuery,
        selectedCategory,
        setSelectedCategory,
        selectedPriority,
        setSelectedPriority,
        addOpportunity,
        updateOpportunity,
        deleteOpportunity,
        toggleComplete,
        snoozeOpportunity,
        togglePin,
        toggleChecklistItem,
        addChecklistItem,
        batchDelete,
        batchComplete,
        batchArchive,
        resetToSampleData,
        uncompletedCount,
      }}
    >
      {children}
    </OpportunityContext.Provider>
  );
};

export const useOpportunities = () => {
  const context = useContext(OpportunityContext);
  if (!context) throw new Error('useOpportunities must be used within an OpportunityProvider');
  return context;
};

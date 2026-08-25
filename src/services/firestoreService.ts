/**
 * Firestore Service
 * Strict per-user CRUD for opportunities in Firestore subcollection: users/{uid}/opportunities
 * Safe public shared reminders collection: shared_reminders/{shareId}
 */
import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from './firebase';
import { Opportunity, SharedReminder } from '../types/opportunity';

const getUserOpportunitiesRef = (userId: string) => {
  if (!db) return null;
  return collection(db, 'users', userId, 'opportunities');
};

const getUserDocRef = (userId: string) => {
  if (!db) return null;
  return doc(db, 'users', userId);
};

export const FirestoreService = {
  /**
   * Ensure user document exists in Firestore
   */
  async ensureUserDocument(userId: string, profile: Record<string, unknown>): Promise<void> {
    if (!db || !userId) return;
    try {
      const userRef = getUserDocRef(userId);
      if (!userRef) return;
      await setDoc(userRef, { ...profile, updatedAt: serverTimestamp() }, { merge: true });
    } catch (e) {
      console.warn('[Firestore] ensureUserDocument error:', e);
    }
  },

  /**
   * Get all opportunities for a user
   */
  async getOpportunities(userId: string): Promise<Opportunity[]> {
    if (!db || !userId) return [];
    try {
      const ref = getUserOpportunitiesRef(userId);
      if (!ref) return [];
      const snapshot = await getDocs(ref);
      return snapshot.docs.map((d) => ({ id: d.id, ownerUid: userId, ...d.data() } as Opportunity));
    } catch (e) {
      console.warn('[Firestore] getOpportunities error:', e);
      return [];
    }
  },

  /**
   * Save or overwrite an opportunity
   */
  async saveOpportunity(userId: string, opportunity: Opportunity): Promise<void> {
    if (!db || !userId) return;
    try {
      const ref = getUserOpportunitiesRef(userId);
      if (!ref) return;
      const docRef = doc(ref, opportunity.id);
      await setDoc(
        docRef,
        { ...opportunity, ownerUid: userId, updatedAt: serverTimestamp() },
        { merge: true }
      );
    } catch (e) {
      console.warn('[Firestore] saveOpportunity error:', e);
    }
  },

  /**
   * Add a new opportunity with explicit ID
   */
  async addOpportunity(userId: string, data: Opportunity): Promise<string | null> {
    if (!db || !userId) return null;
    try {
      const ref = getUserOpportunitiesRef(userId);
      if (!ref) return null;
      const docRef = doc(ref, data.id);
      await setDoc(
        docRef,
        { ...data, ownerUid: userId, createdAt: serverTimestamp(), updatedAt: serverTimestamp() },
        { merge: true }
      );
      return data.id;
    } catch (e) {
      console.warn('[Firestore] addOpportunity error:', e);
      return null;
    }
  },

  /**
   * Update an existing opportunity
   */
  async updateOpportunity(userId: string, id: string, updates: Partial<Opportunity>): Promise<void> {
    if (!db || !userId) return;
    try {
      const ref = getUserOpportunitiesRef(userId);
      if (!ref) return;
      const docRef = doc(ref, id);
      await updateDoc(docRef, { ...updates, ownerUid: userId, updatedAt: serverTimestamp() });
    } catch (e) {
      console.warn('[Firestore] updateOpportunity error:', e);
    }
  },

  /**
   * Delete an opportunity
   */
  async deleteOpportunity(userId: string, id: string): Promise<void> {
    if (!db || !userId) return;
    try {
      const ref = getUserOpportunitiesRef(userId);
      if (!ref) return;
      const docRef = doc(ref, id);
      await deleteDoc(docRef);
    } catch (e) {
      console.warn('[Firestore] deleteOpportunity error:', e);
    }
  },

  /**
   * Public Shared Reminders (Safe Model)
   */
  async createSharedReminder(share: SharedReminder): Promise<void> {
    if (!db) return;
    try {
      const docRef = doc(db, 'shared_reminders', share.shareId);
      await setDoc(docRef, { ...share, createdAt: serverTimestamp() });
    } catch (e) {
      console.warn('[Firestore] createSharedReminder error:', e);
      throw e;
    }
  },

  async getSharedReminder(shareId: string): Promise<SharedReminder | null> {
    if (!db) return null;
    try {
      const docRef = doc(db, 'shared_reminders', shareId);
      const snap = await getDoc(docRef);
      if (snap.exists()) {
        return snap.data() as SharedReminder;
      }
      return null;
    } catch (e) {
      console.warn('[Firestore] getSharedReminder error:', e);
      return null;
    }
  },
};

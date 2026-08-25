/**
 * AuthContext — Production Firebase Authentication
 * Features:
 *  - Persistent Firebase Auth via onAuthStateChanged
 *  - Google Sign-In via expo-auth-session
 *  - Email & Password Sign-In and Registration
 *  - Strict UID-based data association
 */
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Platform } from 'react-native';
import { UserProfile } from '../types/opportunity';
import { auth, isConfigured } from '../services/firebase';
import { FirestoreService } from '../services/firestoreService';
import { NotificationService } from '../services/notifications';

import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  GoogleAuthProvider,
  signInWithCredential,
  signInWithPopup,
  updateProfile,
  User as FirebaseUser,
} from 'firebase/auth';

import * as WebBrowser from 'expo-web-browser';
import * as Google from 'expo-auth-session/providers/google';

WebBrowser.maybeCompleteAuthSession();

interface AuthContextType {
  user: UserProfile | null;
  loading: boolean;
  loginWithGoogle: () => Promise<void>;
  loginWithEmail: (email: string, pass: string) => Promise<void>;
  registerWithEmail: (name: string, email: string, pass: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

function firebaseUserToProfile(fbUser: FirebaseUser): UserProfile {
  return {
    uid: fbUser.uid,
    email: fbUser.email || '',
    displayName: fbUser.displayName || fbUser.email?.split('@')[0] || 'User',
    photoURL: fbUser.photoURL || undefined,
    isAnonymous: false,
    settings: {
      theme: 'dark',
      defaultSnoozeMinutes: 60,
      calendarSyncEnabled: false,
      pushNotificationsEnabled: true,
      prioritySuggestionsEnabled: true,
    },
  };
}

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  // Google OAuth via expo-auth-session
  const [request, response, promptAsync] = Google.useAuthRequest({
    webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID,
    scopes: ['profile', 'email'],
  });

  // Listen to authoritative Firebase auth state
  useEffect(() => {
    if (!isConfigured || !auth) {
      setUser(null);
      setLoading(false);
      return;
    }

    const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
      if (fbUser) {
        const profile = firebaseUserToProfile(fbUser);
        setUser(profile);
        // Ensure user document exists in Firestore
        await FirestoreService.ensureUserDocument(fbUser.uid, {
          email: profile.email,
          displayName: profile.displayName,
          photoURL: profile.photoURL || null,
        });
      } else {
        setUser(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Handle native Google OAuth response
  useEffect(() => {
    if (response?.type === 'success') {
      const idToken = response.authentication?.idToken || (response.params as any)?.id_token;
      const accessToken = response.authentication?.accessToken || (response.params as any)?.access_token;
      
      if (auth && idToken) {
        const credential = GoogleAuthProvider.credential(idToken, accessToken);
        signInWithCredential(auth, credential).catch((e) => {
          console.warn('[Auth] Google credential sign-in failed:', e);
        });
      }
    }
  }, [response]);

  const loginWithGoogle = async () => {
    if (!isConfigured || !auth) {
      throw new Error('Firebase Authentication is not configured on this device.');
    }

    if (Platform.OS === 'web') {
      const provider = new GoogleAuthProvider();
      await signInWithPopup(auth, provider);
    } else {
      const result = await promptAsync();
      if (result.type === 'cancel' || result.type === 'dismiss') {
        throw new Error('Google Sign-In was cancelled.');
      }
      if (result.type === 'error') {
        throw new Error(result.error?.message || 'Google Sign-In failed.');
      }
    }
  };

  const loginWithEmail = async (email: string, pass: string) => {
    const cleanEmail = email.trim();
    if (!cleanEmail || !pass) {
      throw new Error('Please enter both email and password.');
    }
    if (!isConfigured || !auth) {
      throw new Error('Firebase Authentication is not configured on this device.');
    }

    try {
      await signInWithEmailAndPassword(auth, cleanEmail, pass);
    } catch (e: any) {
      let message = 'Sign in failed. Please check your credentials.';
      if (e.code === 'auth/invalid-email') message = 'The email address is not valid.';
      else if (e.code === 'auth/user-not-found' || e.code === 'auth/invalid-credential' || e.code === 'auth/wrong-password') {
        message = 'Invalid email or password. Please try again or create an account.';
      } else if (e.code === 'auth/too-many-requests') {
        message = 'Access temporarily disabled due to many failed attempts. Try again later or reset password.';
      } else if (e.code === 'auth/network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      } else if (e.message) {
        message = e.message;
      }
      throw new Error(message);
    }
  };

  const registerWithEmail = async (name: string, email: string, pass: string) => {
    const cleanEmail = email.trim();
    const cleanName = name.trim();

    if (!cleanName) {
      throw new Error('Please enter your full name.');
    }
    if (!cleanEmail) {
      throw new Error('Please enter a valid email address.');
    }
    if (pass.length < 6) {
      throw new Error('Password must be at least 6 characters long.');
    }
    if (!isConfigured || !auth) {
      throw new Error('Firebase Authentication is not configured on this device.');
    }

    try {
      const cred = await createUserWithEmailAndPassword(auth, cleanEmail, pass);
      await updateProfile(cred.user, { displayName: cleanName });
      await FirestoreService.ensureUserDocument(cred.user.uid, {
        email: cleanEmail,
        displayName: cleanName,
        photoURL: null,
      });
    } catch (e: any) {
      let message = 'Registration failed. Please check your details.';
      if (e.code === 'auth/email-already-in-use') {
        message = 'An account already exists with this email address. Please sign in instead.';
      } else if (e.code === 'auth/invalid-email') {
        message = 'The email address is formatted incorrectly.';
      } else if (e.code === 'auth/weak-password') {
        message = 'Password should be at least 6 characters.';
      } else if (e.code === 'auth/network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      } else if (e.message) {
        message = e.message;
      }
      throw new Error(message);
    }
  };

  const logout = async () => {
    if (isConfigured && auth) {
      await signOut(auth);
    }
    setUser(null);
    await NotificationService.cancelAllUserReminders();
  };

  return (
    <AuthContext.Provider value={{ user, loading, loginWithGoogle, loginWithEmail, registerWithEmail, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
};

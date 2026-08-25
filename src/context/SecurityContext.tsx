import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AppState, AppStateStatus } from 'react-native';

interface SecurityContextType {
  isPinEnabled: boolean;
  pinCode: string | null;
  isLocked: boolean;
  securingSession: boolean;
  setPin: (newPin: string) => Promise<void>;
  disablePin: () => Promise<void>;
  unlock: () => void;
  verifyPin: (enteredPin: string) => boolean;
}

const PIN_STORAGE_KEY = '@marakadhey_security_pin_v1';
const PIN_ENABLED_KEY = '@marakadhey_pin_enabled_v1';

const SecurityContext = createContext<SecurityContextType | undefined>(undefined);

export const SecurityProvider = ({ children }: { children: ReactNode }) => {
  const [isPinEnabled, setIsPinEnabled] = useState(false);
  const [pinCode, setPinCode] = useState<string | null>(null);
  const [isLocked, setIsLocked] = useState(false);
  const [securingSession, setSecuringSession] = useState(false);

  // Load PIN settings from storage on mount
  useEffect(() => {
    (async () => {
      try {
        const storedEnabled = await AsyncStorage.getItem(PIN_ENABLED_KEY);
        const storedPin = await AsyncStorage.getItem(PIN_STORAGE_KEY);
        if (storedEnabled === 'true' && storedPin) {
          setIsPinEnabled(true);
          setPinCode(storedPin);
          triggerSecuringFlow();
        }
      } catch (e) {
        console.warn('Failed to load security PIN state:', e);
      }
    })();
  }, []);

  // Listen to AppState changes (when app comes to foreground)
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextAppState: AppStateStatus) => {
      if (nextAppState === 'active' && isPinEnabled && pinCode) {
        triggerSecuringFlow();
      }
    });
    return () => subscription.remove();
  }, [isPinEnabled, pinCode]);

  const triggerSecuringFlow = () => {
    setSecuringSession(true);
    setIsLocked(true);
    // Show "Securing Session..." for 500ms then transition to PIN pad
    setTimeout(() => {
      setSecuringSession(false);
    }, 600);
  };

  const setPin = async (newPin: string) => {
    const cleanPin = String(newPin).trim();
    await AsyncStorage.setItem(PIN_STORAGE_KEY, cleanPin);
    await AsyncStorage.setItem(PIN_ENABLED_KEY, 'true');
    setPinCode(cleanPin);
    setIsPinEnabled(true);
    setIsLocked(false);
  };

  const disablePin = async () => {
    await AsyncStorage.removeItem(PIN_STORAGE_KEY);
    await AsyncStorage.setItem(PIN_ENABLED_KEY, 'false');
    setPinCode(null);
    setIsPinEnabled(false);
    setIsLocked(false);
  };

  const verifyPin = (enteredPin: string) => {
    if (!pinCode) return false;
    return String(enteredPin).trim() === String(pinCode).trim();
  };

  const unlock = () => {
    setIsLocked(false);
    setSecuringSession(false);
  };

  return (
    <SecurityContext.Provider
      value={{
        isPinEnabled,
        pinCode,
        isLocked,
        securingSession,
        setPin,
        disablePin,
        unlock,
        verifyPin,
      }}
    >
      {children}
    </SecurityContext.Provider>
  );
};

export const useSecurity = () => {
  const ctx = useContext(SecurityContext);
  if (!ctx) throw new Error('useSecurity must be used within a SecurityProvider');
  return ctx;
};

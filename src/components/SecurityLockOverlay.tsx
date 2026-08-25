import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { Delete, KeyRound, Lock } from 'lucide-react-native';
import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Platform,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  Vibration,
  View,
} from 'react-native';
import { Colors } from '../constants/theme';
import { useAuth } from '../context/AuthContext';
import { useSecurity } from '../context/SecurityContext';

export const SecurityLockOverlay: React.FC = () => {
  const router = useRouter();
  const { isLocked, securingSession, verifyPin, unlock, disablePin } = useSecurity();
  const { logout } = useAuth();

  const [enteredPin, setEnteredPin] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [attempts, setAttempts] = useState(0);

  useEffect(() => {
    if (!isLocked) {
      setEnteredPin('');
      setErrorMsg('');
      setAttempts(0);
    }
  }, [isLocked]);

  if (!isLocked) return null;

  const handleResetAndLogout = async () => {
    await disablePin();
    await logout();
    router.replace('/login');
  };

  const triggerFourAttemptsReset = async () => {
    if (Platform.OS === 'web') {
      window.alert('PIN Lockout (4 Failed Attempts): You entered an incorrect PIN 4 times. Signing out now so you can sign in to reset your PIN.');
      await handleResetAndLogout();
    } else {
      Vibration.vibrate([0, 200, 100, 200]);
      Alert.alert(
        'PIN Lockout (4 Failed Attempts)',
        'You entered an incorrect PIN 4 times. For your security, your session has been signed out. Please sign in with Google or Email to reset your passkey PIN.',
        [
          {
            text: 'Sign In to Reset PIN',
            onPress: handleResetAndLogout,
          },
        ],
        { cancelable: false }
      );
    }
  };

  // Screen 1: "Securing Session..." brief splash loader (matches screenshot 1)
  if (securingSession) {
    return (
      <View style={styles.securingOverlay}>
        <StatusBar barStyle="light-content" backgroundColor="#090D16" />
        <View style={styles.securingBox}>
          <View style={styles.securingLockBadge}>
            <Lock size={32} color={Colors.primary} />
          </View>
          <Text style={styles.securingTitle}>Securing Session...</Text>
          <Text style={styles.securingSub}>Verifying security lock & credentials</Text>
          <ActivityIndicator size="small" color={Colors.primary} style={{ marginTop: 14 }} />
        </View>
      </View>
    );
  }

  // Screen 2: 4-digit PIN Keypad Lock Screen
  const handleNumberPress = (num: string) => {
    if (enteredPin.length >= 4) return;
    const newPin = enteredPin + num;
    setEnteredPin(newPin);
    setErrorMsg('');

    if (newPin.length === 4) {
      setTimeout(() => {
        if (verifyPin(newPin)) {
          Vibration.vibrate(50);
          unlock();
          setEnteredPin('');
          setAttempts(0);
          setErrorMsg('');
        } else {
          const nextAttempts = attempts + 1;
          setAttempts(nextAttempts);
          Vibration.vibrate([0, 100, 50, 100]);
          setEnteredPin('');
          setErrorMsg('Incorrect PIN. Please try again.');
        }
      }, 150);
    }
  };

  const handleDelete = () => {
    setEnteredPin(prev => prev.slice(0, -1));
    setErrorMsg('');
  };

  return (
    <SafeAreaView style={styles.keypadOverlay}>
      <StatusBar barStyle="light-content" backgroundColor="#090D16" />
      <View style={styles.keypadContainer}>
        {/* Branding Logo Header */}
        <View style={styles.brandHeader}>
          <Image
            source={require('../../assets/logo.png')}
            style={{ width: 56, height: 56 }}
            contentFit="contain"
          />
          <Text style={styles.welcomeTitle}>Welcome Back, Opportunity Hunter 👋</Text>
          <Text style={styles.welcomeSub}>Enter your 4-digit PIN to unlock Marakadhey</Text>
        </View>

        {/* PIN Indicator Dots */}
        <View style={styles.dotsRow}>
          {[0, 1, 2, 3].map(idx => (
            <View
              key={idx}
              style={[
                styles.dot,
                enteredPin.length > idx && styles.dotFilled,
                errorMsg ? styles.dotError : null,
              ]}
            />
          ))}
        </View>

        {/* Error / Attempts Message */}
        {errorMsg ? (
          <Text style={styles.errorText}>{errorMsg}</Text>
        ) : (
          <View style={{ height: 20 }} />
        )}

        {/* Keypad Grid */}
        <View style={styles.keypadGrid}>
          {[['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']].map((row, rIdx) => (
            <View key={rIdx} style={styles.keypadRow}>
              {row.map(num => (
                <TouchableOpacity
                  key={num}
                  style={styles.keyBtn}
                  onPress={() => handleNumberPress(num)}
                  activeOpacity={0.7}
                >
                  <Text style={styles.keyNumText}>{num}</Text>
                </TouchableOpacity>
              ))}
            </View>
          ))}

          {/* Bottom Row: Lock, 0, Backspace */}
          <View style={styles.keypadRow}>
            <View style={styles.keyBtnEmpty}>
              <KeyRound size={22} color={Colors.textMuted} />
            </View>

            <TouchableOpacity
              style={styles.keyBtn}
              onPress={() => handleNumberPress('0')}
              activeOpacity={0.7}
            >
              <Text style={styles.keyNumText}>0</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.keyBtn, styles.keyBtnDelete]}
              onPress={handleDelete}
              activeOpacity={0.7}
            >
              <Delete size={22} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        </View>

        {/* Reset via Sign-In Footer Link (matches screenshot 3) */}
        <TouchableOpacity style={styles.forgotBtn} onPress={triggerFourAttemptsReset} activeOpacity={0.7}>
          <Text style={styles.securityFooterText}>
            Forgot PIN? Enter incorrectly 4 times or <Text style={styles.forgotLinkText}>tap here to reset via sign-in</Text>
          </Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  securingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: '#090D16',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 99999,
  },
  securingBox: {
    alignItems: 'center',
    gap: 10,
  },
  securingLockBadge: {
    width: 68,
    height: 68,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 107, 0, 0.12)',
    borderWidth: 1,
    borderColor: 'rgba(255, 107, 0, 0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 6,
  },
  securingTitle: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '800',
  },
  securingSub: {
    color: Colors.textMuted,
    fontSize: 13,
  },

  keypadOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: '#090D16',
    zIndex: 99999,
  },
  keypadContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    gap: 22,
    maxWidth: 440,
    alignSelf: 'center',
    width: '100%',
  },
  brandHeader: {
    alignItems: 'center',
    gap: 8,
  },
  welcomeTitle: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '800',
    textAlign: 'center',
    marginTop: 6,
  },
  welcomeSub: {
    color: Colors.textMuted,
    fontSize: 13,
    textAlign: 'center',
  },

  dotsRow: {
    flexDirection: 'row',
    gap: 16,
    marginVertical: 4,
  },
  dot: {
    width: 14,
    height: 14,
    borderRadius: 7,
    borderWidth: 2,
    borderColor: Colors.textMuted,
    backgroundColor: 'transparent',
  },
  dotFilled: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  dotError: {
    borderColor: '#EF4444',
    backgroundColor: '#EF4444',
  },
  errorText: {
    color: '#EF4444',
    fontSize: 13,
    fontWeight: '700',
    height: 20,
  },

  keypadGrid: {
    gap: 14,
    width: '100%',
    maxWidth: 300,
  },
  keypadRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 14,
  },
  keyBtn: {
    width: 72,
    height: 72,
    borderRadius: 20,
    backgroundColor: '#1E293B',
    borderWidth: 1,
    borderColor: '#334155',
    alignItems: 'center',
    justifyContent: 'center',
  },
  keyBtnEmpty: {
    width: 72,
    height: 72,
    borderRadius: 20,
    backgroundColor: 'transparent',
    alignItems: 'center',
    justifyContent: 'center',
  },
  keyBtnDelete: {
    backgroundColor: '#334155',
  },
  keyNumText: {
    color: '#FFFFFF',
    fontSize: 24,
    fontWeight: '800',
  },

  forgotBtn: {
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  securityFooterText: {
    color: Colors.textMuted,
    fontSize: 12,
    textAlign: 'center',
    marginTop: 10,
    lineHeight: 18,
  },
  forgotLinkText: {
    color: Colors.primary,
    fontWeight: '800',
    textDecorationLine: 'underline',
  },
});

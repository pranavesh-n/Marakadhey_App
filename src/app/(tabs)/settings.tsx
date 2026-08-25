import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Switch,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
  Alert,
  Platform,
  Modal,
  TextInput,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useRouter } from 'expo-router';
import { Colors } from '../../constants/theme';
import { MarakadheyHeader } from '../../components/Header';
import { useAuth } from '../../context/AuthContext';
import { useSecurity } from '../../context/SecurityContext';
import { User, LogOut, ShieldCheck, Lock, Key, BellRing, Info } from 'lucide-react-native';

const PREF_KEYS = {
  AUTO_COMPLETE: '@marakadhey_pref_autocomplete',
  HIDE_COMPLETED: '@marakadhey_pref_hidecompleted',
  DEVICE_NOTIFS: '@marakadhey_pref_devicenotifs',
};

export default function SettingsScreen() {
  const router = useRouter();
  const { user, logout } = useAuth();
  const { isPinEnabled, setPin, disablePin } = useSecurity();

  // Preferences State
  const [autoComplete, setAutoComplete] = useState(true);
  const [hideCompleted, setHideCompleted] = useState(false);
  const [deviceNotifsDefault, setDeviceNotifsDefault] = useState(true);

  // Set PIN Modal State
  const [pinModalVisible, setPinModalVisible] = useState(false);
  const [newPin, setNewPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [modalError, setModalError] = useState('');

  // Load preferences persistently on mount
  useEffect(() => {
    (async () => {
      try {
        const storedAC = await AsyncStorage.getItem(PREF_KEYS.AUTO_COMPLETE);
        if (storedAC !== null) setAutoComplete(storedAC === 'true');

        const storedHC = await AsyncStorage.getItem(PREF_KEYS.HIDE_COMPLETED);
        if (storedHC !== null) setHideCompleted(storedHC === 'true');

        const storedDN = await AsyncStorage.getItem(PREF_KEYS.DEVICE_NOTIFS);
        if (storedDN !== null) setDeviceNotifsDefault(storedDN === 'true');
      } catch (e) {
        console.warn('Failed to load user preferences:', e);
      }
    })();
  }, []);

  const handleTogglePref = async (key: string, value: boolean, setter: (v: boolean) => void) => {
    setter(value);
    await AsyncStorage.setItem(key, String(value));
  };

  const handleSecurityToggle = async (val: boolean) => {
    if (val) {
      setNewPin('');
      setConfirmPin('');
      setModalError('');
      setPinModalVisible(true);
    } else {
      if (Platform.OS === 'web') {
        if (window.confirm('Are you sure you want to disable 4-digit PIN Security Lock?')) {
          await disablePin();
        }
      } else {
        Alert.alert(
          'Disable App Lock',
          'Are you sure you want to disable 4-digit PIN Security Lock?',
          [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Disable',
              style: 'destructive',
              onPress: async () => {
                await disablePin();
              },
            },
          ]
        );
      }
    }
  };

  const handleSavePin = async () => {
    if (newPin.length !== 4 || !/^\d{4}$/.test(newPin)) {
      setModalError('PIN must be exactly 4 digits.');
      return;
    }
    if (newPin !== confirmPin) {
      setModalError('PINs do not match. Please re-enter.');
      return;
    }
    await setPin(newPin);
    setPinModalVisible(false);
    Alert.alert('Security Enabled ✓', 'App Passkey PIN lock is now active.');
  };

  const handleLogout = async () => {
    if (Platform.OS === 'web') {
      await logout();
      router.replace('/login');
    } else {
      Alert.alert(
        'Sign Out',
        'Are you sure you want to sign out of your Marakadhey account?',
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Sign Out',
            style: 'destructive',
            onPress: async () => {
              await logout();
              router.replace('/login');
            },
          },
        ]
      );
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.headerBg} />
      <MarakadheyHeader />

      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        <View style={styles.responsiveContainer}>
          {/* USER ACCOUNT CARD */}
          <View style={styles.card}>
            <View style={styles.cardTitleRow}>
              <User size={15} color={Colors.primary} />
              <Text style={styles.cardHeaderTitle}>USER ACCOUNT</Text>
            </View>

            <View style={styles.userProfileRow}>
              <View style={styles.avatarCircle}>
                <User size={22} color={Colors.primary} />
              </View>
              <View style={styles.userTextCol}>
                <Text style={styles.userNameText}>{user?.displayName || 'Opportunity Hunter'}</Text>
                <Text style={styles.userEmailText}>{user?.email || 'Logged In'}</Text>
              </View>
            </View>

            <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout} activeOpacity={0.8}>
              <LogOut size={16} color="#EF4444" />
              <Text style={styles.logoutBtnText}>Sign Out of Marakadhey</Text>
            </TouchableOpacity>
          </View>

          {/* SECURITY & PRIVACY CARD */}
          <View style={styles.card}>
            <View style={styles.cardTitleRow}>
              <ShieldCheck size={16} color={Colors.primary} />
              <Text style={styles.cardHeaderTitle}>SECURITY & PRIVACY</Text>
            </View>

            {/* Passkey PIN Lock Toggle */}
            <View style={styles.settingItem}>
              <View style={styles.settingTextCol}>
                <View style={styles.settingTitleRow}>
                  <Text style={styles.settingTitle}>App 4-Digit PIN Security Lock</Text>
                  {isPinEnabled && (
                    <View style={styles.activeBadge}>
                      <Text style={styles.activeBadgeText}>ACTIVE</Text>
                    </View>
                  )}
                </View>
                <Text style={styles.settingDesc}>
                  Require a 4-digit PIN whenever reopening or returning to Marakadhey.
                </Text>
              </View>
              <Switch
                value={isPinEnabled}
                onValueChange={handleSecurityToggle}
                trackColor={{ false: '#D1D5DB', true: Colors.primary }}
                thumbColor="#FFFFFF"
              />
            </View>

            {/* Change PIN Button */}
            {isPinEnabled && (
              <TouchableOpacity
                style={styles.changePinBtn}
                onPress={() => {
                  setNewPin('');
                  setConfirmPin('');
                  setModalError('');
                  setPinModalVisible(true);
                }}
                activeOpacity={0.8}
              >
                <Key size={15} color={Colors.primary} />
                <Text style={styles.changePinBtnText}>Change 4-Digit Security PIN</Text>
              </TouchableOpacity>
            )}
          </View>

          {/* PREFERENCES CARD */}
          <View style={styles.card}>
            <View style={styles.cardTitleRow}>
              <BellRing size={15} color={Colors.primary} />
              <Text style={styles.cardHeaderTitle}>NOTIFICATIONS & PREFERENCES</Text>
            </View>

            {/* Hardware Alarms Default */}
            <View style={styles.settingItem}>
              <View style={styles.settingTextCol}>
                <Text style={styles.settingTitle}>Device notifications enabled by default</Text>
                <Text style={styles.settingDesc}>
                  Keep device alarm reminders turned on automatically when creating new reminders.
                </Text>
              </View>
              <Switch
                value={deviceNotifsDefault}
                onValueChange={(val) =>
                  handleTogglePref(PREF_KEYS.DEVICE_NOTIFS, val, setDeviceNotifsDefault)
                }
                trackColor={{ false: '#D1D5DB', true: Colors.primary }}
                thumbColor="#FFFFFF"
              />
            </View>

            {/* Mark completed after opening link */}
            <View style={styles.settingItem}>
              <View style={styles.settingTextCol}>
                <Text style={styles.settingTitle}>Mark completed after opening link</Text>
                <Text style={styles.settingDesc}>
                  Automatically mark reminder completed when opening its webpage link.
                </Text>
              </View>
              <Switch
                value={autoComplete}
                onValueChange={(val) =>
                  handleTogglePref(PREF_KEYS.AUTO_COMPLETE, val, setAutoComplete)
                }
                trackColor={{ false: '#D1D5DB', true: Colors.primary }}
                thumbColor="#FFFFFF"
              />
            </View>

            {/* Hide completed from Inbox */}
            <View style={styles.settingItem}>
              <View style={styles.settingTextCol}>
                <Text style={styles.settingTitle}>Hide completed reminders from Inbox</Text>
                <Text style={styles.settingDesc}>
                  Filter out completed items from your default Inbox view.
                </Text>
              </View>
              <Switch
                value={hideCompleted}
                onValueChange={(val) =>
                  handleTogglePref(PREF_KEYS.HIDE_COMPLETED, val, setHideCompleted)
                }
                trackColor={{ false: '#D1D5DB', true: Colors.primary }}
                thumbColor="#FFFFFF"
              />
            </View>
          </View>

          {/* ABOUT CARD */}
          <View style={styles.card}>
            <View style={styles.cardTitleRow}>
              <Info size={15} color={Colors.primary} />
              <Text style={styles.cardHeaderTitle}>ABOUT MARAKADHEY</Text>
            </View>
            <Text style={styles.aboutText}>
              Marakadhey Mobile v2.3.1 • 100% Free Forever Tier Active
            </Text>
            <Text style={styles.aboutSubText}>
              Originating from the Marakadhey Extension to help you never miss internships, jobs, scholarships, and deadlines.
            </Text>
          </View>

          <View style={{ height: 40 }} />
        </View>
      </ScrollView>

      {/* SET 4-DIGIT PIN MODAL */}
      <Modal visible={pinModalVisible} transparent animationType="slide">
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <View style={styles.modalLockBadge}>
                <Lock size={22} color={Colors.primary} />
              </View>
              <Text style={styles.modalTitle}>Set 4-Digit Security PIN</Text>
              <Text style={styles.modalSub}>
                Create a 4-digit PIN code to secure your Marakadhey app.
              </Text>
            </View>

            <View style={styles.modalForm}>
              <Text style={styles.modalLabel}>ENTER 4-DIGIT PIN</Text>
              <TextInput
                style={styles.modalPinInput}
                keyboardType="number-pad"
                maxLength={4}
                secureTextEntry
                placeholder="••••"
                placeholderTextColor={Colors.textLight}
                value={newPin}
                onChangeText={setNewPin}
              />

              <Text style={styles.modalLabel}>CONFIRM 4-DIGIT PIN</Text>
              <TextInput
                style={styles.modalPinInput}
                keyboardType="number-pad"
                maxLength={4}
                secureTextEntry
                placeholder="••••"
                placeholderTextColor={Colors.textLight}
                value={confirmPin}
                onChangeText={setConfirmPin}
              />

              {modalError ? <Text style={styles.modalErrorText}>{modalError}</Text> : null}
            </View>

            <View style={styles.modalBtnRow}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => setPinModalVisible(false)}
              >
                <Text style={styles.modalCancelBtnText}>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.modalSaveBtn} onPress={handleSavePin}>
                <Text style={styles.modalSaveBtnText}>Save PIN</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  container: {
    flex: 1,
    padding: 14,
  },
  responsiveContainer: {
    width: '100%',
    maxWidth: 640,
    alignSelf: 'center',
    gap: 12,
  },
  card: {
    backgroundColor: Colors.surface,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  cardTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  cardHeaderTitle: {
    fontSize: 11,
    fontWeight: '800',
    color: Colors.secondary,
    letterSpacing: 0.5,
  },
  userProfileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  avatarCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#FFF7ED',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#FFEDD5',
  },
  userTextCol: {
    flex: 1,
    gap: 2,
  },
  userNameText: {
    fontSize: 15,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  userEmailText: {
    fontSize: 12,
    color: Colors.textMuted,
  },
  logoutBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#FEF2F2',
    paddingVertical: 11,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#FCA5A5',
    marginTop: 2,
  },
  logoutBtnText: {
    color: '#EF4444',
    fontSize: 13,
    fontWeight: '700',
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  settingTextCol: {
    flex: 1,
    gap: 2,
  },
  settingTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  settingTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  activeBadge: {
    backgroundColor: '#F0FDF4',
    borderWidth: 1,
    borderColor: '#86EFAC',
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  activeBadgeText: {
    color: '#166534',
    fontSize: 9,
    fontWeight: '900',
  },
  settingDesc: {
    fontSize: 12,
    color: Colors.textMuted,
    lineHeight: 16,
  },
  changePinBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: '#FFF7ED',
    borderWidth: 1,
    borderColor: '#FED7AA',
    borderRadius: 8,
    paddingVertical: 8,
    marginTop: 2,
  },
  changePinBtnText: {
    color: Colors.primary,
    fontSize: 12,
    fontWeight: '700',
  },
  aboutText: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  aboutSubText: {
    fontSize: 12,
    color: Colors.textMuted,
    lineHeight: 16,
  },

  // Modal Styles
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  modalCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    width: '100%',
    maxWidth: 360,
    gap: 14,
  },
  modalHeader: {
    alignItems: 'center',
    gap: 6,
  },
  modalLockBadge: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: '#FFF7ED',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  modalSub: {
    fontSize: 12,
    color: Colors.textMuted,
    textAlign: 'center',
  },
  modalForm: {
    gap: 8,
  },
  modalLabel: {
    fontSize: 10,
    fontWeight: '800',
    color: Colors.secondary,
  },
  modalPinInput: {
    backgroundColor: '#F9FAFB',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 9,
    fontSize: 18,
    letterSpacing: 8,
    textAlign: 'center',
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  modalErrorText: {
    color: '#EF4444',
    fontSize: 12,
    fontWeight: '700',
    textAlign: 'center',
  },
  modalBtnRow: {
    flexDirection: 'row',
    gap: 10,
  },
  modalCancelBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: '#F3F4F6',
    alignItems: 'center',
  },
  modalCancelBtnText: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '700',
  },
  modalSaveBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: Colors.primary,
    alignItems: 'center',
  },
  modalSaveBtnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '800',
  },
});

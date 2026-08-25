import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
  ScrollView,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { Colors } from '../constants/theme';
import { MarakadheyHeader } from '../components/Header';
import { useAuth } from '../context/AuthContext';
import { Mail, Lock, User, Sparkles, ArrowRight, ShieldCheck } from 'lucide-react-native';

export default function LoginScreen() {
  const router = useRouter();
  const { loginWithGoogle, loginWithEmail, registerWithEmail } = useAuth();

  const [mode, setMode] = useState<'signin' | 'register'>('signin');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [googleSubmitting, setGoogleSubmitting] = useState(false);
  const [errorBanner, setErrorBanner] = useState<string | null>(null);

  const handleEmailSubmit = async () => {
    setErrorBanner(null);

    if (!email.trim() || !password.trim()) {
      setErrorBanner('Please enter your email and password.');
      return;
    }

    if (mode === 'register' && !name.trim()) {
      setErrorBanner('Please enter your full name to create an account.');
      return;
    }

    setSubmitting(true);
    try {
      if (mode === 'register') {
        await registerWithEmail(name, email, password);
      } else {
        await loginWithEmail(email, password);
      }
      router.replace('/(tabs)');
    } catch (e: any) {
      setErrorBanner(e.message || 'Authentication error. Please check your credentials.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setErrorBanner(null);
    setGoogleSubmitting(true);
    try {
      await loginWithGoogle();
      router.replace('/(tabs)');
    } catch (e: any) {
      if (!e.message?.includes('cancelled')) {
        setErrorBanner(e.message || 'Failed to sign in with Google.');
      }
    } finally {
      setGoogleSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.headerBg} />
      <MarakadheyHeader />

      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={{ flex: 1 }}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.responsiveContainer}>
            {/* Hero Section */}
            <View style={styles.heroSection}>
              <View style={styles.logoBadge}>
                <Image
                  source={require('../../assets/logo.png')}
                  style={{ width: 44, height: 44 }}
                  contentFit="contain"
                />
              </View>
              <Text style={styles.heroTitle}>Never Miss An Opportunity</Text>
              <Text style={styles.heroSub}>
                Sign in to sync your reminders, deadlines, and smart alerts across your devices.
              </Text>
            </View>

            {/* Auth Form Card */}
            <View style={styles.authCard}>
              {/* Tab Selector */}
              <View style={styles.tabToggleRow}>
                <TouchableOpacity
                  style={[styles.toggleTab, mode === 'signin' && styles.toggleTabActive]}
                  onPress={() => {
                    setMode('signin');
                    setErrorBanner(null);
                  }}
                  activeOpacity={0.8}
                >
                  <Text style={[styles.toggleTabText, mode === 'signin' && styles.toggleTabTextActive]}>
                    Sign In
                  </Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[styles.toggleTab, mode === 'register' && styles.toggleTabActive]}
                  onPress={() => {
                    setMode('register');
                    setErrorBanner(null);
                  }}
                  activeOpacity={0.8}
                >
                  <Text style={[styles.toggleTabText, mode === 'register' && styles.toggleTabTextActive]}>
                    Create Account
                  </Text>
                </TouchableOpacity>
              </View>

              {/* Error Banner if any */}
              {errorBanner ? (
                <View style={styles.errorBox}>
                  <Text style={styles.errorBoxText}>{errorBanner}</Text>
                </View>
              ) : null}

              {/* Google Sign In Option */}
              <TouchableOpacity
                style={styles.googleBtn}
                onPress={handleGoogleSignIn}
                disabled={googleSubmitting || submitting}
                activeOpacity={0.85}
              >
                {googleSubmitting ? (
                  <ActivityIndicator size="small" color={Colors.primary} />
                ) : (
                  <>
                    <Image
                      source={require('../../assets/google-logo.png')}
                      style={{ width: 20, height: 20 }}
                      contentFit="contain"
                    />
                    <Text style={styles.googleBtnText}>Continue with Google</Text>
                  </>
                )}
              </TouchableOpacity>

              <View style={styles.dividerRow}>
                <View style={styles.dividerLine} />
                <Text style={styles.dividerText}>OR WITH EMAIL</Text>
                <View style={styles.dividerLine} />
              </View>

              {/* Form Fields */}
              {mode === 'register' && (
                <View style={styles.formGroup}>
                  <Text style={styles.label}>FULL NAME</Text>
                  <View style={styles.inputWrapper}>
                    <User size={16} color={Colors.textMuted} />
                    <TextInput
                      style={styles.input}
                      placeholder="Your full name"
                      placeholderTextColor={Colors.textLight}
                      value={name}
                      onChangeText={setName}
                    />
                  </View>
                </View>
              )}

              <View style={styles.formGroup}>
                <Text style={styles.label}>EMAIL ADDRESS</Text>
                <View style={styles.inputWrapper}>
                  <Mail size={16} color={Colors.textMuted} />
                  <TextInput
                    style={styles.input}
                    placeholder="name@example.com"
                    placeholderTextColor={Colors.textLight}
                    keyboardType="email-address"
                    autoCapitalize="none"
                    autoCorrect={false}
                    value={email}
                    onChangeText={setEmail}
                  />
                </View>
              </View>

              <View style={styles.formGroup}>
                <Text style={styles.label}>PASSWORD</Text>
                <View style={styles.inputWrapper}>
                  <Lock size={16} color={Colors.textMuted} />
                  <TextInput
                    style={styles.input}
                    placeholder="••••••••"
                    placeholderTextColor={Colors.textLight}
                    secureTextEntry
                    value={password}
                    onChangeText={setPassword}
                  />
                </View>
              </View>

              {/* Submit Email Button */}
              <TouchableOpacity
                style={styles.submitBtn}
                onPress={handleEmailSubmit}
                disabled={submitting || googleSubmitting}
                activeOpacity={0.88}
              >
                {submitting ? (
                  <ActivityIndicator size="small" color="#FFFFFF" />
                ) : (
                  <>
                    <Text style={styles.submitBtnText}>
                      {mode === 'signin' ? 'Sign In to Account' : 'Create Account'}
                    </Text>
                    <ArrowRight size={16} color="#FFFFFF" />
                  </>
                )}
              </TouchableOpacity>
            </View>

            {/* Privacy & Security Tagline */}
            <View style={styles.securityFooter}>
              <ShieldCheck size={14} color={Colors.textMuted} />
              <Text style={styles.securityFooterText}>
                Your data is securely isolated and encrypted.
              </Text>
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  responsiveContainer: {
    width: '100%',
    maxWidth: 420,
    gap: 16,
  },
  heroSection: {
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  logoBadge: {
    width: 60,
    height: 60,
    borderRadius: 18,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
    marginBottom: 6,
  },
  heroTitle: {
    fontSize: 20,
    fontWeight: '900',
    color: Colors.textPrimary,
    textAlign: 'center',
    letterSpacing: -0.3,
  },
  heroSub: {
    fontSize: 13,
    color: Colors.textMuted,
    textAlign: 'center',
    lineHeight: 18,
    paddingHorizontal: 12,
  },
  authCard: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  tabToggleRow: {
    flexDirection: 'row',
    backgroundColor: '#F3F4F6',
    borderRadius: 10,
    padding: 4,
  },
  toggleTab: {
    flex: 1,
    paddingVertical: 9,
    alignItems: 'center',
    borderRadius: 8,
  },
  toggleTabActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 2,
    elevation: 1,
  },
  toggleTabText: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textMuted,
  },
  toggleTabTextActive: {
    color: Colors.primary,
  },
  errorBox: {
    backgroundColor: '#FEF2F2',
    borderRadius: 8,
    padding: 10,
    borderWidth: 1,
    borderColor: '#FCA5A5',
  },
  errorBoxText: {
    color: '#DC2626',
    fontSize: 12,
    fontWeight: '700',
    textAlign: 'center',
  },
  googleBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    paddingVertical: 11,
    borderRadius: 10,
    gap: 10,
  },
  googleBtnText: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  dividerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginVertical: 2,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#E5E7EB',
  },
  dividerText: {
    fontSize: 10,
    fontWeight: '800',
    color: Colors.textLight,
    letterSpacing: 0.5,
  },
  formGroup: {
    gap: 5,
  },
  label: {
    fontSize: 11,
    fontWeight: '800',
    color: Colors.secondary,
    letterSpacing: 0.5,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    paddingHorizontal: 12,
    height: 44,
    gap: 8,
  },
  input: {
    flex: 1,
    fontSize: 14,
    color: Colors.textPrimary,
  },
  submitBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.primary,
    paddingVertical: 12,
    borderRadius: 10,
    gap: 8,
    marginTop: 4,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '800',
  },
  securityFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    marginTop: 4,
  },
  securityFooterText: {
    color: Colors.textMuted,
    fontSize: 11,
    fontWeight: '500',
  },
});

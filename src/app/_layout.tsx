import React, { useEffect, useRef } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { AuthProvider, useAuth } from '../context/AuthContext';
import { OpportunityProvider } from '../context/OpportunityContext';
import { Colors } from '../constants/theme';
import { View, StyleSheet, ActivityIndicator, Text } from 'react-native';
import { Image } from 'expo-image';
import * as Notifications from 'expo-notifications';
import * as Linking from 'expo-linking';

import { SecurityProvider } from '../context/SecurityContext';
import { SecurityLockOverlay } from '../components/SecurityLockOverlay';

function AuthGuardNavigator() {
  const { user, loading } = useAuth();
  const segments = useSegments();
  const router = useRouter();
  const notificationListener = useRef<Notifications.EventSubscription | null>(null);

  // Set up notification tap handler — opens the opportunity or target url
  useEffect(() => {
    notificationListener.current = Notifications.addNotificationResponseReceivedListener((response) => {
      const data = response.notification.request.content.data as { url?: string; opportunityId?: string };
      if (data?.opportunityId) {
        router.push(`/opportunity/${data.opportunityId}` as any);
      } else if (data?.url) {
        import('expo-web-browser').then((m) => m.openBrowserAsync(data.url as string));
      }
    });

    return () => {
      notificationListener.current?.remove();
    };
  }, [router]);

  // Deep Link Listener for incoming URL schemes (marakadheyapp://share/[id], etc.)
  useEffect(() => {
    const handleDeepLink = (event: { url: string }) => {
      const parsed = Linking.parse(event.url);
      if (parsed.path?.startsWith('share/')) {
        const shareId = parsed.path.replace('share/', '');
        if (shareId) {
          router.push(`/share/${shareId}` as any);
        }
      } else if (parsed.path?.startsWith('opportunity/') || parsed.path?.startsWith('reminder/')) {
        const oppId = parsed.path.replace('opportunity/', '').replace('reminder/', '');
        if (oppId) {
          router.push(`/opportunity/${oppId}` as any);
        }
      }
    };

    const sub = Linking.addEventListener('url', handleDeepLink);
    Linking.getInitialURL().then((url) => {
      if (url) handleDeepLink({ url });
    });

    return () => {
      sub.remove();
    };
  }, [router]);

  // Navigation Guard: Segregate Auth and App Routes
  useEffect(() => {
    if (loading) return;

    const currentSegment = segments[0] as string | undefined;
    const isPublicShare = currentSegment === 'share';
    const isLogin = currentSegment === 'login';

    if (!user) {
      // Unauthenticated user attempting to access private tabs or private screens
      if (!isLogin && !isPublicShare) {
        router.replace('/login');
      }
    } else {
      // Authenticated user on login or empty root
      if (isLogin || currentSegment === undefined || currentSegment === 'index') {
        router.replace('/(tabs)');
      }
    }
  }, [user, loading, segments, router]);

  if (loading) {
    return (
      <View style={[styles.container, styles.loadingCenter]}>
        <StatusBar style="light" />
        <Image
          source={require('../../assets/logo.png')}
          style={{ width: 64, height: 64, marginBottom: 16 }}
          contentFit="contain"
        />
        <ActivityIndicator size="large" color={Colors.primary} />
        <Text style={styles.loadingText}>Loading Marakadhey...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: Colors.background },
          animation: 'fade_from_bottom',
        }}
      >
        <Stack.Screen name="index" options={{ headerShown: false }} />
        <Stack.Screen name="login" options={{ headerShown: false }} />
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="opportunity/[id]" options={{ headerShown: false, presentation: 'card' }} />
        <Stack.Screen name="share/[id]" options={{ headerShown: false, presentation: 'card' }} />
      </Stack>
      <SecurityLockOverlay />
    </View>
  );
}

export default function RootLayout() {
  return (
    <AuthProvider>
      <SecurityProvider>
        <OpportunityProvider>
          <AuthGuardNavigator />
        </OpportunityProvider>
      </SecurityProvider>
    </AuthProvider>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  loadingCenter: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#090D16',
    gap: 8,
  },
  loadingText: {
    color: '#9CA3AF',
    fontSize: 13,
    fontWeight: '600',
    marginTop: 8,
  },
});

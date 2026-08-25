import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { Colors } from '../constants/theme';
import { useAuth } from '../context/AuthContext';
import { User } from 'lucide-react-native';

export const MarakadheyHeader: React.FC = () => {
  const router = useRouter();
  const { user } = useAuth();

  return (
    <View style={styles.header}>
      <View style={styles.leftCol}>
        <View style={styles.brandRow}>
          <Image
            source={require('../../assets/logo.png')}
            style={styles.logoImage}
            contentFit="contain"
          />
          <Text style={styles.brandName}>Marakadhey</Text>
        </View>
        <Text style={styles.tagline}>Don't lose opportunities.</Text>
      </View>

      <TouchableOpacity
        style={styles.userBadge}
        onPress={() => {
          if (user) {
            router.push('/(tabs)/settings');
          } else {
            router.push('/login');
          }
        }}
        activeOpacity={0.8}
      >
        <User size={14} color={Colors.primary} />
        <Text style={styles.userBadgeText} numberOfLines={1}>
          {user?.displayName || 'Sign In'}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  header: {
    backgroundColor: Colors.headerBg,
    paddingHorizontal: 20,
    paddingTop: 14,
    paddingBottom: 12,
    borderBottomWidth: 3,
    borderBottomColor: Colors.headerBorder,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  leftCol: {
    flex: 1,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  logoImage: {
    width: 28,
    height: 28,
  },
  brandName: {
    color: '#FFFFFF',
    fontSize: 22,
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  tagline: {
    color: Colors.taglineText,
    fontSize: 12,
    fontWeight: '400',
    marginTop: 1,
  },
  userBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(255, 107, 0, 0.15)',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(255, 107, 0, 0.3)',
  },
  userBadgeText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
    maxWidth: 90,
  },
});

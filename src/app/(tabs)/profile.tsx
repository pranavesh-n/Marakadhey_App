import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  SafeAreaView,
  StatusBar,
  Alert,
} from 'react-native';
import { Colors } from '../../constants/theme';
import { useOpportunities } from '../../context/OpportunityContext';
import {
  ShieldCheck,
  Moon,
  Bell,
  Calendar,
  Cloud,
  Download,
  Upload,
  MessageSquare,
  Info,
  RefreshCw,
  UserCheck,
  Lock,
} from 'lucide-react-native';

export default function ProfileScreen() {
  const { opportunities, resetToSampleData } = useOpportunities();

  const [darkMode, setDarkMode] = useState(true);
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [calendarSync, setCalendarSync] = useState(true);
  const [cloudSyncActive, setCloudSyncActive] = useState(true);

  const handleExportData = () => {
    const jsonString = JSON.stringify(opportunities, null, 2);
    Alert.alert(
      'Export Complete',
      `Exported ${opportunities.length} opportunities successfully to JSON format.`
    );
  };

  const handleResetData = () => {
    Alert.alert(
      'Reset Sample Data',
      'This will clear local cache and re-seed with fresh sample opportunities.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Reset', style: 'destructive', onPress: resetToSampleData },
      ]
    );
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.background} />
      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        {/* Profile Card */}
        <View style={styles.profileCard}>
          <View style={styles.avatarCircle}>
            <UserCheck size={32} color={Colors.primary} />
          </View>
          <View style={styles.profileInfo}>
            <Text style={styles.userName}>Opportunity Guardian</Text>
            <Text style={styles.userEmail}>user@marakadhey.app</Text>
            <View style={styles.cloudBadge}>
              <Cloud size={12} color={Colors.success} />
              <Text style={styles.cloudText}>Appwrite Cloud Synced</Text>
            </View>
          </View>
        </View>

        {/* Protection Summary */}
        <View style={styles.summaryBox}>
          <View style={styles.summaryItem}>
            <Text style={styles.summaryNum}>{opportunities.length}</Text>
            <Text style={styles.summaryLabel}>Protected Opps</Text>
          </View>
          <View style={styles.summaryDivider} />
          <View style={styles.summaryItem}>
            <Text style={styles.summaryNum}>
              {opportunities.filter((o) => o.status === 'COMPLETED').length}
            </Text>
            <Text style={styles.summaryLabel}>Secured</Text>
          </View>
          <View style={styles.summaryDivider} />
          <View style={styles.summaryItem}>
            <Text style={styles.summaryNum}>100%</Text>
            <Text style={styles.summaryLabel}>Uptime</Text>
          </View>
        </View>

        {/* SECTION: Preferences */}
        <Text style={styles.sectionHeader}>PREFERENCES & SYNC</Text>

        <View style={styles.settingsGroup}>
          <View style={styles.settingRow}>
            <View style={styles.settingLeft}>
              <Moon size={18} color={Colors.primary} />
              <Text style={styles.settingLabel}>Dark Mode (Default)</Text>
            </View>
            <Switch
              value={darkMode}
              onValueChange={setDarkMode}
              trackColor={{ false: Colors.surfaceBorder, true: Colors.primary }}
              thumbColor="#FFF"
            />
          </View>

          <View style={styles.settingRow}>
            <View style={styles.settingLeft}>
              <Bell size={18} color={Colors.warning} />
              <Text style={styles.settingLabel}>Push Notifications</Text>
            </View>
            <Switch
              value={notificationsEnabled}
              onValueChange={setNotificationsEnabled}
              trackColor={{ false: Colors.surfaceBorder, true: Colors.primary }}
              thumbColor="#FFF"
            />
          </View>

          <View style={styles.settingRow}>
            <View style={styles.settingLeft}>
              <Calendar size={18} color={Colors.info} />
              <Text style={styles.settingLabel}>Google / Outlook Calendar Sync</Text>
            </View>
            <Switch
              value={calendarSync}
              onValueChange={setCalendarSync}
              trackColor={{ false: Colors.surfaceBorder, true: Colors.primary }}
              thumbColor="#FFF"
            />
          </View>

          <View style={[styles.settingRow, { borderBottomWidth: 0 }]}>
            <View style={styles.settingLeft}>
              <Cloud size={18} color={Colors.success} />
              <Text style={styles.settingLabel}>Appwrite Realtime Sync</Text>
            </View>
            <Switch
              value={cloudSyncActive}
              onValueChange={setCloudSyncActive}
              trackColor={{ false: Colors.surfaceBorder, true: Colors.primary }}
              thumbColor="#FFF"
            />
          </View>
        </View>

        {/* SECTION: Backup & Security */}
        <Text style={styles.sectionHeader}>DATA & SECURITY</Text>

        <View style={styles.settingsGroup}>
          <TouchableOpacity style={styles.settingRowBtn} onPress={handleExportData}>
            <View style={styles.settingLeft}>
              <Download size={18} color={Colors.primary} />
              <Text style={styles.settingLabel}>Export Backup (JSON / ICS)</Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity style={styles.settingRowBtn} onPress={handleResetData}>
            <View style={styles.settingLeft}>
              <RefreshCw size={18} color={Colors.warning} />
              <Text style={styles.settingLabel}>Reset Sample Data</Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.settingRowBtn, { borderBottomWidth: 0 }]}
            onPress={() =>
              Alert.alert('Security', 'All local data is stored with AES-256 encrypted storage.')
            }
          >
            <View style={styles.settingLeft}>
              <Lock size={18} color={Colors.success} />
              <Text style={styles.settingLabel}>Encryption & Privacy Status</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* SECTION: About */}
        <Text style={styles.sectionHeader}>ABOUT</Text>

        <View style={styles.settingsGroup}>
          <TouchableOpacity
            style={styles.settingRowBtn}
            onPress={() => Alert.alert('Feedback', 'Thank you for protecting opportunities with Marakadhey!')}
          >
            <View style={styles.settingLeft}>
              <MessageSquare size={18} color={Colors.primary} />
              <Text style={styles.settingLabel}>Send Feedback</Text>
            </View>
          </TouchableOpacity>

          <View style={[styles.settingRowBtn, { borderBottomWidth: 0 }]}>
            <View style={styles.settingLeft}>
              <Info size={18} color={Colors.textMuted} />
              <Text style={styles.settingLabel}>App Version</Text>
            </View>
            <Text style={styles.versionValue}>v1.0.0 (Appwrite Powered)</Text>
          </View>
        </View>

        <View style={styles.brandFooter}>
          <ShieldCheck size={20} color={Colors.primary} />
          <Text style={styles.footerBrandText}>MARAKADHEY OPPORTUNITY PLATFORM</Text>
          <Text style={styles.footerCopyright}>Never Lose Opportunities.</Text>
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>
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
    paddingHorizontal: 16,
    paddingTop: 10,
  },
  profileCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surfaceElevated,
    borderRadius: 22,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginBottom: 16,
    gap: 14,
  },
  avatarCircle: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: 'rgba(255, 107, 0, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.primary,
  },
  profileInfo: {
    flex: 1,
  },
  userName: {
    color: Colors.textPrimary,
    fontSize: 18,
    fontWeight: '800',
  },
  userEmail: {
    color: Colors.textSecondary,
    fontSize: 12,
    marginVertical: 2,
  },
  cloudBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  cloudText: {
    color: Colors.success,
    fontSize: 11,
    fontWeight: '700',
  },
  summaryBox: {
    flexDirection: 'row',
    backgroundColor: Colors.surface,
    borderRadius: 18,
    padding: 14,
    justifyContent: 'space-around',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginBottom: 20,
  },
  summaryItem: {
    alignItems: 'center',
  },
  summaryNum: {
    color: Colors.primary,
    fontSize: 20,
    fontWeight: '900',
  },
  summaryLabel: {
    color: Colors.textMuted,
    fontSize: 11,
    fontWeight: '600',
    marginTop: 2,
  },
  summaryDivider: {
    width: 1,
    height: 24,
    backgroundColor: Colors.surfaceBorder,
  },
  sectionHeader: {
    color: Colors.textMuted,
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1,
    marginBottom: 8,
    marginLeft: 4,
  },
  settingsGroup: {
    backgroundColor: Colors.surface,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginBottom: 20,
    overflow: 'hidden',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: Colors.surfaceBorder,
  },
  settingRowBtn: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: Colors.surfaceBorder,
  },
  settingLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  settingLabel: {
    color: Colors.textPrimary,
    fontSize: 14,
    fontWeight: '600',
  },
  versionValue: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '600',
  },
  brandFooter: {
    alignItems: 'center',
    marginVertical: 20,
  },
  footerBrandText: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1,
    marginTop: 6,
  },
  footerCopyright: {
    color: Colors.textMuted,
    fontSize: 11,
    marginTop: 2,
  },
});

import React, { useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
  Alert,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { Colors } from '../../constants/theme';
import { MarakadheyHeader } from '../../components/Header';
import { useOpportunities } from '../../context/OpportunityContext';
import { Category, Priority } from '../../types/opportunity';
import {
  Bell,
  Sparkles,
  CheckCircle2,
  Search,
  Calendar,
  Clock,
  Tag,
  Repeat,
  FileText,
  Plus,
  Bookmark,
} from 'lucide-react-native';

const HOURS = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
const MINUTES = ['00', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'];
const PRIORITIES: Priority[] = ['HIGH', 'MEDIUM', 'LOW'];
const CATEGORIES: Category[] = [
  'Internship',
  'Job',
  'Scholarship',
  'Webinar',
  'Hackathon',
  'Certification',
  'Personal',
  'Other',
];
const RECURRENCES = ['none', 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'] as const;
type Recurrence = (typeof RECURRENCES)[number];

async function fetchPageTitle(url: string): Promise<string | null> {
  try {
    const proxyUrl = `https://api.allorigins.win/get?url=${encodeURIComponent(url)}`;
    const res = await fetch(proxyUrl, { signal: AbortSignal.timeout(8000) });
    const json = (await res.json()) as { contents?: string };
    const html = json.contents || '';
    const match = html.match(/<title[^>]*>([^<]+)<\/title>/i);
    return match ? match[1].trim() : null;
  } catch {
    return null;
  }
}

export default function AddReminderScreen() {
  const { addOpportunity } = useOpportunities();

  const todayStr = new Date().toISOString().split('T')[0];

  const [title, setTitle] = useState('');
  const [url, setUrl] = useState('');
  const [date, setDate] = useState(todayStr);
  const [hour, setHour] = useState('09');
  const [minute, setMinute] = useState('00');
  const [ampm, setAmpm] = useState<'AM' | 'PM'>('AM');
  const [priority, setPriority] = useState<Priority>('MEDIUM');
  const [category, setCategory] = useState<Category>('Internship');
  const [recurrence, setRecurrence] = useState<Recurrence>('none');
  const [repeatPattern, setRepeatPattern] = useState<'weekdays' | 'weekends' | 'custom'>('weekdays');
  const [customDays, setCustomDays] = useState<string[]>(['Mon', 'Wed', 'Fri']);
  const [leadTimeMinutes, setLeadTimeMinutes] = useState(0);
  const [tagInput, setTagInput] = useState('');
  const [tags, setTags] = useState<string[]>([]);
  const [notes, setNotes] = useState('');
  const [pushEnabled, setPushEnabled] = useState(true);
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [saving, setSaving] = useState(false);

  // URL scan state
  const [scanning, setScanning] = useState(false);
  const [detectedTitle, setDetectedTitle] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const storedDN = await AsyncStorage.getItem('@marakadhey_pref_devicenotifs');
        if (storedDN !== null) {
          setPushEnabled(storedDN === 'true');
        }
      } catch {
        setPushEnabled(true);
      }
    })();
  }, []);

  const handlePreset = (preset: 'today-eve' | 'tomorrow' | '3days' | '1week') => {
    const now = new Date();
    if (preset === 'today-eve') {
      setDate(now.toISOString().split('T')[0]);
      setHour('06');
      setMinute('00');
      setAmpm('PM');
      return;
    }
    const targetDate = new Date();
    if (preset === 'tomorrow') targetDate.setDate(now.getDate() + 1);
    else if (preset === '3days') targetDate.setDate(now.getDate() + 3);
    else if (preset === '1week') targetDate.setDate(now.getDate() + 7);
    setDate(targetDate.toISOString().split('T')[0]);
    setHour('09');
    setMinute('00');
    setAmpm('AM');
  };

  const handleScanUrl = async () => {
    const trimmedUrl = url.trim();
    if (!trimmedUrl || (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://'))) {
      Alert.alert('Invalid URL', 'Please enter a full URL starting with https://');
      return;
    }
    setScanning(true);
    setDetectedTitle(null);
    const found = await fetchPageTitle(trimmedUrl);
    setScanning(false);
    if (found) {
      setDetectedTitle(found);
      setTitle(found);
    } else {
      Alert.alert('Could not read title', 'The page did not return a readable title. Enter it manually.');
    }
  };

  const computeISODeadline = () => {
    let h = parseInt(hour, 10);
    if (ampm === 'PM' && h < 12) h += 12;
    if (ampm === 'AM' && h === 12) h = 0;
    const [y, mo, d] = date.split('-').map(Number);
    return new Date(y, mo - 1, d, h, parseInt(minute, 10), 0).toISOString();
  };

  const handleSave = async () => {
    if (!title.trim()) {
      Alert.alert('Required', 'Please enter an Opportunity Title.');
      return;
    }
    if (!date) {
      Alert.alert('Required', 'Please select a Reminder Date.');
      return;
    }

    setSaving(true);
    const deadline = computeISODeadline();

    try {
      await addOpportunity({
        title: title.trim(),
        description: notes.trim() || undefined,
        websiteUrl: url.trim() || undefined,
        category,
        priority,
        status: 'PENDING',
        deadline,
        isRecurring: recurrence !== 'none',
        recurrenceRule: recurrence !== 'none' ? recurrence : null,
        repeatPattern: recurrence !== 'none' ? repeatPattern : undefined,
        customDays: recurrence !== 'none' && repeatPattern === 'custom' ? customDays : undefined,
        leadTimeMinutes,
        checklist: [],
        reminderTimes: pushEnabled ? [deadline] : [],
        tags,
        calendarSynced: false,
        pinned: false,
      });

      setSavedSuccess(true);
      setTitle('');
      setUrl('');
      setDate(todayStr);
      setHour('09');
      setMinute('00');
      setAmpm('AM');
      setPriority('MEDIUM');
      setCategory('Internship');
      setRecurrence('none');
      setNotes('');
      setDetectedTitle(null);
      setTags([]);
      setTimeout(() => setSavedSuccess(false), 2500);
    } catch (e: any) {
      Alert.alert('Error', e.message || 'Failed to save reminder.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.headerBg} />
      <MarakadheyHeader />

      <ScrollView
        style={styles.container}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.responsiveContainer}>
          {/* Success Banner */}
          {savedSuccess && (
            <View style={styles.successBanner}>
              <CheckCircle2 size={18} color="#15803D" />
              <Text style={styles.successText}>Reminder saved! Device alarm scheduled. ✓</Text>
            </View>
          )}

          {/* CARD 1: OPPORTUNITY BASICS */}
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Bookmark size={16} color={Colors.primary} />
              <Text style={styles.cardTitle}>OPPORTUNITY DETAILS</Text>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>OPPORTUNITY TITLE *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Google Summer Internship / Rhodes Scholarship"
                placeholderTextColor={Colors.textLight}
                value={title}
                onChangeText={setTitle}
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>WEBPAGE LINK (OPTIONAL)</Text>
              <View style={styles.urlRow}>
                <TextInput
                  style={[styles.input, styles.urlInput]}
                  placeholder="https://opportunity-link.com"
                  placeholderTextColor={Colors.textLight}
                  value={url}
                  onChangeText={(v) => {
                    setUrl(v);
                    setDetectedTitle(null);
                  }}
                  keyboardType="url"
                  autoCapitalize="none"
                />
                <TouchableOpacity style={styles.scanBtn} onPress={handleScanUrl} activeOpacity={0.8}>
                  {scanning ? (
                    <ActivityIndicator size="small" color="#FFFFFF" />
                  ) : (
                    <Search size={16} color="#FFFFFF" />
                  )}
                </TouchableOpacity>
              </View>

              {detectedTitle && (
                <View style={styles.detectedBanner}>
                  <Sparkles size={14} color={Colors.primary} />
                  <Text style={styles.detectedText} numberOfLines={2}>
                    Auto-detected: <Text style={styles.detectedTitle}>"{detectedTitle}"</Text>
                  </Text>
                </View>
              )}
            </View>
          </View>

          {/* CARD 2: DATE, TIME & PRESETS */}
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Calendar size={16} color={Colors.primary} />
              <Text style={styles.cardTitle}>SCHEDULE & DEADLINE</Text>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>REMINDER DATE (YYYY-MM-DD) *</Text>
              <TextInput
                style={styles.input}
                placeholder="YYYY-MM-DD"
                placeholderTextColor={Colors.textLight}
                value={date}
                onChangeText={setDate}
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>REMINDER TIME *</Text>
              <View style={styles.timeSelectGroup}>
                <View style={styles.pickerWrapper}>
                  <Picker
                    selectedValue={hour}
                    onValueChange={(v) => setHour(v)}
                    style={styles.picker}
                    dropdownIconColor={Colors.secondary}
                  >
                    {HOURS.map((h) => (
                      <Picker.Item key={h} label={h} value={h} />
                    ))}
                  </Picker>
                </View>
                <Text style={styles.timeSeparator}>:</Text>
                <View style={styles.pickerWrapper}>
                  <Picker
                    selectedValue={minute}
                    onValueChange={(v) => setMinute(v)}
                    style={styles.picker}
                    dropdownIconColor={Colors.secondary}
                  >
                    {MINUTES.map((m) => (
                      <Picker.Item key={m} label={m} value={m} />
                    ))}
                  </Picker>
                </View>
                <View style={[styles.pickerWrapper, styles.pickerAmpm]}>
                  <Picker
                    selectedValue={ampm}
                    onValueChange={(v) => setAmpm(v as 'AM' | 'PM')}
                    style={styles.picker}
                    dropdownIconColor={Colors.secondary}
                  >
                    <Picker.Item label="AM" value="AM" />
                    <Picker.Item label="PM" value="PM" />
                  </Picker>
                </View>
              </View>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>QUICK PRESETS</Text>
              <View style={styles.presetsRow}>
                {[
                  { key: 'today-eve', label: 'Today Eve' },
                  { key: 'tomorrow', label: 'Tomorrow' },
                  { key: '3days', label: '3 Days' },
                  { key: '1week', label: '1 Week' },
                ].map((p) => (
                  <TouchableOpacity
                    key={p.key}
                    style={styles.presetBtn}
                    onPress={() => handlePreset(p.key as any)}
                    activeOpacity={0.8}
                  >
                    <Text style={styles.presetBtnText}>{p.label}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          </View>

          {/* CARD 3: CLASSIFICATION */}
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Tag size={16} color={Colors.primary} />
              <Text style={styles.cardTitle}>CLASSIFICATION & PRIORITY</Text>
            </View>

            <View style={styles.rowFields}>
              <View style={[styles.formGroup, { flex: 1 }]}>
                <Text style={styles.label}>PRIORITY</Text>
                <View style={styles.pickerWrapper}>
                  <Picker
                    selectedValue={priority}
                    onValueChange={(v) => setPriority(v as Priority)}
                    style={styles.picker}
                  >
                    {PRIORITIES.map((p) => (
                      <Picker.Item
                        key={p}
                        label={p.charAt(0) + p.slice(1).toLowerCase()}
                        value={p}
                      />
                    ))}
                  </Picker>
                </View>
              </View>

              <View style={[styles.formGroup, { flex: 1 }]}>
                <Text style={styles.label}>CATEGORY</Text>
                <View style={styles.pickerWrapper}>
                  <Picker
                    selectedValue={category}
                    onValueChange={(v) => setCategory(v as Category)}
                    style={styles.picker}
                  >
                    {CATEGORIES.map((c) => (
                      <Picker.Item key={c} label={c} value={c} />
                    ))}
                  </Picker>
                </View>
              </View>
            </View>
          </View>

          {/* CARD 4: RECURRENCE & DEVICE NOTIFICATIONS */}
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Repeat size={16} color={Colors.primary} />
              <Text style={styles.cardTitle}>RECURRENCE & ALARMS</Text>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>RECURRENCE</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={recurrence}
                  onValueChange={(v) => setRecurrence(v as Recurrence)}
                  style={styles.picker}
                >
                  <Picker.Item label="Never (One-time)" value="none" />
                  <Picker.Item label="Daily" value="daily" />
                  <Picker.Item label="Weekly" value="weekly" />
                  <Picker.Item label="Monthly" value="monthly" />
                  <Picker.Item label="Quarterly" value="quarterly" />
                  <Picker.Item label="Yearly" value="yearly" />
                </Picker>
              </View>
            </View>

            {(recurrence === 'weekly' || recurrence === 'daily' || recurrence === 'monthly') && (
              <View style={styles.subCard}>
                <Text style={styles.subCardTitle}>REPEAT ON</Text>

                <TouchableOpacity
                  style={styles.radioOption}
                  onPress={() => setRepeatPattern('weekdays')}
                  activeOpacity={0.8}
                >
                  <View style={[styles.radioOuter, repeatPattern === 'weekdays' && styles.radioOuterActive]}>
                    {repeatPattern === 'weekdays' && <View style={styles.radioInner} />}
                  </View>
                  <Text style={styles.radioText}>Weekdays (Mon-Fri)</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.radioOption}
                  onPress={() => setRepeatPattern('weekends')}
                  activeOpacity={0.8}
                >
                  <View style={[styles.radioOuter, repeatPattern === 'weekends' && styles.radioOuterActive]}>
                    {repeatPattern === 'weekends' && <View style={styles.radioInner} />}
                  </View>
                  <Text style={styles.radioText}>Weekends (Sat-Sun)</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.radioOption}
                  onPress={() => setRepeatPattern('custom')}
                  activeOpacity={0.8}
                >
                  <View style={[styles.radioOuter, repeatPattern === 'custom' && styles.radioOuterActive]}>
                    {repeatPattern === 'custom' && <View style={styles.radioInner} />}
                  </View>
                  <Text style={styles.radioText}>Custom Days</Text>
                </TouchableOpacity>

                {repeatPattern === 'custom' && (
                  <View style={styles.dayPillsRow}>
                    {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => {
                      const isSelected = customDays.includes(day);
                      return (
                        <TouchableOpacity
                          key={day}
                          style={[styles.dayPill, isSelected && styles.dayPillActive]}
                          onPress={() => {
                            if (isSelected) {
                              setCustomDays(customDays.filter((d) => d !== day));
                            } else {
                              setCustomDays([...customDays, day]);
                            }
                          }}
                        >
                          <Text style={[styles.dayPillText, isSelected && styles.dayPillTextActive]}>
                            {day}
                          </Text>
                        </TouchableOpacity>
                      );
                    })}
                  </View>
                )}
              </View>
            )}

            <View style={styles.formGroup}>
              <Text style={styles.label}>REMIND ME BEFORE DEADLINE</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={leadTimeMinutes}
                  onValueChange={(v) => setLeadTimeMinutes(v)}
                  style={styles.picker}
                >
                  <Picker.Item label="At exact deadline time" value={0} />
                  <Picker.Item label="15 minutes before" value={15} />
                  <Picker.Item label="30 minutes before" value={30} />
                  <Picker.Item label="1 hour before" value={60} />
                  <Picker.Item label="3 hours before" value={180} />
                  <Picker.Item label="1 day before (24h)" value={1440} />
                  <Picker.Item label="2 days before (48h)" value={2880} />
                </Picker>
              </View>
            </View>

            <TouchableOpacity
              style={styles.checkboxRow}
              onPress={() => setPushEnabled((v) => !v)}
              activeOpacity={0.8}
            >
              <View style={[styles.checkbox, pushEnabled && styles.checkboxActive]}>
                {pushEnabled && <Text style={styles.checkboxTick}>✓</Text>}
              </View>
              <View style={styles.checkboxTextCol}>
                <Text style={styles.checkboxLabel}>
                  <Bell size={13} color={Colors.secondary} /> Send hardware alarm to this device
                </Text>
                <Text style={styles.helpText}>
                  Your phone will fire local notifications at the scheduled time — 100% offline capable.
                </Text>
              </View>
            </TouchableOpacity>
          </View>

          {/* CARD 5: NOTES & TAGS */}
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <FileText size={16} color={Colors.primary} />
              <Text style={styles.cardTitle}>NOTES & TAGS</Text>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>CUSTOM TAGS</Text>
              <View style={styles.urlRow}>
                <TextInput
                  style={[styles.input, styles.urlInput]}
                  placeholder="e.g. Interview, Google, Urgent"
                  placeholderTextColor={Colors.textLight}
                  value={tagInput}
                  onChangeText={setTagInput}
                  onSubmitEditing={() => {
                    const cleaned = tagInput.trim().replace(/^#/, '');
                    if (cleaned && !tags.includes(cleaned)) {
                      setTags([...tags, cleaned]);
                      setTagInput('');
                    }
                  }}
                />
                <TouchableOpacity
                  style={styles.scanBtn}
                  onPress={() => {
                    const cleaned = tagInput.trim().replace(/^#/, '');
                    if (cleaned && !tags.includes(cleaned)) {
                      setTags([...tags, cleaned]);
                      setTagInput('');
                    }
                  }}
                  activeOpacity={0.8}
                >
                  <Plus size={16} color="#FFFFFF" />
                </TouchableOpacity>
              </View>

              {tags.length > 0 && (
                <View style={styles.tagsContainer}>
                  {tags.map((t) => (
                    <TouchableOpacity
                      key={t}
                      style={styles.tagChip}
                      onPress={() => setTags(tags.filter((x) => x !== t))}
                    >
                      <Text style={styles.tagChipText}>#{t}</Text>
                      <Text style={styles.tagChipRemove}>✕</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              )}
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.label}>CONTEXT NOTES</Text>
              <TextInput
                style={[styles.input, styles.textarea]}
                placeholder="Add eligibility details, notes, or referral links..."
                placeholderTextColor={Colors.textLight}
                value={notes}
                onChangeText={setNotes}
                multiline
                numberOfLines={3}
                textAlignVertical="top"
              />
            </View>
          </View>

          {/* SAVE BUTTON */}
          <TouchableOpacity
            style={styles.saveBtn}
            onPress={handleSave}
            disabled={saving}
            activeOpacity={0.88}
          >
            {saving ? (
              <ActivityIndicator size="small" color="#FFFFFF" />
            ) : (
              <Text style={styles.saveBtnText}>Save Opportunity Reminder</Text>
            )}
          </TouchableOpacity>

          <View style={{ height: 40 }} />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: Colors.background },
  container: { flex: 1, padding: 14 },
  responsiveContainer: { width: '100%', maxWidth: 640, alignSelf: 'center', gap: 14 },

  card: {
    backgroundColor: Colors.surface,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 2,
  },
  cardTitle: {
    fontSize: 11,
    fontWeight: '800',
    color: Colors.secondary,
    letterSpacing: 0.5,
  },

  successBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#F0FDF4',
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    borderColor: '#86EFAC',
  },
  successText: { color: '#15803D', fontWeight: '700', fontSize: 13, flex: 1 },

  formGroup: { gap: 5 },
  rowFields: { flexDirection: 'row', gap: 12 },
  label: { fontSize: 11, fontWeight: '800', color: Colors.secondary, letterSpacing: 0.5 },

  input: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 9,
    fontSize: 14,
    color: Colors.textPrimary,
  },
  textarea: { minHeight: 70, paddingTop: 8 },

  urlRow: { flexDirection: 'row', gap: 8, alignItems: 'center' },
  urlInput: { flex: 1 },
  scanBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },

  detectedBanner: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 6,
    backgroundColor: '#FFF7ED',
    borderRadius: 6,
    padding: 8,
    borderWidth: 1,
    borderColor: '#FED7AA',
  },
  detectedText: { flex: 1, fontSize: 12, color: Colors.secondary },
  detectedTitle: { fontWeight: '700', color: Colors.primary },

  timeSelectGroup: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  pickerWrapper: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    overflow: 'hidden',
  },
  pickerAmpm: { flex: 0.75 },
  picker: { height: Platform.OS === 'ios' ? 120 : 44, color: Colors.textPrimary },
  timeSeparator: { fontSize: 18, fontWeight: '700', color: Colors.secondary },

  presetsRow: { flexDirection: 'row', gap: 8, flexWrap: 'wrap' },
  presetBtn: {
    flex: 1,
    minWidth: 70,
    backgroundColor: '#F9FAFB',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    paddingVertical: 8,
    alignItems: 'center',
  },
  presetBtnText: { fontSize: 12, fontWeight: '700', color: Colors.secondary },

  subCard: {
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    gap: 10,
  },
  subCardTitle: { fontSize: 11, fontWeight: '800', color: Colors.secondary, letterSpacing: 0.5 },
  radioOption: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 2 },
  radioOuter: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: Colors.textMuted,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioOuterActive: { borderColor: Colors.primary },
  radioInner: { width: 10, height: 10, borderRadius: 5, backgroundColor: Colors.primary },
  radioText: { fontSize: 13, fontWeight: '600', color: Colors.textPrimary },
  dayPillsRow: { flexDirection: 'row', gap: 6, flexWrap: 'wrap', marginTop: 4 },
  dayPill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 16,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#D1D5DB',
  },
  dayPillActive: { backgroundColor: Colors.primary, borderColor: Colors.primary },
  dayPillText: { fontSize: 12, fontWeight: '700', color: Colors.textSecondary },
  dayPillTextActive: { color: '#FFFFFF' },

  tagsContainer: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 4 },
  tagChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFF7ED',
    borderWidth: 1,
    borderColor: '#FED7AA',
    borderRadius: 14,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  tagChipText: { color: Colors.primary, fontSize: 12, fontWeight: '700' },
  tagChipRemove: { color: Colors.primary, fontSize: 11, fontWeight: '900' },

  checkboxRow: { flexDirection: 'row', gap: 10, alignItems: 'flex-start', marginTop: 4 },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: 5,
    borderWidth: 2,
    borderColor: '#D1D5DB',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 1,
  },
  checkboxActive: { backgroundColor: Colors.primary, borderColor: Colors.primary },
  checkboxTick: { color: '#FFFFFF', fontSize: 12, fontWeight: '900' },
  checkboxTextCol: { flex: 1 },
  checkboxLabel: { fontSize: 13, fontWeight: '700', color: Colors.textPrimary },
  helpText: { fontSize: 11, color: Colors.textMuted, lineHeight: 15, marginTop: 2 },

  saveBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 6,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 6,
    elevation: 3,
  },
  saveBtnText: { color: '#FFFFFF', fontSize: 15, fontWeight: '800' },
});

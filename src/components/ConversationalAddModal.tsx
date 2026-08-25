import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
} from 'react-native';
import { Colors } from '../constants/theme';
import { Category, Priority } from '../types/opportunity';
import { X, Link2, Mic, Image, Sparkles, Check, Calendar } from 'lucide-react-native';

interface ModalProps {
  visible: boolean;
  onClose: () => void;
  onSave: (data: {
    title: string;
    description: string;
    websiteUrl: string;
    category: Category;
    priority: Priority;
    deadline: string;
  }) => void;
}

const CATEGORIES: Category[] = [
  'Internship',
  'Hackathon',
  'Scholarship',
  'Job',
  'Assignment',
  'Conference',
  'Exam',
  'Registration',
  'Application',
  'Other',
];

const PRIORITIES: Priority[] = ['HIGH', 'MEDIUM', 'LOW'];

export const ConversationalAddModal: React.FC<ModalProps> = ({ visible, onClose, onSave }) => {
  const [activeTab, setActiveTab] = useState<'MANUAL' | 'LINK' | 'VOICE' | 'PHOTO'>('MANUAL');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [websiteUrl, setWebsiteUrl] = useState('');
  const [category, setCategory] = useState<Category>('Internship');
  const [priority, setPriority] = useState<Priority>('HIGH');

  // Default deadline 2 days from now
  const defaultDeadline = new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString().slice(0, 16);
  const [deadlineString, setDeadlineString] = useState(defaultDeadline);

  const handleLinkPaste = (url: string) => {
    setWebsiteUrl(url);
    if (!url) return;
    try {
      const parsedUrl = new URL(url.startsWith('http') ? url : `https://${url}`);
      const domain = parsedUrl.hostname.replace('www.', '').split('.')[0];
      const capitalized = domain.charAt(0).toUpperCase() + domain.slice(1);
      
      if (!title) {
        setTitle(`${capitalized} Opportunity`);
      }
      if (url.includes('intern') || url.includes('career')) {
        setCategory('Internship');
      } else if (url.includes('hack') || url.includes('dev')) {
        setCategory('Hackathon');
      } else if (url.includes('scholarship') || url.includes('edu')) {
        setCategory('Scholarship');
      }
    } catch (e) {
      // Invalid URL format fallback
    }
  };

  const handleSave = () => {
    if (!title.trim()) {
      Alert.alert('Title Required', 'Please enter an opportunity title.');
      return;
    }

    const isoDeadline = new Date(deadlineString).toISOString();

    onSave({
      title: title.trim(),
      description: description.trim(),
      websiteUrl: websiteUrl.trim(),
      category,
      priority,
      deadline: isoDeadline,
    });

    // Reset form
    setTitle('');
    setDescription('');
    setWebsiteUrl('');
    setCategory('Internship');
    setPriority('HIGH');
    onClose();
  };

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={styles.modalCard}>
          {/* Header Bar */}
          <View style={styles.header}>
            <View style={styles.titleRow}>
              <Sparkles size={20} color={Colors.primary} />
              <Text style={styles.headerTitle}>Protect New Opportunity</Text>
            </View>
            <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
              <X size={20} color={Colors.textSecondary} />
            </TouchableOpacity>
          </View>

          {/* Quick Input Method Tabs */}
          <View style={styles.tabsRow}>
            <TouchableOpacity
              style={[styles.tab, activeTab === 'MANUAL' && styles.activeTab]}
              onPress={() => setActiveTab('MANUAL')}
            >
              <Text style={[styles.tabText, activeTab === 'MANUAL' && styles.activeTabText]}>
                ✏️ Manual
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.tab, activeTab === 'LINK' && styles.activeTab]}
              onPress={() => setActiveTab('LINK')}
            >
              <Link2 size={14} color={activeTab === 'LINK' ? Colors.primary : Colors.textMuted} />
              <Text style={[styles.tabText, activeTab === 'LINK' && styles.activeTabText]}>
                Paste Link
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.tab, activeTab === 'VOICE' && styles.activeTab]}
              onPress={() => setActiveTab('VOICE')}
            >
              <Mic size={14} color={activeTab === 'VOICE' ? Colors.primary : Colors.textMuted} />
              <Text style={[styles.tabText, activeTab === 'VOICE' && styles.activeTabText]}>
                Voice
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.tab, activeTab === 'PHOTO' && styles.activeTab]}
              onPress={() => setActiveTab('PHOTO')}
            >
              <Image size={14} color={activeTab === 'PHOTO' ? Colors.primary : Colors.textMuted} />
              <Text style={[styles.tabText, activeTab === 'PHOTO' && styles.activeTabText]}>
                Photo
              </Text>
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.body} showsVerticalScrollIndicator={false}>
            {/* LINK AUTO PARSER BOX */}
            {activeTab === 'LINK' && (
              <View style={styles.pasteBox}>
                <Text style={styles.fieldLabel}>Paste Opportunity URL</Text>
                <TextInput
                  style={styles.input}
                  placeholder="https://careers.google.com/jobs/..."
                  placeholderTextColor={Colors.textMuted}
                  value={websiteUrl}
                  onChangeText={handleLinkPaste}
                  autoCapitalize="none"
                />
                <Text style={styles.helperText}>
                  ✨ Marakadhey will automatically detect title, domain & category.
                </Text>
              </View>
            )}

            {/* VOICE DRAFT BOX */}
            {activeTab === 'VOICE' && (
              <View style={styles.pasteBox}>
                <Text style={styles.fieldLabel}>Voice Note / Audio Transcript</Text>
                <TextInput
                  style={[styles.input, { height: 70 }]}
                  placeholder="e.g. Apply for Rhodes scholarship before Thursday 5 PM..."
                  placeholderTextColor={Colors.textMuted}
                  multiline
                  value={description}
                  onChangeText={txt => {
                    setDescription(txt);
                    if (!title && txt.length > 5) setTitle(txt.slice(0, 30) + '...');
                  }}
                />
              </View>
            )}

            {/* Title Input */}
            <View style={styles.fieldGroup}>
              <Text style={styles.fieldLabel}>Opportunity Title *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Google Summer SWE Internship 2027"
                placeholderTextColor={Colors.textMuted}
                value={title}
                onChangeText={setTitle}
              />
            </View>

            {/* Priority Selector */}
            <View style={styles.fieldGroup}>
              <Text style={styles.fieldLabel}>Priority Level</Text>
              <View style={styles.pillSelectorRow}>
                {PRIORITIES.map(p => (
                  <TouchableOpacity
                    key={p}
                    style={[
                      styles.selectorPill,
                      priority === p && {
                        backgroundColor:
                          p === 'HIGH'
                            ? Colors.priorityHighGlow
                            : p === 'MEDIUM'
                            ? Colors.priorityMediumGlow
                            : Colors.priorityLowGlow,
                        borderColor:
                          p === 'HIGH'
                            ? Colors.priorityHigh
                            : p === 'MEDIUM'
                            ? Colors.priorityMedium
                            : Colors.priorityLow,
                      },
                    ]}
                    onPress={() => setPriority(p)}
                  >
                    <Text
                      style={[
                        styles.selectorPillText,
                        priority === p && {
                          color:
                            p === 'HIGH'
                              ? Colors.priorityHigh
                              : p === 'MEDIUM'
                              ? Colors.priorityMedium
                              : Colors.priorityLow,
                          fontWeight: '800',
                        },
                      ]}
                    >
                      {p === 'HIGH' ? '🔥 HIGH' : p === 'MEDIUM' ? '⚡ MEDIUM' : '🌱 LOW'}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Category Selector */}
            <View style={styles.fieldGroup}>
              <Text style={styles.fieldLabel}>Category</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.horizontalPillRow}>
                {CATEGORIES.map(cat => (
                  <TouchableOpacity
                    key={cat}
                    style={[styles.categoryPill, category === cat && styles.activeCategoryPill]}
                    onPress={() => setCategory(cat)}
                  >
                    <Text
                      style={[
                        styles.categoryPillText,
                        category === cat && styles.activeCategoryPillText,
                      ]}
                    >
                      {cat}
                    </Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

            {/* Deadline ISO / String */}
            <View style={styles.fieldGroup}>
              <Text style={styles.fieldLabel}>Deadline (YYYY-MM-DDTHH:MM)</Text>
              <View style={styles.inputWithIcon}>
                <Calendar size={18} color={Colors.primary} />
                <TextInput
                  style={styles.flexInput}
                  placeholder="2026-08-10T18:00"
                  placeholderTextColor={Colors.textMuted}
                  value={deadlineString}
                  onChangeText={setDeadlineString}
                />
              </View>
            </View>

            {/* Website URL (if manual) */}
            {activeTab !== 'LINK' && (
              <View style={styles.fieldGroup}>
                <Text style={styles.fieldLabel}>Website URL (Optional)</Text>
                <TextInput
                  style={styles.input}
                  placeholder="https://..."
                  placeholderTextColor={Colors.textMuted}
                  value={websiteUrl}
                  onChangeText={setWebsiteUrl}
                  autoCapitalize="none"
                />
              </View>
            )}

            {/* Description Notes */}
            <View style={styles.fieldGroup}>
              <Text style={styles.fieldLabel}>Notes & Instructions</Text>
              <TextInput
                style={[styles.input, { height: 75, textAlignVertical: 'top' }]}
                placeholder="Add referral info, checklist hints, or application requirements..."
                placeholderTextColor={Colors.textMuted}
                multiline
                value={description}
                onChangeText={setDescription}
              />
            </View>
          </ScrollView>

          {/* Submit Button */}
          <TouchableOpacity style={styles.saveBtn} onPress={handleSave} activeOpacity={0.85}>
            <Check size={20} color="#FFF" />
            <Text style={styles.saveBtnText}>Protect Opportunity</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: Colors.overlay,
    justifyContent: 'flex-end',
  },
  modalCard: {
    backgroundColor: Colors.surfaceElevated,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    maxHeight: '90%',
    padding: 20,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  headerTitle: {
    color: Colors.textPrimary,
    fontSize: 18,
    fontWeight: '800',
  },
  closeBtn: {
    padding: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.06)',
    borderRadius: 16,
  },
  tabsRow: {
    flexDirection: 'row',
    backgroundColor: Colors.surface,
    borderRadius: 14,
    padding: 4,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    borderRadius: 10,
    gap: 4,
  },
  activeTab: {
    backgroundColor: 'rgba(255, 107, 0, 0.15)',
  },
  tabText: {
    color: Colors.textMuted,
    fontSize: 12,
    fontWeight: '600',
  },
  activeTabText: {
    color: Colors.primary,
    fontWeight: '700',
  },
  body: {
    marginBottom: 16,
  },
  pasteBox: {
    backgroundColor: 'rgba(255, 107, 0, 0.08)',
    borderRadius: 16,
    padding: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 107, 0, 0.2)',
    marginBottom: 16,
  },
  helperText: {
    color: Colors.primary,
    fontSize: 11,
    marginTop: 6,
    fontWeight: '500',
  },
  fieldGroup: {
    marginBottom: 14,
  },
  fieldLabel: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  input: {
    backgroundColor: Colors.surface,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: Colors.textPrimary,
    fontSize: 14,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  inputWithIcon: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderRadius: 14,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    gap: 10,
  },
  flexInput: {
    flex: 1,
    paddingVertical: 12,
    color: Colors.textPrimary,
    fontSize: 14,
  },
  pillSelectorRow: {
    flexDirection: 'row',
    gap: 8,
  },
  selectorPill: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    borderRadius: 12,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
  },
  selectorPillText: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '600',
  },
  horizontalPillRow: {
    flexDirection: 'row',
  },
  categoryPill: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 12,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.surfaceBorder,
    marginRight: 8,
  },
  activeCategoryPill: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  categoryPillText: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '600',
  },
  activeCategoryPillText: {
    color: '#FFF',
    fontWeight: '800',
  },
  saveBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 18,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 10,
    elevation: 6,
  },
  saveBtnText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
});

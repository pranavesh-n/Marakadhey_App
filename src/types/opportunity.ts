export type Priority = 'HIGH' | 'MEDIUM' | 'LOW';

export type Category =
  | 'Internship'
  | 'Hackathon'
  | 'Scholarship'
  | 'Job'
  | 'Webinar'
  | 'Certification'
  | 'Personal'
  | 'Assignment'
  | 'Conference'
  | 'Exam'
  | 'Registration'
  | 'Application'
  | 'Other';

export type Status = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'ARCHIVED';

export interface ChecklistItem {
  id: string;
  task: string;
  completed: boolean;
}

export interface Attachment {
  id: string;
  name: string;
  url: string;
  type: 'image' | 'pdf' | 'link';
}

export interface HistoryEntry {
  id: string;
  action: 'CREATED' | 'UPDATED' | 'SNOOZED' | 'COMPLETED' | 'UNCOMPLETED' | 'PINNED';
  timestamp: string;
  note?: string;
}

export interface Opportunity {
  id: string;
  ownerUid?: string;
  userId?: string;
  title: string;
  description?: string;
  websiteUrl?: string;
  category: Category;
  priority: Priority;
  status: Status;
  deadline: string; // ISO String date format
  reminderTimes: string[]; // ISO Strings
  isRecurring: boolean;
  recurrenceRule?: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'QUARTERLY' | 'YEARLY' | 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly' | 'none' | null;
  checklist: ChecklistItem[];
  tags: string[];
  notes?: string;
  attachments?: Attachment[];
  pinned: boolean;
  calendarSynced: boolean;
  history: HistoryEntry[];
  createdAt: string;
  updatedAt: string;

  // Enhanced Customizations
  repeatPattern?: 'weekdays' | 'weekends' | 'custom';
  customDays?: string[]; // e.g. ['Mon', 'Wed', 'Fri']
  repeatIntervalDays?: number; // e.g. every 2 days
  leadTimeMinutes?: number; // e.g. 0, 15, 60, 1440
}

export interface SharedReminder {
  shareId: string;
  ownerUid: string;
  ownerDisplayName?: string;
  title: string;
  description?: string;
  websiteUrl?: string;
  category: Category;
  priority: Priority;
  deadline: string;
  isRecurring?: boolean;
  recurrenceRule?: string | null;
  tags?: string[];
  createdAt: string;
}

export interface UserProfile {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  isAnonymous: boolean;
  settings: {
    theme: 'dark';
    defaultSnoozeMinutes: number;
    calendarSyncEnabled: boolean;
    pushNotificationsEnabled: boolean;
    prioritySuggestionsEnabled: boolean;
  };
}

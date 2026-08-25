import { Opportunity } from '../types/opportunity';

const now = new Date();

export const INITIAL_OPPORTUNITIES: Opportunity[] = [
  {
    id: 'opp-1',
    title: 'Google Summer Software Engineering Internship 2027',
    description: '12-week software engineering internship for undergraduate students. Requires proficiency in C++, Java, Python, or Go.',
    websiteUrl: 'https://careers.google.com/jobs/results/',
    category: 'Internship',
    priority: 'HIGH',
    status: 'PENDING',
    deadline: new Date(now.getTime() + 1000 * 60 * 60 * 18).toISOString(), // 18 hours from now (Today)
    reminderTimes: [new Date(now.getTime() + 1000 * 60 * 60 * 2).toISOString()],
    isRecurring: false,
    checklist: [
      { id: 'c1', task: 'Update Resume with React Native projects', completed: true },
      { id: 'c2', task: 'Write tailored Cover Letter', completed: false },
      { id: 'c3', task: 'Submit online application form', completed: false },
      { id: 'c4', task: 'Practice 2 LeetCode Medium questions', completed: false }
    ],
    tags: ['Google', 'SWE', 'Internship', 'Tech'],
    notes: 'Referral requested from Alex on LinkedIn on Friday.',
    pinned: true,
    calendarSynced: true,
    history: [
      { id: 'h1', action: 'CREATED', timestamp: new Date(now.getTime() - 1000 * 60 * 60 * 24).toISOString() },
      { id: 'h2', action: 'PINNED', timestamp: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString() }
    ],
    createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 24).toISOString(),
    updatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString()
  },
  {
    id: 'opp-2',
    title: 'Rhodes Global Scholarship Application 2027',
    description: 'Fully funded postgraduate award supporting exceptional students to study at Oxford University.',
    websiteUrl: 'https://www.rhodeshouse.ox.ac.uk/',
    category: 'Scholarship',
    priority: 'HIGH',
    status: 'PENDING',
    deadline: new Date(now.getTime() + 1000 * 60 * 60 * 42).toISOString(), // 42 hours from now (Tomorrow)
    reminderTimes: [new Date(now.getTime() + 1000 * 60 * 60 * 24).toISOString()],
    isRecurring: false,
    checklist: [
      { id: 'c21', task: 'Gather 4 Recommendation Letters', completed: true },
      { id: 'c22', task: 'Finalize Personal Statement essay', completed: true },
      { id: 'c23', task: 'Obtain official academic transcript', completed: false }
    ],
    tags: ['Scholarship', 'Oxford', 'Postgrad'],
    notes: 'Check global eligibility criteria before final upload.',
    pinned: true,
    calendarSynced: false,
    history: [
      { id: 'h21', action: 'CREATED', timestamp: new Date(now.getTime() - 1000 * 60 * 60 * 48).toISOString() }
    ],
    createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 48).toISOString(),
    updatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 48).toISOString()
  },
  {
    id: 'opp-3',
    title: 'HackMIT 2026 - International Hackathon',
    description: '36-hour flagship hackathon hosted at Massachusetts Institute of Technology.',
    websiteUrl: 'https://hackmit.org/',
    category: 'Hackathon',
    priority: 'MEDIUM',
    status: 'PENDING',
    deadline: new Date(now.getTime() + 1000 * 60 * 60 * 120).toISOString(), // 5 days from now (This Week)
    reminderTimes: [new Date(now.getTime() + 1000 * 60 * 60 * 72).toISOString()],
    isRecurring: false,
    checklist: [
      { id: 'c31', task: 'Form team of 4 developers', completed: true },
      { id: 'c32', task: 'Submit team pitch deck draft', completed: false }
    ],
    tags: ['Hackathon', 'MIT', 'AI', 'Mobile'],
    notes: 'Travel stipend available for international attendees.',
    pinned: false,
    calendarSynced: true,
    history: [
      { id: 'h31', action: 'CREATED', timestamp: new Date(now.getTime() - 1000 * 60 * 60 * 36).toISOString() }
    ],
    createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 36).toISOString(),
    updatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 36).toISOString()
  },
  {
    id: 'opp-4',
    title: 'AWS Cloud Innovators Conference Registration',
    description: 'Virtual summit showcasing serverless architecture, AI agents, and cloud infrastructure.',
    websiteUrl: 'https://aws.amazon.com/events/innovate-online-conference/',
    category: 'Conference',
    priority: 'LOW',
    status: 'PENDING',
    deadline: new Date(now.getTime() + 1000 * 60 * 60 * 240).toISOString(), // 10 days from now
    reminderTimes: [new Date(now.getTime() + 1000 * 60 * 60 * 180).toISOString()],
    isRecurring: false,
    checklist: [
      { id: 'c41', task: 'Register for free online pass', completed: false }
    ],
    tags: ['AWS', 'Cloud', 'Conference', 'Virtual'],
    notes: 'Keynote starts at 9:00 AM PST.',
    pinned: false,
    calendarSynced: false,
    history: [
      { id: 'h41', action: 'CREATED', timestamp: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString() }
    ],
    createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString(),
    updatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString()
  },
  {
    id: 'opp-5',
    title: 'Microsoft Full Stack Developer Job Application',
    description: 'Full-time position for software engineers focusing on Azure Cloud Services & React Native apps.',
    websiteUrl: 'https://careers.microsoft.com/',
    category: 'Job',
    priority: 'HIGH',
    status: 'COMPLETED',
    deadline: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString(), // Yesterday
    reminderTimes: [],
    isRecurring: false,
    checklist: [
      { id: 'c51', task: 'Submit application via portal', completed: true }
    ],
    tags: ['Microsoft', 'FullTime', 'Job'],
    notes: 'Submitted application on portal. Confirmation ID: MSFT-89302',
    pinned: false,
    calendarSynced: true,
    history: [
      { id: 'h51', action: 'CREATED', timestamp: new Date(now.getTime() - 1000 * 60 * 60 * 72).toISOString() },
      { id: 'h52', action: 'COMPLETED', timestamp: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString() }
    ],
    createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 72).toISOString(),
    updatedAt: new Date(now.getTime() - 1000 * 60 * 60 * 12).toISOString()
  }
];

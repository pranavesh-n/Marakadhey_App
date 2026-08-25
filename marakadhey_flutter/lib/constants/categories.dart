class AppConstants {
  static const List<String> categories = [
    'Internship',
    'Job',
    'Scholarship',
    'Webinar',
    'Hackathon',
    'Certification',
    'Exam',
    'Registration',
    'Application',
    'Assignment',
    'Conference',
    'Personal',
    'Other',
  ];

  static const List<String> hours = [
    '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'
  ];

  static final List<String> minutes = List.generate(60, (i) => i.toString().padLeft(2, '0'));

  static const List<String> weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  static const Map<int, String> leadTimeOptions = {
    0: 'At exact deadline time',
    15: '15 minutes before',
    30: '30 minutes before',
    60: '1 hour before',
    180: '3 hours before',
    1440: '1 day before (24 hours)',
    2880: '2 days before (48 hours)',
  };
}

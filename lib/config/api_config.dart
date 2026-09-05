import 'package:flutter/foundation.dart';

class ApiConfig {
  // Android emulators use 10.0.2.2 to reach the host machine.
  // Web and desktop apps use localhost directly.
  static String get baseUrl {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://127.0.0.1:5000';
    }
    return 'http://10.0.2.2:5000';
  }

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String currentUser = '/api/auth/me';
  static const String profile = '/api/profile';
  static const String signup = '/api/auth/signup';
  static const String logout = '/api/auth/logout';

  // Student endpoints
  static const String studentDashboard = '/api/student/dashboard';
  static const String studentCourses = '/api/student/courses';
  static const String studentTests = '/api/student/tests';
  static const String studentSubmitTest = '/api/student/tests/submit';
  static const String studentPerformance = '/api/student/performance';
  static const String studentProfile = '/api/student/profile';
  static const String studentReportBug = '/api/student/report-bug';

  // Instructor endpoints
  static const String instructorDashboard = '/api/instructor/dashboard';
  static const String instructorCourses = '/api/instructor/courses';
  static const String instructorExams = '/api/instructor/exams';
  static const String instructorStudents = '/api/instructor/students';
  static const String instructorProfile = '/api/instructor/profile';
  static const String instructorReportBug = '/api/instructor/report-bug';

  // Admin endpoints
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminUsers = '/api/admin/users';
  static const String adminContent = '/api/admin/content';

  // Reports
  static const String reports = '/api/reports';
  static const String myReports = '/api/reports/mine';

  // Discussion endpoints
  static const String discussions = '/api/discussions';

  // Study Circles
  static const String studyCircles = '/api/study-circles';

  // Health
  static const String health = '/api/health';

  // Packages
  static const String packages = '/api/packages';
  static const String adminPackages = '/api/admin/packages';
}
